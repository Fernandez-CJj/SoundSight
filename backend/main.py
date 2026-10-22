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
from omr.music_sheet_models import OmrConversionRequest
from omr.omr_conversion_service import convertMusicSheet
from composition.generation_service import generateCompositionFiles
from composition.private_composition_service import (
    generatedFilesAreCurrent,
    getOwnedCompositionReference,
    loadOwnedComposition,
    saveGeneratedFilePaths,
    saveGenerationStatus,
)

app = FastAPI(
    title="SoundSight API",
    description=(
        "Converts compositions into music sheets "
        "and recognizes uploaded music sheets."
    ),
    version="1.0.0",
)


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
    }


@app.post(
    "/music-sheets/{sheetId}/recognize"
)
def recognize_music_sheet(
    sheetId: str,
    request: OmrConversionRequest,
):
    try:
        return convertMusicSheet(
            sheetId,
            request.ownerId,
        )
    except FileNotFoundError as error:
        raise HTTPException(
            status_code=404,
            detail=str(error),
        ) from error
    except PermissionError as error:
        raise HTTPException(
            status_code=403,
            detail=str(error),
        ) from error
    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail=str(error),
        ) from error
    except RuntimeError as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        ) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=(
                "The music sheet could not be converted."
            ),
        ) from error


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

@app.post("/compositions/{compositionId}/generate")
def generatePrivateCompositionFiles(
    compositionId: str,
    authenticatedUserId: str = Depends(
        requireVerifiedFirebaseUser
    ),
):
    try:
        composition = loadOwnedComposition(
            compositionId,
            authenticatedUserId,
        )
    except FileNotFoundError as error:
        raise HTTPException(
            status_code=404,
            detail=str(error),
        ) from error
    except PermissionError as error:
        raise HTTPException(
            status_code=403,
            detail=str(error),
        ) from error
    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail=str(error),
        ) from error

    saveGenerationStatus(
        composition.id,
        authenticatedUserId,
        "generating",
    )

    try:
        publicProfile = getPublicProfile(
            composition.ownerId
        )

        storagePaths = generateCompositionFiles(
            composition,
            publicProfile["username"],
        )

        saveGeneratedFilePaths(
            composition.id,
            authenticatedUserId,
            storagePaths,
            composition,
        )
    except PermissionError as error:
        saveGenerationStatus(
            composition.id,
            authenticatedUserId,
            "failed",
        )
        raise HTTPException(
            status_code=403,
            detail=str(error),
        ) from error
    except ValueError as error:
        saveGenerationStatus(
            composition.id,
            authenticatedUserId,
            "failed",
        )
        raise HTTPException(
            status_code=400,
            detail=str(error),
        ) from error
    except (FileNotFoundError, RuntimeError) as error:
        saveGenerationStatus(
            composition.id,
            authenticatedUserId,
            "failed",
        )
        raise HTTPException(
            status_code=500,
            detail=str(error),
        ) from error
    except Exception as error:
        saveGenerationStatus(
            composition.id,
            authenticatedUserId,
            "failed",
        )
        raise HTTPException(
            status_code=500,
            detail=(
                "The composition files could not be generated."
            ),
        ) from error
    return {
        "message": (
            "Composition files generated successfully."
        ),
        "compositionId": composition.id,
        "pdfStoragePath": (
            storagePaths["pdfStoragePath"]
        ),
        "musicXmlStoragePath": (
            storagePaths["musicXmlStoragePath"]
        ),
        "midiStoragePath": (
            storagePaths["midiStoragePath"]
        ),
        "mp3StoragePath": (
            storagePaths["mp3StoragePath"]
        ),
    }
