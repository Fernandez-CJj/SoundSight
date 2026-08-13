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
    pdfStoragePath,
    publicProfile,
    versionNumber,
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
        "tempo": composition.tempo,
        "key": composition.key,
        "beatsPerMeasure": (
            composition.beatsPerMeasure
        ),
        "beatUnit": composition.beatUnit,
        "measureCount": composition.measureCount,
        "noteCount": len(composition.notes),
        "pdfStoragePath": pdfStoragePath,
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
