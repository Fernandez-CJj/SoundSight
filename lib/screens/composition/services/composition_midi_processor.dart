import 'dart:math' as math;

import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/models/piano_note.dart';
import 'package:soundsight/screens/composition/models/quantized_note.dart';
import 'package:soundsight/screens/composition/models/recorded_midi_event.dart';
import 'package:soundsight/screens/composition/models/recorded_note.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';

class CompositionMidiProcessingResult {
  const CompositionMidiProcessingResult({
    required this.recordedNotes,
    required this.quantizedNotes,
    required this.compositionNotes,
    required this.capturedDurationBeats,
  });

  final List<RecordedNote> recordedNotes;
  final List<QuantizedNote> quantizedNotes;
  final List<CompositionNote> compositionNotes;
  final double capturedDurationBeats;
}

class CompositionMidiProcessor {
  const CompositionMidiProcessor({
    required this.tempo,
    required this.beatUnit,
    required this.beatsPerMeasure,
  });

  static const int ticksPerQuarterNote = 480;
  static const int quantizationGridTicks = ticksPerQuarterNote ~/ 4;

  final int tempo;
  final int beatUnit;
  final int beatsPerMeasure;

  CompositionMidiProcessingResult process({
    required List<RecordedMidiEvent> events,
    required Duration captureEndTime,
    double startAbsoluteBeat = 0,
    double? maximumAbsoluteBeat,
    String idPrefix = 'captured',
  }) {
    final recordedNotes = pairEvents(
      events,
      captureEndTime: captureEndTime,
    );
    final maximumDurationBeats = maximumAbsoluteBeat == null
        ? null
        : math.max(0, maximumAbsoluteBeat - startAbsoluteBeat).toDouble();
    final maximumDurationTicks = maximumDurationBeats == null
        ? null
        : (compositionBeatsToTicks(maximumDurationBeats) ~/
                  quantizationGridTicks) *
              quantizationGridTicks;
    final quantizedNotes = quantizeNotes(
      recordedNotes,
      maximumDurationTicks: maximumDurationTicks,
    );
    final compositionNotes = createCompositionNotes(
      quantizedNotes,
      startAbsoluteBeat: startAbsoluteBeat,
      maximumAbsoluteBeat: maximumAbsoluteBeat,
      idPrefix: idPrefix,
    );

    var capturedDurationTicks = quantizeTick(timeToTicks(captureEndTime));
    if (maximumDurationTicks != null) {
      capturedDurationTicks = math.min(
        capturedDurationTicks,
        maximumDurationTicks,
      );
    }
    for (final note in quantizedNotes) {
      capturedDurationTicks = math.max(capturedDurationTicks, note.endTick);
    }

    return CompositionMidiProcessingResult(
      recordedNotes: recordedNotes,
      quantizedNotes: quantizedNotes,
      compositionNotes: compositionNotes,
      capturedDurationBeats: ticksToCompositionBeats(capturedDurationTicks),
    );
  }

  List<RecordedNote> pairEvents(
    List<RecordedMidiEvent> events, {
    required Duration captureEndTime,
  }) {
    final notes = <RecordedNote>[];
    final activeNoteEvents = <int, RecordedMidiEvent>{};

    for (final event in events) {
      if (event.timestamp > captureEndTime) {
        break;
      }

      if (event.type == MidiNoteEventType.noteOn) {
        final previousNoteOn = activeNoteEvents[event.noteNumber];

        if (previousNoteOn != null &&
            event.timestamp > previousNoteOn.timestamp) {
          notes.add(
            RecordedNote(
              noteNumber: previousNoteOn.noteNumber,
              velocity: previousNoteOn.velocity,
              startTime: previousNoteOn.timestamp,
              endTime: event.timestamp,
            ),
          );
        }

        activeNoteEvents[event.noteNumber] = event;
        continue;
      }

      final matchingNoteOn = activeNoteEvents.remove(event.noteNumber);

      if (matchingNoteOn == null ||
          event.timestamp <= matchingNoteOn.timestamp) {
        continue;
      }

      notes.add(
        RecordedNote(
          noteNumber: matchingNoteOn.noteNumber,
          velocity: matchingNoteOn.velocity,
          startTime: matchingNoteOn.timestamp,
          endTime: event.timestamp,
        ),
      );
    }

    for (final remainingNoteOn in activeNoteEvents.values) {
      if (captureEndTime <= remainingNoteOn.timestamp) {
        continue;
      }

      notes.add(
        RecordedNote(
          noteNumber: remainingNoteOn.noteNumber,
          velocity: remainingNoteOn.velocity,
          startTime: remainingNoteOn.timestamp,
          endTime: captureEndTime,
        ),
      );
    }

    notes.sort((firstNote, secondNote) {
      return firstNote.startTime.compareTo(secondNote.startTime);
    });

    return notes;
  }

  List<QuantizedNote> quantizeNotes(
    List<RecordedNote> recordedNotes, {
    int? maximumDurationTicks,
  }) {
    final notes = <QuantizedNote>[];

    for (final note in recordedNotes) {
      final quantizedStartTick = quantizeTick(timeToTicks(note.startTime));
      var quantizedEndTick = quantizeTick(timeToTicks(note.endTime));

      if (maximumDurationTicks != null) {
        if (quantizedStartTick >= maximumDurationTicks) {
          continue;
        }
        quantizedEndTick = math.min(quantizedEndTick, maximumDurationTicks);
      }

      if (quantizedEndTick <= quantizedStartTick) {
        quantizedEndTick = quantizedStartTick + quantizationGridTicks;
      }
      if (maximumDurationTicks != null) {
        quantizedEndTick = math.min(quantizedEndTick, maximumDurationTicks);
      }
      if (quantizedEndTick <= quantizedStartTick) {
        continue;
      }

      notes.add(
        QuantizedNote(
          noteNumber: note.noteNumber,
          velocity: note.velocity,
          startTick: quantizedStartTick,
          durationTicks: quantizedEndTick - quantizedStartTick,
        ),
      );
    }

    notes.sort((firstNote, secondNote) {
      final startComparison = firstNote.startTick.compareTo(
        secondNote.startTick,
      );
      if (startComparison != 0) {
        return startComparison;
      }
      return firstNote.noteNumber.compareTo(secondNote.noteNumber);
    });

    return resolveRepeatedNoteOverlaps(notes);
  }

  List<QuantizedNote> resolveRepeatedNoteOverlaps(
    List<QuantizedNote> notes,
  ) {
    final resolvedNotes = <QuantizedNote>[];
    final lastNoteIndexByNumber = <int, int>{};

    for (final note in notes) {
      final previousNoteIndex = lastNoteIndexByNumber[note.noteNumber];

      if (previousNoteIndex == null) {
        resolvedNotes.add(note);
        lastNoteIndexByNumber[note.noteNumber] = resolvedNotes.length - 1;
        continue;
      }

      final previousNote = resolvedNotes[previousNoteIndex];

      if (note.startTick >= previousNote.endTick) {
        resolvedNotes.add(note);
        lastNoteIndexByNumber[note.noteNumber] = resolvedNotes.length - 1;
        continue;
      }

      if (note.startTick == previousNote.startTick) {
        final mergedEndTick = math.max(note.endTick, previousNote.endTick);
        final mergedVelocity = math.max(note.velocity, previousNote.velocity);

        resolvedNotes[previousNoteIndex] = QuantizedNote(
          noteNumber: previousNote.noteNumber,
          velocity: mergedVelocity,
          startTick: previousNote.startTick,
          durationTicks: mergedEndTick - previousNote.startTick,
        );
        continue;
      }

      resolvedNotes[previousNoteIndex] = QuantizedNote(
        noteNumber: previousNote.noteNumber,
        velocity: previousNote.velocity,
        startTick: previousNote.startTick,
        durationTicks: note.startTick - previousNote.startTick,
      );
      resolvedNotes.add(note);
      lastNoteIndexByNumber[note.noteNumber] = resolvedNotes.length - 1;
    }

    return resolvedNotes;
  }

  Map<int, List<QuantizedNote>> groupByStartTick(
    List<QuantizedNote> notes,
  ) {
    final groupedNotes = <int, List<QuantizedNote>>{};

    for (final note in notes) {
      groupedNotes.putIfAbsent(note.startTick, () => []).add(note);
    }

    return groupedNotes;
  }

  List<CompositionNote> createCompositionNotes(
    List<QuantizedNote> notes, {
    double startAbsoluteBeat = 0,
    double? maximumAbsoluteBeat,
    String idPrefix = 'captured',
  }) {
    final compositionNotes = <CompositionNote>[];

    for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
      final note = notes[noteIndex];
      final pianoNote = PianoNote.fromMidi(note.noteNumber);
      var currentAbsoluteBeat =
          startAbsoluteBeat + ticksToCompositionBeats(note.startTick);
      var remainingDurationBeats = ticksToCompositionBeats(
        note.durationTicks,
      );

      if (maximumAbsoluteBeat != null) {
        remainingDurationBeats = math.min(
          remainingDurationBeats,
          maximumAbsoluteBeat - currentAbsoluteBeat,
        );
      }

      var segmentIndex = 0;

      while (remainingDurationBeats > 0.0000001) {
        final measureIndex = currentAbsoluteBeat ~/ beatsPerMeasure;
        final startBeat = CompositionNote.normalizeTiming(
          currentAbsoluteBeat - (measureIndex * beatsPerMeasure),
        );
        final availableBeats = beatsPerMeasure - startBeat;
        final segmentDurationBeats = math.min(
          remainingDurationBeats,
          availableBeats,
        );
        final hasNextSegment =
            remainingDurationBeats - segmentDurationBeats > 0.0000001;

        compositionNotes.add(
          CompositionNote(
            id:
                '$idPrefix-$noteIndex-$segmentIndex-'
                '${note.startTick}-${note.noteNumber}',
            pitch: pianoNote.pitch,
            octave: pianoNote.octave,
            midiNumber: note.noteNumber,
            measureIndex: measureIndex,
            startBeat: startBeat,
            durationBeats: segmentDurationBeats,
            velocity: note.velocity / 127,
            tieToNext: hasNextSegment,
          ),
        );

        currentAbsoluteBeat += segmentDurationBeats;
        remainingDurationBeats -= segmentDurationBeats;
        segmentIndex++;
      }
    }

    return compositionNotes;
  }

  int timeToTicks(Duration time) {
    final quarterNotes =
        time.inMicroseconds * tempo / Duration.microsecondsPerMinute;
    return (quarterNotes * ticksPerQuarterNote).round();
  }

  int compositionBeatsToTicks(double beats) {
    final quarterNotesPerBeat = 4 / beatUnit;
    return (beats * quarterNotesPerBeat * ticksPerQuarterNote).round();
  }

  double ticksToCompositionBeats(int ticks) {
    final quarterNotes = ticks / ticksPerQuarterNote;
    final quarterNotesPerBeat = 4 / beatUnit;
    return CompositionNote.normalizeTiming(quarterNotes / quarterNotesPerBeat);
  }

  int quantizeTick(int rawTick) {
    return (rawTick / quantizationGridTicks).round() * quantizationGridTicks;
  }

  int calculateRequiredMeasureCount(List<CompositionNote> notes) {
    if (notes.isEmpty) {
      return 1;
    }

    var latestEndBeat = 0.0;
    for (final note in notes) {
      final noteEnd =
          (note.measureIndex * beatsPerMeasure) +
          note.startBeat +
          note.durationBeats;
      latestEndBeat = math.max(latestEndBeat, noteEnd);
    }

    return math.max(1, (latestEndBeat / beatsPerMeasure).ceil());
  }
}
