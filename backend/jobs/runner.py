"""One isolated attempt. Launched exclusively by jobs.worker."""
import logging
import sys


def main():
    if sys.stdin.readline().strip() != "run":
        raise SystemExit("The worker did not authorize execution.")
    from jobs.store import Store
    from jobs.processors import execute
    store = Store()
    job = store.get(sys.argv[1])
    try:
        result = execute(job)
        store.finish(job["id"], "completed", result)
    except Exception as error:
        logging.exception("job_failed job=%s kind=%s attempt=%s", job["id"], job["kind"], job["attempts"])
        safe = str(error)[:300] if isinstance(error, (ValueError, FileNotFoundError)) else "The task could not be completed. Please retry."
        store.finish(job["id"], "failed", error=safe)


if __name__ == "__main__":
    main()
