"""HTTP endpoints for publishing and unpublishing compositions."""
import logging

from fastapi import APIRouter, Depends, HTTPException

from composition.repositories.published_composition_repository import getNextPublishedVersion, saveCompositionPost
from composition.repositories.public_profile_repository import getPublicProfile
from composition.repositories.composition_storage_repository import copyPublishedCompositionFiles, deleteStoragePaths
from composition.services.unpublish_service import unpublishComposition
from composition.repositories.private_composition_repository import (
    generatedFilesAreCurrent,
    getOwnedCompositionReference,
    loadOwnedComposition,
)
from core.auth_service import requireVerifiedFirebaseUser

logger = logging.getLogger("uvicorn.error")
router = APIRouter()


@router.post("/compositions/{compositionId}/publish")
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


@router.delete("/compositions/{compositionId}/publish")
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
