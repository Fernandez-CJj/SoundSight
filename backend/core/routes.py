"""Root and health endpoints for the backend."""
from fastapi import APIRouter

from jobs.repositories.store import Store
from omr.processing.audiveris_service import isAudiverisInstalled

router = APIRouter()


@router.get("/")
def root():
    return {
        "message": "SoundSight backend is running."
    }


@router.get("/health")
def health():
    return {
        "status": "ok",
        "audiverisInstalled": isAudiverisInstalled(),
        **Store().health(),
        "jobProtocol": 1,
    }


