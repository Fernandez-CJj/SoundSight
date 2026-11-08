"""SoundSight API entry point. Run with uvicorn main:app from backend/."""
from fastapi import FastAPI

from composition.routes import router as compositionRouter
from core.routes import router as coreRouter
from jobs.routes import router as jobsRouter
from core.logging_setup import configure_logging
from core.request_logging import RequestLoggingMiddleware

configure_logging("API")

app = FastAPI(
    title="SoundSight API",
    description=(
        "Converts compositions into music sheets "
        "recognizes uploaded music sheets, and transcribes piano MP3s."
    ),
    version="1.0.0",
)


app.include_router(jobsRouter)
app.include_router(coreRouter)
app.include_router(compositionRouter)
app.add_middleware(RequestLoggingMiddleware)
