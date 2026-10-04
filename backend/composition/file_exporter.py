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

def saveMidi(score, compositionId, outputFolder):
    if compositionId == "":
        fileName = "composition.mid"
    else:
        fileName = (
            compositionId
            + ".mid"
        )

    filePath = os.path.join(outputFolder, fileName)

    savedFilePath = score.write("midi", fp=filePath)

    return str(savedFilePath)