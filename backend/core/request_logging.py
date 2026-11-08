"""Describe HTTP activity without recording request bodies, tokens, or headers."""
from collections import OrderedDict
from http import HTTPStatus
import json
import logging
import re
from time import perf_counter

log = logging.getLogger("soundsight.api")

_ACTIONS = (
    ("POST", r"/music-sheets/([^/]+)/recognize", "Recognize sheet music", "item"),
    ("POST", r"/music-sheets/([^/]+)/transcribe-audio", "Transcribe piano audio", "item"),
    ("POST", r"/compositions/([^/]+)/generate", "Generate composition files", "item"),
    ("POST", r"/compositions/([^/]+)/publish", "Publish composition", "item"),
    ("DELETE", r"/compositions/([^/]+)/publish", "Unpublish composition", "item"),
    ("GET", r"/jobs/([^/]+)", "Check job progress", "job"),
    ("POST", r"/jobs/([^/]+)/cancel", "Cancel queued job", "job"),
    ("PUT", r"/notifications/devices/[^/]+", "Register device notifications", None),
    ("DELETE", r"/notifications/devices/[^/]+", "Remove device notifications", None),
)
_RESPONSES = {
    200: "Request succeeded",
    202: "Job accepted; check its state for progress",
    400: "Request is invalid",
    401: "Sign-in is required or has expired",
    403: "Access denied; check email verification and ownership",
    404: "Requested item was not found",
    409: "Request conflicts with the item's current state",
    422: "Request fields failed validation",
    426: "The app needs an update",
    429: "Too many pending jobs; try again later",
    500: "Unexpected backend error; check the error details",
    503: "Backend or processing worker is unavailable; try again later",
}
_STATES = {
    "admitting": "accepting job",
    "queued": "waiting for worker",
    "processing": "processing",
    "finishing": "saving results",
    "completed": "completed and saved",
    "failed": "failed",
    "cancelled": "cancelled",
}


def _clean(value, limit=160):
    return " ".join(str(value).split())[:limit]


def _action(method, path):
    if method == "GET" and path == "/health":
        return "Check backend health", None
    if method == "GET" and path == "/":
        return "Open backend status", None
    for action_method, pattern, label, identifier in _ACTIONS:
        match = re.fullmatch(pattern, path)
        if method == action_method and match:
            return label, f"{identifier}={_clean(match[1])}" if identifier else None
    return f"{method} {_clean(path)}", None


class RequestLoggingMiddleware:
    def __init__(self, app):
        self.app = app
        self._last_job_states = OrderedDict()

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        started = perf_counter()
        status = 500
        response_started = False
        body = bytearray()
        oversized = False

        async def capture_send(message):
            nonlocal status, response_started, oversized
            if message["type"] == "http.response.start":
                status = message["status"]
                response_started = True
            elif message["type"] == "http.response.body" and not oversized:
                chunk = message.get("body", b"")
                if len(body) + len(chunk) <= 8192:
                    body.extend(chunk)
                else:
                    oversized = True
                    body.clear()
            await send(message)

        try:
            await self.app(scope, receive, capture_send)
        except Exception:
            self._record(scope, status, started, body, failed=True,
                         response_started=response_started)
            raise
        else:
            self._record(scope, status, started, body)

    def _record(self, scope, status, started, body, *, failed=False, response_started=False):
        method, path = scope["method"], scope["path"]
        label, identifier = _action(method, path)
        metadata = {}
        try:
            payload = json.loads(body)
            if isinstance(payload, dict):
                metadata = payload
        except (ValueError, UnicodeError):
            pass

        try:
            reason = HTTPStatus(status).phrase
        except ValueError:
            reason = "Response"
        explanation = _RESPONSES.get(status, reason)
        if failed:
            explanation = ("Error after response started; see error details" if response_started
                           else "Request failed; see error details")
        parts = [f"Request: {label}"]
        if identifier:
            parts.append(identifier)
        parts.append(f"Response: {status} {reason} - {explanation}")

        # Only public job metadata is logged. Other response fields are ignored.
        is_job_request = (path.startswith("/jobs/") or
                          (method == "POST" and path.endswith(("/recognize", "/transcribe-audio", "/generate"))))
        job_id = metadata.get("jobId") if is_job_request else None
        state = metadata.get("status") if is_job_request else None
        if isinstance(job_id, str) and identifier != f"job={_clean(job_id)}":
            parts.append(f"job={_clean(job_id)}")
        if isinstance(state, str) and state in _STATES:
            parts.append(f"state={_STATES[state]}")

        routine = method == "GET" and path == "/health" and status == 200
        if method == "GET" and path.startswith("/jobs/") and status == 200 and isinstance(state, str) and state in _STATES:
            key = path
            routine = self._last_job_states.get(key) == state
            self._last_job_states[key] = state
            self._last_job_states.move_to_end(key)
            if len(self._last_job_states) > 512:
                self._last_job_states.popitem(last=False)
        parts.append(f"{(perf_counter() - started) * 1000:.0f} ms")
        level = logging.ERROR if failed or status >= 500 else logging.WARNING if status >= 400 else logging.INFO
        log.log(level, " | ".join(parts), extra={"routine_request": routine and not failed})
