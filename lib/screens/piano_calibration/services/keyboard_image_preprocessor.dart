import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Produces a binary mask in which dark, black-key-like regions are white.
class KeyboardImagePreprocessor {
  final int blurKernelSize = 5;
  final int adaptiveBlockSize = 31;
  final double adaptiveConstant = 7;

  final double searchBandTopFraction = 0.40;
  final double searchBandBottomFraction = 0.72;

  /// Blurs noise, applies adaptive thresholding, and limits the search height.
  ///
  /// The caller owns the returned OpenCV matrix and must dispose it.
  cv.Mat createDarkRegionMask(cv.Mat grayscaleImage) {
    cv.Mat blurredImage = cv.gaussianBlur(grayscaleImage, (
      blurKernelSize,
      blurKernelSize,
    ), 0);

    try {
      cv.Mat darkRegionMask = cv.adaptiveThreshold(
        blurredImage,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY_INV,
        adaptiveBlockSize,
        adaptiveConstant,
      );

      try {
        limitToBlackKeySearchBand(darkRegionMask);
        return darkRegionMask;
      } catch (error) {
        darkRegionMask.dispose();
        rethrow;
      }
    } finally {
      blurredImage.dispose();
    }
  }

  /// Clears mask pixels outside the broad vertical black-key search region.
  void limitToBlackKeySearchBand(cv.Mat darkRegionMask) {
    int topBoundary = (darkRegionMask.rows * searchBandTopFraction).round();

    int bottomBoundary = (darkRegionMask.rows * searchBandBottomFraction)
        .round();

    cv.Rect ignoredTopRegion = cv.Rect(0, 0, darkRegionMask.cols, topBoundary);

    cv.Rect ignoredBottomRegion = cv.Rect(
      0,
      bottomBoundary,
      darkRegionMask.cols,
      darkRegionMask.rows - bottomBoundary,
    );

    cv.Scalar ignoredColor = cv.Scalar.all(0);

    try {
      cv.rectangle(
        darkRegionMask,
        ignoredTopRegion,
        ignoredColor,
        thickness: cv.FILLED,
      );

      cv.rectangle(
        darkRegionMask,
        ignoredBottomRegion,
        ignoredColor,
        thickness: cv.FILLED,
      );
    } finally {
      ignoredColor.dispose();
      ignoredBottomRegion.dispose();
      ignoredTopRegion.dispose();
    }
  }
}
