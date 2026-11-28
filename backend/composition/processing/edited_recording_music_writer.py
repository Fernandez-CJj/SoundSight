from fractions import Fraction

from music21 import chord
from music21 import duration
from music21 import note
from music21 import stream
from music21 import tie

from composition.models.composition_models import CompositionRequest


NOTATION_UNITS_PER_BEAT = 12
# Binary, dotted and simple triplet lengths on the editor's timing grid.
# Other lengths (for example 5/12 beat) need multiple tied notes, rather
# than a single irregular tuplet that MuseScore cannot reliably import.
NOTATION_SEGMENT_UNITS = (48, 42, 36, 32, 24, 21, 18, 16, 12, 9, 8, 6, 4, 3, 2, 1)


def quarterPosition(beats, beatLength):
    return Fraction(
        round(beats * NOTATION_UNITS_PER_BEAT),
        NOTATION_UNITS_PER_BEAT,
    ) * beatLength


def notationDurations(durationBeats, beatLength):
    remaining = round(durationBeats * NOTATION_UNITS_PER_BEAT)
    durations = []
    candidates = NOTATION_SEGMENT_UNITS
    if remaining % 3 == 0:
        candidates = tuple(units for units in candidates if units % 3 == 0)
    for units in candidates:
        while remaining >= units:
            durations.append(Fraction(units, NOTATION_UNITS_PER_BEAT) * beatLength)
            remaining -= units
    return durations


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
    durationQuarterLength=None,
    segmentIndex=0,
    segmentCount=1,
):
    musicNote = note.Note()

    musicNote.pitch.midi = (
        compositionNote.midiNumber
    )

    musicNote.duration.quarterLength = (
        durationQuarterLength if durationQuarterLength is not None else
        quarterPosition(compositionNote.durationBeats, beatLength)
    )

    musicNote.volume.velocityScalar = (
        compositionNote.velocity
    )

    tieType = getTieType(
        compositionNote,
        composition,
    )
    tiedFromPrevious = tieType in ("stop", "continue") or segmentIndex > 0
    tiedToNext = tieType in ("start", "continue") or segmentIndex + 1 < segmentCount
    if tiedFromPrevious and tiedToNext:
        musicNote.tie = tie.Tie("continue")
    elif tiedFromPrevious:
        musicNote.tie = tie.Tie("stop")
    elif tiedToNext:
        musicNote.tie = tie.Tie("start")

    return musicNote


def addRest(
    measure,
    startBeat,
    durationBeats,
    beatLength,
):
    startPosition = quarterPosition(startBeat, beatLength)
    for duration in notationDurations(durationBeats, beatLength):
        musicRest = note.Rest()
        musicRest.duration.quarterLength = duration
        measure.insert(startPosition, musicRest)
        startPosition += duration


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
    durationQuarterLength=None,
    segmentIndex=0,
    segmentCount=1,
):
    musicNotes = [
        createMusicNote(
            compositionNote,
            composition,
            beatLength,
            durationQuarterLength,
            segmentIndex,
            segmentCount,
        )
        for compositionNote in noteGroup
    ]

    if len(musicNotes) == 1:
        return musicNotes[0]

    musicChord = chord.Chord(musicNotes)
    musicChord.duration.quarterLength = (
        durationQuarterLength if durationQuarterLength is not None else
        quarterPosition(noteGroup[0].durationBeats, beatLength)
    )
    return musicChord


def addGridAlignedGroups(container, groups, composition, beatLength):
    """Write complete beat-sized tuplets for offsets on the 1/12-beat grid.

    Each tuplet uses the same normal-note unit throughout its beat. Letting
    music21 infer that unit separately from each note/rest creates incomplete
    groups when a recorded phrase mixes different lengths.
    """
    intervals = []
    currentUnit = 0
    tupletBeats = set()
    for group in groups:
        start = round(group[0].startBeat * NOTATION_UNITS_PER_BEAT)
        end = start + round(group[0].durationBeats * NOTATION_UNITS_PER_BEAT)
        for boundary in (start, end):
            if boundary % 3:
                tupletBeats.add(boundary // NOTATION_UNITS_PER_BEAT)
        if start > currentUnit:
            intervals.append((currentUnit, start, None))
        intervals.append((start, end, group))
        currentUnit = end
    measureEnd = composition.beatsPerMeasure * NOTATION_UNITS_PER_BEAT
    if currentUnit < measureEnd:
        intervals.append((currentUnit, measureEnd, None))

    tupletUnit = duration.Duration(beatLength / 2).components[0]
    for start, end, group in intervals:
        segments = []
        cursor = start
        while cursor < end:
            beat = cursor // NOTATION_UNITS_PER_BEAT
            beatEnd = (beat + 1) * NOTATION_UNITS_PER_BEAT
            available = min(end, beatEnd) - cursor
            isTuplet = beat in tupletBeats
            candidates = (8, 4, 2, 1) if isTuplet else (12, 9, 6, 3)
            units = next((value for value in candidates if value <= available), None)
            if units is None:
                raise ValueError("The score timing cannot be written on the editor's grid.")
            segments.append((cursor, units, isTuplet))
            cursor += units

        for index, (offset, units, isTuplet) in enumerate(segments):
            quarterLength = Fraction(units, NOTATION_UNITS_PER_BEAT) * beatLength
            if group is None:
                musicalObject = note.Rest()
                musicalObject.duration.quarterLength = quarterLength
            else:
                musicalObject = createManualMusicalObject(
                    group, composition, beatLength, quarterLength, index, len(segments),
                )
            if isTuplet:
                # A 3:2 tuplet scales the binary written duration by 2/3.
                # Fix the group's unit to half a beat for every member,
                # including rests and the differently sized tied segments.
                writtenDuration = duration.Duration(Fraction(units, 8) * beatLength)
                writtenDuration.appendTuplet(duration.Tuplet(
                    3, 2, durationActual=tupletUnit, durationNormal=tupletUnit,
                ))
                musicalObject.duration = writtenDuration
            container.insert(
                Fraction(offset, NOTATION_UNITS_PER_BEAT) * beatLength,
                musicalObject,
            )


def addGroupsToContainer(
    container,
    groups,
    composition,
    beatLength,
):
    if any(
        round(boundary * NOTATION_UNITS_PER_BEAT) % 3
        for group in groups
        for boundary in (group[0].startBeat, group[0].startBeat + group[0].durationBeats)
    ):
        addGridAlignedGroups(container, groups, composition, beatLength)
        return
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

        durations = notationDurations(compositionNote.durationBeats, beatLength)
        if not durations:
            raise ValueError("A score note is shorter than the editor's timing grid.")
        startPosition = quarterPosition(compositionNote.startBeat, beatLength)
        for segmentIndex, duration in enumerate(durations):
            musicalObject = createManualMusicalObject(
                noteGroup,
                composition,
                beatLength,
                duration,
                segmentIndex,
                len(durations),
            )
            container.insert(startPosition, musicalObject)
            startPosition += duration
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


def addEditedRecordingMusic(
    pianoPart,
    composition: CompositionRequest,
    minimumMidi=None,
    maximumMidi=None,
):
    beatLength = Fraction(4, composition.beatUnit)

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
