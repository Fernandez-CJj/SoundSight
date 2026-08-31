import 'dart:math' as math;
import 'dart:ui';

import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/calibration_frame.dart';
import '../models/keyboard_area_corners.dart';
import '../models/piano_key_marker.dart';
import '../models/white_key_boundary_detection_result.dart';

/// Refines white-key centers by detecting dark seams in a rectified keyboard.
///
/// The playable quadrilateral is perspective-warped into a rectangle before
/// vertical brightness profiles are measured. Weak or inconsistent detections
/// safely fall back to the geometrically derived marker positions.
class WhiteKeyBoundaryDetector {
  final double scanTopFraction = 0.58;
  final double scanBottomFraction = 0.91;
  final double searchRadiusScale = 0.32;
  final double minimumBoundaryContrast = 2;
  final double minimumConfidentBoundaryFraction = 0.60;
  final double maximumCenterCorrectionScale = 0.45;
  final double maximumC4AlignmentScale = 0.35;

  /// Detects seams near expected boundaries and returns corrected key centers.
  ///
  /// Corrections are accepted only when enough boundaries have adequate local
  /// contrast, remain ordered, and keep C4 close to the user's selected anchor.
  WhiteKeyBoundaryDetectionResult refineCenters({
    required CalibrationFrame calibrationFrame,
    required KeyboardAreaCorners keyboardAreaCorners,
    required List<PianoKeyMarker> fallbackMarkers,
  }) {
    int requiredBoundaryCount = math.max(0, fallbackMarkers.length - 1);

    if (fallbackMarkers.length < 3 ||
        calibrationFrame.width != keyboardAreaCorners.sourceImageWidth ||
        calibrationFrame.height != keyboardAreaCorners.sourceImageHeight ||
        calibrationFrame.grayscaleBytes.length !=
            calibrationFrame.width * calibrationFrame.height) {
      return fallbackResult(
        fallbackMarkers: fallbackMarkers,
        requiredBoundaryCount: requiredBoundaryCount,
      );
    }

    int rectifiedWidth = calculateRectifiedWidth(
      keyboardAreaCorners,
      calibrationFrame.width,
    );

    int rectifiedHeight = calculateRectifiedHeight(
      keyboardAreaCorners,
      calibrationFrame.height,
    );

    if (rectifiedWidth < 64 || rectifiedHeight < 32) {
      return fallbackResult(
        fallbackMarkers: fallbackMarkers,
        requiredBoundaryCount: requiredBoundaryCount,
      );
    }

    cv.Mat? sourceImage;
    cv.VecPoint2f? sourcePoints;
    cv.VecPoint2f? destinationPoints;
    cv.Mat? forwardTransform;
    cv.Mat? inverseTransform;
    cv.Mat? rectifiedImage;

    try {
      sourceImage = cv.Mat.fromList(
        calibrationFrame.height,
        calibrationFrame.width,
        cv.MatType.CV_8UC1,
        calibrationFrame.grayscaleBytes,
      );

      sourcePoints = cv.VecPoint2f.fromList([
        cv.Point2f(
          keyboardAreaCorners.topLeft.dx,
          keyboardAreaCorners.topLeft.dy,
        ),
        cv.Point2f(
          keyboardAreaCorners.topRight.dx,
          keyboardAreaCorners.topRight.dy,
        ),
        cv.Point2f(
          keyboardAreaCorners.bottomRight.dx,
          keyboardAreaCorners.bottomRight.dy,
        ),
        cv.Point2f(
          keyboardAreaCorners.bottomLeft.dx,
          keyboardAreaCorners.bottomLeft.dy,
        ),
      ]);

      destinationPoints = cv.VecPoint2f.fromList([
        cv.Point2f(0, 0),
        cv.Point2f((rectifiedWidth - 1).toDouble(), 0),
        cv.Point2f(
          (rectifiedWidth - 1).toDouble(),
          (rectifiedHeight - 1).toDouble(),
        ),
        cv.Point2f(0, (rectifiedHeight - 1).toDouble()),
      ]);

      forwardTransform = cv.getPerspectiveTransform2f(
        sourcePoints,
        destinationPoints,
      );

      inverseTransform = cv.getPerspectiveTransform2f(
        destinationPoints,
        sourcePoints,
      );

      rectifiedImage = cv.warpPerspective(sourceImage, forwardTransform, (
        rectifiedWidth,
        rectifiedHeight,
      ));

      List<Offset> rectifiedMarkerPositions = [];

      for (PianoKeyMarker marker in fallbackMarkers) {
        Offset rectifiedPosition = transformPoint(
          marker.position,
          forwardTransform,
        );

        if (!rectifiedPosition.dx.isFinite || !rectifiedPosition.dy.isFinite) {
          return fallbackResult(
            fallbackMarkers: fallbackMarkers,
            requiredBoundaryCount: requiredBoundaryCount,
          );
        }

        rectifiedMarkerPositions.add(rectifiedPosition);
      }

      if (!positionsIncreaseFromLeftToRight(rectifiedMarkerPositions)) {
        return fallbackResult(
          fallbackMarkers: fallbackMarkers,
          requiredBoundaryCount: requiredBoundaryCount,
        );
      }

      double typicalWhiteKeyWidth = calculateTypicalWhiteKeyWidth(
        rectifiedMarkerPositions,
      );

      if (typicalWhiteKeyWidth < 4) {
        return fallbackResult(
          fallbackMarkers: fallbackMarkers,
          requiredBoundaryCount: requiredBoundaryCount,
        );
      }

      int scanTop = (rectifiedHeight * scanTopFraction).round();
      int scanBottom = (rectifiedHeight * scanBottomFraction).round();

      scanTop = scanTop.clamp(0, rectifiedHeight - 2).toInt();
      scanBottom = scanBottom.clamp(scanTop + 1, rectifiedHeight).toInt();

      List<double> columnBrightness = calculateColumnBrightness(
        image: rectifiedImage,
        imageWidth: rectifiedWidth,
        scanTop: scanTop,
        scanBottom: scanBottom,
      );

      List<WhiteKeyBoundaryCandidate> boundaryCandidates = [];

      for (
        int index = 0;
        index < rectifiedMarkerPositions.length - 1;
        index++
      ) {
        double leftMarkerX = rectifiedMarkerPositions[index].dx;
        double rightMarkerX = rectifiedMarkerPositions[index + 1].dx;
        double expectedBoundaryX = (leftMarkerX + rightMarkerX) / 2;
        double localWhiteKeyWidth = rightMarkerX - leftMarkerX;

        WhiteKeyBoundaryCandidate candidate = findBoundaryCandidate(
          columnBrightness: columnBrightness,
          expectedBoundaryX: expectedBoundaryX,
          localWhiteKeyWidth: localWhiteKeyWidth,
        );

        boundaryCandidates.add(candidate);
      }

      double confidenceThreshold = calculateConfidenceThreshold(
        boundaryCandidates,
      );

      List<bool> confidentBoundaries = [];
      int detectedBoundaryCount = 0;

      for (WhiteKeyBoundaryCandidate candidate in boundaryCandidates) {
        bool isConfident = candidate.contrast >= confidenceThreshold;

        confidentBoundaries.add(isConfident);

        if (isConfident) {
          detectedBoundaryCount++;
        }
      }

      int minimumDetectedCount =
          (requiredBoundaryCount * minimumConfidentBoundaryFraction).ceil();

      if (detectedBoundaryCount < minimumDetectedCount ||
          !boundariesIncreaseFromLeftToRight(boundaryCandidates)) {
        return WhiteKeyBoundaryDetectionResult(
          markers: fallbackMarkers,
          detectedBoundaryCount: detectedBoundaryCount,
          requiredBoundaryCount: requiredBoundaryCount,
          usedDetectedBoundaries: false,
        );
      }

      List<double> refinedCenterXs = calculateRefinedCenterXs(
        fallbackPositions: rectifiedMarkerPositions,
        boundaryCandidates: boundaryCandidates,
        confidentBoundaries: confidentBoundaries,
      );

      int c4Index = findC4Index(fallbackMarkers);

      if (c4Index < 0) {
        return fallbackResult(
          fallbackMarkers: fallbackMarkers,
          requiredBoundaryCount: requiredBoundaryCount,
          detectedBoundaryCount: detectedBoundaryCount,
        );
      }

      double c4Alignment =
          rectifiedMarkerPositions[c4Index].dx - refinedCenterXs[c4Index];

      if (c4Alignment.abs() > typicalWhiteKeyWidth * maximumC4AlignmentScale) {
        return WhiteKeyBoundaryDetectionResult(
          markers: fallbackMarkers,
          detectedBoundaryCount: detectedBoundaryCount,
          requiredBoundaryCount: requiredBoundaryCount,
          usedDetectedBoundaries: false,
        );
      }

      List<PianoKeyMarker> refinedMarkers = [];

      for (int index = 0; index < fallbackMarkers.length; index++) {
        PianoKeyMarker fallbackMarker = fallbackMarkers[index];

        if (index == c4Index) {
          refinedMarkers.add(fallbackMarker);
          continue;
        }

        double alignedCenterX = refinedCenterXs[index] + c4Alignment;
        double correction = alignedCenterX - rectifiedMarkerPositions[index].dx;

        if (correction.abs() >
            typicalWhiteKeyWidth * maximumCenterCorrectionScale) {
          refinedMarkers.add(fallbackMarker);
          continue;
        }

        Offset refinedSourcePosition = transformPoint(
          Offset(alignedCenterX, rectifiedMarkerPositions[index].dy),
          inverseTransform,
        );

        if (!refinedSourcePosition.dx.isFinite ||
            !refinedSourcePosition.dy.isFinite) {
          refinedMarkers.add(fallbackMarker);
          continue;
        }

        refinedMarkers.add(
          PianoKeyMarker(
            noteLetter: fallbackMarker.noteLetter,
            octaveNumber: fallbackMarker.octaveNumber,
            position: refinedSourcePosition,
            isBlackKey: fallbackMarker.isBlackKey,
          ),
        );
      }

      return WhiteKeyBoundaryDetectionResult(
        markers: List<PianoKeyMarker>.unmodifiable(refinedMarkers),
        detectedBoundaryCount: detectedBoundaryCount,
        requiredBoundaryCount: requiredBoundaryCount,
        usedDetectedBoundaries: true,
      );
    } catch (_) {
      return fallbackResult(
        fallbackMarkers: fallbackMarkers,
        requiredBoundaryCount: requiredBoundaryCount,
      );
    } finally {
      rectifiedImage?.dispose();
      inverseTransform?.dispose();
      forwardTransform?.dispose();
      destinationPoints?.dispose();
      sourcePoints?.dispose();
      sourceImage?.dispose();
    }
  }

  /// Chooses a safe rectified width from the longer keyboard edge.
  int calculateRectifiedWidth(KeyboardAreaCorners corners, int imageWidth) {
    double topWidth = (corners.topRight - corners.topLeft).distance;
    double bottomWidth = (corners.bottomRight - corners.bottomLeft).distance;
    double largestWidth = math.max(topWidth, bottomWidth);

    return largestWidth.round().clamp(64, imageWidth).toInt();
  }

  /// Chooses a safe rectified height from the longer keyboard side.
  int calculateRectifiedHeight(KeyboardAreaCorners corners, int imageHeight) {
    double leftHeight = (corners.bottomLeft - corners.topLeft).distance;
    double rightHeight = (corners.bottomRight - corners.topRight).distance;
    double largestHeight = math.max(leftHeight, rightHeight);

    return largestHeight.round().clamp(32, imageHeight).toInt();
  }

  /// Applies a 3x3 perspective transform to one point.
  Offset transformPoint(Offset sourcePoint, cv.Mat transform) {
    double firstRowX = transform.at<double>(0, 0);
    double firstRowY = transform.at<double>(0, 1);
    double firstRowOffset = transform.at<double>(0, 2);
    double secondRowX = transform.at<double>(1, 0);
    double secondRowY = transform.at<double>(1, 1);
    double secondRowOffset = transform.at<double>(1, 2);
    double thirdRowX = transform.at<double>(2, 0);
    double thirdRowY = transform.at<double>(2, 1);
    double thirdRowOffset = transform.at<double>(2, 2);

    double divisor =
        (thirdRowX * sourcePoint.dx) +
        (thirdRowY * sourcePoint.dy) +
        thirdRowOffset;

    if (divisor.abs() < 0.000001) {
      return const Offset(double.nan, double.nan);
    }

    double transformedX =
        ((firstRowX * sourcePoint.dx) +
            (firstRowY * sourcePoint.dy) +
            firstRowOffset) /
        divisor;

    double transformedY =
        ((secondRowX * sourcePoint.dx) +
            (secondRowY * sourcePoint.dy) +
            secondRowOffset) /
        divisor;

    return Offset(transformedX, transformedY);
  }

  /// Verifies that marker x-coordinates remain strictly ordered.
  bool positionsIncreaseFromLeftToRight(List<Offset> positions) {
    for (int index = 1; index < positions.length; index++) {
      if (positions[index].dx <= positions[index - 1].dx) {
        return false;
      }
    }

    return true;
  }

  /// Returns median horizontal spacing between expected white-key markers.
  double calculateTypicalWhiteKeyWidth(List<Offset> markerPositions) {
    List<double> widths = [];

    for (int index = 1; index < markerPositions.length; index++) {
      double width = markerPositions[index].dx - markerPositions[index - 1].dx;

      if (width > 0) {
        widths.add(width);
      }
    }

    return calculateMedian(widths);
  }

  /// Averages each rectified column over the lower key-seam scan area.
  List<double> calculateColumnBrightness({
    required cv.Mat image,
    required int imageWidth,
    required int scanTop,
    required int scanBottom,
  }) {
    List<double> columnBrightness = List<double>.filled(imageWidth, 0);
    int rowCount = scanBottom - scanTop;
    List<int> imageBytes = image.data;

    for (int row = scanTop; row < scanBottom; row++) {
      int rowStart = row * imageWidth;

      for (int column = 0; column < imageWidth; column++) {
        columnBrightness[column] += imageBytes[rowStart + column];
      }
    }

    for (int column = 0; column < imageWidth; column++) {
      columnBrightness[column] /= rowCount;
    }

    return columnBrightness;
  }

  /// Finds the strongest dark-line contrast near an expected seam position.
  WhiteKeyBoundaryCandidate findBoundaryCandidate({
    required List<double> columnBrightness,
    required double expectedBoundaryX,
    required double localWhiteKeyWidth,
  }) {
    int imageWidth = columnBrightness.length;
    int searchRadius = math.max(
      3,
      (localWhiteKeyWidth * searchRadiusScale).round(),
    );

    int startColumn = (expectedBoundaryX.round() - searchRadius)
        .clamp(2, imageWidth - 3)
        .toInt();

    int endColumn = (expectedBoundaryX.round() + searchRadius)
        .clamp(2, imageWidth - 3)
        .toInt();

    double bestContrast = double.negativeInfinity;
    int bestColumn = expectedBoundaryX.round().clamp(0, imageWidth - 1);

    for (int column = startColumn; column <= endColumn; column++) {
      double contrast = calculateDarkLineContrast(
        columnBrightness: columnBrightness,
        column: column,
        localWhiteKeyWidth: localWhiteKeyWidth,
      );

      if (contrast > bestContrast) {
        bestContrast = contrast;
        bestColumn = column;
      }
    }

    return WhiteKeyBoundaryCandidate(
      position: bestColumn.toDouble(),
      contrast: bestContrast,
    );
  }

  /// Compares a column's brightness with small regions on both sides.
  double calculateDarkLineContrast({
    required List<double> columnBrightness,
    required int column,
    required double localWhiteKeyWidth,
  }) {
    int imageWidth = columnBrightness.length;
    int sideDistance = math.max(3, (localWhiteKeyWidth * 0.16).round());
    int sideRadius = math.max(1, (localWhiteKeyWidth * 0.06).round());

    double centerBrightness = averageRange(
      columnBrightness,
      column - 1,
      column + 1,
    );

    int leftCenter = (column - sideDistance).clamp(0, imageWidth - 1);
    int rightCenter = (column + sideDistance).clamp(0, imageWidth - 1);

    double leftBrightness = averageRange(
      columnBrightness,
      leftCenter - sideRadius,
      leftCenter + sideRadius,
    );

    double rightBrightness = averageRange(
      columnBrightness,
      rightCenter - sideRadius,
      rightCenter + sideRadius,
    );

    double surroundingBrightness = (leftBrightness + rightBrightness) / 2;

    return surroundingBrightness - centerBrightness;
  }

  /// Averages a clamped inclusive range in a brightness profile.
  double averageRange(
    List<double> values,
    int requestedStart,
    int requestedEnd,
  ) {
    int start = requestedStart.clamp(0, values.length - 1);
    int end = requestedEnd.clamp(0, values.length - 1);

    double total = 0;
    int valueCount = 0;

    for (int index = start; index <= end; index++) {
      total += values[index];
      valueCount++;
    }

    return total / valueCount;
  }

  /// Derives an adaptive contrast threshold while respecting the fixed minimum.
  double calculateConfidenceThreshold(
    List<WhiteKeyBoundaryCandidate> boundaryCandidates,
  ) {
    List<double> contrasts = [];

    for (WhiteKeyBoundaryCandidate candidate in boundaryCandidates) {
      if (candidate.contrast > 0) {
        contrasts.add(candidate.contrast);
      }
    }

    if (contrasts.isEmpty) {
      return minimumBoundaryContrast;
    }

    double medianContrast = calculateMedian(contrasts);
    double relativeThreshold = medianContrast * 0.35;

    return math.max(minimumBoundaryContrast, relativeThreshold);
  }

  /// Ensures detected seam candidates do not cross or duplicate each other.
  bool boundariesIncreaseFromLeftToRight(
    List<WhiteKeyBoundaryCandidate> boundaryCandidates,
  ) {
    for (int index = 1; index < boundaryCandidates.length; index++) {
      if (boundaryCandidates[index].position <=
          boundaryCandidates[index - 1].position) {
        return false;
      }
    }

    return true;
  }

  /// Reconstructs key centers from detected seams and fallback edge estimates.
  List<double> calculateRefinedCenterXs({
    required List<Offset> fallbackPositions,
    required List<WhiteKeyBoundaryCandidate> boundaryCandidates,
    required List<bool> confidentBoundaries,
  }) {
    List<double> refinedCenterXs = [];
    int lastMarkerIndex = fallbackPositions.length - 1;

    for (int markerIndex = 0; markerIndex <= lastMarkerIndex; markerIndex++) {
      if (markerIndex == 0) {
        bool canUseFirstTwoBoundaries =
            confidentBoundaries.length >= 2 &&
            confidentBoundaries[0] &&
            confidentBoundaries[1];

        if (canUseFirstTwoBoundaries) {
          double firstBoundary = boundaryCandidates[0].position;
          double secondBoundary = boundaryCandidates[1].position;

          refinedCenterXs.add(
            firstBoundary - ((secondBoundary - firstBoundary) / 2),
          );
        } else {
          refinedCenterXs.add(fallbackPositions[markerIndex].dx);
        }

        continue;
      }

      if (markerIndex == lastMarkerIndex) {
        int lastBoundaryIndex = boundaryCandidates.length - 1;
        int previousBoundaryIndex = lastBoundaryIndex - 1;

        bool canUseLastTwoBoundaries =
            previousBoundaryIndex >= 0 &&
            confidentBoundaries[previousBoundaryIndex] &&
            confidentBoundaries[lastBoundaryIndex];

        if (canUseLastTwoBoundaries) {
          double previousBoundary =
              boundaryCandidates[previousBoundaryIndex].position;
          double lastBoundary = boundaryCandidates[lastBoundaryIndex].position;

          refinedCenterXs.add(
            lastBoundary + ((lastBoundary - previousBoundary) / 2),
          );
        } else {
          refinedCenterXs.add(fallbackPositions[markerIndex].dx);
        }

        continue;
      }

      int leftBoundaryIndex = markerIndex - 1;
      int rightBoundaryIndex = markerIndex;

      bool canUseSurroundingBoundaries =
          confidentBoundaries[leftBoundaryIndex] &&
          confidentBoundaries[rightBoundaryIndex];

      if (canUseSurroundingBoundaries) {
        refinedCenterXs.add(
          (boundaryCandidates[leftBoundaryIndex].position +
                  boundaryCandidates[rightBoundaryIndex].position) /
              2,
        );
      } else {
        refinedCenterXs.add(fallbackPositions[markerIndex].dx);
      }
    }

    return refinedCenterXs;
  }

  /// Returns C4's index, or `-1` if the current visible range lacks C4.
  int findC4Index(List<PianoKeyMarker> markers) {
    for (int index = 0; index < markers.length; index++) {
      PianoKeyMarker marker = markers[index];

      if (marker.noteLetter == 'C' && marker.octaveNumber == 4) {
        return index;
      }
    }

    return -1;
  }

  /// Returns the median of [values], or zero for an empty list.
  double calculateMedian(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    List<double> orderedValues = List<double>.from(values);
    orderedValues.sort();

    int middleIndex = orderedValues.length ~/ 2;

    if (orderedValues.length.isOdd) {
      return orderedValues[middleIndex];
    }

    return (orderedValues[middleIndex - 1] + orderedValues[middleIndex]) / 2;
  }

  /// Packages unchanged markers when image-based seam refinement is unsafe.
  WhiteKeyBoundaryDetectionResult fallbackResult({
    required List<PianoKeyMarker> fallbackMarkers,
    required int requiredBoundaryCount,
    int detectedBoundaryCount = 0,
  }) {
    return WhiteKeyBoundaryDetectionResult(
      markers: fallbackMarkers,
      detectedBoundaryCount: detectedBoundaryCount,
      requiredBoundaryCount: requiredBoundaryCount,
      usedDetectedBoundaries: false,
    );
  }
}

/// One possible white-key seam and its measured darkness contrast.
class WhiteKeyBoundaryCandidate {
  const WhiteKeyBoundaryCandidate({
    required this.position,
    required this.contrast,
  });

  /// Horizontal position in the rectified keyboard image.
  final double position;
  /// Brightness difference between the seam and its neighboring columns.
  final double contrast;
}
