import 'flyaway_finger.dart';

/// Stores one finger's relative-depth measurement for one camera frame.
/// This model does not decide whether the finger is a flyaway finger.
class FingerMeasurement {
  const FingerMeasurement({
    required this.finger,
    required this.relativeDepth,
  });

  /// Identifies which finger was measured.
  final FlyawayFinger finger;

  /// Estimated depth difference between the finger base and fingertip.
  final double relativeDepth;
}
