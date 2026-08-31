import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/keyboard_search_band.dart';

/// Creates temporary masks for several possible vertical keyboard locations.
class KeyboardSearchBandMasker {
  /// Copies [completeMask] and clears every row outside [searchBand].
  ///
  /// The caller owns the returned matrix and must dispose it.
  cv.Mat createBandMask(cv.Mat completeMask, KeyboardSearchBand searchBand) {
    cv.Mat bandMask = cv.Mat.fromMat(completeMask, copy: true);

    int topBoundary = (completeMask.rows * searchBand.topFraction).round();

    int bottomBoundary = (completeMask.rows * searchBand.bottomFraction)
        .round();

    cv.Rect ignoredTopRegion = cv.Rect(0, 0, completeMask.cols, topBoundary);

    cv.Rect ignoredBottomRegion = cv.Rect(
      0,
      bottomBoundary,
      completeMask.cols,
      completeMask.rows - bottomBoundary,
    );

    cv.Scalar ignoredColor = cv.Scalar.all(0);

    try {
      cv.rectangle(
        bandMask,
        ignoredTopRegion,
        ignoredColor,
        thickness: cv.FILLED,
      );

      cv.rectangle(
        bandMask,
        ignoredBottomRegion,
        ignoredColor,
        thickness: cv.FILLED,
      );

      return bandMask;
    } catch (_) {
      bandMask.dispose();
      rethrow;
    } finally {
      ignoredColor.dispose();
      ignoredBottomRegion.dispose();
      ignoredTopRegion.dispose();
    }
  }
}
