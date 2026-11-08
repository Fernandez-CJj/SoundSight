"""Offline checks for readable logs and unchanged HTTP responses."""
import json
import logging
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

from fastapi import FastAPI
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.testclient import TestClient

from core.request_logging import RequestLoggingMiddleware
from jobs import worker

ROOT = Path(__file__).resolve().parents[1]


class RecordCollector(logging.Handler):
    def __init__(self):
        super().__init__()
        self.records = []

    def emit(self, record):
        self.records.append(record)


class RequestActivityTests(unittest.TestCase):
    def setUp(self):
        self.collector = RecordCollector()
        self.logger = logging.getLogger("soundsight.api")
        self.previous = self.logger.handlers[:], self.logger.level, self.logger.propagate
        self.logger.handlers = [self.collector]
        self.logger.setLevel(logging.INFO)
        self.logger.propagate = False
        self.status = "queued"
        self.health_status = 200
        app = FastAPI()
        app.add_middleware(RequestLoggingMiddleware)

        @app.post("/music-sheets/item/recognize", status_code=202)
        def recognize():
            return {"jobId": "task", "status": self.status, "token": "response-secret"}

        @app.get("/health")
        def health():
            return JSONResponse({"status": "ok"}, status_code=self.health_status)

        @app.get("/jobs/{job_id}")
        def job(job_id: str):
            if job_id == "invalid":
                return {"jobId": "task", "status": {"unexpected": "object"}}
            if job_id == "large":
                return {"jobId": "task", "status": "processing", "data": "x" * 9000}
            if job_id == "stream":
                async def chunks():
                    yield b'{"jobId":"task",'
                    yield b'"status":"completed"}'
                return StreamingResponse(chunks(), media_type="application/json")
            return {"jobId": "task", "status": self.status}

        @app.get("/explode")
        def explode():
            raise RuntimeError("simulated application failure")

        self.client = TestClient(app, raise_server_exceptions=False)

    def tearDown(self):
        self.client.close()
        self.logger.handlers, level, self.logger.propagate = self.previous
        self.logger.setLevel(level)

    def test_submission_explains_acceptance_and_preserves_payload(self):
        response = self.client.post("/music-sheets/item/recognize?token=query-secret",
                                    headers={"Authorization": "Bearer request-secret"},
                                    json={"password": "body-secret"})
        self.assertEqual(response.status_code, 202)
        self.assertEqual(response.json(), {"jobId": "task", "status": "queued", "token": "response-secret"})
        message = self.collector.records[-1].getMessage()
        self.assertIn("Request: Recognize sheet music", message)
        self.assertIn("Response: 202 Accepted", message)
        self.assertIn("job=task", message)
        self.assertIn("state=waiting for worker", message)
        self.assertNotIn("secret", message)

    def test_repeated_poll_is_routine_but_state_changes_are_visible(self):
        self.client.get("/jobs/task")
        self.client.get("/jobs/task")
        self.status = "completed"
        self.client.get("/jobs/task")
        self.assertEqual([record.routine_request for record in self.collector.records], [False, True, False])
        self.assertIn("completed and saved", self.collector.records[-1].getMessage())

    def test_health_failures_are_visible(self):
        self.client.get("/health")
        self.health_status = 503
        self.client.get("/health")
        first, second = self.collector.records
        self.assertTrue(first.routine_request)
        self.assertFalse(second.routine_request)
        self.assertEqual(second.levelno, logging.ERROR)
        self.assertIn("503 Service Unavailable", second.getMessage())

    def test_unexpected_metadata_large_and_streamed_responses_are_preserved(self):
        self.assertEqual(self.client.get("/jobs/invalid").json()["status"], {"unexpected": "object"})
        self.assertEqual(len(self.client.get("/jobs/large").json()["data"]), 9000)
        self.assertEqual(self.client.get("/jobs/stream").json(), {"jobId": "task", "status": "completed"})
        self.assertIn("completed and saved", self.collector.records[-1].getMessage())

    def test_unhandled_exception_is_reported_without_changing_500(self):
        response = self.client.get("/explode")
        self.assertEqual(response.status_code, 500)
        record = self.collector.records[-1]
        self.assertEqual(record.levelno, logging.ERROR)
        self.assertIn("Response: 500 Internal Server Error", record.getMessage())


class LogDestinationTests(unittest.TestCase):
    def test_console_is_concise_and_file_retains_routine_requests_and_tracebacks(self):
        with tempfile.TemporaryDirectory() as folder:
            environment = os.environ.copy()
            environment["SOUNDSIGHT_LOG_DIR"] = folder
            script = '''from core.logging_setup import configure_logging
import logging
configure_logging("API")
logger = logging.getLogger("soundsight.api")
logger.info("Visible request")
logger.info("Routine health check", extra={"routine_request": True})
try:
    raise RuntimeError("diagnostic error detail")
except RuntimeError:
    logger.exception("Could not complete request")
'''
            result = subprocess.run([sys.executable, "-B", "-c", script], cwd=ROOT,
                                    env=environment, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Visible request", result.stdout)
            self.assertIn("Could not complete request", result.stdout)
            self.assertNotIn("Routine health check", result.stdout)
            self.assertNotIn("Traceback", result.stdout)
            file = (Path(folder) / "api.log").read_text(encoding="utf-8")
            self.assertIn("Routine health check", file)
            self.assertIn("Traceback", file)
            self.assertIn("diagnostic error detail", file)


class WorkerActivityTests(unittest.TestCase):
    def _store(self, outcome):
        store = Mock()
        store.path = Path(tempfile.gettempdir()) / "soundsight-test-queue" / "jobs.sqlite3"
        job = {"id": "task", "target": "item", "kind": "omr", "attempts": 1,
               "outcome": outcome, "error": "Conversion failed" if outcome == "failed" else None}
        store.pending.side_effect = lambda state: [job] if state == "finishing" else []
        store.cleanup_jobs.return_value = []
        return store, job

    def test_completion_is_reported_after_results_are_committed(self):
        store, job = self._store("completed")
        with patch("jobs.repositories.firebase_bridge.complete", return_value="completed"), patch.object(worker.log, "info") as info:
            worker.synchronize(store)
        store.commit_terminal.assert_called_once_with(job)
        self.assertIn("Completed and saved", info.call_args.args[0])

    def test_failed_commit_does_not_report_success(self):
        store, _ = self._store("completed")
        store.commit_terminal.side_effect = RuntimeError("database write failed")
        with patch("jobs.repositories.firebase_bridge.complete", return_value="completed"), patch.object(worker.log, "info") as info:
            with self.assertRaises(RuntimeError):
                worker.synchronize(store)
        info.assert_not_called()

    def test_failed_job_reports_its_reason(self):
        store, _ = self._store("failed")
        with patch("jobs.repositories.firebase_bridge.complete", return_value="failed"), patch.object(worker.log, "error") as error:
            worker.synchronize(store)
        self.assertIn("Failed", error.call_args.args[0])
        self.assertIn("Conversion failed", error.call_args.args)


if __name__ == "__main__":
    unittest.main()
