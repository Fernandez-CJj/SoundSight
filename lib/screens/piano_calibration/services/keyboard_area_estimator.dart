import 'dart:ui';

import '../models/black_key_candidate.dart';
import '../models/keyboard_area_corners.dart';

/// Estimates the initial draggable keyboard quadrilateral from black keys.
class KeyboardAreaEstimator {
  final double topPaddingScale = 0.10;
  final double bottomExtensionScale = 0.70;

  /// Builds playable-area corners using the outer candidates and perspective.
  ///
  /// Medians from candidates on both sides make the top and bottom edges less
  /// sensitive to one badly sized contour.
  KeyboardAreaCorners estimate({
    required List<List<BlackKeyCandidate>> groups,
    required int imageWidth,
    required int imageHeight,
  }) {
    List<BlackKeyCandidate> candidates = [];

    for (List<BlackKeyCandidate> group in groups) {
      candidates.addAll(group);
    }

    candidates.sort((firstCandidate, secondCandidate) {
      return firstCandidate.left.compareTo(secondCandidate.left);
    });

    if (candidates.length < 2) {
      throw StateError('At least two black-key candidates are required.');
    }

    double whiteKeyWidth = estimateWhiteKeyWidth(candidates);

    BlackKeyCandidate firstCandidate = candidates.first;
    BlackKeyCandidate lastCandidate = candidates.last;

    double firstCenter = firstCandidate.left + (firstCandidate.width / 2);

    double lastCenter = lastCandidate.left + (lastCandidate.width / 2);

    double leftBoundary = keepWithinImage(
      firstCenter - whiteKeyWidth,
      imageWidth,
    );

    double rightBoundary = keepWithinImage(
      lastCenter + whiteKeyWidth,
      imageWidth,
    );

    int sideCandidateCount = 3;

    if (candidates.length < 6) {
      sideCandidateCount = candidates.length ~/ 2;
    }

    List<BlackKeyCandidate> leftCandidates = candidates.sublist(
      0,
      sideCandidateCount,
    );

    List<BlackKeyCandidate> rightCandidates = candidates.sublist(
      candidates.length - sideCandidateCount,
    );

    List<double> leftTops = [];
    List<double> leftBottoms = [];
    List<double> leftHeights = [];

    for (BlackKeyCandidate candidate in leftCandidates) {
      leftTops.add(candidate.top.toDouble());

      leftBottoms.add((candidate.top + candidate.height).toDouble());

      leftHeights.add(candidate.height.toDouble());
    }

    List<double> rightTops = [];
    List<double> rightBottoms = [];
    List<double> rightHeights = [];

    for (BlackKeyCandidate candidate in rightCandidates) {
      rightTops.add(candidate.top.toDouble());

      rightBottoms.add((candidate.top + candidate.height).toDouble());

      rightHeights.add(candidate.height.toDouble());
    }

    double leftTop = calculateMedian(leftTops);
    double leftBottom = calculateMedian(leftBottoms);
    double leftHeight = calculateMedian(leftHeights);

    double rightTop = calculateMedian(rightTops);
    double rightBottom = calculateMedian(rightBottoms);
    double rightHeight = calculateMedian(rightHeights);

    double topLeftY = keepWithinImage(
      leftTop - (leftHeight * topPaddingScale),
      imageHeight,
    );

    double topRightY = keepWithinImage(
      rightTop - (rightHeight * topPaddingScale),
      imageHeight,
    );

    double bottomLeftY = keepWithinImage(
      leftBottom + (leftHeight * bottomExtensionScale),
      imageHeight,
    );

    double bottomRightY = keepWithinImage(
      rightBottom + (rightHeight * bottomExtensionScale),
      imageHeight,
    );

    return KeyboardAreaCorners(
      topLeft: Offset(leftBoundary, topLeftY),
      topRight: Offset(rightBoundary, topRightY),
      bottomRight: Offset(rightBoundary, bottomRightY),
      bottomLeft: Offset(leftBoundary, bottomLeftY),
      sourceImageWidth: imageWidth,
      sourceImageHeight: imageHeight,
    );
  }

  /// Estimates one white-key width from median adjacent black-key spacing.
  double estimateWhiteKeyWidth(List<BlackKeyCandidate> candidates) {
    List<double> centerGaps = [];

    for (int index = 1; index < candidates.length; index++) {
      BlackKeyCandidate previousCandidate = candidates[index - 1];
      BlackKeyCandidate currentCandidate = candidates[index];

      double previousCenter =
          previousCandidate.left + (previousCandidate.width / 2);

      double currentCenter =
          currentCandidate.left + (currentCandidate.width / 2);

      centerGaps.add(currentCenter - previousCenter);
    }

    return calculateMedian(centerGaps);
  }

  /// Clamps a coordinate to valid image bounds.
  double keepWithinImage(double value, int imageSize) {
    if (value < 0) {
      return 0;
    }

    if (value > imageSize) {
      return imageSize.toDouble();
    }

    return value;
  }

  /// Returns the median, averaging the two middle values for an even list.
  double calculateMedian(List<double> values) {
    List<double> sortedValues = List<double>.from(values);
    sortedValues.sort();

    int middleIndex = sortedValues.length ~/ 2;

    if (sortedValues.length.isOdd) {
      return sortedValues[middleIndex];
    }

    double valueBeforeMiddle = sortedValues[middleIndex - 1];
    double valueAfterMiddle = sortedValues[middleIndex];

    return (valueBeforeMiddle + valueAfterMiddle) / 2;
  }
}
