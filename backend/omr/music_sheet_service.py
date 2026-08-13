from core.firebase_service import getDatabase


def getMusicSheet(
    sheetId,
    ownerId,
):
    database = getDatabase()

    sheetDocument = (
        database
        .collection("musicSheets")
        .document(sheetId)
        .get()
    )

    if not sheetDocument.exists:
        raise FileNotFoundError(
            "The music sheet was not found."
        )

    sheetData = sheetDocument.to_dict()

    if sheetData["ownerId"] != ownerId:
        raise PermissionError(
            "You do not own this music sheet."
        )

    sheetFiles = sheetData.get(
        "files",
        [],
    )

    if len(sheetFiles) == 0:
        raise ValueError(
            "The music sheet does not contain any files."
        )

    return sheetData
