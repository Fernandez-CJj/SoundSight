import os


def saveMusicXml(score, compositionId, outputFolder):
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
