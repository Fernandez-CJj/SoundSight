import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import '../utils/midi_note_converter.dart';
import '../services/midi_input_service.dart';

class MidiNoteIdentifierScreen extends StatefulWidget {
  const MidiNoteIdentifierScreen({super.key});

  @override
  State<MidiNoteIdentifierScreen> createState() =>
      _MidiNoteIdentifierScreenState();
}

class _MidiNoteIdentifierScreenState extends State<MidiNoteIdentifierScreen> {
  final midiInputService = MidiInputService();
  List<MidiDevice> midiDevices = [];
  StreamSubscription<Set<int>>? activeNotesSubscription;
  Set<int> activeMidiNotes = {};
  @override
  void initState() {
    super.initState();
    activeNotesSubscription = midiInputService.activeNotesStream.listen((
      notes,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        activeMidiNotes = notes;
      });
    });
    getMidiDevices();
  }

  @override
  Widget build(BuildContext context) {
    final activeNotes = activeMidiNotes.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('MIDI Note Identifier')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: midiDevices.isEmpty
                ? const Text('No MIDI device detected')
                : Text('Detected: ${midiDevices.first.name}'),
          ),
          ElevatedButton(
            onPressed: () {
              getMidiDevices();
            },
            child: Text('Refresh Device'),
          ),
          ElevatedButton(
            onPressed: connectToMidi,
            child: const Text('Connect'),
          ),
          Text(
            activeNotes.isEmpty
                ? 'Press a piano key'
                : activeNotes.map(midiToNoteName).join(' + '),
          ),
        ],
      ),
    );
  }

  Future<void> getMidiDevices() async {
    final devices = await midiInputService.getDevices();

    setState(() {
      midiDevices = devices;
    });
  }

  Future<void> connectToMidi() async {
    if (midiDevices.isEmpty) {
      return;
    }

    await midiInputService.connectToDevice(midiDevices.first);
  }

  @override
  void dispose() {
    activeNotesSubscription?.cancel();

    midiInputService.dispose();

    super.dispose();
  }
}
