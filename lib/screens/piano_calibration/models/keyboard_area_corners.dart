import 'dart:ui';

/// Four source-image points that bound the playable keyboard area.
///
/// The source dimensions allow the points to be scaled correctly when the
/// camera preview is displayed at a different size.
class KeyboardAreaCorners {
  KeyboardAreaCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.sourceImageWidth,
    required this.sourceImageHeight,
  });

  /// Upper-left point in source-image pixels.
  final Offset topLeft;
  /// Upper-right point in source-image pixels.
  final Offset topRight;
  /// Lower-right point in source-image pixels.
  final Offset bottomRight;
  /// Lower-left point in source-image pixels.
  final Offset bottomLeft;

  /// Width of the image in which the corners were measured.
  final int sourceImageWidth;
  /// Height of the image in which the corners were measured.
  final int sourceImageHeight;
}
