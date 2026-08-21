import 'package:flutter/material.dart';

import 'midi/midi_note_identifier_screen.dart';

class NoteInputScreen extends StatefulWidget {
  const NoteInputScreen({super.key});

  @override
  State<NoteInputScreen> createState() => _NoteInputScreenState();
}

class _NoteInputScreenState extends State<NoteInputScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Note Identifier')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Input Method',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MidiNoteIdentifierScreen(),
                  ),
                );
              },
              child: const Text('MIDI Connection'),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: null,
              child: const Text('Microphone - Coming Soon'),
            ),
          ],
        ),
      ),
    );
  }
}
