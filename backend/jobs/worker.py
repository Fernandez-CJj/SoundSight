"""Run from backend: python -m jobs.worker. One worker per local database."""
import logging
import os
from pathlib import Path
import signal
import sys
import threading
import time

from jobs.repositories.store import Store, QueueError
from jobs.process_guard import ProcessTree, WorkerLock
from jobs.services.artifact_cleanup import cleanup_local_artifacts
from core.logging_setup import configure_logging

log = logging.getLogger("soundsight.worker")
DEADLINES = {"omr": 65 * 60, "audio": 40 * 60, "composition": 35 * 60}


def describe_job(job):
    label = {"omr": "Recognize sheet music", "audio": "Transcribe piano audio",
             "composition": "Generate composition files"}.get(job["kind"], job["kind"])
    return f"{label} | job={job['id']} | item={job['target']}"


def synchronize(store):
    from jobs.repositories import firebase_bridge as bridge
    for job in store.pending("admitting"):
        try:
            bridge.activate(job)
            store.ready(job["id"])
        except QueueError:
            store.abandon(job["id"])
    for job in store.pending("finishing"):
        outcome = bridge.complete(job)
        if outcome != job["outcome"]:
            job["error"] = "This item changed or was removed. Please retry."
        job["outcome"] = outcome
        store.commit_terminal(job)
        if outcome == "completed":
            log.info("Completed and saved: %s", describe_job(job))
        elif outcome == "cancelled":
            log.info("Cancelled: %s", describe_job(job))
        else:
            attempt_log = store.path.parent / f"{job['id']}-{job['attempts']}.log"
            details = f" | details={attempt_log}" if attempt_log.is_file() else ""
            log.error("Failed: %s | Reason: %s%s", describe_job(job),
                      job.get("error") or "See the worker log for details.", details)
    for job in store.cleanup_jobs():
        # Remove abandoned attempts and superseded private outputs only after
        # the conditional commit. Files still referenced by the item are kept.
        try:
            from core.integrations.firebase_service import getStorageBucket
            target, _ = bridge.refs(job)
            current = target.get().to_dict() or {}
            keep = {current.get(k) for k in bridge.OUTPUTS}
            base = (f"composition_files/{job['owner']}/{job['target']}/score-" if job["kind"] == "composition"
                    else f"musicSheets/{job['owner']}/{job['target']}/")
            for blob in getStorageBucket().list_blobs(prefix=base):
                if f"-{job['id']}-" in blob.name and blob.name not in keep:
                    blob.delete(timeout=15)
            if job["state"] == "completed":
                for path in job["snapshot"].get("previousPaths", {}).values():
                    owned_prefix = f"composition_files/{job['owner']}/{job['target']}/"
                    sheet_prefix = f"musicSheets/{job['owner']}/{job['target']}/"
                    is_generated = path.startswith(owned_prefix) or (
                        path.startswith(sheet_prefix) and path.rsplit("/", 1)[-1].startswith(("recognized", "preview")))
                    if is_generated and path not in keep:
                        from google.cloud.exceptions import NotFound
                        try:
                            getStorageBucket().blob(path).delete(timeout=15)
                        except NotFound:
                            pass
            store.cleanup_done(job["id"])
        except Exception:
            log.exception("Could not clean up old files; will retry | job=%s", job["id"])


def main():
    log_path = configure_logging("WORKER")
    log.info("Starting worker. Checking unfinished jobs and connecting to Firebase. Log: %s", log_path)
    store = Store()
    lock = WorkerLock(store.path.with_suffix(".worker.lock"))
    stop = threading.Event()
    for event in (signal.SIGTERM, signal.SIGINT):
        signal.signal(event, lambda *_: stop.set())

    def local_cleanup_loop():
        while not stop.is_set():
            try:
                cleanup_local_artifacts(store)
            except Exception:
                log.exception("Could not clean up temporary files; will retry in 60 seconds.")
            stop.wait(60)

    # Local maintenance also runs while Firebase is unavailable or the worker
    # is waiting for restart reconciliation. Unfinished jobs are never removed.
    threading.Thread(target=local_cleanup_loop, daemon=True).start()
    from jobs.repositories import firebase_bridge as bridge
    from jobs.services.notifications import deliver

    # Startup reconciliation must succeed before accepting new work.
    recovered = []
    while not stop.is_set():
        try:
            synchronize(store)
            for job in store.pending("processing"):
                terminal = bridge.terminal_status(job)
                if terminal:
                    store.finish(job["id"], terminal)
                else:
                    job = store.recover(job)
                    if job["state"] == "processing":
                        recovered.append(job)
            break
        except Exception:
            log.exception("Could not restore pending jobs from Firebase; retrying in 5 seconds.")
            stop.wait(5)

    def sync_loop():
        while not stop.is_set():
            try:
                synchronize(store)
            except Exception:
                log.exception("Could not save job updates to Firebase; retrying in 2 seconds.")
            stop.wait(2)

    def notification_loop():
        while not stop.is_set():
            try:
                deliver(store)
            except Exception:
                log.exception("Could not send completion notifications; retrying in 5 seconds.")
            stop.wait(5)

    threading.Thread(target=sync_loop, daemon=True).start()
    threading.Thread(target=notification_loop, daemon=True).start()
    log.info("Ready. Waiting for sheet-recognition, audio, or composition jobs.")
    active = None
    output = None
    try:
        while not stop.is_set():
            store.heartbeat()
            if active:
                tree, job, started = active
                deadline = int(os.environ.get(f"SOUNDSIGHT_{job['kind'].upper()}_TIMEOUT", DEADLINES[job["kind"]]))
                if tree.process.poll() is not None:
                    tree.close()
                    output.close()
                    if store.get(job["id"])["state"] == "processing":
                        store.finish(job["id"], "failed", error="The processing program stopped unexpectedly. Please retry.")
                    active = None
                elif time.monotonic() - started > deadline:
                    tree.close()
                    output.close()
                    store.finish(job["id"], "failed", error="Processing exceeded its time limit. Please retry.")
                    active = None
            else:
                job = recovered.pop(0) if recovered else store.claim()
                if job:
                    try:
                        if not bridge.processing(job):
                            store.finish(job["id"], bridge.terminal_status(job) or "failed")
                            continue
                        log.info("Started: %s | attempt=%s", describe_job(job), job["attempts"])
                        output = open(store.path.parent / f"{job['id']}-{job['attempts']}.log", "ab", buffering=0)
                        scratch = (store.path.parent / "work" / f"{job['id']}-{job['attempts']}").resolve()
                        scratch.mkdir(parents=True, exist_ok=True)
                        environment = os.environ.copy()
                        environment.update(TEMP=str(scratch), TMP=str(scratch), TMPDIR=str(scratch))
                        tree = ProcessTree([sys.executable, "-m", "jobs.runner", job["id"]], output,
                                           Path(__file__).resolve().parents[1], env=environment)
                        active = (tree, job, time.monotonic())
                    except Exception:
                        log.exception("Could not start processing: %s", describe_job(job))
                        if output:
                            output.close()
                        store.finish(job["id"], "failed", error="The task could not start. Please retry.")
            stop.wait(1)
    finally:
        if active:
            active[0].close()
        if output:
            output.close()
        # Keep interrupted work for the next worker's recovery, without a false failure alert.
        with store.connect() as db:
            db.execute("DELETE FROM runtime WHERE key='heartbeat'")
        lock.close()
        log.info("Worker stopped. Interrupted jobs will be checked on the next start.")


if __name__ == "__main__":
    main()
