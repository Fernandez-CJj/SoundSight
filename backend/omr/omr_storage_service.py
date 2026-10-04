import os

from core.firebase_service import getStorageBucket


def validateGeneratedFile(
    filePath,
    fileLabel,
):
    if not os.path.exists(
        filePath
    ):
        raise FileNotFoundError(
            "The "
            + fileLabel
            + " file was not found."
        )

    if os.path.getsize(
        filePath
    ) == 0:
        raise RuntimeError(
            "The "
            + fileLabel
            + " file is empty."
        )


def uploadOmrFiles(
    musicXmlPath,
    midiPath,
    pdfPath,
    mp3Path,
    ownerId,
    sheetId,
):
    validateGeneratedFile(
        musicXmlPath,
        "MusicXML",
    )

    validateGeneratedFile(
        midiPath,
        "MIDI",
    )

    validateGeneratedFile(
        pdfPath,
        "recognized PDF",
    )

    validateGeneratedFile(
        mp3Path,
        "MP3 preview",
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

    midiStoragePath = (
        "musicSheets/"
        + ownerId
        + "/"
        + sheetId
        + "/recognized.mid"
    )

    recognizedPdfStoragePath = (
        "musicSheets/"
        + ownerId
        + "/"
        + sheetId
        + "/recognized.pdf"
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

    midiFile = bucket.blob(
        midiStoragePath
    )

    recognizedPdfFile = bucket.blob(
        recognizedPdfStoragePath
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

        midiFile.upload_from_filename(
            midiPath,
            content_type="audio/midi",
        )

        uploadedFiles.append(
            midiFile
        )

        recognizedPdfFile.upload_from_filename(
            pdfPath,
            content_type="application/pdf",
        )

        uploadedFiles.append(
            recognizedPdfFile
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
        "midiStoragePath": midiStoragePath,
        "recognizedPdfStoragePath": recognizedPdfStoragePath,
        "previewAudioStoragePath": previewAudioStoragePath,
    }
