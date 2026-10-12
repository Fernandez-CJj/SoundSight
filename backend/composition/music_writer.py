from music21 import chord
from music21 import note
from music21 import stream
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


def groupMeasureNotes(measureNotes):
    groupsByTiming = {}
    for compositionNote in measureNotes:
        timingKey = (
            round(compositionNote.startBeat, 8),
            round(compositionNote.durationBeats, 8),
        )
        groupsByTiming.setdefault(
            timingKey,
            [],
        ).append(compositionNote)

    groups = list(groupsByTiming.values())
    groups.sort(
        key=lambda group: (
            group[0].startBeat,
            -group[0].durationBeats,
            min(item.midiNumber for item in group),
        )
    )
    return groups


def assignGroupsToVoices(groups):
    voices = []
    voiceEndBeats = []

    for group in groups:
        startBeat = group[0].startBeat
        endBeat = startBeat + group[0].durationBeats
        voiceIndex = None

        for index, voiceEndBeat in enumerate(voiceEndBeats):
            if voiceEndBeat <= startBeat + 0.0001:
                voiceIndex = index
                break

        if voiceIndex is None:
            voiceIndex = len(voices)
            voices.append([])
            voiceEndBeats.append(0)

        voices[voiceIndex].append(group)
        voiceEndBeats[voiceIndex] = endBeat

    return voices


def createManualMusicalObject(
    noteGroup,
    composition,
    beatLength,
):
    musicNotes = [
        createMusicNote(
            compositionNote,
            composition,
            beatLength,
        )
        for compositionNote in noteGroup
    ]

    if len(musicNotes) == 1:
        return musicNotes[0]

    musicChord = chord.Chord(musicNotes)
    musicChord.duration.quarterLength = (
        noteGroup[0].durationBeats * beatLength
    )
    return musicChord


def addGroupsToContainer(
    container,
    groups,
    composition,
    beatLength,
):
    currentBeat = 0

    for noteGroup in groups:
        compositionNote = noteGroup[0]
        if compositionNote.startBeat > currentBeat + 0.0001:
            addRest(
                container,
                currentBeat,
                compositionNote.startBeat - currentBeat,
                beatLength,
            )

        musicalObject = createManualMusicalObject(
            noteGroup,
            composition,
            beatLength,
        )
        container.insert(
            compositionNote.startBeat * beatLength,
            musicalObject,
        )
        currentBeat = max(
            currentBeat,
            compositionNote.startBeat
            + compositionNote.durationBeats,
        )

    if currentBeat < composition.beatsPerMeasure - 0.0001:
        addRest(
            container,
            currentBeat,
            composition.beatsPerMeasure - currentBeat,
            beatLength,
        )


def addMeasureMusic(
    measure,
    measureNotes,
    composition,
    beatLength,
):
    if len(measureNotes) == 0:
        addRest(
            measure,
            0,
            composition.beatsPerMeasure,
            beatLength,
        )
        return

    voices = assignGroupsToVoices(
        groupMeasureNotes(measureNotes)
    )

    if len(voices) == 1:
        addGroupsToContainer(
            measure,
            voices[0],
            composition,
            beatLength,
        )
        return

    for voiceIndex, voiceGroups in enumerate(voices):
        musicVoice = stream.Voice(
            id=str(voiceIndex + 1)
        )
        addGroupsToContainer(
            musicVoice,
            voiceGroups,
            composition,
            beatLength,
        )
        measure.insert(0, musicVoice)


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
