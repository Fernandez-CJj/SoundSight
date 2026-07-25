import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_midi_pro/dart_midi_pro.dart';

import '../domain/editor_note.dart';
import '../domain/midi_project.dart';

class MidiEditorRepository {
  Future<MidiProject> importFile(File file) async {
    final midi = MidiParser().parseMidiFromFile(file);
    if (midi.header.format != 0 && midi.header.format != 1) {
      throw const MidiImportException('Only Standard MIDI format 0 and 1 are supported.');
    }

    final eventsByTrack = <List<TimedMidiEvent>>[];
    final notes = <EditorNote>[];
    var maxTick = 0;

    for (var trackIndex = 0; trackIndex < midi.tracks.length; trackIndex++) {
      var tick = 0;
      var order = 0;
      final active = HashMap<String, Queue<_OpenNote>>();
      final events = <TimedMidiEvent>[];

      for (final event in midi.tracks[trackIndex]) {
        tick += event.deltaTime;
        maxTick = max(maxTick, tick);
        events.add(TimedMidiEvent(
          trackIndex: trackIndex,
          absoluteTick: tick,
          event: event,
          order: order++,
        ));

        if (event is NoteOnEvent && event.velocity > 0) {
          active
              .putIfAbsent('${event.channel}:${event.noteNumber}', Queue.new)
              .addLast(_OpenNote(event, tick));
          continue;
        }

        final noteOff = _asNoteOff(event);
        if (noteOff == null) {
          continue;
        }

        final key = '${noteOff.channel}:${noteOff.noteNumber}';
        final queue = active[key];
        if (queue == null || queue.isEmpty) {
          continue;
        }

        final opened = queue.removeFirst();
        if (queue.isEmpty) {
          active.remove(key);
        }

        final duration = max(1, tick - opened.tick);
        notes.add(EditorNote(
          id: '${trackIndex}_${notes.length}',
          trackIndex: trackIndex,
          channel: opened.event.channel,
          pitch: opened.event.noteNumber,
          startTick: opened.tick,
          durationTicks: duration,
          velocity: opened.event.velocity,
          noteOn: opened.event,
          noteOff: event,
          noteOffVelocity: noteOff.velocity,
          originalStartTick: opened.tick,
          originalEndTick: tick,
        ));
      }

      eventsByTrack.add(events);
    }

    notes.sort(_compareNotes);
    return MidiProject(
      fileName: file.uri.pathSegments.isEmpty ? file.path : file.uri.pathSegments.last,
      header: midi.header,
      eventsByTrack: eventsByTrack,
      notes: notes,
      ticksPerQuarter: midi.header.ticksPerBeat ?? 480,
      lastTick: maxTick,
    );
  }

  Uint8List exportProject(MidiProject project, List<EditorNote> notes, Set<String> deletedNoteIds) {
    final originalNoteOnEvents = HashSet<MidiEvent>.identity()
      ..addAll(notes.map((note) => note.noteOn));
    final originalNoteOffEvents = HashSet<MidiEvent>.identity()
      ..addAll(notes.map((note) => note.noteOff));
    final keptNotes = notes.where((note) => !deletedNoteIds.contains(note.id)).toList()..sort(_compareNotes);
    final tracks = <List<MidiEvent>>[];

    for (var trackIndex = 0; trackIndex < project.eventsByTrack.length; trackIndex++) {
      final nonNoteEvents = <_ExportEvent>[];
      final endOfTrackEvents = <_ExportEvent>[];
      for (final timed in project.eventsByTrack[trackIndex]) {
        if (originalNoteOnEvents.contains(timed.event) || originalNoteOffEvents.contains(timed.event)) {
          continue;
        }
        final exportEvent = _ExportEvent(timed.absoluteTick, timed.order, timed.event);
        if (timed.event is EndOfTrackEvent) {
          endOfTrackEvents.add(exportEvent);
        } else {
          nonNoteEvents.add(exportEvent);
        }
      }

      final trackNotes = keptNotes.where((note) => note.trackIndex == trackIndex);
      var ordinal = project.eventsByTrack[trackIndex].length;
      final noteEvents = <_ExportEvent>[];
      for (final note in trackNotes) {
        noteEvents.add(_ExportEvent(note.startTick, ordinal++, _makeNoteOn(note)));
        noteEvents.add(_ExportEvent(note.endTick, ordinal++, _makeNoteOff(note)));
      }

      final finalTick = [...nonNoteEvents, ...noteEvents].fold<int>(0, (latest, event) => max(latest, event.tick));
      final merged = [...nonNoteEvents, ...noteEvents, for (final event in endOfTrackEvents) _ExportEvent(finalTick, event.order, event.event)]
        ..sort((a, b) {
          final tickCompare = a.tick.compareTo(b.tick);
          if (tickCompare != 0) {
            return tickCompare;
          }
          return _eventPriority(a.event).compareTo(_eventPriority(b.event));
        });

      var previousTick = 0;
      final track = <MidiEvent>[];
      for (final item in merged) {
        item.event.deltaTime = max(0, item.tick - previousTick);
        previousTick = item.tick;
        track.add(item.event);
      }
      tracks.add(track);
    }

    return Uint8List.fromList(MidiWriter().writeMidiToBuffer(
      MidiFile(tracks, project.header),
      running: false,
      useByte9ForNoteOff: false,
    ));
  }

  static int _compareNotes(EditorNote a, EditorNote b) {
    final byStart = a.startTick.compareTo(b.startTick);
    if (byStart != 0) {
      return byStart;
    }
    final byTrack = a.trackIndex.compareTo(b.trackIndex);
    if (byTrack != 0) {
      return byTrack;
    }
    return a.pitch.compareTo(b.pitch);
  }

  static _NoteOffData? _asNoteOff(MidiEvent event) {
    if (event is NoteOffEvent) {
      return _NoteOffData(event.channel, event.noteNumber, event.velocity);
    }
    if (event is NoteOnEvent && event.velocity == 0) {
      return _NoteOffData(event.channel, event.noteNumber, 0);
    }
    return null;
  }

  static NoteOnEvent _makeNoteOn(EditorNote note) {
    return NoteOnEvent()
      ..channel = note.channel
      ..noteNumber = note.pitch
      ..velocity = note.velocity;
  }

  static MidiEvent _makeNoteOff(EditorNote note) {
    if (note.noteOff is NoteOnEvent) {
      return NoteOnEvent()
        ..channel = note.channel
        ..noteNumber = note.pitch
        ..velocity = 0;
    }
    return NoteOffEvent()
      ..channel = note.channel
      ..noteNumber = note.pitch
      ..velocity = note.noteOffVelocity;
  }

  static int _eventPriority(MidiEvent event) {
    if (event is NoteOffEvent || event is NoteOnEvent && event.velocity == 0) {
      return 0;
    }
    if (event is NoteOnEvent) {
      return 2;
    }
    if (event is EndOfTrackEvent) {
      return 3;
    }
    return 1;
  }
}

class MidiImportException implements Exception {
  const MidiImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _OpenNote {
  const _OpenNote(this.event, this.tick);
  final NoteOnEvent event;
  final int tick;
}

class _NoteOffData {
  const _NoteOffData(this.channel, this.noteNumber, this.velocity);
  final int channel;
  final int noteNumber;
  final int velocity;
}

class _ExportEvent {
  const _ExportEvent(this.tick, this.order, this.event);
  final int tick;
  final int order;
  final MidiEvent event;
}
