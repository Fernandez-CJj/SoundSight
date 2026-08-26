import 'package:hand_detection/hand_detection.dart';

import '../models/finger_measurement.dart';
import '../models/flyaway_finger.dart';

/// Converts one detected hand's landmarks into finger-depth measurements.
class FlyawayAnalysisController {
  /// Measures the relative depth of all five fingers.
  List<FingerMeasurement> measureHand(Hand hand) {
    return FlyawayFinger.values.map((finger) {
      final fingerBase = hand.landmarks[finger.baseLandmarkIndex];
      final fingerTip = hand.landmarks[finger.tipLandmarkIndex];

      final relativeDepth = fingerBase.z - fingerTip.z;

      return FingerMeasurement(
        finger: finger,
        relativeDepth: relativeDepth,
      );
    }).toList();
  }
}
