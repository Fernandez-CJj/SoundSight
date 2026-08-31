import 'dart:ui';

import '../models/keyboard_area_corners.dart';
import '../models/normalized_image_point.dart';
import '../models/normalized_piano_calibration.dart';
import '../models/piano_key_marker.dart';
import '../models/piano_key_region.dart';
import '../models/reference_key_marker.dart';
import '../models/restored_piano_calibration.dart';

/// Restores normalized Firestore geometry for the current camera frame size.
class PianoCalibrationRestorer {
  /// Rebuilds overlay-ready corners, markers, regions, and reference C keys.
  ///
  /// The restored coordinates use the new source dimensions, allowing a saved
  /// mapping to survive preview-resolution differences between sessions.
  RestoredPianoCalibration restore({
    required NormalizedPianoCalibration calibration,
    required int sourceImageWidth,
    required int sourceImageHeight,
  }) {
    if (sourceImageWidth <= 0 || sourceImageHeight <= 0) {
      throw ArgumentError(
        'The camera image dimensions must be greater than zero.',
      );
    }

    KeyboardAreaCorners restoredCorners = KeyboardAreaCorners(
      topLeft: restorePoint(
        point: calibration.topLeft,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      topRight: restorePoint(
        point: calibration.topRight,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      bottomRight: restorePoint(
        point: calibration.bottomRight,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      bottomLeft: restorePoint(
        point: calibration.bottomLeft,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      sourceImageWidth: sourceImageWidth,
      sourceImageHeight: sourceImageHeight,
    );

    List<PianoKeyMarker> restoredMarkers = [];
    List<PianoKeyRegion> restoredRegions = [];
    List<ReferenceKeyMarker> restoredReferenceMarkers = [];

    for (var normalizedKey in calibration.pianoKeys) {
      Offset restoredMarkerPosition = restorePoint(
        point: normalizedKey.markerPosition,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      );

      List<Offset> restoredOutlinePoints = [];

      for (NormalizedImagePoint outlinePoint in normalizedKey.outlinePoints) {
        restoredOutlinePoints.add(
          restorePoint(
            point: outlinePoint,
            sourceImageWidth: sourceImageWidth,
            sourceImageHeight: sourceImageHeight,
          ),
        );
      }

      restoredMarkers.add(
        PianoKeyMarker(
          noteLetter: normalizedKey.noteLetter,
          octaveNumber: normalizedKey.octaveNumber,
          isBlackKey: normalizedKey.isBlackKey,
          position: restoredMarkerPosition,
        ),
      );

      restoredRegions.add(
        PianoKeyRegion(
          noteLetter: normalizedKey.noteLetter,
          octaveNumber: normalizedKey.octaveNumber,
          isBlackKey: normalizedKey.isBlackKey,
          outlinePoints: List<Offset>.unmodifiable(restoredOutlinePoints),
        ),
      );

      if (normalizedKey.noteLetter == 'C' && !normalizedKey.isBlackKey) {
        restoredReferenceMarkers.add(
          ReferenceKeyMarker(
            octaveNumber: normalizedKey.octaveNumber,
            position: restoredMarkerPosition,
          ),
        );
      }
    }

    return RestoredPianoCalibration(
      keyboardAreaCorners: restoredCorners,
      pianoKeyMarkers: List<PianoKeyMarker>.unmodifiable(restoredMarkers),
      pianoKeyRegions: List<PianoKeyRegion>.unmodifiable(restoredRegions),
      referenceKeyMarkers: List<ReferenceKeyMarker>.unmodifiable(
        restoredReferenceMarkers,
      ),
    );
  }

  /// Converts one normalized image point back into source-image pixels.
  Offset restorePoint({
    required NormalizedImagePoint point,
    required int sourceImageWidth,
    required int sourceImageHeight,
  }) {
    return Offset(
      point.horizontalFraction * sourceImageWidth,
      point.verticalFraction * sourceImageHeight,
    );
  }
}
