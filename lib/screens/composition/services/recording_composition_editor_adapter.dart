import 'dart:math' as math;

import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/composition_limits.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/models/piano_note.dart';
import 'package:soundsight/screens/composition/models/quantized_note.dart';
import 'package:soundsight/screens/composition/services/composition_midi_processor.dart';

enum RecordingEditFailure { invalidRecording, noteLimit, measureLimit }

class RecordingEditException implements Exception {
  const RecordingEditException(this.failure);
  final RecordingEditFailure failure;
}

class RecordingCompositionEditorAdapter {
  const RecordingCompositionEditorAdapter();

  /// Produces an in-memory draft. Nothing is persisted until the user saves.
  Composition prepare(Composition source) {
    if (source.contentMode != null &&
        source.contentMode != Composition.scoreContentMode &&
        source.contentMode != Composition.performanceContentMode) {
      throw const RecordingEditException(RecordingEditFailure.invalidRecording);
    }
    if (!source.usesPerformanceRecording) {
      if (source.creationMethod == Composition.recordingCreationMethod &&
          source.contentMode == null && source.notes.isEmpty) {
        throw const RecordingEditException(RecordingEditFailure.invalidRecording);
      }
      return source.copyWith(contentMode: Composition.scoreContentMode);
    }
    if (source.performanceNotes.isEmpty || source.tempo < 40 ||
        source.tempo > 200 || source.beatsPerMeasure < 1 ||
        (source.beatUnit != 4 && source.beatUnit != 8) ||
        source.performanceDurationUs == null || source.performanceDurationUs! <= 0 ||
        source.performanceDurationUs! > const Duration(minutes: 10).inMicroseconds ||
        source.measureCount < 1) {
      throw const RecordingEditException(RecordingEditFailure.invalidRecording);
    }
    if (source.performanceNotes.length > CompositionLimits.maximumNotes) {
      throw const RecordingEditException(RecordingEditFailure.noteLimit);
    }
    final processor = CompositionMidiProcessor(
      tempo: source.tempo,
      beatUnit: source.beatUnit,
      beatsPerMeasure: source.beatsPerMeasure,
    );
    // The manual editor supports 1/12 of a notated beat, including eighth-note
    // time signatures. Do not use the MIDI recorder's coarser sixteenth grid.
    final gridTicks = processor.compositionBeatsToTicks(CompositionNote.timingStep);
    final microsecondsPerBeat =
        Duration.microsecondsPerMinute / source.tempo * (4 / source.beatUnit);
    int snap(int microseconds) =>
        (microseconds / microsecondsPerBeat / CompositionNote.timingStep).round() * gridTicks;

    final quantized = <QuantizedNote>[];
    for (final note in source.performanceNotes) {
      if (!PianoNote.isValidMidi(note.midiNumber) || note.velocity < 1 ||
          note.velocity > 127 || note.startTimeUs < 0 || note.durationUs <= 0 ||
          note.endTimeUs > source.performanceDurationUs!) {
        throw const RecordingEditException(RecordingEditFailure.invalidRecording);
      }
      final startTick = snap(note.startTimeUs);
      final endTick = math.max(startTick + gridTicks, snap(note.endTimeUs));
      quantized.add(QuantizedNote(
        noteNumber: note.midiNumber,
        velocity: note.velocity,
        startTick: startTick,
        durationTicks: endTick - startTick,
      ));
    }
    quantized.sort((first, second) {
      final start = first.startTick.compareTo(second.startTick);
      return start != 0 ? start : first.noteNumber.compareTo(second.noteNumber);
    });
    final resolved = processor.resolveRepeatedNoteOverlaps(quantized);
    final notes = <CompositionNote>[];
    final unitsPerMeasure = source.beatsPerMeasure * 12;
    var requiredMeasures = 1;
    for (var index = 0; index < resolved.length; index++) {
      final note = resolved[index];
      final pianoNote = PianoNote.fromMidi(note.noteNumber);
      var cursor = note.startTick ~/ gridTicks;
      var remaining = note.durationTicks ~/ gridTicks;
      var segment = 0;
      while (remaining > 0) {
        final measureIndex = cursor ~/ unitsPerMeasure;
        if (measureIndex >= CompositionLimits.maximumMeasures) {
          throw const RecordingEditException(RecordingEditFailure.measureLimit);
        }
        if (notes.length >= CompositionLimits.maximumNotes) {
          throw const RecordingEditException(RecordingEditFailure.noteLimit);
        }
        final start = cursor % unitsPerMeasure;
        final length = math.min(remaining, unitsPerMeasure - start);
        notes.add(CompositionNote(
          id: 'recording-edit-$index-$segment',
          pitch: pianoNote.pitch,
          octave: pianoNote.octave,
          midiNumber: note.noteNumber,
          measureIndex: measureIndex,
          startBeat: start / 12,
          durationBeats: length / 12,
          velocity: note.velocity / 127,
          tieToNext: remaining > length,
        ));
        requiredMeasures = math.max(requiredMeasures, measureIndex + 1);
        cursor += length;
        remaining -= length;
        segment++;
      }
    }
    final measures = math.max(source.measureCount, requiredMeasures);
    if (measures > CompositionLimits.maximumMeasures) {
      throw const RecordingEditException(RecordingEditFailure.measureLimit);
    }
    return source.copyWith(
      notes: notes,
      measureCount: measures,
      contentMode: Composition.scoreContentMode,
      originalRecordingSettings: source.originalRecordingSettings ??
          Map<String, dynamic>.unmodifiable({
            'tempo': source.tempo,
            'key': source.keySignature,
            'beatsPerMeasure': source.beatsPerMeasure,
            'beatUnit': source.beatUnit,
            'measureCount': source.measureCount,
          }),
    );
  }
}
