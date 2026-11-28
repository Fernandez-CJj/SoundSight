from firebase_admin import firestore

from core.integrations.firebase_service import getDatabase
from composition.models.composition_models import CompositionRequest, MAX_COMPOSITION_NOTES
from composition.processing.performance_timing import (
    normalizeRecordedCompositionTiming,
)


CURRENT_GENERATED_FILES_VERSION = 2


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
        .collection("users")
        .document(ownerId)
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


def loadOwnedComposition(
    compositionId,
    ownerId,
):
    compositionReference = getOwnedCompositionReference(
        compositionId,
        ownerId,
    )
    compositionData = compositionReference.get().to_dict() or {}
    compositionData["id"] = compositionId

    storedNotes = compositionData.get("notes", [])
    normalizedNotes = []
    for storedNote in storedNotes:
        noteData = dict(storedNote)
        if "id" not in noteData and "noteId" in noteData:
            noteData["id"] = noteData.pop("noteId")
        normalizedNotes.append(noteData)
    compositionData["notes"] = normalizedNotes

    try:
        composition = CompositionRequest.model_validate(compositionData)
    except AttributeError:
        composition = CompositionRequest.parse_obj(compositionData)

    if len(composition.notes) > MAX_COMPOSITION_NOTES:
        raise ValueError(
            f"A composition can contain up to {MAX_COMPOSITION_NOTES} notes."
        )

    if composition.recordingSchemaVersion not in [None, 1]:
        raise ValueError(
            "The recording schema version is not supported."
        )

    if composition.recordingSchemaVersion == 1:
        if (
            composition.creationMethod != "recording"
            or len(composition.performanceNotes) == 0
            or len(composition.performanceNotes) > MAX_COMPOSITION_NOTES
            or composition.performanceDurationUs is None
        ):
            raise ValueError(
                "The recorded performance data is incomplete."
            )
        if composition.usesPerformanceRecording:
            normalizeRecordedCompositionTiming(composition)
        if composition.performanceDurationUs > 600_000_000:
            raise ValueError(
                "The recorded performance is longer than 10 minutes."
            )
        if any(note.startTimeUs + note.durationUs > composition.performanceDurationUs
               for note in composition.performanceNotes):
            raise ValueError("A recorded note extends past the performance ending.")

    if composition.usesPerformanceRecording and (
        composition.creationMethod != "recording" or composition.recordingSchemaVersion != 1
    ):
        raise ValueError("The recorded performance data is incomplete.")
    if composition.originalRecordingSettings is not None and (
        composition.creationMethod != "recording" or composition.recordingSchemaVersion != 1
        or composition.effectiveContentMode != "score"
    ):
        raise ValueError("Original settings belong to an edited recording.")

    return composition


def saveGeneratedFilePaths(
    compositionId,
    ownerId,
    storagePaths,
    composition=None,
):
    compositionReference = (
        getOwnedCompositionReference(
            compositionId,
            ownerId,
        )
    )

    generatedData = {
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
        "generatedFilesVersion": (
            CURRENT_GENERATED_FILES_VERSION
        ),
        "filesGeneratedAt": (
            firestore.SERVER_TIMESTAMP
        ),
    }

    if (
        composition is not None
        and composition.usesPerformanceRecording
    ):
        generatedData.update({
            "tempo": composition.tempo,
            "measureCount": composition.measureCount,
            "performanceDurationUs": (
                composition.performanceDurationUs
            ),
        })

    compositionReference.update(generatedData)


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

    if (
        compositionData.get("generatedFilesVersion")
        != CURRENT_GENERATED_FILES_VERSION
    ):
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
