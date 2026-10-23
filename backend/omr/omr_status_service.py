from firebase_admin import firestore

from core.firebase_service import getDatabase


def setOmrProcessing(
    sheetId,
    ownerId,
):
    database = getDatabase()

    sheetReference = (
        database
        .collection("users")
        .document(ownerId)
        .collection("musicSheets")
        .document(sheetId)
    )

    sheetReference.update({
        "omrStatus": "processing",
        "omrEngine": "audiveris",
        "omrError": None,
        "omrStartedAt": (
            firestore.SERVER_TIMESTAMP
        ),
        "omrFailedAt": (
            firestore.DELETE_FIELD
        ),
    })


def setOmrCompleted(
    sheetId,
    ownerId,
    storagePaths,
    validationResult,
):
    database = getDatabase()

    sheetReference = (
        database
        .collection("users")
        .document(ownerId)
        .collection("musicSheets")
        .document(sheetId)
    )

    sheetReference.update({
        "omrStatus": "completed",
        "omrEngine": "audiveris",
        "omrError": None,
        "omrProcessedAt": (
            firestore.SERVER_TIMESTAMP
        ),
        "omrFailedAt": (
            firestore.DELETE_FIELD
        ),
        "musicXmlStoragePath": (
            storagePaths[
                "musicXmlStoragePath"
            ]
        ),
        "midiStoragePath": (
            storagePaths[
                "midiStoragePath"
            ]
        ),
        "recognizedPdfStoragePath": (
            storagePaths[
                "recognizedPdfStoragePath"
            ]
        ),
        "previewAudioStoragePath": (
            storagePaths[
                "previewAudioStoragePath"
            ]
        ),
        "omrPartCount": (
            validationResult[
                "partCount"
            ]
        ),
        "omrNoteCount": (
            validationResult[
                "noteCount"
            ]
        ),
    })


def setOmrFailed(
    sheetId,
    ownerId,
    errorMessage,
):
    database = getDatabase()

    sheetReference = (
        database
        .collection("users")
        .document(ownerId)
        .collection("musicSheets")
        .document(sheetId)
    )

    safeErrorMessage = str(
        errorMessage
    )

    if len(safeErrorMessage) > 500:
        safeErrorMessage = (
            safeErrorMessage[:500]
        )

    sheetReference.update({
        "omrStatus": "failed",
        "omrEngine": "audiveris",
        "omrError": safeErrorMessage,
        "omrFailedAt": (
            firestore.SERVER_TIMESTAMP
        ),
    })
