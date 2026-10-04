import 'package:soundsight/screens/midi/models/midi_note_event.dart';

class RecordedMidiEvent {
  const RecordedMidiEvent({
    required this.type,
    required this.noteNumber,
    required this.velocity,
    required this.timestamp,
  });

  final MidiNoteEventType type;
  final int noteNumber;
  final int velocity;
  final Duration timestamp;
}
