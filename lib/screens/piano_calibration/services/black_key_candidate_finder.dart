import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/black_key_candidate.dart';

/// Extracts plausible black-key rectangles from a thresholded dark-region mask.
class BlackKeyCandidateFinder {
  final double minimumWidthFraction = 0.005;
  final double maximumWidthFraction = 0.12;
  final double minimumHeightFraction = 0.08;
  final double maximumHeightFraction = 0.70;
  final double minimumAspectRatio = 1.2;
  final double maximumAspectRatio = 10;
  final double minimumFillRatio = 0.35;

  /// Finds external contours and filters them by size, shape, and fill ratio.
  ///
  /// Returned candidates are sorted from left to right for pattern analysis.
  List<BlackKeyCandidate> findCandidates(cv.Mat darkRegionMask) {
    var (contours, hierarchy) = cv.findContours(
      darkRegionMask,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );

    try {
      List<BlackKeyCandidate> candidates = [];

      double minimumWidth = darkRegionMask.cols * minimumWidthFraction;

      double maximumWidth = darkRegionMask.cols * maximumWidthFraction;

      double minimumHeight = darkRegionMask.rows * minimumHeightFraction;

      double maximumHeight = darkRegionMask.rows * maximumHeightFraction;

      for (int index = 0; index < contours.length; index++) {
        cv.VecPoint contour = contours[index];
        cv.Rect bounds = cv.boundingRect(contour);

        try {
          if (bounds.width < minimumWidth || bounds.width > maximumWidth) {
            continue;
          }

          if (bounds.height < minimumHeight || bounds.height > maximumHeight) {
            continue;
          }

          double aspectRatio = bounds.height / bounds.width;

          if (aspectRatio < minimumAspectRatio ||
              aspectRatio > maximumAspectRatio) {
            continue;
          }

          double contourArea = cv.contourArea(contour);

          double rectangleArea = (bounds.width * bounds.height).toDouble();

          double fillRatio = contourArea / rectangleArea;

          if (fillRatio < minimumFillRatio) {
            continue;
          }

          candidates.add(
            BlackKeyCandidate(
              left: bounds.x,
              top: bounds.y,
              width: bounds.width,
              height: bounds.height,
              fillRatio: fillRatio,
            ),
          );
        } finally {
          bounds.dispose();
        }
      }

      candidates.sort((firstCandidate, secondCandidate) {
        return firstCandidate.left.compareTo(secondCandidate.left);
      });

      return candidates;
    } finally {
      hierarchy.dispose();
      contours.dispose();
    }
  }
}
