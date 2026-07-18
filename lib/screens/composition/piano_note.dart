class PianoNote {
  const PianoNote({
    required this.midiNumber,
    required this.pitch,
    required this.octave,
  });

  static const int minimumMidi = 21;
  static const int maximumMidi = 108;

  static const List<String> _pitchNames = [
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

  final int midiNumber;
  final String pitch;
  final int octave;

  bool get isBlackKey => pitch.contains('#');

  String get label => '$pitch$octave';

  static bool isValidMidi(int midiNumber) {
    return midiNumber >= minimumMidi && midiNumber <= maximumMidi;
  }

  static PianoNote fromMidi(int midiNumber) {
    if (!isValidMidi(midiNumber)) {
      throw ArgumentError.value(
        midiNumber,
        'midiNumber',
        'A piano note must be between A0 and C8.',
      );
    }

    return PianoNote(
      midiNumber: midiNumber,
      pitch: _pitchNames[midiNumber % 12],
      octave: (midiNumber ~/ 12) - 1,
    );
  }

  static List<PianoNote> buildRange(int startMidi, int endMidi) {
    final firstMidi = startMidi < minimumMidi ? minimumMidi : startMidi;
    final lastMidi = endMidi > maximumMidi ? maximumMidi : endMidi;

    if (firstMidi > lastMidi) {
      return const [];
    }

    return List<PianoNote>.generate(
      lastMidi - firstMidi + 1,
      (index) => fromMidi(firstMidi + index),
    );
  }

  static final List<PianoNote> allKeys = List<PianoNote>.unmodifiable(
    buildRange(minimumMidi, maximumMidi),
  );
}
