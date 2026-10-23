import os
from uuid import uuid4

from core.firebase_service import getStorageBucket


def copyPublishedCompositionFiles(
    privateStoragePaths,
    ownerId,
    compositionId,
    versionNumber,
):
    if ownerId == "" or compositionId == "":
        raise ValueError(
            "The published composition owner and ID are required."
        )

    bucket = getStorageBucket()
    privatePrefix = (
        "composition_files/"
        + ownerId
        + "/"
        + compositionId
        + "/"
    )
    publicPrefix = (
        "published_compositions/"
        + ownerId
        + "/"
        + compositionId
        + "/version_"
        + str(versionNumber)
    )
    fileDefinitions = [
        {
            "key": "pdfStoragePath",
            "extension": "pdf",
            "contentType": "application/pdf",
        },
        {
            "key": "musicXmlStoragePath",
            "extension": "musicxml",
            "contentType": "application/vnd.recordare.musicxml+xml",
        },
        {
            "key": "midiStoragePath",
            "extension": "mid",
            "contentType": "audio/midi",
        },
        {
            "key": "mp3StoragePath",
            "extension": "mp3",
            "contentType": "audio/mpeg",
        },
    ]
    publishedStoragePaths = {}
    copiedFiles = []

    try:
        for fileDefinition in fileDefinitions:
            resultKey = fileDefinition["key"]
            privatePath = privateStoragePaths.get(resultKey)

            if (
                not isinstance(privatePath, str)
                or not privatePath.startswith(privatePrefix)
            ):
                raise ValueError(
                    "The private composition file paths are invalid."
                )

            privateFile = bucket.blob(privatePath)
            if not privateFile.exists():
                raise FileNotFoundError(
                    "A private composition file is missing: "
                    + privatePath
                )

            publicPath = (
                publicPrefix
                + "."
                + fileDefinition["extension"]
            )
            publicFile = bucket.copy_blob(
                privateFile,
                bucket,
                new_name=publicPath,
            )
            publicFile.content_type = fileDefinition["contentType"]
            publicFile.metadata = {
                "firebaseStorageDownloadTokens": str(uuid4()),
            }
            publicFile.patch()

            copiedFiles.append(publicFile)
            publishedStoragePaths[resultKey] = publicPath
    except Exception:
        for copiedFile in copiedFiles:
            try:
                copiedFile.delete()
            except Exception:
                pass
        raise

    return publishedStoragePaths


def deleteStoragePaths(storagePaths):
    bucket = getStorageBucket()

    for storagePath in storagePaths:
        if not isinstance(storagePath, str) or storagePath == "":
            continue

        try:
            storageFile = bucket.blob(storagePath)
            if storageFile.exists():
                storageFile.delete()
        except Exception:
            pass


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

            storageFile.metadata = {
                "firebaseStorageDownloadTokens": (
                    str(uuid4())
                ),
            }

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


def deletePublishedCompositionFiles(
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

    for publishedFile in bucket.list_blobs(
        prefix=versionedPrefix
    ):
        publishedFile.delete()

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
