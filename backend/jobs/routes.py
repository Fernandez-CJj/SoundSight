import logging
import re
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field

from core.auth_service import requireVerifiedFirebaseUser
from jobs.repositories.store import Store, QueueError, public_job
from jobs.repositories import firebase_bridge as bridge

router = APIRouter()


def protocol(version: Annotated[str | None, Header(alias="X-SoundSight-Job-Protocol")] = None,
             key: Annotated[str | None, Header(alias="Idempotency-Key")] = None):
    if version != "1":
        raise HTTPException(426, "Update SoundSight to submit background tasks.")
    if key is None or not re.fullmatch(r"[A-Za-z0-9_-]{16,100}", key):
        raise HTTPException(400, "A valid Idempotency-Key is required.")
    return key


def submit(owner, kind, target, key):
    store = Store()
    try:
        previous = store.existing(owner, key, kind, target)
        if previous and previous["state"] != "admitting":
            return public_job(previous)
        if not store.available():
            raise QueueError(503, "The processing worker is offline. Please try again later.")
        if previous:
            job = previous
        else:
            # IDs become export basenames on Windows: reject path separators,
            # drive prefixes and traversal rather than trusting a Firestore ID.
            if not re.fullmatch(r"[A-Za-z0-9_-]{1,150}", target):
                raise QueueError(400, "Invalid item ID.")
            snapshot, revision = bridge.inspect_target(owner, kind, target)
            job = store.reserve(owner, kind, target, key, snapshot, revision)
        if job["state"] == "admitting":
            try:
                bridge.activate(job)
            except QueueError:
                store.abandon(job["id"])
                raise
            store.ready(job["id"])
        return public_job(store.get(job["id"]))
    except QueueError as error:
        raise HTTPException(error.status, str(error), headers={"Retry-After": "30"} if error.status in (429, 503) else None) from error
    except FileNotFoundError as error:
        raise HTTPException(404, str(error)) from error
    except PermissionError as error:
        raise HTTPException(403, str(error)) from error
    except ValueError as error:
        raise HTTPException(400, str(error)) from error
    except Exception as error:
        logging.exception("job_submission_unavailable")
        # Retain an uncertain admission for reconciliation; never lose an accepted lock.
        raise HTTPException(503, "Submission could not be confirmed. Retry the same request.") from error


@router.post("/music-sheets/{sheetId}/recognize", status_code=202)
def recognize(sheetId: str, key=Depends(protocol), owner=Depends(requireVerifiedFirebaseUser)):
    return submit(owner, "omr", sheetId, key)


@router.post("/music-sheets/{sheetId}/transcribe-audio", status_code=202)
def transcribe(sheetId: str, key=Depends(protocol), owner=Depends(requireVerifiedFirebaseUser)):
    return submit(owner, "audio", sheetId, key)


@router.post("/compositions/{compositionId}/generate", status_code=202)
def generate(compositionId: str, key=Depends(protocol), owner=Depends(requireVerifiedFirebaseUser)):
    return submit(owner, "composition", compositionId, key)


@router.get("/jobs/{jobId}")
def get_job(jobId: str, owner=Depends(requireVerifiedFirebaseUser)):
    try:
        return public_job(Store().get(jobId, owner))
    except QueueError as error:
        raise HTTPException(error.status, str(error)) from error


@router.post("/jobs/{jobId}/cancel")
def cancel_job(jobId: str, owner=Depends(requireVerifiedFirebaseUser)):
    store = Store()
    try:
        store.cancel(jobId, owner)
        job = store.get(jobId, owner)
        if job["state"] == "finishing":
            job["outcome"] = bridge.complete(job)
            store.commit_terminal(job)
        return public_job(store.get(jobId, owner))
    except QueueError as error:
        raise HTTPException(error.status, str(error)) from error
    except Exception as error:
        logging.exception("cancel_sync_retry job=%s", jobId)
        raise HTTPException(503, "Cancellation is saved but not confirmed yet. Please retry.") from error


class Device(BaseModel):
    token: str = Field(min_length=20, max_length=4096)
    language: str = Field(default="en", pattern="^(en|fil)$")


@router.put("/notifications/devices/{installationId}")
def register_device(installationId: str, body: Device, owner=Depends(requireVerifiedFirebaseUser)):
    if not re.fullmatch(r"[A-Za-z0-9_-]{16,150}", installationId):
        raise HTTPException(400, "Invalid installation ID.")
    Store().register(installationId, owner, body.token, body.language)
    return {"registered": True}


@router.delete("/notifications/devices/{installationId}")
def unregister_device(installationId: str, owner=Depends(requireVerifiedFirebaseUser)):
    Store().unregister(installationId, owner)
    return {"registered": False}
