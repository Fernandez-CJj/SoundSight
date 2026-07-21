import os

from firebase_service import getStorageBucket


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
