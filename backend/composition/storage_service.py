import os

from core.firebase_service import getStorageBucket


def uploadPdf(
    pdfPath,
    ownerId,
    compositionId,
    versionNumber,
):
    if not os.path.exists(pdfPath):
        raise FileNotFoundError(
            "The PDF file does not exist."
        )

    if compositionId == "":
        raise ValueError(
            "The composition ID cannot be empty."
        )

    bucket = getStorageBucket()

    storagePath = (
        "published_compositions/"
        + ownerId
        + "/"
        + compositionId
        + "/version_"
        + str(versionNumber)
        + ".pdf"
    )

    pdfFile = bucket.blob(
        storagePath
    )

    pdfFile.upload_from_filename(
        pdfPath,
        content_type="application/pdf",
    )

    return storagePath


def uploadCompositionFiles(
    pdfPath,
    musicXmlPath,
    midiPath,
    mp3Path,
    ownerId,
    compositionId,
):
    generatedFiles = [
        {
            "localPath": pdfPath,
            "extension": "pdf",
            "contentType": "application/pdf",
            "resultKey": "pdfStoragePath",
        },
        {
            "localPath": musicXmlPath,
            "extension": "musicxml",
            "contentType": (
                "application/vnd.recordare.musicxml+xml"
            ),
            "resultKey": "musicXmlStoragePath",
        },
        {
            "localPath": midiPath,
            "extension": "mid",
            "contentType": "audio/midi",
            "resultKey": "midiStoragePath",
        },
        {
            "localPath": mp3Path,
            "extension": "mp3",
            "contentType": "audio/mpeg",
            "resultKey": "mp3StoragePath",
        },
    ]

    if ownerId == "":
        raise ValueError(
            "The owner ID cannot be empty."
        )

    if compositionId == "":
        raise ValueError(
            "The composition ID cannot be empty."
        )

    bucket = getStorageBucket()

    baseStoragePath = (
        "composition_files/"
        + ownerId
        + "/"
        + compositionId
    )

    storagePaths = {}
    uploadedFiles = []

    try:
        for generatedFile in generatedFiles:
            localPath = generatedFile["localPath"]

            if not os.path.exists(localPath):
                raise FileNotFoundError(
                    "A generated composition file "
                    "does not exist: "
                    + localPath
                )

            storagePath = (
                baseStoragePath
                + "/score."
                + generatedFile["extension"]
            )

            storageFile = bucket.blob(
                storagePath
            )

            storageFile.upload_from_filename(
                localPath,
                content_type=(
                    generatedFile["contentType"]
                ),
            )

            uploadedFiles.append(
                storageFile
            )

            storagePaths[
                generatedFile["resultKey"]
            ] = storagePath

    except Exception:
        for uploadedFile in uploadedFiles:
            try:
                uploadedFile.delete()
            except Exception:
                pass

        raise

    return storagePaths


def deletePublishedPdfs(
    ownerId,
    compositionId,
):
    bucket = getStorageBucket()

    versionedPrefix = (
        "published_compositions/"
        + ownerId
        + "/"
        + compositionId
        + "/"
    )

    for pdfFile in bucket.list_blobs(
        prefix=versionedPrefix
    ):
        pdfFile.delete()

    legacyPath = (
        "published_compositions/"
        + ownerId
        + "/"
        + compositionId
        + ".pdf"
    )

    legacyFile = bucket.blob(
        legacyPath
    )

    if legacyFile.exists():
        legacyFile.delete()
