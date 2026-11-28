enum MidiNoteEventType { noteOn, noteOff }

class MidiControlEvent {
  const MidiControlEvent({required this.controller, required this.value});
  final int controller;
  final int value;
}

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
