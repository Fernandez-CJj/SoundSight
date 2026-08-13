// Keeps a piano note name with its matching MIDI number.
// The note name is easy to read, while the MIDI number helps order the keys
// and calculate how many physical keys are inside a range.
class PianoNote {
  const PianoNote({required this.noteName, required this.midiNumber});

  final String noteName;
  final int midiNumber;
}

// Generates every note from A0 through C8.
// This avoids writing 88 notes manually and helps prevent a note name
// from being matched with the wrong MIDI number.
List<PianoNote> createPianoNotes() {
  // MIDI uses the same 12-note pattern in every octave.
  // A MIDI number's position in this list identifies its note name.
  List<String> noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  List<PianoNote> pianoNotes = [];

  // Creates one PianoNote for each MIDI number in the full piano range.
  // The loop starts at MIDI 21 for A0 and ends at MIDI 108 for C8.
  for (int midiNumber = 21; midiNumber <= 108; midiNumber++) {
    int notePosition = midiNumber % 12;
    int octaveNumber = (midiNumber ~/ 12) - 1;
    String noteName = '${noteNames[notePosition]}$octaveNumber';

    PianoNote pianoNote = PianoNote(noteName: noteName, midiNumber: midiNumber);

    pianoNotes.add(pianoNote);
  }

  return pianoNotes;
}
