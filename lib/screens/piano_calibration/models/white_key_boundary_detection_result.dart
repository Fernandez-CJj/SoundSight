import 'piano_key_marker.dart';

/// White-key markers produced by seam detection or its geometry fallback.
class WhiteKeyBoundaryDetectionResult {
  const WhiteKeyBoundaryDetectionResult({
    required this.markers,
    required this.detectedBoundaryCount,
    required this.requiredBoundaryCount,
    required this.usedDetectedBoundaries,
  });

  /// Refined white-key centers in source-image coordinates.
  final List<PianoKeyMarker> markers;
  /// Number of usable dark seams detected between white keys.
  final int detectedBoundaryCount;
  /// Number of seams required for the current visible key range.
  final int requiredBoundaryCount;
  /// Whether image-detected seams, rather than fallback spacing, were used.
  final bool usedDetectedBoundaries;
}
