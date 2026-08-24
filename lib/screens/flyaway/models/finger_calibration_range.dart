/// Stores the lowest and highest normal height recorded for one finger.
class FingerCalibrationRange {
  FingerCalibrationRange({
    required this.minimumHeight,
    required this.maximumHeight,
  });

  double minimumHeight;
  double maximumHeight;

  /// Expands the normal range when a new measurement is outside it.
  void includeHeight(double height) {
    if (height < minimumHeight) {
      minimumHeight = height;
    } else if (height > maximumHeight) {
      maximumHeight = height;
    }
  }
}
