import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Converts camera luminance planes into small OpenCV grayscale matrices.
///
/// Limiting the largest dimension keeps real-time detection responsive while
/// preserving the aspect ratio used by all following geometry calculations.
class CameraImageConverter {
  /// Maximum width or height processed by the detector.
  final int maximumProcessingDimension = 640;

  /// Samples the camera's brightness plane into an 8-bit grayscale [cv.Mat].
  ///
  /// Camera row/pixel strides are respected because their buffers are not
  /// guaranteed to be tightly packed on every Android device.
  cv.Mat convertToGrayscale(CameraImage cameraImage) {
    Plane brightnessPlane = cameraImage.planes.first;

    int imageWidth = cameraImage.width;
    int imageHeight = cameraImage.height;
    int rowStride = brightnessPlane.bytesPerRow;
    int pixelStride = brightnessPlane.bytesPerPixel ?? 1;

    int largestDimension = imageWidth;

    if (imageHeight > imageWidth) {
      largestDimension = imageHeight;
    }

    double resizeScale = 1;

    if (largestDimension > maximumProcessingDimension) {
      resizeScale = maximumProcessingDimension / largestDimension;
    }

    int processingWidth = (imageWidth * resizeScale).round();
    int processingHeight = (imageHeight * resizeScale).round();

    Uint8List grayscaleBytes = Uint8List(processingWidth * processingHeight);

    double horizontalScale = imageWidth / processingWidth;
    double verticalScale = imageHeight / processingHeight;

    for (int row = 0; row < processingHeight; row++) {
      int sourceRow = (row * verticalScale).floor();
      int sourceRowStart = sourceRow * rowStride;
      int destinationRowStart = row * processingWidth;

      for (int column = 0; column < processingWidth; column++) {
        int sourceColumn = (column * horizontalScale).floor();

        int sourceIndex = sourceRowStart + (sourceColumn * pixelStride);

        int destinationIndex = destinationRowStart + column;

        grayscaleBytes[destinationIndex] = brightnessPlane.bytes[sourceIndex];
      }
    }

    return cv.Mat.fromList(
      processingHeight,
      processingWidth,
      cv.MatType.CV_8UC1,
      grayscaleBytes,
    );
  }
}
