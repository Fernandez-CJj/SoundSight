import 'package:hand_detection/hand_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter_litert/flutter_litert.dart';

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

    return detector.detectFromCameraImage(
      image,
      rotation: rotation,

      // Limit the analyzed frame size to balance speed and landmark detail.
      maxDim: 640,
    );
  }

  /// Releases the detector's native machine-learning resources.
  Future<void> dispose() async {
    await handDetector?.dispose();
    handDetector = null;
  }
}
