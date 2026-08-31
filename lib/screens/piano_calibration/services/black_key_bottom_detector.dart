import 'dart:math' as math;
import 'dart:ui';

import '../models/black_key_candidate.dart';
import '../models/black_key_geometry.dart';
import '../models/calibration_frame.dart';
import '../models/keyboard_area_corners.dart';
import '../models/normalized_keyboard_point.dart';
import 'keyboard_perspective_mapper.dart';

/// Refines a black key's bottom edge and side boundaries from grayscale pixels.
///
/// This avoids centering markers on estimated white-key seams, which becomes
/// increasingly inaccurate near the perspective-distorted sides of the image.
class BlackKeyBottomDetector {
  final KeyboardPerspectiveMapper perspectiveMapper =
      KeyboardPerspectiveMapper();

  final double maximumSearchFraction = 0.82;
  final double minimumBrightnessIncrease = 10;
  final double minimumHorizontalTransition = 8;
  final double markerInsetFraction = 0.15;
  final double outerSearchWidthScale = 1.0;
  final double minimumDetectedWidthScale = 0.45;
  final double maximumDetectedWidthScale = 1.80;

  /// Finds the visible black-key polygon and a marker inset from its bottom.
  ///
  /// Brightness transitions are sampled downward from the contour. If a safe
  /// transition or horizontal bounds cannot be established, `null` asks the
  /// caller to use its geometry fallback.
  BlackKeyGeometry? findGeometry({
    required BlackKeyCandidate candidate,
    BlackKeyCandidate? previousCandidate,
    BlackKeyCandidate? nextCandidate,
    required CalibrationFrame calibrationFrame,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    if (calibrationFrame.width != keyboardAreaCorners.sourceImageWidth ||
        calibrationFrame.height != keyboardAreaCorners.sourceImageHeight ||
        calibrationFrame.grayscaleBytes.length !=
            calibrationFrame.width * calibrationFrame.height) {
      return null;
    }

    Offset candidateCenter = Offset(
      candidate.left + (candidate.width / 2),
      candidate.top + (candidate.height / 2),
    );

    NormalizedKeyboardPoint normalizedCenter = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: candidateCenter,
          corners: keyboardAreaCorners,
        );

    double searchStartFraction = normalizedCenter.verticalFraction;

    if (searchStartFraction >= maximumSearchFraction) {
      return null;
    }

    Offset searchStart = perspectiveMapper.toSourcePosition(
      normalizedPosition: NormalizedKeyboardPoint(
        horizontalFraction: normalizedCenter.horizontalFraction,
        verticalFraction: searchStartFraction,
      ),
      corners: keyboardAreaCorners,
    );

    Offset searchEnd = perspectiveMapper.toSourcePosition(
      normalizedPosition: NormalizedKeyboardPoint(
        horizontalFraction: normalizedCenter.horizontalFraction,
        verticalFraction: maximumSearchFraction,
      ),
      corners: keyboardAreaCorners,
    );

    int sampleCount = math.max(24, (searchEnd - searchStart).distance.round());
    int horizontalRadius = math.max(1, (candidate.width * 0.12).round());
    List<double> brightnessValues = [];
    List<Offset> samplePositions = [];

    for (int sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
      double progress = sampleIndex / (sampleCount - 1);
      double verticalFraction =
          searchStartFraction +
          ((maximumSearchFraction - searchStartFraction) * progress);

      Offset samplePosition = perspectiveMapper.toSourcePosition(
        normalizedPosition: NormalizedKeyboardPoint(
          horizontalFraction: normalizedCenter.horizontalFraction,
          verticalFraction: verticalFraction,
        ),
        corners: keyboardAreaCorners,
      );

      brightnessValues.add(
        averageBrightness(
          position: samplePosition,
          horizontalRadius: horizontalRadius,
          calibrationFrame: calibrationFrame,
        ),
      );

      samplePositions.add(samplePosition);
    }

    int comparisonRadius = math.max(2, (sampleCount * 0.025).round());
    double strongestIncrease = double.negativeInfinity;
    int strongestIndex = -1;

    for (
      int sampleIndex = comparisonRadius;
      sampleIndex < sampleCount - comparisonRadius;
      sampleIndex++
    ) {
      double brightnessBefore = averageValues(
        brightnessValues,
        sampleIndex - comparisonRadius,
        sampleIndex - 1,
      );

      double brightnessAfter = averageValues(
        brightnessValues,
        sampleIndex,
        sampleIndex + comparisonRadius - 1,
      );

      double brightnessIncrease = brightnessAfter - brightnessBefore;

      if (brightnessIncrease > strongestIncrease) {
        strongestIncrease = brightnessIncrease;
        strongestIndex = sampleIndex;
      }
    }

    if (strongestIndex < 0 || strongestIncrease < minimumBrightnessIncrease) {
      return null;
    }

    Offset detectedBottom = samplePositions[strongestIndex];

    NormalizedKeyboardPoint normalizedBottom = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: detectedBottom,
          corners: keyboardAreaCorners,
        );

    double markerVerticalFraction =
        (normalizedBottom.verticalFraction - markerInsetFraction)
            .clamp(0.0, 1.0)
            .toDouble();

    Offset markerSearchPosition = perspectiveMapper.toSourcePosition(
      normalizedPosition: NormalizedKeyboardPoint(
        horizontalFraction: normalizedBottom.horizontalFraction,
        verticalFraction: markerVerticalFraction,
      ),
      corners: keyboardAreaCorners,
    );

    BlackKeyHorizontalBounds? markerBounds = findHorizontalBounds(
      candidate: candidate,
      previousCandidate: previousCandidate,
      nextCandidate: nextCandidate,
      detectedPosition: markerSearchPosition,
      calibrationFrame: calibrationFrame,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    double markerHorizontalFraction =
        markerBounds?.centerFraction ?? normalizedBottom.horizontalFraction;

    Offset markerPosition = perspectiveMapper.toSourcePosition(
      normalizedPosition: NormalizedKeyboardPoint(
        horizontalFraction: markerHorizontalFraction,
        verticalFraction: markerVerticalFraction,
      ),
      corners: keyboardAreaCorners,
    );

    double maximumTopMeasurementFraction = math.max(
      0.05,
      markerVerticalFraction - 0.04,
    );

    double topMeasurementFraction = (normalizedCenter.verticalFraction - 0.10)
        .clamp(0.05, maximumTopMeasurementFraction)
        .toDouble();

    double bottomMeasurementFraction =
        (normalizedBottom.verticalFraction - 0.035)
            .clamp(markerVerticalFraction, normalizedBottom.verticalFraction)
            .toDouble();

    BlackKeyHorizontalBounds? topBounds = findHorizontalBoundsAtFraction(
      candidate: candidate,
      previousCandidate: previousCandidate,
      nextCandidate: nextCandidate,
      horizontalFraction: markerHorizontalFraction,
      verticalFraction: topMeasurementFraction,
      calibrationFrame: calibrationFrame,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    BlackKeyHorizontalBounds? bottomBounds = findHorizontalBoundsAtFraction(
      candidate: candidate,
      previousCandidate: previousCandidate,
      nextCandidate: nextCandidate,
      horizontalFraction: markerHorizontalFraction,
      verticalFraction: bottomMeasurementFraction,
      calibrationFrame: calibrationFrame,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    topBounds ??= markerBounds;
    bottomBounds ??= markerBounds;

    List<Offset> outlinePoints = [];

    if (topBounds != null && bottomBounds != null) {
      outlinePoints = [
        sourcePosition(topBounds.leftFraction, 0, keyboardAreaCorners),
        sourcePosition(topBounds.rightFraction, 0, keyboardAreaCorners),
        sourcePosition(
          bottomBounds.rightFraction,
          normalizedBottom.verticalFraction,
          keyboardAreaCorners,
        ),
        sourcePosition(
          bottomBounds.leftFraction,
          normalizedBottom.verticalFraction,
          keyboardAreaCorners,
        ),
      ];
    }

    return BlackKeyGeometry(
      markerPosition: markerPosition,
      outlinePoints: List<Offset>.unmodifiable(outlinePoints),
    );
  }

  /// Samples several vertical levels and chooses stable left/right key edges.
  BlackKeyHorizontalBounds? findHorizontalBounds({
    required BlackKeyCandidate candidate,
    required BlackKeyCandidate? previousCandidate,
    required BlackKeyCandidate? nextCandidate,
    required Offset detectedPosition,
    required CalibrationFrame calibrationFrame,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    NormalizedKeyboardPoint normalizedPosition = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: detectedPosition,
          corners: keyboardAreaCorners,
        );

    Offset rowLeft = perspectiveMapper.toSourcePosition(
      normalizedPosition: NormalizedKeyboardPoint(
        horizontalFraction: 0,
        verticalFraction: normalizedPosition.verticalFraction,
      ),
      corners: keyboardAreaCorners,
    );

    Offset rowRight = perspectiveMapper.toSourcePosition(
      normalizedPosition: NormalizedKeyboardPoint(
        horizontalFraction: 1,
        verticalFraction: normalizedPosition.verticalFraction,
      ),
      corners: keyboardAreaCorners,
    );

    double keyboardWidth = (rowRight - rowLeft).distance;

    if (keyboardWidth < 1 || candidate.width < 2) {
      return null;
    }

    double outerSearchFraction =
        (candidate.width * outerSearchWidthScale) / keyboardWidth;

    double searchStartFraction =
        normalizedPosition.horizontalFraction - outerSearchFraction;

    if (previousCandidate != null) {
      double previousHorizontalFraction = horizontalFractionForCandidate(
        previousCandidate,
        keyboardAreaCorners,
      );

      searchStartFraction =
          (previousHorizontalFraction + normalizedPosition.horizontalFraction) /
          2;
    }

    double searchEndFraction =
        normalizedPosition.horizontalFraction + outerSearchFraction;

    if (nextCandidate != null) {
      double nextHorizontalFraction = horizontalFractionForCandidate(
        nextCandidate,
        keyboardAreaCorners,
      );

      searchEndFraction =
          (normalizedPosition.horizontalFraction + nextHorizontalFraction) / 2;
    }

    searchStartFraction = searchStartFraction
        .clamp(0.0, normalizedPosition.horizontalFraction)
        .toDouble();

    searchEndFraction = searchEndFraction
        .clamp(normalizedPosition.horizontalFraction, 1.0)
        .toDouble();

    double searchWidth =
        (searchEndFraction - searchStartFraction) * keyboardWidth;
    int sampleCount = math.max(25, searchWidth.round());

    if (searchEndFraction <= searchStartFraction || sampleCount < 5) {
      return null;
    }

    List<double> brightnessValues = [];
    List<double> horizontalFractions = [];

    for (int sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
      double progress = sampleIndex / (sampleCount - 1);
      double horizontalFraction =
          searchStartFraction +
          ((searchEndFraction - searchStartFraction) * progress);

      Offset samplePosition = perspectiveMapper.toSourcePosition(
        normalizedPosition: NormalizedKeyboardPoint(
          horizontalFraction: horizontalFraction,
          verticalFraction: normalizedPosition.verticalFraction,
        ),
        corners: keyboardAreaCorners,
      );

      brightnessValues.add(
        averageBrightness(
          position: samplePosition,
          horizontalRadius: 0,
          verticalRadius: 2,
          calibrationFrame: calibrationFrame,
        ),
      );

      horizontalFractions.add(horizontalFraction);
    }

    int centerIndex =
        (((normalizedPosition.horizontalFraction - searchStartFraction) /
                    (searchEndFraction - searchStartFraction)) *
                (sampleCount - 1))
            .round()
            .clamp(0, sampleCount - 1);

    int comparisonRadius = math.max(2, (candidate.width * 0.08).round());

    if (centerIndex <= comparisonRadius ||
        centerIndex >= sampleCount - comparisonRadius) {
      return null;
    }

    int leftEdgeIndex = -1;

    for (
      int sampleIndex = centerIndex - comparisonRadius;
      sampleIndex >= comparisonRadius;
      sampleIndex--
    ) {
      double brightnessBefore = averageValues(
        brightnessValues,
        sampleIndex - comparisonRadius,
        sampleIndex - 1,
      );

      double brightnessAfter = averageValues(
        brightnessValues,
        sampleIndex,
        sampleIndex + comparisonRadius - 1,
      );

      double darkening = brightnessBefore - brightnessAfter;

      if (darkening >= minimumHorizontalTransition) {
        leftEdgeIndex = sampleIndex;
        break;
      }
    }

    int rightEdgeIndex = -1;

    for (
      int sampleIndex = centerIndex + comparisonRadius;
      sampleIndex < sampleCount - comparisonRadius;
      sampleIndex++
    ) {
      double brightnessBefore = averageValues(
        brightnessValues,
        sampleIndex - comparisonRadius,
        sampleIndex - 1,
      );

      double brightnessAfter = averageValues(
        brightnessValues,
        sampleIndex,
        sampleIndex + comparisonRadius - 1,
      );

      double brightening = brightnessAfter - brightnessBefore;

      if (brightening >= minimumHorizontalTransition) {
        rightEdgeIndex = sampleIndex;
        break;
      }
    }

    if (leftEdgeIndex < 0 || rightEdgeIndex <= leftEdgeIndex) {
      return null;
    }

    double detectedWidth =
        (horizontalFractions[rightEdgeIndex] -
            horizontalFractions[leftEdgeIndex]) *
        keyboardWidth;

    if (detectedWidth < candidate.width * minimumDetectedWidthScale ||
        detectedWidth > candidate.width * maximumDetectedWidthScale) {
      return null;
    }

    return BlackKeyHorizontalBounds(
      leftFraction: horizontalFractions[leftEdgeIndex],
      rightFraction: horizontalFractions[rightEdgeIndex],
    );
  }

  /// Measures black-key side transitions at one normalized vertical position.
  BlackKeyHorizontalBounds? findHorizontalBoundsAtFraction({
    required BlackKeyCandidate candidate,
    required BlackKeyCandidate? previousCandidate,
    required BlackKeyCandidate? nextCandidate,
    required double horizontalFraction,
    required double verticalFraction,
    required CalibrationFrame calibrationFrame,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    Offset measurementPosition = sourcePosition(
      horizontalFraction,
      verticalFraction,
      keyboardAreaCorners,
    );

    return findHorizontalBounds(
      candidate: candidate,
      previousCandidate: previousCandidate,
      nextCandidate: nextCandidate,
      detectedPosition: measurementPosition,
      calibrationFrame: calibrationFrame,
      keyboardAreaCorners: keyboardAreaCorners,
    );
  }

  /// Maps a normalized keyboard coordinate into the source image.
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

  /// Returns the perspective-corrected horizontal center of [candidate].
  double horizontalFractionForCandidate(
    BlackKeyCandidate candidate,
    KeyboardAreaCorners keyboardAreaCorners,
  ) {
    Offset center = Offset(
      candidate.left + (candidate.width / 2),
      candidate.top + (candidate.height / 2),
    );

    return perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: center,
          corners: keyboardAreaCorners,
        )
        .horizontalFraction;
  }

  /// Averages grayscale pixels around [position], clamped to frame boundaries.
  double averageBrightness({
    required Offset position,
    required int horizontalRadius,
    int verticalRadius = 0,
    required CalibrationFrame calibrationFrame,
  }) {
    int centerX = position.dx.round().clamp(0, calibrationFrame.width - 1);
    int centerY = position.dy.round().clamp(0, calibrationFrame.height - 1);
    int startX = (centerX - horizontalRadius).clamp(
      0,
      calibrationFrame.width - 1,
    );
    int endX = (centerX + horizontalRadius).clamp(
      0,
      calibrationFrame.width - 1,
    );
    int startY = (centerY - verticalRadius).clamp(
      0,
      calibrationFrame.height - 1,
    );
    int endY = (centerY + verticalRadius).clamp(0, calibrationFrame.height - 1);

    double totalBrightness = 0;
    int pixelCount = 0;

    for (int row = startY; row <= endY; row++) {
      for (int column = startX; column <= endX; column++) {
        int pixelIndex = (row * calibrationFrame.width) + column;
        totalBrightness += calibrationFrame.grayscaleBytes[pixelIndex];
        pixelCount++;
      }
    }

    return totalBrightness / pixelCount;
  }

  /// Averages an inclusive range in a precomputed brightness profile.
  double averageValues(List<double> values, int startIndex, int endIndex) {
    double total = 0;

    for (int index = startIndex; index <= endIndex; index++) {
      total += values[index];
    }

    return total / (endIndex - startIndex + 1);
  }
}

/// Perspective-normalized horizontal edges measured for one black key.
class BlackKeyHorizontalBounds {
  const BlackKeyHorizontalBounds({
    required this.leftFraction,
    required this.rightFraction,
  });

  /// Left edge within the keyboard quadrilateral.
  final double leftFraction;
  /// Right edge within the keyboard quadrilateral.
  final double rightFraction;

  /// Midpoint between [leftFraction] and [rightFraction].
  double get centerFraction {
    return (leftFraction + rightFraction) / 2;
  }
}
