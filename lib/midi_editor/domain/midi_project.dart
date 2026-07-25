import 'package:dart_midi_pro/dart_midi_pro.dart';

import 'editor_note.dart';

class TimedMidiEvent {
  const TimedMidiEvent({
    required this.trackIndex,
    required this.absoluteTick,
    required this.event,
    required this.order,
  });

  final int trackIndex;
  final int absoluteTick;
  final MidiEvent event;
  final int order;
}

class MidiProject {
  const MidiProject({
    required this.fileName,
    required this.header,
    required this.eventsByTrack,
    required this.notes,
    required this.ticksPerQuarter,
    required this.lastTick,
  });

  final String fileName;
  final MidiHeader header;
  final List<List<TimedMidiEvent>> eventsByTrack;
  final List<EditorNote> notes;
  final int ticksPerQuarter;
  final int lastTick;
}
