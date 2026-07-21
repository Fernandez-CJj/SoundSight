import os

from fastapi import FastAPI
from fastapi import HTTPException

from composition_models import CompositionRequest
from composition_models import UnpublishRequest
from file_exporter import saveMusicXml
from musescore_service import exportPdf
from post_service import getNextPublishedVersion
from post_service import saveCompositionPost
from public_profile_service import getPublicProfile
from score_builder import create_basic_score
from storage_service import uploadPdf
from unpublish_service import unpublishComposition


app = FastAPI(
    title="SoundSight Composition API",
    description="Converts SoundSight compositions into music sheets.",
    version="1.0.0",
)


@app.get("/")
def root():
    return {
        "message": "SoundSight composition backend is running."
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


@app.post("/compositions")
def receive_composition(composition: CompositionRequest):
    publicProfile = getPublicProfile(
        composition.ownerId
    )

    score = create_basic_score(
        composition,
        publicProfile["username"],
    )

    versionNumber = getNextPublishedVersion(
        composition.id
    )

    scoreNoteCount = 0
    chordCount = 0
    restCount = 0
    tiedNoteCount = 0

    for musicalObject in score.recurse().notesAndRests:
        if musicalObject.isChord:
            chordCount = chordCount + 1

            scoreNoteCount = (
                scoreNoteCount
                + len(musicalObject.pitches)
            )

            for chordNote in musicalObject.notes:
                if chordNote.tie is not None:
                    tiedNoteCount = (
                        tiedNoteCount + 1
                    )

        elif musicalObject.isNote:
            scoreNoteCount = scoreNoteCount + 1

            if musicalObject.tie is not None:
                tiedNoteCount = (
                    tiedNoteCount + 1
                )

        elif musicalObject.isRest:
            restCount = restCount + 1

    musicXmlPath = saveMusicXml(
        score,
        composition.id,
    )

    pdfPath = exportPdf(
        musicXmlPath
    )

    pdfStoragePath = uploadPdf(
        pdfPath,
        composition.ownerId,
        composition.id,
        versionNumber,
    )

    postId = saveCompositionPost(
        composition,
        pdfStoragePath,
        publicProfile,
        versionNumber,
    )

    return {
        "message": "Composition published successfully.",
        "postId": postId,
        "compositionId": composition.id,
        "title": score.metadata.title,
        "authorName": publicProfile["username"],
        "versionNumber": versionNumber,
        "receivedNoteCount": len(composition.notes),
        "scoreNoteCount": scoreNoteCount,
        "chordCount": chordCount,
        "restCount": restCount,
        "tiedNoteCount": tiedNoteCount,
        "partCount": len(score.parts),
        "musicXmlCreated": os.path.exists(
            musicXmlPath
        ),
        "pdfCreated": os.path.exists(
            pdfPath
        ),
        "pdfFileName": os.path.basename(
            pdfPath
        ),
        "pdfStoragePath": pdfStoragePath,
    }


@app.delete("/compositions/{compositionId}")
def unpublish_composition(
    compositionId: str,
    request: UnpublishRequest,
):
    try:
        wasDeleted = unpublishComposition(
            compositionId,
            request.ownerId,
        )
    except PermissionError as error:
        raise HTTPException(
            status_code=403,
            detail=str(error),
        ) from error

    if not wasDeleted:
        raise HTTPException(
            status_code=404,
            detail="The published composition was not found.",
        )

    return {
        "message": "Composition unpublished successfully.",
        "compositionId": compositionId,
    }
