import '../../../../../piano_calibration/models/piano_key_marker.dart';

/// Conversion helpers shared by calibration markers and MIDI score events.
class MidiNoteUtils {
  const MidiNoteUtils._();

  static const Map<String, int> semitonesByNoteLetter = {
    'C': 0,
    'C#': 1,
    'Db': 1,
    'D': 2,
    'D#': 3,
    'Eb': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'Gb': 6,
    'G': 7,
    'G#': 8,
    'Ab': 8,
    'A': 9,
    'A#': 10,
    'Bb': 10,
    'B': 11,
  };

  static const List<String> noteNames = [
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

  /// Converts a labeled piano marker into a standard MIDI note number.
  ///
  /// Enharmonic flats and common sharp/flat Unicode encodings are normalized.
  /// Returns `null` when the marker contains an unsupported note spelling.
  static int? fromPianoKeyMarker(PianoKeyMarker marker) {
    String normalizedNoteLetter = marker.noteLetter
        .trim()
        .replaceAll('♯', '#')
        .replaceAll('＃', '#')
        .replaceAll('♭', 'b');

    int? semitone = semitonesByNoteLetter[normalizedNoteLetter];

    if (semitone == null) {
      return null;
    }

    return ((marker.octaveNumber + 1) * 12) + semitone;
  }

  /// Converts a MIDI number into a sharp-based scientific pitch name.
  static String nameForMidiNote(int midiNote) {
    int noteIndex = midiNote % 12;
    int octaveNumber = (midiNote ~/ 12) - 1;

    return '${noteNames[noteIndex]}$octaveNumber';
  }
}
