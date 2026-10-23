import 'dart:math' as math;

import 'package:soundsight/screens/composition/models/recorded_midi_event.dart';
import 'package:soundsight/screens/composition/models/recorded_performance_note.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';

class RecordedPerformanceResult {
  const RecordedPerformanceResult({
    required this.notes,
    required this.durationUs,
    required this.detectedTempo,
    required this.measureCount,
  });

  final List<RecordedPerformanceNote> notes;
  final int durationUs;
  final int detectedTempo;
  final int measureCount;
}

class RecordedPerformanceProcessor {
  const RecordedPerformanceProcessor({
    required this.beatsPerMeasure,
    required this.beatUnit,
  });

  static const int minimumTempo = 40;
  static const int maximumTempo = 200;
  static const int fallbackTempo = 80;
  static const int maximumMeasures = 128;
  static const int maximumNotes = 256;
  static const Duration maximumAudioDuration = Duration(minutes: 10);
  static const List<double> commonQuarterLengths = <double>[
    0.25,
    1 / 3,
    0.5,
    2 / 3,
    0.75,
    1,
    1.5,
    2,
    3,
    4,
  ];
  static const List<double> rhythmicComplexities = <double>[
    1,
    0.7,
    0.15,
    0.45,
    0.25,
    0,
    0.1,
    0,
    0.1,
    0,
  ];

  final int beatsPerMeasure;
  final int beatUnit;

  Duration get maximumRecordingDuration {
    final quarterNotesPerMeasure = beatsPerMeasure * (4 / beatUnit);
    final secondsAtSlowestTempo =
        maximumMeasures * quarterNotesPerMeasure * 60 / minimumTempo;
    return Duration(
      microseconds: math
          .min(
            maximumAudioDuration.inMicroseconds,
            (secondsAtSlowestTempo * Duration.microsecondsPerSecond).round(),
          )
          .toInt(),
    );
  }

  RecordedPerformanceResult process(List<RecordedMidiEvent> events) {
    final pairedNotes = _pairCompletedNotes(events);
    if (pairedNotes.isEmpty) {
      return const RecordedPerformanceResult(
        notes: [],
        durationUs: 0,
        detectedTempo: fallbackTempo,
        measureCount: 1,
      );
    }

    final firstStartUs = pairedNotes
        .map((note) => note.startTimeUs)
        .reduce((first, second) => first < second ? first : second);
    final finalEndUs = pairedNotes
        .map((note) => note.endTimeUs)
        .reduce((first, second) => first > second ? first : second);
    final trimmedNotes =
        pairedNotes
            .map(
              (note) => RecordedPerformanceNote(
                midiNumber: note.midiNumber,
                velocity: note.velocity,
                startTimeUs: note.startTimeUs - firstStartUs,
                durationUs: note.durationUs,
              ),
            )
            .toList()
          ..sort((first, second) {
            final startComparison = first.startTimeUs.compareTo(
              second.startTimeUs,
            );
            if (startComparison != 0) return startComparison;
            return first.midiNumber.compareTo(second.midiNumber);
          });
    final durationUs = finalEndUs - firstStartUs;
    final tempo = detectTempo(trimmedNotes, durationUs);

    return RecordedPerformanceResult(
      notes: trimmedNotes,
      durationUs: durationUs,
      detectedTempo: tempo,
      measureCount: calculateMeasureCount(durationUs, tempo),
    );
  }

  int detectTempo(List<RecordedPerformanceNote> notes, int durationUs) {
    final onsetTimes = notes.map((note) => note.startTimeUs).toSet().toList()
      ..sort();
    if (onsetTimes.length < 4) {
      return _tempoThatFitsDuration(fallbackTempo, durationUs);
    }

    final intervals = <int>[];
    for (var index = 1; index < onsetTimes.length; index++) {
      final interval = onsetTimes[index] - onsetTimes[index - 1];
      if (interval >= 30000) intervals.add(interval);
    }
    if (intervals.length < 3) {
      return _tempoThatFitsDuration(fallbackTempo, durationUs);
    }
    final noteDurations = notes
        .map((note) => note.durationUs)
        .where((duration) => duration >= 30000)
        .toList();
    final candidates = <_TempoCandidate>[];

    for (var tempo = minimumTempo; tempo <= maximumTempo; tempo++) {
      if (calculateMeasureCount(durationUs, tempo) > maximumMeasures) continue;
      var onsetError = 0.0;
      var readability = 0.0;
      for (final intervalUs in intervals) {
        final quarterLength =
            intervalUs * tempo / Duration.microsecondsPerMinute;
        final rhythmicValueIndex = _nearestRhythmicValueIndex(quarterLength);
        onsetError +=
            (quarterLength - commonQuarterLengths[rhythmicValueIndex]).abs();
        readability += rhythmicComplexities[rhythmicValueIndex];
      }
      onsetError /= intervals.length;
      readability /= intervals.length;

      var durationError = 0.0;
      if (noteDurations.isNotEmpty) {
        for (final duration in noteDurations) {
          final quarterLength =
              duration * tempo / Duration.microsecondsPerMinute;
          final rhythmicValueIndex = _nearestRhythmicValueIndex(quarterLength);
          durationError +=
              (quarterLength - commonQuarterLengths[rhythmicValueIndex]).abs();
        }
        durationError /= noteDurations.length;
      }

      candidates.add(
        _TempoCandidate(
          tempo: tempo,
          fit: onsetError + durationError * 0.15,
          readability:
              readability + (tempo - fallbackTempo).abs() * 0.003,
        ),
      );
    }

    if (candidates.isEmpty) return fallbackTempo;

    final bestFit = candidates
        .map((candidate) => candidate.fit)
        .reduce(math.min);
    final readableCandidates = candidates
        .where((candidate) => candidate.fit <= bestFit + 0.03)
        .toList()
      ..sort((first, second) {
        final readabilityComparison = first.readability.compareTo(
          second.readability,
        );
        if (readabilityComparison != 0) return readabilityComparison;
        final fitComparison = first.fit.compareTo(second.fit);
        if (fitComparison != 0) return fitComparison;
        return (first.tempo - fallbackTempo).abs().compareTo(
          (second.tempo - fallbackTempo).abs(),
        );
      });
    return readableCandidates.first.tempo;
  }

  int _nearestRhythmicValueIndex(double quarterLength) {
    var bestIndex = 0;
    var smallestDifference = double.infinity;
    for (var index = 0; index < commonQuarterLengths.length; index++) {
      final difference =
          (quarterLength - commonQuarterLengths[index]).abs();
      if (difference < smallestDifference) {
        smallestDifference = difference;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  int calculateMeasureCount(int durationUs, int tempo) {
    if (durationUs <= 0) return 1;
    final quarterNotes = durationUs * tempo / Duration.microsecondsPerMinute;
    final quarterNotesPerMeasure = beatsPerMeasure * (4 / beatUnit);
    final measurePosition = quarterNotes / quarterNotesPerMeasure;
    return math.max(1, (measurePosition - 0.000000001).ceil()).toInt();
  }

  int _tempoThatFitsDuration(int preferredTempo, int durationUs) {
    var tempo = preferredTempo;
    while (tempo > minimumTempo &&
        calculateMeasureCount(durationUs, tempo) > maximumMeasures) {
      tempo--;
    }
    return tempo;
  }

  List<RecordedPerformanceNote> _pairCompletedNotes(
    List<RecordedMidiEvent> events,
  ) {
    final notes = <RecordedPerformanceNote>[];
    final activeNoteOns = <int, List<RecordedMidiEvent>>{};

    for (final event in events) {
      if (event.type == MidiNoteEventType.noteOn) {
        activeNoteOns.putIfAbsent(event.noteNumber, () => []).add(event);
        continue;
      }

      final matchingNoteOns = activeNoteOns[event.noteNumber];
      if (matchingNoteOns == null || matchingNoteOns.isEmpty) continue;
      final noteOn = matchingNoteOns.removeAt(0);
      if (matchingNoteOns.isEmpty) activeNoteOns.remove(event.noteNumber);
      if (event.timestamp <= noteOn.timestamp) continue;
      notes.add(_createNote(noteOn, event.timestamp));
    }

    return notes;
  }

  RecordedPerformanceNote _createNote(
    RecordedMidiEvent noteOn,
    Duration endTime,
  ) {
    return RecordedPerformanceNote(
      midiNumber: noteOn.noteNumber,
      velocity: noteOn.velocity.clamp(1, 127).toInt(),
      startTimeUs: noteOn.timestamp.inMicroseconds,
      durationUs: endTime.inMicroseconds - noteOn.timestamp.inMicroseconds,
    );
  }
}

class _TempoCandidate {
  const _TempoCandidate({
    required this.tempo,
    required this.fit,
    required this.readability,
  });

  final int tempo;
  final double fit;
  final double readability;
}
