import os

from core.firebase_service import getStorageBucket


def uploadOmrFiles(
    musicXmlPath,
    mp3Path,
    ownerId,
    sheetId,
):
    if not os.path.exists(
        musicXmlPath
    ):
        raise FileNotFoundError(
            "The MusicXML file was not found."
        )

    if not os.path.exists(
        mp3Path
    ):
        raise FileNotFoundError(
            "The MP3 preview was not found."
        )

    if ownerId == "":
        raise ValueError(
            "The owner ID cannot be empty."
        )

    if sheetId == "":
        raise ValueError(
            "The sheet ID cannot be empty."
        )

    bucket = getStorageBucket()

    musicXmlStoragePath = (
        "musicSheets/"
        + ownerId
        + "/"
        + sheetId
        + "/recognized.mxl"
    )

    previewAudioStoragePath = (
        "musicSheets/"
        + ownerId
        + "/"
        + sheetId
        + "/preview.mp3"
    )

    musicXmlFile = bucket.blob(
        musicXmlStoragePath
    )

    previewAudioFile = bucket.blob(
        previewAudioStoragePath
    )

    uploadedFiles = []

    try:
        musicXmlFile.upload_from_filename(
            musicXmlPath,
            content_type=(
                "application/vnd.recordare.musicxml"
            ),
        )

        uploadedFiles.append(
            musicXmlFile
        )

        previewAudioFile.upload_from_filename(
            mp3Path,
            content_type="audio/mpeg",
        )

        uploadedFiles.append(
            previewAudioFile
        )
    except Exception:
        for uploadedFile in uploadedFiles:
            try:
                uploadedFile.delete()
            except Exception:
                pass

        raise

    return {
        "musicXmlStoragePath": musicXmlStoragePath,
        "previewAudioStoragePath": previewAudioStoragePath,
    }
