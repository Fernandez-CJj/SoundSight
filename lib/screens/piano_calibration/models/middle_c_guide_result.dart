/// The kind of guidance produced from a single MIDI note press.
enum MiddleCGuideResultType { invalid, blackKey, moveLeft, moveRight, found }

/// Pure result used by the calibration screen to guide a player to Middle C.
class MiddleCGuideResult {
  const MiddleCGuideResult({
    required this.type,
    required this.midiNote,
    required this.noteName,
    this.whiteKeyDistance = 0,
  });

  final MiddleCGuideResultType type;
  final int midiNote;
  final String? noteName;
  final int whiteKeyDistance;
}
