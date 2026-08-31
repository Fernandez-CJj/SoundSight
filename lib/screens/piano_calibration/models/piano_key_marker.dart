import 'dart:ui';

/// A labeled target point for a visible piano key in source-image pixels.
class PianoKeyMarker {
  const PianoKeyMarker({
    required this.noteLetter,
    required this.octaveNumber,
    required this.position,
    this.isBlackKey = false,
  });

  /// Letter name, such as `C` or `G#`.
  final String noteLetter;
  /// Scientific-pitch octave number.
  final int octaveNumber;
  /// Point used for the key label and falling-note horizontal alignment.
  final Offset position;
  /// Whether this marker belongs to a raised black key.
  final bool isBlackKey;

  /// Whether this marker represents a natural C key.
  bool get isC {
    return noteLetter == 'C' && !isBlackKey;
  }

  /// Human-readable note name such as `C4`.
  String get noteName {
    return '$noteLetter$octaveNumber';
  }
}
