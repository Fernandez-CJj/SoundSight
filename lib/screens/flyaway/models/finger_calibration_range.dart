/// Stores one finger's resting, total-lift, and independent-lift references.
class FingerCalibrationRange {
  FingerCalibrationRange({
    required this.restingDepth,
    this.maximumNormalLift = 0,
    this.maximumNormalIndependentLift = 0,
    this.normalMovementSampleCount = 0,
  });

  /// Stable depth recorded while the finger rests on a piano key.
  final double restingDepth;

  /// Largest lift amount observed during normal movement calibration.
  double maximumNormalLift;

  /// Largest lift above neighboring fingers during normal movement.
  double maximumNormalIndependentLift;

  /// Number of normal-movement samples collected for this finger.
  int normalMovementSampleCount;

  /// Includes one normal movement sample in this finger's calibration.
  void includeNormalMovement({
    required double liftAmount,
    required double independentLift,
  }) {
    normalMovementSampleCount++;

    if (liftAmount > maximumNormalLift) {
      maximumNormalLift = liftAmount;
    }

    if (independentLift > maximumNormalIndependentLift) {
      maximumNormalIndependentLift = independentLift;
    }
  }
}
