"""Remove local conversion leftovers only after the job is durably final."""
import logging
from pathlib import Path
import re
import shutil
import time

from jobs.store import QueueError

log = logging.getLogger("soundsight.cleanup")
FAILED_LOG_RETENTION_SECONDS = 7 * 24 * 60 * 60
LOG_NAME = re.compile(r"([0-9a-f]{32})-([1-9][0-9]*)\.log", re.IGNORECASE)
WORK_NAME = re.compile(r"([0-9a-f]{32})-([1-9][0-9]*)", re.IGNORECASE)


def safe_child(path, root):
    # Verify the resolved destination before every deletion. Do not follow
    # links or junctions, even when their names resemble a conversion artifact.
    return (not path.is_symlink() and not path.is_junction()
            and path.parent.resolve() == root
            and path.resolve().parent == root)


def cleanup_local_artifacts(store, *, dry_run=False):
    """Return eligible paths; leave active/unknown jobs and all queue files alone.

    SQLite terminal states are committed only after Firebase has saved the final
    result. Logs for interrupted attempts stay until their entire job is final.
    A dry run reads metadata but does not delete any files.
    """
    root = Path(store.path).resolve().parent
    cutoff = time.time() - FAILED_LOG_RETENTION_SECONDS
    jobs = {}
    removed = []

    def terminal_job(job_id):
        if job_id not in jobs:
            try:
                job = store.get(job_id)
            except QueueError:
                job = None
            jobs[job_id] = job if job and job["state"] in (
                "completed", "failed", "cancelled") else None
        return jobs[job_id]

    for path in root.glob("*.log"):
        match = LOG_NAME.fullmatch(path.name)
        if not match or not safe_child(path, root) or not path.is_file():
            continue
        job = terminal_job(match.group(1).lower())
        if job is None:
            continue
        if job["state"] == "failed" and (
                job["finished"] is None or job["finished"] > cutoff):
            continue
        try:
            if not dry_run:
                path.unlink(missing_ok=True)
            removed.append(path)
        except OSError:
            # An exiting runner may still hold the log open on Windows.
            log.warning("log_cleanup_retry file=%s", path.name)

    work = root / "work"
    if work.is_dir() and safe_child(work, root):
        work_root = work.resolve()
        for folder in work.iterdir():
            match = WORK_NAME.fullmatch(folder.name)
            if (not match or not safe_child(folder, work_root)
                    or not folder.is_dir()
                    or terminal_job(match.group(1).lower()) is None):
                continue
            try:
                if not dry_run:
                    shutil.rmtree(folder)
                removed.append(folder)
            except FileNotFoundError:
                pass
            except OSError:
                log.warning("scratch_cleanup_retry folder=%s", folder.name)

    if removed and not dry_run:
        log.info("local_artifacts_removed count=%s", len(removed))
    return removed
