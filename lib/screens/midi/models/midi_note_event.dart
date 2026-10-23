enum MidiNoteEventType { noteOn, noteOff }

class MidiNoteEvent {
  const MidiNoteEvent({
    required this.type,
    required this.noteNumber,
    required this.velocity,
  });

  final MidiNoteEventType type;
  final int noteNumber;
  final int velocity;
}
