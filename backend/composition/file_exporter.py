import os


def saveMusicXml(score, compositionId):
    backendFolder = os.path.dirname(
        os.path.dirname(
            os.path.abspath(__file__)
        )
    )

    outputFolder = os.path.join(
        backendFolder,
        "generated_files",
    )

    os.makedirs(
        outputFolder,
        exist_ok=True,
    )

    if compositionId == "":
        fileName = "composition.musicxml"
    else:
        fileName = (
            compositionId
            + ".musicxml"
        )

    filePath = os.path.join(
        outputFolder,
        fileName,
    )

    savedFilePath = score.write(
        "musicxml",
        fp=filePath,
    )

    return str(savedFilePath)
