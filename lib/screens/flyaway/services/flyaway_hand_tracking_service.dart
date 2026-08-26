import 'package:hand_detection/hand_detection.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

/// Manages the hand detector and converts camera frames into detected hands.
/// The service owns the detector from initialization until disposal.
class FlyawayHandTrackingService {
  HandDetector? handDetector;

  /// Reports whether the detector exists and is ready to process frames.
  bool get isInitialized {
    final detector = handDetector;

    if (detector == null) {
      return false;
    } else {
      return detector.isReady;
    }
  }

  /// Creates a detector configured for landmarks and up to two hands.
  Future<void> initialize() async {
    // Prevent creating a second detector if this service was already initialized.
    if (handDetector != null) return;

    handDetector = await HandDetector.create(
      mode: HandMode.boxesAndLandmarks,
      landmarkModel: HandLandmarkModel.full,
      detectorConf: 0.5,
      maxDetections: 2,
      minLandmarkScore: 0.5,
      enableTracking: true,
    );
  }

  /// Processes one camera frame and returns its detected hands.
  Future<List<Hand>> detectHands({
    required CameraImage image,
    required CameraFrameRotation? rotation,
  }) async {
    final detector = handDetector;

    // Return no results if detection was requested before initialization.
    if (detector == null || !detector.isReady) {
      return <Hand>[];
    }

    final hands = await detector.detectFromCameraImage(
      image,
      rotation: rotation,

      // Limit the analyzed frame size to balance speed and landmark detail.
      maxDim: 640,
    );

    return removeDuplicateHands(hands);
  }

  /// Removes detections whose landmarks represent the same physical hand.
  List<Hand> removeDuplicateHands(List<Hand> hands) {
    final uniqueHands = <Hand>[];

    for (final hand in hands) {
      var duplicateIndex = -1;

      for (
        var uniqueIndex = 0;
        uniqueIndex < uniqueHands.length;
        uniqueIndex++
      ) {
        final existingHand = uniqueHands[uniqueIndex];

        if (handsAreNearlyIdentical(hand, existingHand)) {
          duplicateIndex = uniqueIndex;
          break;
        }
      }

      if (duplicateIndex == -1) {
        uniqueHands.add(hand);
      } else {
        final existingHand = uniqueHands[duplicateIndex];

        if (hand.score > existingHand.score) {
          uniqueHands[duplicateIndex] = hand;
        }
      }
    }

    return uniqueHands;
  }

  /// Checks whether two detections have nearly overlapping landmarks.
  bool handsAreNearlyIdentical(Hand firstHand, Hand secondHand) {
    if (firstHand.landmarks.length != secondHand.landmarks.length) {
      return false;
    }

    if (firstHand.landmarks.length < 10) {
      return false;
    }

    final firstPalmLength = landmarkDistance(
      firstHand.landmarks[0],
      firstHand.landmarks[9],
    );

    final secondPalmLength = landmarkDistance(
      secondHand.landmarks[0],
      secondHand.landmarks[9],
    );

    final averagePalmLength = (firstPalmLength + secondPalmLength) / 2;

    if (averagePalmLength <= 0) {
      return false;
    }

    var totalLandmarkDistance = 0.0;

    for (
      var landmarkIndex = 0;
      landmarkIndex < firstHand.landmarks.length;
      landmarkIndex++
    ) {
      totalLandmarkDistance += landmarkDistance(
        firstHand.landmarks[landmarkIndex],
        secondHand.landmarks[landmarkIndex],
      );
    }

    final averageLandmarkDistance =
        totalLandmarkDistance / firstHand.landmarks.length;

    final normalizedDistance = averageLandmarkDistance / averagePalmLength;

    const duplicateDistanceLimit = 0.20;

    if (normalizedDistance < duplicateDistanceLimit) {
      return true;
    } else {
      return false;
    }
  }

  /// Calculates the pixel distance between two hand landmarks.
  double landmarkDistance(
    HandLandmark firstLandmark,
    HandLandmark secondLandmark,
  ) {
    final horizontalDistance = secondLandmark.x - firstLandmark.x;

    final verticalDistance = secondLandmark.y - firstLandmark.y;

    return math.sqrt(
      horizontalDistance * horizontalDistance +
          verticalDistance * verticalDistance,
    );
  }

  /// Releases the detector's native machine-learning resources.
  Future<void> dispose() async {
    await handDetector?.dispose();
    handDetector = null;
  }
}
