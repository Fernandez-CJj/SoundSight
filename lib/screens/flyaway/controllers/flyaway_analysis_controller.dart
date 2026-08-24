import 'dart:math' as math;

import 'package:hand_detection/hand_detection.dart';

import '../models/finger_measurement.dart';
import '../models/flyaway_finger.dart';

/// Converts one detected hand's landmarks into finger-height measurements.
/// This controller currently measures positions only. Smoothing, calibration,
/// and the final flyaway decision will be added in later phases.
class FlyawayAnalysisController {
  /// Measures all five fingers of one detected hand.
  List<FingerMeasurement> measureHand(Hand hand) {
    final wrist = hand.landmarks[0];
    final middleFingerBase = hand.landmarks[9];

    // Use wrist-to-middle-finger-base distance as a reference for hand size.
    final palmHorizontalDistance = middleFingerBase.x - wrist.x;
    final palmVerticalDistance = middleFingerBase.y - wrist.y;

    final palmLength = math.sqrt(
      palmHorizontalDistance * palmHorizontalDistance +
          palmVerticalDistance * palmVerticalDistance,
    );

    // Ignore an invalid measurement instead of dividing by zero.
    if (palmLength <= 0) {
      return <FingerMeasurement>[];
    }

    // Apply the same height calculation to all five finger definitions.
    return FlyawayFinger.values.map((finger) {
      final fingerBase = hand.landmarks[finger.baseLandmarkIndex];
      final fingerTip = hand.landmarks[finger.tipLandmarkIndex];

      // Image y-coordinates increase downward, so a tip above its base
      // produces a positive value.
      final fingerHeight = fingerBase.y - fingerTip.y;

      // Make the result relative to hand size instead of raw camera pixels.
      final normalizedHeight = fingerHeight / palmLength;

      return FingerMeasurement(
        finger: finger,
        normalizedHeight: normalizedHeight,
      );
    }).toList();
  }
}
