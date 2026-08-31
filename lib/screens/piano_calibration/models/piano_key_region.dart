import 'dart:ui';

/// Polygonal visual region assigned to one labeled piano key.
class PianoKeyRegion {
  const PianoKeyRegion({
    required this.noteLetter,
    required this.octaveNumber,
    required this.isBlackKey,
    required this.outlinePoints,
  });

  /// Letter name, including a sharp symbol when applicable.
  final String noteLetter;
  /// Scientific-pitch octave number.
  final int octaveNumber;
  /// Whether the outline belongs to a black key.
  final bool isBlackKey;
  /// Ordered polygon vertices in source-image pixels.
  final List<Offset> outlinePoints;

  /// Human-readable note name used to match this region to its marker.
  String get noteName {
    return '$noteLetter$octaveNumber';
  }
}
