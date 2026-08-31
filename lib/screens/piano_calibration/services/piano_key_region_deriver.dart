import 'dart:ui';

import '../models/keyboard_area_corners.dart';
import '../models/normalized_keyboard_point.dart';
import '../models/piano_key_marker.dart';
import '../models/piano_key_region.dart';
import 'keyboard_perspective_mapper.dart';

/// Creates display polygons for every labeled white and black piano key.
class PianoKeyRegionDeriver {
  final KeyboardPerspectiveMapper perspectiveMapper =
      KeyboardPerspectiveMapper();

  final double blackKeyWidthScale = 0.60;
  final double blackKeyBottomExtensionFraction = 0.15;

  /// Combines full-depth white regions with detected or estimated black regions.
  ///
  /// Marker positions are first converted into keyboard-relative fractions so
  /// region widths remain correct under camera perspective.
  List<PianoKeyRegion> deriveRegions({
    required List<PianoKeyMarker> pianoKeyMarkers,
    required KeyboardAreaCorners keyboardAreaCorners,
    List<PianoKeyRegion> detectedBlackKeyRegions = const <PianoKeyRegion>[],
  }) {
    if (pianoKeyMarkers.isEmpty) {
      return const <PianoKeyRegion>[];
    }

    List<PianoKeyMarker> whiteKeyMarkers = pianoKeyMarkers
        .where((PianoKeyMarker marker) => !marker.isBlackKey)
        .toList();

    List<PianoKeyMarker> blackKeyMarkers = pianoKeyMarkers
        .where((PianoKeyMarker marker) => marker.isBlackKey)
        .toList();

    whiteKeyMarkers.sort((PianoKeyMarker first, PianoKeyMarker second) {
      return horizontalFraction(
        first,
        keyboardAreaCorners,
      ).compareTo(horizontalFraction(second, keyboardAreaCorners));
    });

    blackKeyMarkers.sort((PianoKeyMarker first, PianoKeyMarker second) {
      return horizontalFraction(
        first,
        keyboardAreaCorners,
      ).compareTo(horizontalFraction(second, keyboardAreaCorners));
    });

    List<double> whiteKeyFractions = [
      for (PianoKeyMarker marker in whiteKeyMarkers)
        horizontalFraction(marker, keyboardAreaCorners),
    ];

    List<PianoKeyRegion> regions = [];

    regions.addAll(
      deriveWhiteKeyRegions(
        whiteKeyMarkers: whiteKeyMarkers,
        whiteKeyFractions: whiteKeyFractions,
        keyboardAreaCorners: keyboardAreaCorners,
      ),
    );

    regions.addAll(
      deriveBlackKeyRegions(
        blackKeyMarkers: blackKeyMarkers,
        whiteKeyFractions: whiteKeyFractions,
        keyboardAreaCorners: keyboardAreaCorners,
        detectedBlackKeyRegions: detectedBlackKeyRegions,
      ),
    );

    return List<PianoKeyRegion>.unmodifiable(regions);
  }

  /// Creates adjacent white-key polygons from midpoint boundaries.
  List<PianoKeyRegion> deriveWhiteKeyRegions({
    required List<PianoKeyMarker> whiteKeyMarkers,
    required List<double> whiteKeyFractions,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    if (whiteKeyMarkers.isEmpty) {
      return const <PianoKeyRegion>[];
    }

    List<double> boundaries = calculateWhiteKeyBoundaries(whiteKeyFractions);

    List<PianoKeyRegion> regions = [];

    for (int index = 0; index < whiteKeyMarkers.length; index++) {
      PianoKeyMarker marker = whiteKeyMarkers[index];

      regions.add(
        createRegion(
          marker: marker,
          leftFraction: boundaries[index],
          rightFraction: boundaries[index + 1],
          topFraction: 0,
          bottomFraction: 1,
          keyboardAreaCorners: keyboardAreaCorners,
        ),
      );
    }

    return regions;
  }

  /// Converts ordered white-key centers into left/right cell boundaries.
  List<double> calculateWhiteKeyBoundaries(List<double> centerFractions) {
    if (centerFractions.length == 1) {
      double halfWidth = 0.035;

      return [
        (centerFractions.first - halfWidth).clamp(0.0, 1.0).toDouble(),
        (centerFractions.first + halfWidth).clamp(0.0, 1.0).toDouble(),
      ];
    }

    List<double> boundaries = [];
    double firstSpacing = centerFractions[1] - centerFractions[0];

    boundaries.add(
      (centerFractions.first - (firstSpacing / 2)).clamp(0.0, 1.0).toDouble(),
    );

    for (int index = 0; index < centerFractions.length - 1; index++) {
      boundaries.add((centerFractions[index] + centerFractions[index + 1]) / 2);
    }

    int lastIndex = centerFractions.length - 1;
    double lastSpacing =
        centerFractions[lastIndex] - centerFractions[lastIndex - 1];

    boundaries.add(
      (centerFractions.last + (lastSpacing / 2)).clamp(0.0, 1.0).toDouble(),
    );

    return boundaries;
  }

  /// Uses image-detected black outlines when available, otherwise estimates them.
  List<PianoKeyRegion> deriveBlackKeyRegions({
    required List<PianoKeyMarker> blackKeyMarkers,
    required List<double> whiteKeyFractions,
    required KeyboardAreaCorners keyboardAreaCorners,
    required List<PianoKeyRegion> detectedBlackKeyRegions,
  }) {
    if (blackKeyMarkers.isEmpty || whiteKeyFractions.length < 2) {
      return const <PianoKeyRegion>[];
    }

    double typicalWhiteKeyWidth = calculateTypicalWhiteKeyWidth(
      whiteKeyFractions,
    );

    List<PianoKeyRegion> regions = [];
    Map<String, PianoKeyRegion> detectedRegionByNoteName = {
      for (PianoKeyRegion region in detectedBlackKeyRegions)
        region.noteName: region,
    };

    for (PianoKeyMarker marker in blackKeyMarkers) {
      PianoKeyRegion? detectedRegion =
          detectedRegionByNoteName[marker.noteName];

      if (detectedRegion != null) {
        regions.add(detectedRegion);
        continue;
      }

      NormalizedKeyboardPoint markerPosition = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: marker.position,
            corners: keyboardAreaCorners,
          );

      double localWhiteKeyWidth = findLocalWhiteKeyWidth(
        markerPosition.horizontalFraction,
        whiteKeyFractions,
        typicalWhiteKeyWidth,
      );

      double blackKeyWidth = localWhiteKeyWidth * blackKeyWidthScale;
      double leftFraction =
          (markerPosition.horizontalFraction - (blackKeyWidth / 2))
              .clamp(0.0, 1.0)
              .toDouble();
      double rightFraction =
          (markerPosition.horizontalFraction + (blackKeyWidth / 2))
              .clamp(0.0, 1.0)
              .toDouble();
      double bottomFraction =
          (markerPosition.verticalFraction + blackKeyBottomExtensionFraction)
              .clamp(0.0, 1.0)
              .toDouble();

      regions.add(
        createRegion(
          marker: marker,
          leftFraction: leftFraction,
          rightFraction: rightFraction,
          topFraction: 0,
          bottomFraction: bottomFraction,
          keyboardAreaCorners: keyboardAreaCorners,
        ),
      );
    }

    return regions;
  }

  /// Returns spacing around a black key, falling back near incomplete edges.
  double findLocalWhiteKeyWidth(
    double blackKeyFraction,
    List<double> whiteKeyFractions,
    double fallbackWidth,
  ) {
    for (int index = 0; index < whiteKeyFractions.length - 1; index++) {
      double leftFraction = whiteKeyFractions[index];
      double rightFraction = whiteKeyFractions[index + 1];

      if (blackKeyFraction >= leftFraction &&
          blackKeyFraction <= rightFraction) {
        return rightFraction - leftFraction;
      }
    }

    return fallbackWidth;
  }

  /// Calculates the median spacing between adjacent white-key centers.
  double calculateTypicalWhiteKeyWidth(List<double> whiteKeyFractions) {
    List<double> widths = [];

    for (int index = 1; index < whiteKeyFractions.length; index++) {
      double width = whiteKeyFractions[index] - whiteKeyFractions[index - 1];

      if (width > 0) {
        widths.add(width);
      }
    }

    widths.sort();
    int middleIndex = widths.length ~/ 2;

    if (widths.length.isOdd) {
      return widths[middleIndex];
    }

    return (widths[middleIndex - 1] + widths[middleIndex]) / 2;
  }

  /// Maps fractional rectangle corners into a perspective-aware key polygon.
  PianoKeyRegion createRegion({
    required PianoKeyMarker marker,
    required double leftFraction,
    required double rightFraction,
    required double topFraction,
    required double bottomFraction,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    List<Offset> outlinePoints = [
      sourcePosition(leftFraction, topFraction, keyboardAreaCorners),
      sourcePosition(rightFraction, topFraction, keyboardAreaCorners),
      sourcePosition(rightFraction, bottomFraction, keyboardAreaCorners),
      sourcePosition(leftFraction, bottomFraction, keyboardAreaCorners),
    ];

    return PianoKeyRegion(
      noteLetter: marker.noteLetter,
      octaveNumber: marker.octaveNumber,
      isBlackKey: marker.isBlackKey,
      outlinePoints: List<Offset>.unmodifiable(outlinePoints),
    );
  }

  /// Converts a keyboard-relative fraction into source-image coordinates.
  Offset sourcePosition(
    double horizontalFraction,
    double verticalFraction,
    KeyboardAreaCorners keyboardAreaCorners,
  ) {
    return perspectiveMapper.toSourcePosition(
      normalizedPosition: NormalizedKeyboardPoint(
        horizontalFraction: horizontalFraction,
        verticalFraction: verticalFraction,
      ),
      corners: keyboardAreaCorners,
    );
  }

  /// Reads a marker's perspective-corrected horizontal keyboard fraction.
  double horizontalFraction(
    PianoKeyMarker marker,
    KeyboardAreaCorners keyboardAreaCorners,
  ) {
    return perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: marker.position,
          corners: keyboardAreaCorners,
        )
        .horizontalFraction;
  }
}
