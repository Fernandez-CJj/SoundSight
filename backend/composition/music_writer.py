from music21 import chord
from music21 import note
from music21 import tie

from composition.composition_models import CompositionRequest


def getStartBeat(compositionNote):
    return compositionNote.startBeat


def getTieType(compositionNote, composition):
    tiedFromPrevious = False

    currentStart = (
        compositionNote.measureIndex
        * composition.beatsPerMeasure
        + compositionNote.startBeat
    )

    for previousNote in composition.notes:
        previousEnd = (
            previousNote.measureIndex
            * composition.beatsPerMeasure
            + previousNote.startBeat
            + previousNote.durationBeats
        )

        samePitch = (
            previousNote.midiNumber
            == compositionNote.midiNumber
        )

        touchesCurrentNote = (
            abs(previousEnd - currentStart) < 0.0001
        )

        if (
            previousNote.tieToNext
            and samePitch
            and touchesCurrentNote
        ):
            tiedFromPrevious = True
            break

    if tiedFromPrevious and compositionNote.tieToNext:
        return "continue"

    if compositionNote.tieToNext:
        return "start"

    if tiedFromPrevious:
        return "stop"

    return None


def createMusicNote(
    compositionNote,
    composition,
    beatLength,
):
    musicNote = note.Note()

    musicNote.pitch.midi = (
        compositionNote.midiNumber
    )

    musicNote.duration.quarterLength = (
        compositionNote.durationBeats
        * beatLength
    )

    musicNote.volume.velocityScalar = (
        compositionNote.velocity
    )

    tieType = getTieType(
        compositionNote,
        composition,
    )

    if tieType is not None:
        musicNote.tie = tie.Tie(tieType)

    return musicNote


def addRest(
    measure,
    startBeat,
    durationBeats,
    beatLength,
):
    musicRest = note.Rest()

    musicRest.duration.quarterLength = (
        durationBeats * beatLength
    )

    startPosition = (
        startBeat * beatLength
    )

    measure.insert(
        startPosition,
        musicRest,
    )


def addMeasureMusic(
    measure,
    measureNotes,
    composition,
    beatLength,
):
    currentBeat = 0
    handledNoteIds = []

    for compositionNote in measureNotes:
        if compositionNote.id in handledNoteIds:
            continue

        notesAtSameBeat = []

        for possibleChordNote in measureNotes:
            sameStartBeat = (
                abs(
                    possibleChordNote.startBeat
                    - compositionNote.startBeat
                )
                < 0.0001
            )

            sameDuration = (
                abs(
                    possibleChordNote.durationBeats
                    - compositionNote.durationBeats
                )
                < 0.0001
            )

            if sameStartBeat and sameDuration:
                notesAtSameBeat.append(
                    possibleChordNote
                )

        for groupedNote in notesAtSameBeat:
            handledNoteIds.append(
                groupedNote.id
            )

        if compositionNote.startBeat > currentBeat:
            restDuration = (
                compositionNote.startBeat
                - currentBeat
            )

            addRest(
                measure,
                currentBeat,
                restDuration,
                beatLength,
            )

        musicNotes = []

        for groupedNote in notesAtSameBeat:
            musicNote = createMusicNote(
                groupedNote,
                composition,
                beatLength,
            )

            musicNotes.append(musicNote)

        if len(musicNotes) == 1:
            musicalObject = musicNotes[0]
        else:
            musicalObject = chord.Chord(
                musicNotes
            )

        startPosition = (
            compositionNote.startBeat
            * beatLength
        )

        measure.insert(
            startPosition,
            musicalObject,
        )

        noteEnd = (
            compositionNote.startBeat
            + compositionNote.durationBeats
        )

        if noteEnd > currentBeat:
            currentBeat = noteEnd

    if currentBeat < composition.beatsPerMeasure:
        remainingBeats = (
            composition.beatsPerMeasure
            - currentBeat
        )

        addRest(
            measure,
            currentBeat,
            remainingBeats,
            beatLength,
        )


def addCompositionMusic(
    pianoPart,
    composition: CompositionRequest,
    minimumMidi=None,
    maximumMidi=None,
):
    beatLength = 4 / composition.beatUnit

    for measureIndex in range(
        composition.measureCount
    ):
        measureNumber = measureIndex + 1

        measure = pianoPart.measure(
            measureNumber
        )

        measureNotes = []

        for compositionNote in composition.notes:
            if compositionNote.measureIndex != measureIndex:
                continue

            if (
                minimumMidi is not None
                and compositionNote.midiNumber < minimumMidi
            ):
                continue

            if (
                maximumMidi is not None
                and compositionNote.midiNumber > maximumMidi
            ):
                continue

            measureNotes.append(
                compositionNote
            )

        measureNotes.sort(
            key=getStartBeat
        )

        addMeasureMusic(
            measure,
            measureNotes,
            composition,
            beatLength,
        )
