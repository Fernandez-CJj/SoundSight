import 'dart:typed_data';

/// Grayscale snapshot retained from the stable detection frame.
///
/// Services use this immutable byte buffer to refine key boundaries after
/// live camera processing has stopped.
class CalibrationFrame {
  const CalibrationFrame({
    required this.width,
    required this.height,
    required this.grayscaleBytes,
  });

  /// Source-frame width in pixels.
  final int width;
  /// Source-frame height in pixels.
  final int height;
  /// Row-major, one-byte-per-pixel grayscale image data.
  final Uint8List grayscaleBytes;
}
