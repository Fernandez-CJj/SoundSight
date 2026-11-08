from dataclasses import dataclass
from fractions import Fraction
import math

from music21 import chord
from music21 import note
from music21 import stream
from music21 import tie


TICKS_PER_QUARTER = 960
NOTATION_TICK_STEP = TICKS_PER_QUARTER // 4


@dataclass
class PerformanceNoteGroup:
    startTick: int
    endTick: int
    midiNumbers: list[int]
    velocities: list[int]


def microsecondsToTicks(microseconds, tempo):
    return max(
        0,
        round(
            microseconds
            * tempo
            * TICKS_PER_QUARTER
            / 60_000_000
        ),
    )


def ticksToQuarterLength(ticks):
    return Fraction(ticks, TICKS_PER_QUARTER)


def roundNotationTick(tick):
    return (
        math.floor(
            tick / NOTATION_TICK_STEP + 0.5
        )
        * NOTATION_TICK_STEP
    )


def createPerformanceGroups(performanceNotes, tempo):
    groupsByInterval = {}
    for performanceNote in performanceNotes:
        exactStartTick = microsecondsToTicks(
            performanceNote.startTimeUs, tempo
        )
        exactEndTick = microsecondsToTicks(
            performanceNote.startTimeUs + performanceNote.durationUs,
            tempo,
        )
        startTick = roundNotationTick(exactStartTick)
        endTick = max(
            startTick + NOTATION_TICK_STEP,
            roundNotationTick(exactEndTick),
        )
        interval = (
            startTick,
            endTick,
        )
        group = groupsByInterval.setdefault(
            interval,
            PerformanceNoteGroup(
                startTick=startTick,
                endTick=endTick,
                midiNumbers=[],
                velocities=[],
            ),
        )
        group.midiNumbers.append(performanceNote.midiNumber)
        group.velocities.append(performanceNote.velocity)

    groups = list(groupsByInterval.values())
    groups.sort(
        key=lambda group: (
            group.startTick,
            group.endTick,
            group.midiNumbers,
        )
    )
    return groups


def simplifySequentialTiming(groups):
    simplifiedGroups = []
    for group in groups:
        if simplifiedGroups:
            previousGroup = simplifiedGroups[-1]
            overlap = previousGroup.endTick - group.startTick
            if (
                group.startTick > previousGroup.startTick
                and 0 < overlap <= NOTATION_TICK_STEP
            ):
                previousGroup.endTick = group.startTick
        simplifiedGroups.append(group)
    return simplifiedGroups


def closeSmallNotationGaps(voiceGroups):
    for index in range(1, len(voiceGroups)):
        previousGroup = voiceGroups[index - 1]
        currentGroup = voiceGroups[index]
        gap = currentGroup.startTick - previousGroup.endTick
        if 0 < gap <= NOTATION_TICK_STEP:
            previousGroup.endTick = currentGroup.startTick


def assignGroupsToVoices(groups):
    voices = []
    voiceEndTicks = []
    for group in groups:
        voiceIndex = None
        for index, endTick in enumerate(voiceEndTicks):
            if endTick <= group.startTick:
                voiceIndex = index
                break
        if voiceIndex is None:
            voiceIndex = len(voices)
            voices.append([])
            voiceEndTicks.append(0)
        voices[voiceIndex].append(group)
        voiceEndTicks[voiceIndex] = group.endTick
    return voices


def createMusicalObject(group, durationTicks, tieType):
    musicNotes = []
    for midiNumber, velocity in zip(
        group.midiNumbers,
        group.velocities,
    ):
        musicNote = note.Note()
        musicNote.pitch.midi = midiNumber
        musicNote.duration.quarterLength = ticksToQuarterLength(durationTicks)
        musicNote.volume.velocity = velocity
        if tieType is not None:
            musicNote.tie = tie.Tie(tieType)
        musicNotes.append(musicNote)

    if len(musicNotes) == 1:
        return musicNotes[0]
    musicChord = chord.Chord(musicNotes)
    musicChord.duration.quarterLength = ticksToQuarterLength(durationTicks)
    musicChord.volume.velocity = group.velocities[0]
    return musicChord


def addRestToVoice(voice, offsetTicks, durationTicks):
    if durationTicks <= 0:
        return
    musicRest = note.Rest()
    musicRest.duration.quarterLength = ticksToQuarterLength(durationTicks)
    voice.insert(
        ticksToQuarterLength(offsetTicks),
        musicRest,
    )


def addVoiceToStaff(
    pianoStaff,
    voiceGroups,
    voiceNumber,
    measureTicks,
    performanceEndTick,
):
    segmentsByMeasure = {}
    for group in voiceGroups:
        segmentStart = group.startTick
        while segmentStart < group.endTick:
            measureIndex = segmentStart // measureTicks
            measureEnd = (measureIndex + 1) * measureTicks
            segmentEnd = min(group.endTick, measureEnd)
            hasPrevious = segmentStart > group.startTick
            hasNext = segmentEnd < group.endTick
            tieType = None
            if hasPrevious and hasNext:
                tieType = "continue"
            elif hasNext:
                tieType = "start"
            elif hasPrevious:
                tieType = "stop"
            segmentsByMeasure.setdefault(measureIndex, []).append(
                (
                    segmentStart % measureTicks,
                    segmentEnd - segmentStart,
                    group,
                    tieType,
                )
            )
            segmentStart = segmentEnd

    for measureIndex in range(len(pianoStaff.getElementsByClass(stream.Measure))):
        measure = pianoStaff.measure(measureIndex + 1)
        measureStartTick = measureIndex * measureTicks
        measureDurationTicks = min(
            measureTicks,
            max(0, performanceEndTick - measureStartTick),
        )
        if measureDurationTicks <= 0:
            continue
        musicVoice = stream.Voice(id=str(voiceNumber))
        currentTick = 0
        for offsetTick, durationTicks, group, tieType in sorted(
            segmentsByMeasure.get(measureIndex, []),
            key=lambda segment: segment[0],
        ):
            addRestToVoice(
                musicVoice,
                currentTick,
                offsetTick - currentTick,
            )
            musicalObject = createMusicalObject(
                group,
                durationTicks,
                tieType,
            )
            musicVoice.insert(
                ticksToQuarterLength(offsetTick),
                musicalObject,
            )
            currentTick = max(
                currentTick,
                offsetTick + durationTicks,
            )
        addRestToVoice(
            musicVoice,
            currentTick,
            measureDurationTicks - currentTick,
        )
        measure.insert(0, musicVoice)


def addEmptyStaffRests(
    pianoStaff,
    measureTicks,
    performanceEndTick,
):
    for measureIndex in range(len(pianoStaff.getElementsByClass(stream.Measure))):
        measureStartTick = measureIndex * measureTicks
        durationTicks = min(
            measureTicks,
            max(0, performanceEndTick - measureStartTick),
        )
        if durationTicks <= 0:
            continue
        musicRest = note.Rest()
        musicRest.duration.quarterLength = ticksToQuarterLength(durationTicks)
        pianoStaff.measure(measureIndex + 1).insert(0, musicRest)

    finalMeasureDuration = performanceEndTick % measureTicks
    if finalMeasureDuration > 0:
        finalMeasure = pianoStaff.measure(
            len(pianoStaff.getElementsByClass(stream.Measure))
        )
        finalMeasure.paddingRight = ticksToQuarterLength(
            measureTicks - finalMeasureDuration
        )
        finalMeasure.showNumber = stream.enums.ShowNumber.NEVER


def addPerformanceMusic(
    pianoStaff,
    composition,
    minimumMidi=None,
    maximumMidi=None,
):
    performanceNotes = []
    for performanceNote in composition.performanceNotes:
        if minimumMidi is not None and performanceNote.midiNumber < minimumMidi:
            continue
        if maximumMidi is not None and performanceNote.midiNumber > maximumMidi:
            continue
        performanceNotes.append(performanceNote)

    measureTicks = round(
        composition.beatsPerMeasure
        * (4 / composition.beatUnit)
        * TICKS_PER_QUARTER
    )
    exactPerformanceEndTick = microsecondsToTicks(
        composition.performanceDurationUs,
        composition.tempo,
    )
    performanceEndTick = max(
        NOTATION_TICK_STEP,
        roundNotationTick(exactPerformanceEndTick),
    )

    if not performanceNotes:
        addEmptyStaffRests(
            pianoStaff,
            measureTicks,
            performanceEndTick,
        )
        return

    groups = simplifySequentialTiming(
        createPerformanceGroups(
            performanceNotes,
            composition.tempo,
        )
    )
    voices = assignGroupsToVoices(groups)
    for voiceIndex, voiceGroups in enumerate(voices, start=1):
        closeSmallNotationGaps(voiceGroups)
        addVoiceToStaff(
            pianoStaff,
            voiceGroups,
            voiceIndex,
            measureTicks,
            performanceEndTick,
        )

    finalMeasureDuration = performanceEndTick % measureTicks
    if finalMeasureDuration > 0:
        finalMeasure = pianoStaff.measure(composition.measureCount)
        finalMeasure.paddingRight = ticksToQuarterLength(
            measureTicks - finalMeasureDuration
        )
        finalMeasure.showNumber = stream.enums.ShowNumber.NEVER
