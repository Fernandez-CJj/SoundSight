import 'package:dart_midi_pro/dart_midi_pro.dart';

class EditorNote {
  const EditorNote({
    required this.id,
    required this.trackIndex,
    required this.channel,
    required this.pitch,
    required this.startTick,
    required this.durationTicks,
    required this.velocity,
    required this.noteOn,
    required this.noteOff,
    required this.noteOffVelocity,
    required this.originalStartTick,
    required this.originalEndTick,
  });

  final String id;
  final int trackIndex;
  final int channel;
  final int pitch;
  final int startTick;
  final int durationTicks;
  final int velocity;
  final NoteOnEvent noteOn;
  final MidiEvent noteOff;
  final int noteOffVelocity;
  final int originalStartTick;
  final int originalEndTick;

  int get endTick => startTick + durationTicks;
  bool get isEdited =>
      pitch != noteOn.noteNumber ||
      startTick != originalStartTick ||
      endTick != originalEndTick ||
      velocity != noteOn.velocity;

  EditorNote copyWith({
    int? pitch,
    int? startTick,
    int? durationTicks,
    int? velocity,
  }) {
    return EditorNote(
      id: id,
      trackIndex: trackIndex,
      channel: channel,
      pitch: pitch ?? this.pitch,
      startTick: startTick ?? this.startTick,
      durationTicks: durationTicks ?? this.durationTicks,
      velocity: velocity ?? this.velocity,
      noteOn: noteOn,
      noteOff: noteOff,
      noteOffVelocity: noteOffVelocity,
      originalStartTick: originalStartTick,
      originalEndTick: originalEndTick,
    );
  }
}
