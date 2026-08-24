import 'flyaway_finger.dart';

/// Stores one finger's normalized image-space height for one camera frame.
/// This is a measurement only. It does not yet decide whether the finger
/// should be considered a flyaway finger.
class FingerMeasurement {
  const FingerMeasurement({
    required this.finger,
    required this.normalizedHeight,
  });

  /// Identifies which finger was measured.
  final FlyawayFinger finger;

  /// Signed fingertip height relative to the detected palm length.
  /// This value can be negative or greater than 1.0. Normalized means that
  /// it is relative to hand size, not that it is restricted from 0.0 to 1.0.
  final double normalizedHeight;
}
