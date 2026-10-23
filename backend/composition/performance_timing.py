import math


MINIMUM_TEMPO = 40
MAXIMUM_TEMPO = 200
FALLBACK_TEMPO = 80
MAXIMUM_MEASURES = 128

COMMON_QUARTER_LENGTHS = [
    (0.25, 1.0),
    (1 / 3, 0.7),
    (0.5, 0.15),
    (2 / 3, 0.45),
    (0.75, 0.25),
    (1.0, 0.0),
    (1.5, 0.1),
    (2.0, 0.0),
    (3.0, 0.1),
    (4.0, 0.0),
]


def calculatePerformanceEndUs(performanceNotes):
    if not performanceNotes:
        return 0
    return max(
        performanceNote.startTimeUs
        + performanceNote.durationUs
        for performanceNote in performanceNotes
    )


def calculateMeasureCount(
    durationUs,
    tempo,
    beatsPerMeasure,
    beatUnit,
):
    if durationUs <= 0:
        return 1
    quarterNotes = durationUs * tempo / 60_000_000
    quarterNotesPerMeasure = beatsPerMeasure * (4 / beatUnit)
    measurePosition = quarterNotes / quarterNotesPerMeasure
    return max(
        1,
        math.ceil(measurePosition - 0.000000001),
    )


def nearestRhythmicValue(quarterLength):
    return min(
        COMMON_QUARTER_LENGTHS,
        key=lambda candidate: abs(
            quarterLength - candidate[0]
        ),
    )


def tempoThatFitsDuration(
    preferredTempo,
    durationUs,
    beatsPerMeasure,
    beatUnit,
):
    tempo = preferredTempo
    while (
        tempo > MINIMUM_TEMPO
        and calculateMeasureCount(
            durationUs,
            tempo,
            beatsPerMeasure,
            beatUnit,
        ) > MAXIMUM_MEASURES
    ):
        tempo -= 1
    return tempo


def detectNotationTempo(
    performanceNotes,
    durationUs,
    beatsPerMeasure,
    beatUnit,
):
    onsetTimes = sorted({
        performanceNote.startTimeUs
        for performanceNote in performanceNotes
    })
    if len(onsetTimes) < 4:
        return tempoThatFitsDuration(
            FALLBACK_TEMPO,
            durationUs,
            beatsPerMeasure,
            beatUnit,
        )

    onsetIntervals = [
        onsetTimes[index] - onsetTimes[index - 1]
        for index in range(1, len(onsetTimes))
        if onsetTimes[index] - onsetTimes[index - 1] >= 30_000
    ]
    if len(onsetIntervals) < 3:
        return tempoThatFitsDuration(
            FALLBACK_TEMPO,
            durationUs,
            beatsPerMeasure,
            beatUnit,
        )

    noteDurations = [
        performanceNote.durationUs
        for performanceNote in performanceNotes
        if performanceNote.durationUs >= 30_000
    ]
    candidates = []

    for tempo in range(MINIMUM_TEMPO, MAXIMUM_TEMPO + 1):
        if calculateMeasureCount(
            durationUs,
            tempo,
            beatsPerMeasure,
            beatUnit,
        ) > MAXIMUM_MEASURES:
            continue

        onsetError = 0.0
        readability = 0.0
        for intervalUs in onsetIntervals:
            quarterLength = intervalUs * tempo / 60_000_000
            rhythmicValue, complexity = nearestRhythmicValue(
                quarterLength
            )
            onsetError += abs(quarterLength - rhythmicValue)
            readability += complexity

        onsetError /= len(onsetIntervals)
        readability /= len(onsetIntervals)

        durationError = 0.0
        if noteDurations:
            for duration in noteDurations:
                quarterLength = duration * tempo / 60_000_000
                rhythmicValue, _ = nearestRhythmicValue(
                    quarterLength
                )
                durationError += abs(
                    quarterLength - rhythmicValue
                )
            durationError /= len(noteDurations)

        candidates.append({
            "tempo": tempo,
            "fit": onsetError + durationError * 0.15,
            "readability": (
                readability
                + abs(tempo - FALLBACK_TEMPO) * 0.003
            ),
        })

    if not candidates:
        return FALLBACK_TEMPO

    bestFit = min(candidate["fit"] for candidate in candidates)
    readableCandidates = [
        candidate
        for candidate in candidates
        if candidate["fit"] <= bestFit + 0.03
    ]
    readableCandidates.sort(
        key=lambda candidate: (
            candidate["readability"],
            candidate["fit"],
            abs(candidate["tempo"] - FALLBACK_TEMPO),
        )
    )
    return readableCandidates[0]["tempo"]


def normalizeRecordedCompositionTiming(composition):
    performanceEndUs = calculatePerformanceEndUs(
        composition.performanceNotes
    )
    if performanceEndUs <= 0:
        raise ValueError(
            "The recorded performance does not contain playable notes."
        )

    composition.performanceDurationUs = performanceEndUs
    composition.tempo = detectNotationTempo(
        composition.performanceNotes,
        performanceEndUs,
        composition.beatsPerMeasure,
        composition.beatUnit,
    )
    composition.measureCount = calculateMeasureCount(
        performanceEndUs,
        composition.tempo,
        composition.beatsPerMeasure,
        composition.beatUnit,
    )
    return composition
