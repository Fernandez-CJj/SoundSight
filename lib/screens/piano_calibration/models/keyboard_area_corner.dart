/// Identifies one draggable corner of the calibrated keyboard quadrilateral.
enum KeyboardAreaCorner {
  /// Upper-left corner in camera-image coordinates.
  topLeft,

  /// Upper-right corner in camera-image coordinates.
  topRight,

  /// Lower-right corner in camera-image coordinates.
  bottomRight,

  /// Lower-left corner in camera-image coordinates.
  bottomLeft,
}
