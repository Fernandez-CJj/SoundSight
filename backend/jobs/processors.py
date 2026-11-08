"""Validate queued sources and dispatch work to the owning feature."""
from jobs.repositories.firebase_bridge import check_sources


def execute(job):
    check_sources(job)
    suffix = f"-{job['id']}-{job['attempts']}"
    if job["kind"] == "composition":
        from composition.services.job_processor import process
        return process(job, suffix)
    if job["kind"] == "audio":
        from audio.services.job_processor import process
        return process(job, suffix)
    from omr.services.job_processor import process
    return process(job, suffix)
