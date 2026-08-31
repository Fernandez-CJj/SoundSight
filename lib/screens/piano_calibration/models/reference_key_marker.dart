import 'dart:ui';

/// Candidate natural-C position used while the user identifies middle C.
class ReferenceKeyMarker {
  const ReferenceKeyMarker({
    required this.octaveNumber,
    required this.position,
  });

  /// Tentative octave assigned from the surrounding black-key pattern.
  final int octaveNumber;
  /// Center of the candidate white key in source-image pixels.
  final Offset position;

  /// Human-readable C note name for display during selection.
  String get noteName {
    return 'C$octaveNumber';
  }
}
