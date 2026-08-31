import 'dart:ui';

import '../models/keyboard_area_corners.dart';
import '../models/normalized_image_point.dart';
import '../models/normalized_piano_calibration.dart';
import '../models/normalized_piano_key.dart';
import '../models/piano_key_marker.dart';
import '../models/piano_key_region.dart';

/// Converts runtime pixel geometry into resolution-independent stored data.
class PianoCalibrationNormalizer {
  /// Normalizes all corners, markers, and matching key polygons.
  ///
  /// Throws if dimensions are invalid or a marker has no corresponding region,
  /// preventing incomplete calibrations from being persisted.
  NormalizedPianoCalibration normalize({
    required KeyboardAreaCorners keyboardAreaCorners,
    required List<PianoKeyMarker> pianoKeyMarkers,
    required List<PianoKeyRegion> pianoKeyRegions,
  }) {
    int sourceImageWidth = keyboardAreaCorners.sourceImageWidth;
    int sourceImageHeight = keyboardAreaCorners.sourceImageHeight;

    if (sourceImageWidth <= 0 || sourceImageHeight <= 0) {
      throw ArgumentError(
        'The camera image width and height must be greater than zero.',
      );
    }

    List<NormalizedPianoKey> normalizedPianoKeys = [];

    for (PianoKeyMarker marker in pianoKeyMarkers) {
      PianoKeyRegion? matchingRegion = findMatchingRegion(
        marker: marker,
        pianoKeyRegions: pianoKeyRegions,
      );

      if (matchingRegion == null) {
        throw StateError('No key outline was found for ${marker.noteName}.');
      }

      List<NormalizedImagePoint> normalizedOutlinePoints = [];

      for (Offset outlinePoint in matchingRegion.outlinePoints) {
        normalizedOutlinePoints.add(
          normalizePoint(
            sourcePoint: outlinePoint,
            sourceImageWidth: sourceImageWidth,
            sourceImageHeight: sourceImageHeight,
          ),
        );
      }

      NormalizedPianoKey normalizedPianoKey = NormalizedPianoKey(
        noteLetter: marker.noteLetter,
        octaveNumber: marker.octaveNumber,
        isBlackKey: marker.isBlackKey,
        markerPosition: normalizePoint(
          sourcePoint: marker.position,
          sourceImageWidth: sourceImageWidth,
          sourceImageHeight: sourceImageHeight,
        ),
        outlinePoints: List<NormalizedImagePoint>.unmodifiable(
          normalizedOutlinePoints,
        ),
      );

      normalizedPianoKeys.add(normalizedPianoKey);
    }

    return NormalizedPianoCalibration(
      topLeft: normalizePoint(
        sourcePoint: keyboardAreaCorners.topLeft,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      topRight: normalizePoint(
        sourcePoint: keyboardAreaCorners.topRight,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      bottomRight: normalizePoint(
        sourcePoint: keyboardAreaCorners.bottomRight,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      bottomLeft: normalizePoint(
        sourcePoint: keyboardAreaCorners.bottomLeft,
        sourceImageWidth: sourceImageWidth,
        sourceImageHeight: sourceImageHeight,
      ),
      sourceImageAspectRatio: sourceImageWidth / sourceImageHeight,
      pianoKeys: List<NormalizedPianoKey>.unmodifiable(normalizedPianoKeys),
    );
  }

  /// Finds the region with the same note, octave, and key color as [marker].
  PianoKeyRegion? findMatchingRegion({
    required PianoKeyMarker marker,
    required List<PianoKeyRegion> pianoKeyRegions,
  }) {
    for (PianoKeyRegion region in pianoKeyRegions) {
      bool sameNoteLetter = region.noteLetter == marker.noteLetter;
      bool sameOctave = region.octaveNumber == marker.octaveNumber;
      bool sameKeyType = region.isBlackKey == marker.isBlackKey;

      if (sameNoteLetter && sameOctave && sameKeyType) {
        return region;
      }
    }

    return null;
  }

  /// Converts a source-image pixel into clamped image fractions.
  NormalizedImagePoint normalizePoint({
    required Offset sourcePoint,
    required int sourceImageWidth,
    required int sourceImageHeight,
  }) {
    double horizontalFraction = (sourcePoint.dx / sourceImageWidth)
        .clamp(0.0, 1.0)
        .toDouble();

    double verticalFraction = (sourcePoint.dy / sourceImageHeight)
        .clamp(0.0, 1.0)
        .toDouble();

    return NormalizedImagePoint(
      horizontalFraction: horizontalFraction,
      verticalFraction: verticalFraction,
    );
  }
}
