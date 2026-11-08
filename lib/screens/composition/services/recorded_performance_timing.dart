import 'dart:math' as math;

import 'package:soundsight/screens/composition/models/recorded_performance_note.dart';

class RecordedPerformanceTiming {
  static const chordOnsetWindowUs = 20000;

  static List<RecordedPerformanceNote> alignChordStarts(
    List<RecordedPerformanceNote> notes,
  ) {
    final orderedNotes = List<RecordedPerformanceNote>.of(notes)
      ..sort(_compareNotes);
    final alignedNotes = <RecordedPerformanceNote>[];
    final groupPitches = <int>{};
    final previousEndByPitch = <int, int>{};
    int? groupStartUs;

    for (final note in orderedNotes) {
      final previousEndUs = previousEndByPitch[note.midiNumber];
      if (groupStartUs == null ||
          note.startTimeUs - groupStartUs > chordOnsetWindowUs ||
          groupPitches.contains(note.midiNumber) ||
          (previousEndUs != null && previousEndUs > groupStartUs)) {
        groupStartUs = note.startTimeUs;
        groupPitches.clear();
      }

      // Anchor the window to its first note, keeping each original release time.
      alignedNotes.add(
        RecordedPerformanceNote(
          midiNumber: note.midiNumber,
          velocity: note.velocity,
          startTimeUs: groupStartUs,
          durationUs: note.endTimeUs - groupStartUs,
        ),
      );
      groupPitches.add(note.midiNumber);
      previousEndByPitch[note.midiNumber] = math.max(
        previousEndUs ?? 0,
        note.endTimeUs,
      );
    }

    return alignedNotes..sort(_compareNotes);
  }

  static int _compareNotes(
    RecordedPerformanceNote first,
    RecordedPerformanceNote second,
  ) {
    final startComparison = first.startTimeUs.compareTo(second.startTimeUs);
    if (startComparison != 0) return startComparison;
    return first.midiNumber.compareTo(second.midiNumber);
  }
}
