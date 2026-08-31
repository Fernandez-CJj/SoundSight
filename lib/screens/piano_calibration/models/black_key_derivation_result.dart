import 'piano_key_marker.dart';
import 'piano_key_region.dart';

/// Contains the labeled markers and visual outlines derived for black keys.
class BlackKeyDerivationResult {
  const BlackKeyDerivationResult({
    required this.markers,
    required this.regions,
  });

  /// Positions used to draw note labels and align falling notes.
  final List<PianoKeyMarker> markers;
  /// Polygonal outlines used while reviewing a calibration.
  final List<PianoKeyRegion> regions;
}
