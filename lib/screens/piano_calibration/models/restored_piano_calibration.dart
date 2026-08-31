import 'keyboard_area_corners.dart';
import 'piano_key_marker.dart';
import 'piano_key_region.dart';
import 'reference_key_marker.dart';

/// Runtime, pixel-coordinate form of a saved normalized calibration.
///
/// This object is ready for the overlay and falling-note renderer to consume.
class RestoredPianoCalibration {
  const RestoredPianoCalibration({
    required this.keyboardAreaCorners,
    required this.pianoKeyMarkers,
    required this.pianoKeyRegions,
    required this.referenceKeyMarkers,
  });

  /// Restored playable-area quadrilateral for the current preview dimensions.
  final KeyboardAreaCorners keyboardAreaCorners;
  /// Restored label and note-target markers.
  final List<PianoKeyMarker> pianoKeyMarkers;
  /// Restored white- and black-key polygons.
  final List<PianoKeyRegion> pianoKeyRegions;
  /// Natural-C markers used if the mapping is edited.
  final List<ReferenceKeyMarker> referenceKeyMarkers;
}
