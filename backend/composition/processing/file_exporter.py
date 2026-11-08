import os
import xml.etree.ElementTree as ElementTree


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


def normalizeManualMusicXmlForMuseScore(musicXmlPath):
    try:
        document = ElementTree.parse(musicXmlPath)
    except ElementTree.ParseError as error:
        raise ValueError(
            "The manual composition MusicXML is malformed."
        ) from error

    root = document.getroot()
    wasChanged = False

    for musicNote in root.iter():
        if localName(musicNote.tag) != "note":
            continue

        timeModification = directChild(
            musicNote,
            "time-modification",
        )
        if timeModification is None:
            continue

        actualNotes = childInteger(
            timeModification,
            "actual-notes",
        )
        normalNotes = childInteger(
            timeModification,
            "normal-notes",
        )
        if (
            actualNotes is not None
            and normalNotes is not None
            and isPowerOfTwo(normalNotes)
        ):
            continue

        musicNote.remove(timeModification)
        notations = directChild(musicNote, "notations")
        if notations is not None:
            for notation in list(notations):
                if localName(notation.tag) == "tuplet":
                    notations.remove(notation)
            if len(notations) == 0:
                musicNote.remove(notations)
        wasChanged = True

    if not wasChanged:
        return musicXmlPath

    temporaryPath = musicXmlPath + ".normalized"
    try:
        document.write(
            temporaryPath,
            encoding="utf-8",
            xml_declaration=True,
        )
        if os.path.getsize(temporaryPath) == 0:
            raise RuntimeError(
                "MusicXML normalization created an empty file."
            )
        os.replace(temporaryPath, musicXmlPath)
    finally:
        if os.path.exists(temporaryPath):
            os.remove(temporaryPath)

    return musicXmlPath


def localName(tag):
    return tag.rsplit("}", 1)[-1]


def directChild(parent, childName):
    for child in parent:
        if localName(child.tag) == childName:
            return child
    return None


def childInteger(parent, childName):
    child = directChild(parent, childName)
    if child is None or child.text is None:
        return None
    try:
        return int(child.text)
    except ValueError:
        return None


def isPowerOfTwo(value):
    return value > 0 and value & (value - 1) == 0
