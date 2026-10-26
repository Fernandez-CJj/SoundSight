from core.firebase_service import getDatabase


def validateMusicSheetSources(sheetData, sheetId, ownerId):
    sheetType = sheetData.get("type")
    pageCount = sheetData.get("pageCount")
    files = sheetData.get("files")

    if (
        type(pageCount) is not int
        or not 1 <= pageCount <= 20
        or not isinstance(files, list)
    ):
        raise ValueError("The music sheet has invalid source files.")

    folder = f"musicSheets/{ownerId}/{sheetId}/"

    if sheetType == "pdf":
        if (
            len(files) != 1
            or not isinstance(files[0], dict)
            or files[0].get("storagePath") != folder + "sheet.pdf"
        ):
            raise ValueError("The PDF source path is invalid.")
        return

    if sheetType != "images" or len(files) != pageCount:
        raise ValueError("The image source list is invalid.")

    seenPages = set()

    for fileData in files:
        if not isinstance(fileData, dict):
            raise ValueError("An image source is invalid.")

        pageNumber = fileData.get("pageNumber")
        storagePath = fileData.get("storagePath")

        if (
            type(pageNumber) is not int
            or not 1 <= pageNumber <= pageCount
            or pageNumber in seenPages
        ):
            raise ValueError("An image page number is invalid.")

        allowedPaths = {
            f"{folder}page_{pageNumber:02d}.{extension}"
            for extension in ("jpg", "jpeg", "png")
        }

        if storagePath not in allowedPaths:
            raise ValueError("An image source path is invalid.")

        seenPages.add(pageNumber)

    if seenPages != set(range(1, pageCount + 1)):
        raise ValueError("The music sheet has missing pages.")


def getMusicSheet(sheetId, ownerId):
    database = getDatabase()

    sheetDocument = (
        database
        .collection("users")
        .document(ownerId)
        .collection("musicSheets")
        .document(sheetId)
        .get()
    )

    if not sheetDocument.exists:
        raise FileNotFoundError("The music sheet was not found.")

    sheetData = sheetDocument.to_dict() or {}

    if sheetData.get("ownerId") != ownerId:
        raise PermissionError("You do not own this music sheet.")

    validateMusicSheetSources(sheetData, sheetId, ownerId)
    return sheetData