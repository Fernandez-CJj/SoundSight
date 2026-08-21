import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'dart:async';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';

class MidiInputService {
  final MidiCommand _midiCommand = MidiCommand();

  StreamSubscription<MidiDataReceivedEvent>? _midiSubscription;

  final Set<int> _activeMidiNotes = {};

  final StreamController<Set<int>> _activeNotesController =
      StreamController<Set<int>>.broadcast();

  final StreamController<int> _noteOnController =
      StreamController<int>.broadcast();

  Set<int> get activeMidiNotes => Set<int>.unmodifiable(_activeMidiNotes);

  Stream<Set<int>> get activeNotesStream => _activeNotesController.stream;

  Stream<int> get noteOnStream => _noteOnController.stream;

  Future<List<MidiDevice>> getDevices() async {
    return await _midiCommand.devices ?? [];
  }

  Future<void> connectToDevice(MidiDevice device) async {
    await _midiSubscription?.cancel();

    await _midiCommand.connectToDevice(device);

    _midiSubscription = _midiCommand.onMidiDataReceived?.listen(
      _handleMidiEvent,
    );
  }

  void _handleMidiEvent(MidiDataReceivedEvent event) {
    final message = event.message;

    bool notesChanged = false;

    if (message is NoteOnMessage) {
      if (message.velocity > 0) {
        notesChanged = _activeMidiNotes.add(message.note);

        _noteOnController.add(message.note);
      } else {
        notesChanged = _activeMidiNotes.remove(message.note);
      }
    } else if (message is NoteOffMessage) {
      notesChanged = _activeMidiNotes.remove(message.note);
    }

    if (!notesChanged) {
      return;
    }

    _activeNotesController.add(Set<int>.unmodifiable(_activeMidiNotes));
  }

  Future<void> dispose() async {
    await _midiSubscription?.cancel();
    await _activeNotesController.close();
    await _noteOnController.close();
  }
}
