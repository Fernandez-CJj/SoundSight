"""Readable console output and rotating diagnostic logs for each backend process."""
from copy import copy
import logging
from logging.config import dictConfig
import os
from pathlib import Path


class ConsoleActivityFilter(logging.Filter):
    def filter(self, record):
        return not getattr(record, "routine_request", False)


class ConsoleFormatter(logging.Formatter):
    def format(self, record):
        # Keep full tracebacks in the file while the console shows the summary.
        summary = copy(record)
        summary.exc_info = None
        summary.exc_text = None
        summary.stack_info = None
        return super().format(summary)


def configure_logging(component):
    folder = Path(os.environ.get(
        "SOUNDSIGHT_LOG_DIR",
        Path(__file__).resolve().parents[1] / "data" / "logs",
    ))
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / f"{component.lower()}.log"
    dictConfig({
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "console": {
                "()": ConsoleFormatter,
                "format": f"%(asctime)s %(levelname)s [{component}] %(message)s",
                "datefmt": "%H:%M:%S",
            },
            "file": {
                "format": f"%(asctime)s %(levelname)s [{component}] %(name)s: %(message)s",
            },
        },
        "filters": {"activity": {"()": ConsoleActivityFilter}},
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "stream": "ext://sys.stdout",
                "formatter": "console",
                "filters": ["activity"],
            },
            "file": {
                "class": "logging.handlers.RotatingFileHandler",
                "filename": str(path),
                "encoding": "utf-8",
                "maxBytes": 5_000_000,
                "backupCount": 3,
                "formatter": "file",
            },
        },
        "root": {"level": "INFO", "handlers": ["console", "file"]},
        "loggers": {
            "uvicorn": {"handlers": [], "propagate": True},
            "uvicorn.error": {"handlers": [], "propagate": True},
            # RequestLoggingMiddleware supplies the readable access summaries.
            "uvicorn.access": {"handlers": [], "level": "WARNING", "propagate": False},
        },
    })
    return path
