import math
import os
import struct
from dataclasses import dataclass


TICKS_PER_QUARTER = 960
PIANO_CHANNELS = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    10,
    11,
    12,
    13,
    14,
    15,
]


@dataclass(frozen=True)
class PerformanceMidiExport:
    midiPath: str
    durationSeconds: float


def microsecondsToMidiTicks(microseconds, tempo):
    return max(
        0,
        round(
            microseconds
            * tempo
            * TICKS_PER_QUARTER
            / 60_000_000
        ),
    )


def compositionBeatsToMidiTicks(compositionBeats, beatUnit):
    return max(
        0,
        round(
            compositionBeats
            * (4 / beatUnit)
            * TICKS_PER_QUARTER
        ),
    )


def encodeVariableLength(value):
    if value < 0:
        raise ValueError("A MIDI delta time cannot be negative.")

    encodedBytes = [value & 0x7F]
    value >>= 7
    while value > 0:
        encodedBytes.insert(0, (value & 0x7F) | 0x80)
        value >>= 7
    return bytes(encodedBytes)


def denominatorPower(beatUnit):
    if beatUnit <= 0 or beatUnit & (beatUnit - 1) != 0:
        raise ValueError("The time-signature beat unit must be a power of two.")
    return int(math.log2(beatUnit))


def assignChannels(performanceNotes, tempo):
    channelEndTicksByPitch = {}
    assignedNotes = []

    for performanceNote in sorted(
        performanceNotes,
        key=lambda item: (
            item.startTimeUs,
            item.midiNumber,
            item.durationUs,
        ),
    ):
        startTick = microsecondsToMidiTicks(
            performanceNote.startTimeUs,
            tempo,
        )
        endTick = max(
            startTick + 1,
            microsecondsToMidiTicks(
                performanceNote.startTimeUs + performanceNote.durationUs,
                tempo,
            ),
        )
        pitchChannelEnds = channelEndTicksByPitch.setdefault(
            performanceNote.midiNumber,
            {},
        )
        channel = next(
            (
                candidate
                for candidate in PIANO_CHANNELS
                if pitchChannelEnds.get(candidate, 0) <= startTick
            ),
            None,
        )
        if channel is None:
            raise ValueError(
                "Too many overlapping recordings of the same piano key."
            )
        pitchChannelEnds[channel] = endTick
        assignedNotes.append(
            (
                performanceNote,
                channel,
                startTick,
                endTick,
            )
        )

    return assignedNotes


def createManualMidiNotes(composition):
    sourceNotes = []
    notesByPitchAndStart = {}

    for compositionNote in sorted(
        composition.notes,
        key=lambda item: (
            item.measureIndex,
            item.startBeat,
            item.midiNumber,
        ),
    ):
        absoluteStartBeat = (
            compositionNote.measureIndex
            * composition.beatsPerMeasure
            + compositionNote.startBeat
        )
        absoluteEndBeat = (
            absoluteStartBeat
            + compositionNote.durationBeats
        )
        startTick = compositionBeatsToMidiTicks(
            absoluteStartBeat,
            composition.beatUnit,
        )
        endTick = max(
            startTick + 1,
            compositionBeatsToMidiTicks(
                absoluteEndBeat,
                composition.beatUnit,
            ),
        )
        noteIndex = len(sourceNotes)
        sourceNote = {
            "midiNumber": compositionNote.midiNumber,
            "velocity": max(
                1,
                min(127, round(compositionNote.velocity * 127)),
            ),
            "startTick": startTick,
            "endTick": endTick,
            "tieToNext": compositionNote.tieToNext,
        }
        sourceNotes.append(sourceNote)
        notesByPitchAndStart[
            (compositionNote.midiNumber, startTick)
        ] = noteIndex

    continuationIndexes = set()
    midiNotes = []

    for noteIndex, sourceNote in enumerate(sourceNotes):
        if noteIndex in continuationIndexes:
            continue

        finalEndTick = sourceNote["endTick"]
        currentNote = sourceNote

        while currentNote["tieToNext"]:
            continuationIndex = notesByPitchAndStart.get(
                (
                    currentNote["midiNumber"],
                    currentNote["endTick"],
                )
            )
            if continuationIndex is None:
                raise ValueError(
                    "A tied manual note does not have a continuation."
                )
            if continuationIndex in continuationIndexes:
                raise ValueError(
                    "A manual note continuation is used more than once."
                )

            continuationIndexes.add(continuationIndex)
            currentNote = sourceNotes[continuationIndex]
            finalEndTick = currentNote["endTick"]

        midiNotes.append(
            {
                "midiNumber": sourceNote["midiNumber"],
                "velocity": sourceNote["velocity"],
                "startTick": sourceNote["startTick"],
                "endTick": finalEndTick,
            }
        )

    return midiNotes


def saveManualMidi(composition, outputFolder):
    if len(composition.notes) == 0:
        raise ValueError(
            "The manual composition does not contain playable notes."
        )

    os.makedirs(outputFolder, exist_ok=True)
    midiPath = os.path.join(outputFolder, composition.id + ".mid")
    manualNotes = createManualMidiNotes(composition)
    tempoMicroseconds = round(60_000_000 / composition.tempo)
    events = [
        (
            0,
            0,
            b"\xFF\x51\x03" + tempoMicroseconds.to_bytes(3, "big"),
        ),
        (
            0,
            1,
            bytes(
                [
                    0xFF,
                    0x58,
                    0x04,
                    composition.beatsPerMeasure,
                    denominatorPower(composition.beatUnit),
                    24,
                    8,
                ]
            ),
        ),
        (0, 2, bytes([0xC0, 0])),
    ]

    for manualNote in manualNotes:
        events.append(
            (
                manualNote["startTick"],
                4,
                bytes(
                    [
                        0x90,
                        manualNote["midiNumber"],
                        manualNote["velocity"],
                    ]
                ),
            )
        )
        events.append(
            (
                manualNote["endTick"],
                3,
                bytes(
                    [
                        0x80,
                        manualNote["midiNumber"],
                        0,
                    ]
                ),
            )
        )

    scoreEndTick = compositionBeatsToMidiTicks(
        composition.measureCount * composition.beatsPerMeasure,
        composition.beatUnit,
    )
    finalEventTick = max(
        scoreEndTick,
        max(note["endTick"] for note in manualNotes),
    )
    events.append((finalEventTick, 5, b"\xFF\x2F\x00"))
    events.sort(key=lambda event: (event[0], event[1]))

    trackBytes = bytearray()
    previousTick = 0
    for absoluteTick, _, eventBytes in events:
        trackBytes.extend(
            encodeVariableLength(absoluteTick - previousTick)
        )
        trackBytes.extend(eventBytes)
        previousTick = absoluteTick

    header = b"MThd" + struct.pack(
        ">IHHH",
        6,
        0,
        1,
        TICKS_PER_QUARTER,
    )
    track = b"MTrk" + struct.pack(">I", len(trackBytes)) + trackBytes

    with open(midiPath, "wb") as midiFile:
        midiFile.write(header)
        midiFile.write(track)

    if os.path.getsize(midiPath) == 0:
        raise RuntimeError("The manual MIDI file is empty.")

    return PerformanceMidiExport(
        midiPath=midiPath,
        durationSeconds=(
            finalEventTick
            * tempoMicroseconds
            / TICKS_PER_QUARTER
            / 1_000_000
        ),
    )


def savePerformanceMidi(composition, outputFolder):
    if len(composition.performanceNotes) == 0:
        raise ValueError(
            "The recorded performance does not contain playable notes."
        )

    os.makedirs(outputFolder, exist_ok=True)
    midiPath = os.path.join(outputFolder, composition.id + ".mid")
    assignedNotes = assignChannels(
        composition.performanceNotes,
        composition.tempo,
    )
    usedChannels = sorted({item[1] for item in assignedNotes})
    tempoMicroseconds = round(60_000_000 / composition.tempo)
    events = [
        (
            0,
            0,
            b"\xFF\x51\x03" + tempoMicroseconds.to_bytes(3, "big"),
        ),
        (
            0,
            1,
            bytes(
                [
                    0xFF,
                    0x58,
                    0x04,
                    composition.beatsPerMeasure,
                    denominatorPower(composition.beatUnit),
                    24,
                    8,
                ]
            ),
        ),
    ]

    for channel in usedChannels:
        events.append((0, 2, bytes([0xC0 | channel, 0])))

    for performanceNote, channel, startTick, endTick in assignedNotes:
        events.append(
            (
                startTick,
                4,
                bytes(
                    [
                        0x90 | channel,
                        performanceNote.midiNumber,
                        performanceNote.velocity,
                    ]
                ),
            )
        )
        events.append(
            (
                endTick,
                3,
                bytes(
                    [
                        0x80 | channel,
                        performanceNote.midiNumber,
                        0,
                    ]
                ),
            )
        )

    performanceEndTick = microsecondsToMidiTicks(
        composition.performanceDurationUs,
        composition.tempo,
    )
    finalEventTick = max(
        performanceEndTick,
        max(item[3] for item in assignedNotes),
    )
    events.append((finalEventTick, 5, b"\xFF\x2F\x00"))
    events.sort(key=lambda event: (event[0], event[1]))

    trackBytes = bytearray()
    previousTick = 0
    for absoluteTick, _, eventBytes in events:
        trackBytes.extend(
            encodeVariableLength(absoluteTick - previousTick)
        )
        trackBytes.extend(eventBytes)
        previousTick = absoluteTick

    header = b"MThd" + struct.pack(
        ">IHHH",
        6,
        0,
        1,
        TICKS_PER_QUARTER,
    )
    track = b"MTrk" + struct.pack(">I", len(trackBytes)) + trackBytes

    with open(midiPath, "wb") as midiFile:
        midiFile.write(header)
        midiFile.write(track)

    if os.path.getsize(midiPath) == 0:
        raise RuntimeError("The recorded MIDI file is empty.")

    return PerformanceMidiExport(
        midiPath=midiPath,
        durationSeconds=(
            finalEventTick
            * tempoMicroseconds
            / TICKS_PER_QUARTER
            / 1_000_000
        ),
    )
