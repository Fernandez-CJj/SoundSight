import '../contants/note_names.dart';

String midiToNoteName(int midi) {
  int noteIndex = midi % 12;
  int octave = (midi ~/ 12) - 1;

  return '${noteNames[noteIndex]}$octave';
}
