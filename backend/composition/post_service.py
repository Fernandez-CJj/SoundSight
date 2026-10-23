from firebase_admin import firestore

from core.firebase_service import getDatabase


def getNextPublishedVersion(compositionId):
    database = getDatabase()

    postDocument = database.collection(
        "compositionPosts"
    ).document(
        compositionId
    ).get()

    currentVersion = 0

    if postDocument.exists:
        postData = postDocument.to_dict()
        savedVersion = postData.get(
            "currentVersion"
        )

        if isinstance(savedVersion, int):
            currentVersion = savedVersion

    return currentVersion + 1


def saveCompositionPost(
    composition,
    publishedStoragePaths,
    publicProfile,
    versionNumber,
    sourceUpdatedAt,
):
    if composition.id == "":
        raise ValueError(
            "The composition ID cannot be empty."
        )

    database = getDatabase()

    postId = composition.id

    postData = {
        "compositionId": composition.id,
        "ownerId": composition.ownerId,
        "authorName": publicProfile["username"],
        "authorProfileImageUrl": (
            publicProfile["profileImageUrl"]
        ),
        "currentVersion": versionNumber,
        "title": composition.title,
        "creationMethod": composition.creationMethod,
        "tempo": composition.tempo,
        "key": composition.key,
        "beatsPerMeasure": (
            composition.beatsPerMeasure
        ),
        "beatUnit": composition.beatUnit,
        "measureCount": composition.measureCount,
        "noteCount": (
            len(composition.performanceNotes)
            if composition.recordingSchemaVersion == 1
            else len(composition.notes)
        ),
        "publishedFilesVersion": 1,
        "pdfStoragePath": publishedStoragePaths["pdfStoragePath"],
        "musicXmlStoragePath": (
            publishedStoragePaths["musicXmlStoragePath"]
        ),
        "midiStoragePath": publishedStoragePaths["midiStoragePath"],
        "mp3StoragePath": publishedStoragePaths["mp3StoragePath"],
        "sourceUpdatedAt": sourceUpdatedAt,
        "publishedAt": (
            firestore.SERVER_TIMESTAMP
        ),
    }

    postReference = database.collection(
        "compositionPosts"
    ).document(
        postId
    )

    versionData = dict(postData)
    versionData["versionNumber"] = versionNumber

    notesData = []

    for compositionNote in composition.notes:
        notesData.append({
            "noteId": compositionNote.id,
            "pitch": compositionNote.pitch,
            "octave": compositionNote.octave,
            "midiNumber": compositionNote.midiNumber,
            "measureIndex": compositionNote.measureIndex,
            "startBeat": compositionNote.startBeat,
            "durationBeats": compositionNote.durationBeats,
            "velocity": compositionNote.velocity,
            "tieToNext": compositionNote.tieToNext,
        })

    versionData["notes"] = notesData

    if composition.recordingSchemaVersion == 1:
        versionData["recordingSchemaVersion"] = 1
        versionData["performanceDurationUs"] = (
            composition.performanceDurationUs
        )
        versionData["performanceNotes"] = [
            {
                "midiNumber": performanceNote.midiNumber,
                "velocity": performanceNote.velocity,
                "startTimeUs": performanceNote.startTimeUs,
                "durationUs": performanceNote.durationUs,
            }
            for performanceNote in composition.performanceNotes
        ]

    versionReference = postReference.collection(
        "versions"
    ).document(
        str(versionNumber)
    )

    batch = database.batch()

    batch.set(
        postReference,
        postData
    )

    batch.set(
        versionReference,
        versionData,
    )

    batch.commit()

    return postId
