import os
import shutil

from PIL import Image

from core.firebase_service import getStorageBucket


def createOmrJobFolders(sheetId):
    backendFolder = os.path.dirname(
        os.path.dirname(
            os.path.abspath(__file__)
        )
    )

    jobsFolder = os.path.join(
        backendFolder,
        "omr_jobs",
    )

    safeSheetId = (
        sheetId
        .replace("/", "_")
        .replace("\\", "_")
    )

    jobFolder = os.path.join(
        jobsFolder,
        safeSheetId,
    )

    if os.path.exists(jobFolder):
        shutil.rmtree(
            jobFolder
        )

    inputFolder = os.path.join(
        jobFolder,
        "input",
    )

    outputFolder = os.path.join(
        jobFolder,
        "output",
    )

    os.makedirs(
        inputFolder
    )

    os.makedirs(
        outputFolder
    )

    return {
        "jobFolder": jobFolder,
        "inputFolder": inputFolder,
        "outputFolder": outputFolder,
    }


def downloadMusicSheetFiles(
    sheetData,
    inputFolder,
):
    bucket = getStorageBucket()

    sheetType = sheetData["type"]
    sheetFiles = sheetData["files"]

    if sheetType == "images":
        sheetFiles = sorted(
            sheetFiles,
            key=lambda file: file["pageNumber"],
        )

    downloadedPaths = []

    for index in range(
        len(sheetFiles)
    ):
        fileData = sheetFiles[index]

        storagePath = fileData["storagePath"]

        if sheetType == "pdf":
            localFileName = "sheet.pdf"
        else:
            extension = os.path.splitext(
                storagePath
            )[1].lower()

            if extension not in [
                ".jpg",
                ".jpeg",
                ".png",
            ]:
                raise ValueError(
                    "The music sheet contains an unsupported image."
                )

            pageNumber = index + 1

            localFileName = (
                "page_"
                + str(pageNumber).zfill(2)
                + extension
            )

        localFilePath = os.path.join(
            inputFolder,
            localFileName,
        )

        storageFile = bucket.blob(
            storagePath
        )

        if not storageFile.exists():
            raise FileNotFoundError(
                "An uploaded music-sheet file was not found."
            )

        storageFile.download_to_filename(
            localFilePath
        )

        downloadedPaths.append(
            localFilePath
        )

    return downloadedPaths


def prepareAudiverisInput(
    sheetData,
    downloadedPaths,
    inputFolder,
):
    if sheetData["type"] == "pdf":
        return downloadedPaths[0]

    return createImagePdf(
        downloadedPaths,
        inputFolder,
    )


def createImagePdf(
    imagePaths,
    inputFolder,
):
    preparedImages = []

    try:
        for imagePath in imagePaths:
            with Image.open(
                imagePath
            ) as sourceImage:
                preparedImage = sourceImage.convert(
                    "RGB"
                )

                preparedImages.append(
                    preparedImage
                )

        if len(preparedImages) == 0:
            raise ValueError(
                "There are no images to combine."
            )

        pdfPath = os.path.join(
            inputFolder,
            "sheet.pdf",
        )

        firstImage = preparedImages[0]
        remainingImages = preparedImages[1:]

        firstImage.save(
            pdfPath,
            "PDF",
            resolution=300,
            save_all=True,
            append_images=remainingImages,
        )

        return pdfPath
    finally:
        for preparedImage in preparedImages:
            preparedImage.close()


def deleteOmrJobFolder(
    jobFolder,
):
    if os.path.exists(jobFolder):
        shutil.rmtree(
            jobFolder
        )
