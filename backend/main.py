import logging

from fastapi import FastAPI
from fastapi import Depends
from fastapi import HTTPException

from composition.post_service import getNextPublishedVersion
from composition.post_service import saveCompositionPost
from composition.public_profile_service import getPublicProfile
from composition.storage_service import copyPublishedCompositionFiles
from composition.storage_service import deleteStoragePaths
from composition.unpublish_service import unpublishComposition
from core.auth_service import requireVerifiedFirebaseUser
from omr.audiveris_service import isAudiverisInstalled
from composition.private_composition_service import (
    generatedFilesAreCurrent,
    getOwnedCompositionReference,
    loadOwnedComposition,
)

from jobs.api import router as jobsRouter
from jobs.store import Store

logger = logging.getLogger("uvicorn.error")

app = FastAPI(
    title="SoundSight API",
    description=(
        "Converts compositions into music sheets "
        "recognizes uploaded music sheets, and transcribes piano MP3s."
    ),
    version="1.0.0",
)


app.include_router(jobsRouter)


@app.get("/")
def root():
    return {
        "message": "SoundSight backend is running."
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "audiverisInstalled": isAudiverisInstalled(),
        **Store().health(),
        "jobProtocol": 1,
    }


@app.post("/compositions/{compositionId}/publish")
def publish_composition(
    compositionId: str,
    authenticatedUserId: str = Depends(
        requireVerifiedFirebaseUser
    ),
):
    publishedStoragePaths = None

    try:
        compositionReference = getOwnedCompositionReference(
            compositionId,
            authenticatedUserId,
        )
        compositionData = (
            compositionReference.get().to_dict() or {}
        )

        if not generatedFilesAreCurrent(compositionData):
            raise HTTPException(
                status_code=409,
                detail=(
                    "Prepare the sheet music and playback "
                    "files before publishing."
                ),
            )

        composition = loadOwnedComposition(
            compositionId,
            authenticatedUserId,
        )
        publicProfile = getPublicProfile(authenticatedUserId)
        versionNumber = getNextPublishedVersion(compositionId)
        publishedStoragePaths = copyPublishedCompositionFiles(
            compositionData,
            authenticatedUserId,
            compositionId,
            versionNumber,
        )
        postId = saveCompositionPost(
            composition,
            publishedStoragePaths,
            publicProfile,
            versionNumber,
            compositionData.get("updatedAt"),
        )
        return {
            "message": "Composition published successfully.",
            "postId": postId,
            "compositionId": compositionId,
            "title": composition.title,
            "authorName": publicProfile["username"],
            "versionNumber": versionNumber,
            **publishedStoragePaths,
        }
    except HTTPException:
        if publishedStoragePaths is not None:
            deleteStoragePaths(publishedStoragePaths.values())
        raise
    except FileNotFoundError as error:
        if publishedStoragePaths is not None:
            deleteStoragePaths(publishedStoragePaths.values())
        raise HTTPException(status_code=404, detail=str(error)) from error
    except PermissionError as error:
        if publishedStoragePaths is not None:
            deleteStoragePaths(publishedStoragePaths.values())
        raise HTTPException(status_code=403, detail=str(error)) from error
    except ValueError as error:
        if publishedStoragePaths is not None:
            deleteStoragePaths(publishedStoragePaths.values())
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        logger.exception("Composition publishing failed: %s", compositionId)
        if publishedStoragePaths is not None:
            deleteStoragePaths(publishedStoragePaths.values())
        raise HTTPException(
            status_code=500,
            detail="The composition could not be published.",
        ) from error


@app.delete("/compositions/{compositionId}/publish")
def unpublish_composition(
    compositionId: str,
    authenticatedUserId: str = Depends(
        requireVerifiedFirebaseUser
    ),
):
    try:
        wasDeleted = unpublishComposition(
            compositionId,
            authenticatedUserId,
        )
    except PermissionError as error:
        raise HTTPException(
            status_code=403,
            detail=str(error),
        ) from error

    if not wasDeleted:
        raise HTTPException(
            status_code=404,
            detail=(
                "The published composition was not found."
            ),
        )

    return {
        "message": (
            "Composition unpublished successfully."
        ),
        "compositionId": compositionId,
    }
