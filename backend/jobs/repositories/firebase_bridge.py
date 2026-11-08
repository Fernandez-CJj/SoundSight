"""Idempotent Firebase projections; rendering never writes final item state."""
import hashlib
import json
from datetime import datetime, timezone

from firebase_admin import firestore

from core.integrations.firebase_service import getDatabase, getStorageBucket
from jobs.repositories.store import QueueError, public_job

CONTENT = ("ownerId", "title", "updatedAt", "type", "files", "pageCount", "durationMs",
           "key", "tempo", "beatsPerMeasure", "beatUnit", "measureCount", "notes",
           "creationMethod", "recordingSchemaVersion", "performanceNotes", "performanceDurationUs")
OUTPUTS = ("pdfStoragePath", "musicXmlStoragePath", "midiStoragePath",
           "mp3StoragePath", "recognizedPdfStoragePath", "previewAudioStoragePath")


def revision(data):
    value = {key: data[key] for key in CONTENT if key in data}
    return hashlib.sha256(json.dumps(value, sort_keys=True, default=str).encode()).hexdigest()


def refs(job):
    user = getDatabase().collection("users").document(job["owner"])
    collection = "compositions" if job["kind"] == "composition" else "musicSheets"
    return user.collection(collection).document(job["target"]), user.collection("processingJobs").document(job["id"])


def status_field(kind):
    return {"composition": "generationStatus", "omr": "omrStatus", "audio": "transcriptionStatus"}[kind]


def inspect_target(owner, kind, target):
    # Reuse authoritative validation, without starting a conversion.
    if kind == "composition":
        from composition.repositories.private_composition_repository import loadOwnedComposition, getOwnedCompositionReference
        loadOwnedComposition(target, owner)
        data = getOwnedCompositionReference(target, owner).get().to_dict() or {}
    elif kind == "omr":
        from omr.repositories.music_sheet_repository import getMusicSheet
        data = getMusicSheet(target, owner)
    else:
        from audio.services.transcription_service import _sheet_reference, _validate_source, _worker_python
        _worker_python()
        snap = _sheet_reference(owner, target).get()
        if not snap.exists:
            raise FileNotFoundError("The recording was not found.")
        data = snap.to_dict() or {}
        _validate_source(data, owner, target)
    generations = {}
    for source in data.get("files", []) if kind != "composition" else []:
        blob = getStorageBucket().blob(source["storagePath"])
        blob.reload(timeout=15)
        limit = 95_000_000 if kind == "audio" else (20 * 1024 * 1024 if data["type"] == "pdf" else 5 * 1024 * 1024)
        if not blob.size or blob.size > limit:
            raise ValueError("A source file exceeds the supported size.")
        generations[source["storagePath"]] = str(blob.generation)
    snapshot = {"previousStatus": data.get(status_field(kind)),
                "previousPaths": {k: data[k] for k in OUTPUTS if data.get(k)},
                "title": data.get("title", ""), "sourceGenerations": generations}
    return snapshot, revision(data)


@firestore.transactional
def _activate(transaction, job):
    target, reference = refs(job)
    existing = reference.get(transaction=transaction)
    snap = target.get(transaction=transaction)
    data = snap.to_dict() or {}
    if existing.exists:
        return
    if not snap.exists or data.get("ownerId") != job["owner"]:
        raise QueueError(404, "The item was not found.")
    if data.get("activeJobId"):
        raise QueueError(409, "This item already has an unfinished task.")
    if revision(data) != job["revision"]:
        raise QueueError(409, "The item changed. Submit it again.")
    transaction.update(target, {"activeJobId": job["id"], "lastJobStatus": "queued",
                                "lastJobError": None, status_field(job["kind"]): "queued"})
    transaction.set(reference, {**public_job(job), "ownerId": job["owner"],
                                "createdAt": datetime.fromtimestamp(job["created"], timezone.utc),
                                "sourceRevision": job["revision"], "title": job["snapshot"]["title"],
                                "seenAt": None})


def activate(job):
    _activate(getDatabase().transaction(), job)


@firestore.transactional
def _processing(transaction, job):
    target, reference = refs(job)
    snap = target.get(transaction=transaction)
    summary = reference.get(transaction=transaction)
    if summary.exists and summary.to_dict().get("status") in ("completed", "failed", "cancelled"):
        return False
    data = snap.to_dict() or {}
    if data.get("activeJobId") != job["id"] or revision(data) != job["revision"]:
        raise QueueError(409, "This item changed or was removed before processing.")
    transaction.update(target, {"lastJobStatus": "processing", status_field(job["kind"]):
                               "generating" if job["kind"] == "composition" else "processing"})
    transaction.update(reference, {"status": "processing", "attemptCount": job["attempts"],
                                   "startedAt": firestore.SERVER_TIMESTAMP})
    return True


def processing(job):
    return _processing(getDatabase().transaction(), job)


def check_sources(job):
    for path, expected in job["snapshot"].get("sourceGenerations", {}).items():
        blob = getStorageBucket().blob(path)
        blob.reload(timeout=15)
        if str(blob.generation) != expected:
            raise QueueError(409, "A source file changed. Please retry.")


@firestore.transactional
def _complete(transaction, job):
    target, reference = refs(job)
    summary = reference.get(transaction=transaction)
    snap = target.get(transaction=transaction)
    if summary.exists and summary.to_dict().get("status") in ("completed", "failed", "cancelled"):
        return summary.to_dict()["status"]
    data = snap.to_dict() or {}
    outcome = job["outcome"]
    error = job["error"]
    owns_lock = data.get("activeJobId") == job["id"]
    if outcome == "completed" and (not owns_lock or revision(data) != job["revision"]):
        outcome, error = "failed", "This item changed or was removed. Please retry."
    if owns_lock:
        previous = job["snapshot"].get("previousStatus")
        status = "completed" if outcome == "completed" else (
            "completed" if previous == "completed" else
            ("pending" if job["kind"] == "composition" and outcome == "cancelled" else
             "notStarted" if outcome == "cancelled" else "failed"))
        fields = {"activeJobId": firestore.DELETE_FIELD, "lastJobStatus": outcome,
                  "lastJobError": error, status_field(job["kind"]): status}
        if outcome == "completed":
            fields.update(job["result"].get("fields", {}))
            timestamp = {"composition": "filesGeneratedAt", "omr": "omrProcessedAt",
                         "audio": "transcriptionProcessedAt"}[job["kind"]]
            fields[timestamp] = firestore.SERVER_TIMESTAMP
        transaction.update(target, fields)
    transaction.set(reference, {**public_job(job), "status": outcome, "error": error,
                                "ownerId": job["owner"], "title": job["snapshot"].get("title", ""),
                                "completedAt": firestore.SERVER_TIMESTAMP}, merge=True)
    return outcome


def complete(job):
    return _complete(getDatabase().transaction(), job)


def terminal_status(job):
    _, reference = refs(job)
    snap = reference.get()
    data = snap.to_dict() or {}
    return data.get("status") if data.get("status") in ("completed", "failed", "cancelled") else None
