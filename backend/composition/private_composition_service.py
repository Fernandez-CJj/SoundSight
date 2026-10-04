from firebase_admin import firestore

from core.firebase_service import getDatabase


def getOwnedCompositionReference(
    compositionId,
    ownerId,
):
    if compositionId == "":
        raise ValueError(
            "The composition ID cannot be empty."
        )

    if ownerId == "":
        raise ValueError(
            "The owner ID cannot be empty."
        )

    database = getDatabase()

    compositionReference = (
        database
        .collection("compositions")
        .document(compositionId)
    )

    compositionDocument = (
        compositionReference.get()
    )

    if not compositionDocument.exists:
        raise FileNotFoundError(
            "The composition was not found."
        )

    compositionData = (
        compositionDocument.to_dict() or {}
    )

    if compositionData.get("ownerId") != ownerId:
        raise PermissionError(
            "The composition belongs to another user."
        )

    return compositionReference


def saveGeneratedFilePaths(
    compositionId,
    ownerId,
    storagePaths,
):
    compositionReference = (
        getOwnedCompositionReference(
            compositionId,
            ownerId,
        )
    )

    compositionReference.update({
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
        "generationStatus": "completed",
        "filesGeneratedAt": (
            firestore.SERVER_TIMESTAMP
        ),
    })


def saveGenerationStatus(
    compositionId,
    ownerId,
    generationStatus,
):
    if generationStatus not in [
        "generating",
        "failed",
    ]:
        raise ValueError(
            "Choose a supported generation status."
        )

    compositionReference = (
        getOwnedCompositionReference(
            compositionId,
            ownerId,
        )
    )

    compositionReference.update({
        "generationStatus": generationStatus,
    })


def generatedFilesAreCurrent(compositionData):
    requiredStoragePaths = [
        "pdfStoragePath",
        "musicXmlStoragePath",
        "midiStoragePath",
        "mp3StoragePath",
    ]

    for storagePathKey in requiredStoragePaths:
        storagePath = compositionData.get(
            storagePathKey
        )

        if (
            not isinstance(storagePath, str)
            or storagePath.strip() == ""
        ):
            return False

    generationStatus = compositionData.get(
        "generationStatus"
    )

    if generationStatus not in [None, "completed"]:
        return False

    filesGeneratedAt = compositionData.get(
        "filesGeneratedAt"
    )
    updatedAt = compositionData.get("updatedAt")

    if filesGeneratedAt is None:
        return False

    if (
        updatedAt is not None
        and filesGeneratedAt < updatedAt
    ):
        return False

    return True
