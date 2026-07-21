from music21 import clef
from music21 import instrument
from music21 import key
from music21 import layout
from music21 import metadata
from music21 import meter
from music21 import stream
from music21 import tempo

from composition_models import CompositionRequest
from music_writer import addCompositionMusic


def create_basic_score(
    composition: CompositionRequest,
    authorName="SoundSight Musician",
):
    score = stream.Score()

    scoreMetadata = metadata.Metadata()
    scoreMetadata.title = composition.title
    scoreMetadata.composer = authorName

    score.metadata = scoreMetadata

    keyParts = composition.key.split()

    keyName = keyParts[0]
    keyMode = keyParts[1].lower()

    timeSignatureText = (
        str(composition.beatsPerMeasure)
        + "/"
        + str(composition.beatUnit)
    )

    trebleStaff = createPianoStaff(
        staffId="PianoTreble",
        staffName="Piano",
        staffClef=clef.TrebleClef(),
        composition=composition,
        keyName=keyName,
        keyMode=keyMode,
        timeSignatureText=timeSignatureText,
        includeTempo=True,
    )

    bassStaff = createPianoStaff(
        staffId="PianoBass",
        staffName="",
        staffClef=clef.BassClef(),
        composition=composition,
        keyName=keyName,
        keyMode=keyMode,
        timeSignatureText=timeSignatureText,
        includeTempo=False,
    )

    addCompositionMusic(
        trebleStaff,
        composition,
        minimumMidi=60,
    )

    addCompositionMusic(
        bassStaff,
        composition,
        maximumMidi=59,
    )

    score.append(trebleStaff)
    score.append(bassStaff)

    pianoStaffGroup = layout.StaffGroup(
        [trebleStaff, bassStaff],
        name="Piano",
        abbreviation="Pno.",
        symbol="brace",
        barTogether=True,
    )

    score.insert(0, pianoStaffGroup)

    return score


def createPianoStaff(
    staffId,
    staffName,
    staffClef,
    composition,
    keyName,
    keyMode,
    timeSignatureText,
    includeTempo,
):
    pianoStaff = stream.PartStaff()
    pianoStaff.id = staffId
    pianoStaff.partName = staffName

    pianoInstrument = instrument.Piano()
    pianoInstrument.partName = staffName
    pianoStaff.insert(0, pianoInstrument)

    for measureNumber in range(
        1,
        composition.measureCount + 1,
    ):
        measure = stream.Measure(
            number=measureNumber
        )

        if measureNumber == 1:
            measure.insert(0, staffClef)
            measure.insert(
                0,
                key.Key(keyName, keyMode),
            )
            measure.insert(
                0,
                meter.TimeSignature(
                    timeSignatureText
                ),
            )

            if includeTempo:
                measure.insert(
                    0,
                    tempo.MetronomeMark(
                        number=composition.tempo
                    ),
                )

        pianoStaff.append(measure)

    return pianoStaff
