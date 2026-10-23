import os
from xml.etree import ElementTree


PIANO_PART_NAME = "Piano"
PIANO_PART_ABBREVIATION = "Pno."
PIANO_INSTRUMENT_NAME = "Acoustic Grand Piano"
PIANO_INSTRUMENT_SOUND = "keyboard.piano.grand"
PIANO_MIDI_BANK = "1"
PIANO_MIDI_CHANNEL = "1"
PIANO_MIDI_PROGRAM = "1"


def normalizeMusicXmlForPiano(musicXmlPath):
    if not os.path.exists(musicXmlPath):
        raise FileNotFoundError(
            "The MusicXML file was not found."
        )

    try:
        document = ElementTree.parse(musicXmlPath)
    except ElementTree.ParseError as error:
        raise ValueError(
            "The MusicXML file could not be normalized for piano."
        ) from error

    root = document.getroot()
    namespace = namespaceFor(root.tag)
    if namespace != "":
        ElementTree.register_namespace("", namespace)

    scoreParts = [
        element
        for element in root.iter()
        if localName(element.tag) == "score-part"
    ]

    if len(scoreParts) == 0:
        raise ValueError(
            "The MusicXML file does not declare any score parts."
        )

    referencedInstrumentIds = collectReferencedInstrumentIds(root)

    for scorePart in scoreParts:
        partId = scorePart.attrib.get("id", "").strip()
        if partId == "":
            raise ValueError(
                "The MusicXML file contains a score part without an ID."
            )

        normalizePartLabels(scorePart)
        normalizePartInstruments(
            scorePart,
            referencedInstrumentIds.get(partId, set()),
        )

    temporaryPath = musicXmlPath + ".piano-normalized"

    try:
        document.write(
            temporaryPath,
            encoding="utf-8",
            xml_declaration=True,
        )

        if os.path.getsize(temporaryPath) == 0:
            raise RuntimeError(
                "Piano normalization created an empty MusicXML file."
            )

        try:
            ElementTree.parse(temporaryPath)
        except ElementTree.ParseError as error:
            raise ValueError(
                "Piano normalization created invalid MusicXML."
            ) from error

        os.replace(temporaryPath, musicXmlPath)
    finally:
        if os.path.exists(temporaryPath):
            os.remove(temporaryPath)

    return musicXmlPath


def normalizePartLabels(scorePart):
    partName = directChild(scorePart, "part-name")
    if partName is None:
        partName = createChild(scorePart, "part-name", 0)
    partName.text = PIANO_PART_NAME

    removeDirectChildren(
        scorePart,
        {
            "part-name-display",
            "part-abbreviation-display",
        },
    )

    partAbbreviation = directChild(
        scorePart,
        "part-abbreviation",
    )
    if partAbbreviation is None:
        partAbbreviation = createChildAfter(
            scorePart,
            "part-abbreviation",
            partName,
        )
    partAbbreviation.text = PIANO_PART_ABBREVIATION


def normalizePartInstruments(
    scorePart,
    referencedInstrumentIds,
):
    partId = scorePart.attrib["id"]
    scoreInstruments = directChildren(
        scorePart,
        "score-instrument",
    )

    declaredInstrumentIds = {
        instrument.attrib.get("id", "").strip()
        for instrument in scoreInstruments
        if instrument.attrib.get("id", "").strip() != ""
    }

    requiredInstrumentIds = (
        declaredInstrumentIds
        | referencedInstrumentIds
    )

    if len(requiredInstrumentIds) == 0:
        requiredInstrumentIds = {partId + "-I1"}

    for instrumentId in sorted(requiredInstrumentIds):
        scoreInstrument = findChildById(
            scoreInstruments,
            instrumentId,
        )
        if scoreInstrument is None:
            scoreInstrument = createScoreInstrument(
                scorePart,
                instrumentId,
            )
            scoreInstruments.append(scoreInstrument)
        normalizeScoreInstrument(scoreInstrument)

    midiInstruments = directChildren(
        scorePart,
        "midi-instrument",
    )

    for midiInstrument in midiInstruments:
        instrumentId = midiInstrument.attrib.get(
            "id",
            "",
        ).strip()
        if instrumentId == "":
            midiInstrument.attrib["id"] = sorted(
                requiredInstrumentIds
            )[0]
        normalizeMidiInstrument(midiInstrument)

    midiInstrumentIds = {
        instrument.attrib.get("id", "").strip()
        for instrument in midiInstruments
    }

    for instrumentId in sorted(requiredInstrumentIds):
        if instrumentId in midiInstrumentIds:
            continue
        midiInstrument = ElementTree.Element(
            qualifiedName(scorePart, "midi-instrument"),
            {"id": instrumentId},
        )
        scorePart.append(midiInstrument)
        normalizeMidiInstrument(midiInstrument)


def normalizeScoreInstrument(scoreInstrument):
    instrumentName = directChild(
        scoreInstrument,
        "instrument-name",
    )
    if instrumentName is None:
        instrumentName = createChild(
            scoreInstrument,
            "instrument-name",
            0,
        )
    instrumentName.text = PIANO_INSTRUMENT_NAME

    instrumentAbbreviation = directChild(
        scoreInstrument,
        "instrument-abbreviation",
    )
    if instrumentAbbreviation is None:
        instrumentAbbreviation = createChildAfter(
            scoreInstrument,
            "instrument-abbreviation",
            instrumentName,
        )
    instrumentAbbreviation.text = PIANO_PART_ABBREVIATION

    instrumentSound = directChild(
        scoreInstrument,
        "instrument-sound",
    )
    if instrumentSound is None:
        instrumentSound = createChildAfter(
            scoreInstrument,
            "instrument-sound",
            instrumentAbbreviation,
        )
    instrumentSound.text = PIANO_INSTRUMENT_SOUND

    removeDirectChildren(
        scoreInstrument,
        {"virtual-instrument"},
    )


def normalizeMidiInstrument(midiInstrument):
    removeDirectChildren(
        midiInstrument,
        {
            "midi-channel",
            "midi-name",
            "midi-bank",
            "midi-program",
            "midi-unpitched",
        },
    )

    pianoValues = [
        ("midi-channel", PIANO_MIDI_CHANNEL),
        ("midi-name", PIANO_INSTRUMENT_NAME),
        ("midi-bank", PIANO_MIDI_BANK),
        ("midi-program", PIANO_MIDI_PROGRAM),
    ]

    for index, (childName, value) in enumerate(
        pianoValues
    ):
        child = createChild(
            midiInstrument,
            childName,
            index,
        )
        child.text = value


def collectReferencedInstrumentIds(root):
    referencedIds = {}

    for part in root.iter():
        if localName(part.tag) != "part":
            continue

        partId = part.attrib.get("id", "").strip()
        if partId == "":
            continue

        partInstrumentIds = referencedIds.setdefault(
            partId,
            set(),
        )

        for descendant in part.iter():
            if localName(descendant.tag) != "instrument":
                continue
            instrumentId = descendant.attrib.get(
                "id",
                "",
            ).strip()
            if instrumentId != "":
                partInstrumentIds.add(instrumentId)

    return referencedIds


def createScoreInstrument(scorePart, instrumentId):
    scoreInstrument = ElementTree.Element(
        qualifiedName(scorePart, "score-instrument"),
        {"id": instrumentId},
    )

    insertionIndex = len(scorePart)
    for index, child in enumerate(scorePart):
        if localName(child.tag) in {
            "player",
            "midi-device",
            "midi-instrument",
        }:
            insertionIndex = index
            break

    scorePart.insert(insertionIndex, scoreInstrument)
    return scoreInstrument


def findChildById(children, childId):
    for child in children:
        if child.attrib.get("id", "").strip() == childId:
            return child
    return None


def directChild(parent, childName):
    for child in parent:
        if localName(child.tag) == childName:
            return child
    return None


def directChildren(parent, childName):
    return [
        child
        for child in parent
        if localName(child.tag) == childName
    ]


def removeDirectChildren(parent, childNames):
    for child in list(parent):
        if localName(child.tag) in childNames:
            parent.remove(child)


def createChild(parent, childName, index):
    child = ElementTree.Element(
        qualifiedName(parent, childName)
    )
    parent.insert(index, child)
    return child


def createChildAfter(parent, childName, previousChild):
    child = ElementTree.Element(
        qualifiedName(parent, childName)
    )
    previousIndex = list(parent).index(previousChild)
    parent.insert(previousIndex + 1, child)
    return child


def qualifiedName(referenceElement, childName):
    namespace = namespaceFor(referenceElement.tag)
    if namespace == "":
        return childName
    return "{" + namespace + "}" + childName


def namespaceFor(tag):
    if not tag.startswith("{"):
        return ""
    return tag[1:].split("}", 1)[0]


def localName(tag):
    return tag.rsplit("}", 1)[-1]
