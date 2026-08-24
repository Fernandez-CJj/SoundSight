import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:hand_detection/hand_detection.dart';

import '../controllers/flyaway_analysis_controller.dart';
import '../models/finger_measurement.dart';
import '../models/finger_calibration_range.dart';
import '../models/flyaway_finger.dart';
import '../services/flyaway_hand_tracking_service.dart';
import '../widgets/hand_landmark_painter.dart';
import '../models/flyaway_duration_tracker.dart';

/// Runs the live camera-based Flyaway setup and analysis screen.
///
/// This screen coordinates camera initialization, hand detection, landmark
/// drawing, and per-finger measurements.
class FlyawaySetupScreen extends StatefulWidget {
  const FlyawaySetupScreen({super.key});

  @override
  State<FlyawaySetupScreen> createState() {
    return _FlyawaySetupScreenState();
  }
}

/// Stores the changing camera, detector, and measurement state for the screen.
class _FlyawaySetupScreenState extends State<FlyawaySetupScreen> {
  /// Controls the selected phone camera and its live image stream.
  CameraController? cameraController;

  /// Contains an error message when the camera cannot be initialized.
  String? cameraError;

  /// Owns and communicates with the machine-learning hand detector.
  final FlyawayHandTrackingService handTrackingService =
      FlyawayHandTrackingService();

  /// Indicates whether the hand detector has finished initializing.
  bool handDetectorReady = false;

  /// Contains an error message when hand detection fails.
  String? handDetectorError;

  /// Indicates whether camera frames are currently being sent for detection.
  bool handDetectionStreamStarted = false;

  /// Prevents two camera frames from being analyzed at the same time.
  bool processingCameraFrame = false;

  /// Hands detected in the latest processed camera frame.
  List<Hand> detectedHands = <Hand>[];

  /// Finger measurements grouped by detected hand.
  /// The outer list represents hands. Each inner list contains the five
  /// finger measurements belonging to one detected hand.
  List<List<FingerMeasurement>> handMeasurements = <List<FingerMeasurement>>[];

  final Map<Handedness, List<FingerMeasurement>> previousHandMeasurements =
      <Handedness, List<FingerMeasurement>>{};

  bool calibrationActive = false;

  final Map<Handedness, Map<FlyawayFinger, FingerCalibrationRange>>
  calibrationRanges =
      <Handedness, Map<FlyawayFinger, FingerCalibrationRange>>{};

  /// Size of the rotated and resized image analyzed by the detector.
  Size? detectionImageSize;

  /// Converts detected hand landmarks into normalized finger measurements.
  final FlyawayAnalysisController analysisController =
      FlyawayAnalysisController();

  final Map<Handedness, Map<FlyawayFinger, FlyawayDurationTracker>>
  flyawayTrackers = <Handedness, Map<FlyawayFinger, FlyawayDurationTracker>>{};

  Map<Handedness, Set<FlyawayFinger>> confirmedFlyawayFingers =
      <Handedness, Set<FlyawayFinger>>{};

  @override
  void initState() {
    super.initState();

    // Start the asynchronous camera and detector initialization sequence.
    initializeScreen();

    // Hide the Android system bars while using the camera screen.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final cameraStatus = buildCameraStatus();
    final handDetectorStatus = getHandDetectorStatus();

    return Scaffold(
      body: Stack(
        children: [
          // Bottom layer: live camera, loading indicator, or camera error.
          Positioned.fill(child: Center(child: cameraStatus)),

          // Middle layer: circles drawn over detected hand landmarks.
          buildHandLandmarkOverlay(),

          // Middle layer: temporary finger-height measurement display.
          buildMeasurementPanel(),

          // Top-center layer: starts or finishes calibration.
          buildCalibrationButton(),

          // Top-left layer: button used to leave the camera screen.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
              ),
            ),
          ),

          // Top-right layer: detector loading, error, and hand-count status.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    handDetectorStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the button that starts or finishes calibration.
  Widget buildCalibrationButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: toggleCalibration,
            child: Text(getCalibrationButtonLabel()),
          ),
        ),
      ),
    );
  }

  /// Returns text describing what the calibration button will do.
  String getCalibrationButtonLabel() {
    if (calibrationActive) {
      return 'Finish calibration';
    } else {
      return 'Start calibration';
    }
  }

  /// Switches calibration between running and stopped.
  void toggleCalibration() {
    setState(() {
      if (calibrationActive) {
        calibrationActive = false;
      } else {
        calibrationRanges.clear();
        previousHandMeasurements.clear();
        flyawayTrackers.clear();
        confirmedFlyawayFingers.clear();
        calibrationActive = true;
      }
    });
  }

  /// Returns the appropriate camera widget for the camera's current state.
  Widget buildCameraStatus() {
    final controller = cameraController;
    final cameraReady = controller?.value.isInitialized ?? false;

    if (cameraReady && controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.aspectRatio,
            height: 1,
            child: CameraPreview(controller),
          ),
        ),
      );
    } else if (cameraError != null) {
      return Text(cameraError!);
    } else {
      return const CircularProgressIndicator();
    }
  }

  /// Returns the message displayed in the detector-status panel.
  String getHandDetectorStatus() {
    if (handDetectorError != null) {
      return handDetectorError!;
    } else if (cameraError != null) {
      return 'Hand detector not started';
    } else if (!handDetectorReady) {
      return 'Loading hand detector...';
    } else if (!handDetectionStreamStarted) {
      return 'Starting hand detection...';
    } else if (detectedHands.isEmpty) {
      return 'No hands detected';
    } else if (detectedHands.length == 1) {
      return '1 hand detected';
    } else {
      return '${detectedHands.length} hands detected';
    }
  }

  /// Runs the required startup operations in order.
  Future<void> initializeScreen() async {
    // The mounted camera view is intended to be used in landscape.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) {
      return;
    }

    await initializeCamera();

    // Do not continue when the screen was closed or camera setup failed.
    if (!mounted || cameraController == null) {
      return;
    }

    await initializeHandTracking();

    // Do not start frame streaming when detector initialization failed.
    if (!mounted || !handDetectorReady) {
      return;
    }

    await startHandDetectionStream();
  }

  /// Finds, initializes, and configures the rear camera.
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          cameraError = 'No camera is available on this device.';
        });

        return;
      }

      // Prefer the rear camera and fall back to the first available camera.
      final rearCamera = cameras.firstWhere(
        (camera) {
          return camera.lensDirection == CameraLensDirection.back;
        },
        orElse: () {
          return cameras.first;
        },
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      final minimumZoom = await controller.getMinZoomLevel();
      final maximumZoom = await controller.getMaxZoomLevel();

      // Keep 1× zoom when supported, otherwise use the nearest valid level.
      final oneXZoom = 1.0.clamp(minimumZoom, maximumZoom).toDouble();

      await controller.setZoomLevel(oneXZoom);

      // The screen may have been closed while camera setup was running.
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        cameraController = controller;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        cameraError = error.description ?? 'The camera could not be opened.';
      });
    }
  }

  /// Creates and prepares the hand detector.
  Future<void> initializeHandTracking() async {
    try {
      await handTrackingService.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        handDetectorReady = handTrackingService.isInitialized;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        handDetectorError = 'Hand detector could not start: $error';
      });
    }
  }

  /// Starts continuously receiving raw frames from the camera.
  Future<void> startHandDetectionStream() async {
    final controller = cameraController;

    // Streaming requires an initialized controller that is not already active.
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    try {
      // Flutter calls processCameraFrame whenever a new image is available.
      await controller.startImageStream(processCameraFrame);

      if (!mounted) {
        return;
      }

      setState(() {
        handDetectionStreamStarted = true;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        handDetectorError =
            error.description ?? 'The camera image stream could not start.';
      });
    }
  }

  /// Detects hands and calculates finger measurements for one camera frame.
  Future<void> processCameraFrame(CameraImage image) async {
    // Drop the frame if another frame is processing or the detector is unready.
    if (processingCameraFrame || !handDetectorReady) {
      return;
    }

    final controller = cameraController;

    if (controller == null) {
      return;
    }

    processingCameraFrame = true;

    try {
      // Determine how the raw camera frame must be rotated for detection.
      final rotation = rotationForFrame(
        width: image.width,
        height: image.height,
        sensorOrientation: controller.description.sensorOrientation,
        isFrontCamera:
            controller.description.lensDirection == CameraLensDirection.front,
        deviceOrientation: controller.value.deviceOrientation,
      );

      // Calculate the coordinate-space size used by the detector.
      final currentDetectionImageSize = detectionSize(
        width: image.width,
        height: image.height,
        rotation: rotation,
        maxDim: 640,
      );

      // Run hand detection on the current camera frame.
      final hands = await handTrackingService.detectHands(
        image: image,
        rotation: rotation,
      );

      final orderedHands = orderHandsByHandedness(hands);

      if (!mounted) {
        return;
      }

      // Produce one five-finger measurement list for every detected hand.
      final currentHandMeasurements = <List<FingerMeasurement>>[];

      for (final hand in orderedHands) {
        final rawMeasurements = analysisController.measureHand(hand);

        final smoothedMeasurements = smoothHandMeasurements(
          hand,
          rawMeasurements,
        );

        currentHandMeasurements.add(smoothedMeasurements);
      }

      collectCalibrationMeasurements(orderedHands, currentHandMeasurements);

      final currentFlyawayFingers = updateFlyawayTrackers(
        orderedHands,
        currentHandMeasurements,
      );
      storePreviousMeasurements(orderedHands, currentHandMeasurements);
      // Store all results from the same camera frame together.
      setState(() {
        detectedHands = orderedHands;
        detectionImageSize = currentDetectionImageSize;
        handMeasurements = currentHandMeasurements;
        confirmedFlyawayFingers = currentFlyawayFingers;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        handDetectorError = 'Hand detection failed: $error';
      });
    } finally {
      // Always permit another frame, whether detection succeeded or failed.
      processingCameraFrame = false;
    }
  }

  /// Places the left hand before the right hand.
  /// Hands without a handedness result are placed last.
  List<Hand> orderHandsByHandedness(List<Hand> hands) {
    final orderedHands = <Hand>[];

    for (final hand in hands) {
      if (hand.handedness == Handedness.left) {
        orderedHands.add(hand);
      }
    }

    for (final hand in hands) {
      if (hand.handedness == Handedness.right) {
        orderedHands.add(hand);
      }
    }

    for (final hand in hands) {
      if (hand.handedness == null) {
        orderedHands.add(hand);
      }
    }

    return orderedHands;
  }

  /// Combines the previous and current measurements to reduce jitter.
  List<FingerMeasurement> smoothHandMeasurements(
    Hand hand,
    List<FingerMeasurement> currentMeasurements,
  ) {
    final handedness = hand.handedness;

    if (handedness == null) {
      return currentMeasurements;
    }

    final previousMeasurements = previousHandMeasurements[handedness];

    if (previousMeasurements == null) {
      return currentMeasurements;
    }

    if (previousMeasurements.length != currentMeasurements.length) {
      return currentMeasurements;
    }

    const previousWeight = 0.6;
    const currentWeight = 0.4;

    final smoothedMeasurements = <FingerMeasurement>[];

    for (
      var fingerIndex = 0;
      fingerIndex < currentMeasurements.length;
      fingerIndex++
    ) {
      final previousMeasurement = previousMeasurements[fingerIndex];
      final currentMeasurement = currentMeasurements[fingerIndex];

      final smoothedHeight =
          previousMeasurement.normalizedHeight * previousWeight +
          currentMeasurement.normalizedHeight * currentWeight;

      final smoothedMeasurement = FingerMeasurement(
        finger: currentMeasurement.finger,
        normalizedHeight: smoothedHeight,
      );

      smoothedMeasurements.add(smoothedMeasurement);
    }

    return smoothedMeasurements;
  }

  /// Saves each hand's measurements for the next camera frame.
  void storePreviousMeasurements(
    List<Hand> hands,
    List<List<FingerMeasurement>> measurements,
  ) {
    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      if (handIndex >= measurements.length) {
        return;
      }

      final handedness = hands[handIndex].handedness;

      if (handedness != null) {
        previousHandMeasurements[handedness] = List<FingerMeasurement>.from(
          measurements[handIndex],
        );
      }
    }
  }

  /// Adds the current finger measurements to the active calibration.
  void collectCalibrationMeasurements(
    List<Hand> hands,
    List<List<FingerMeasurement>> measurements,
  ) {
    if (!calibrationActive) {
      return;
    }

    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      if (handIndex >= measurements.length) {
        return;
      }

      final handedness = hands[handIndex].handedness;

      if (handedness != null) {
        var fingerRanges = calibrationRanges[handedness];

        if (fingerRanges == null) {
          fingerRanges = <FlyawayFinger, FingerCalibrationRange>{};
          calibrationRanges[handedness] = fingerRanges;
        }

        for (final measurement in measurements[handIndex]) {
          final existingRange = fingerRanges[measurement.finger];

          if (existingRange == null) {
            fingerRanges[measurement.finger] = FingerCalibrationRange(
              minimumHeight: measurement.normalizedHeight,
              maximumHeight: measurement.normalizedHeight,
            );
          } else {
            existingRange.includeHeight(measurement.normalizedHeight);
          }
        }
      }
    }
  }

  /// Checks whether one finger is above its calibrated normal range.
  bool isFingerExcessivelyHigh(Hand hand, FingerMeasurement measurement) {
    if (calibrationActive) {
      return false;
    }

    final handedness = hand.handedness;

    if (handedness == null) {
      return false;
    }

    final fingerRanges = calibrationRanges[handedness];

    if (fingerRanges == null) {
      return false;
    }

    final fingerRange = fingerRanges[measurement.finger];

    if (fingerRange == null) {
      return false;
    }

    const allowedMargin = 0.10;

    final flyawayThreshold = fingerRange.maximumHeight + allowedMargin;

    if (measurement.normalizedHeight > flyawayThreshold) {
      return true;
    } else {
      return false;
    }
  }

  /// Checks whether a finger is currently a confirmed flyaway.
  bool isFingerConfirmedFlyaway(Hand hand, FlyawayFinger finger) {
    final handedness = hand.handedness;

    if (handedness == null) {
      return false;
    }

    final handFlyaways = confirmedFlyawayFingers[handedness];

    if (handFlyaways == null) {
      return false;
    }

    if (handFlyaways.contains(finger)) {
      return true;
    } else {
      return false;
    }
  }

  /// Updates all finger timers and returns confirmed flyaway fingers.
  Map<Handedness, Set<FlyawayFinger>> updateFlyawayTrackers(
    List<Hand> hands,
    List<List<FingerMeasurement>> measurements,
  ) {
    final confirmedFlyaways = <Handedness, Set<FlyawayFinger>>{};

    if (calibrationActive) {
      flyawayTrackers.clear();
      return confirmedFlyaways;
    }

    final detectedHandednesses = <Handedness>{};
    final currentTime = DateTime.now();

    const requiredHighDuration = Duration(milliseconds: 300);

    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      if (handIndex < measurements.length) {
        final hand = hands[handIndex];
        final handedness = hand.handedness;

        if (handedness != null) {
          detectedHandednesses.add(handedness);

          var fingerTrackers = flyawayTrackers[handedness];

          if (fingerTrackers == null) {
            fingerTrackers = <FlyawayFinger, FlyawayDurationTracker>{};
            flyawayTrackers[handedness] = fingerTrackers;
          }

          final handFlyaways = <FlyawayFinger>{};

          for (final measurement in measurements[handIndex]) {
            final fingerIsHigh = isFingerExcessivelyHigh(hand, measurement);

            var tracker = fingerTrackers[measurement.finger];

            if (tracker == null) {
              tracker = FlyawayDurationTracker();
              fingerTrackers[measurement.finger] = tracker;
            }

            final fingerIsFlyaway = tracker.update(
              fingerIsHigh: fingerIsHigh,
              currentTime: currentTime,
              requiredHighDuration: requiredHighDuration,
            );

            if (fingerIsFlyaway) {
              handFlyaways.add(measurement.finger);
            }
          }

          if (handFlyaways.isNotEmpty) {
            confirmedFlyaways[handedness] = handFlyaways;
          }
        }
      }
    }

    final storedHandednesses = flyawayTrackers.keys.toList();

    for (final handedness in storedHandednesses) {
      if (!detectedHandednesses.contains(handedness)) {
        flyawayTrackers.remove(handedness);
      }
    }

    return confirmedFlyaways;
  }

  /// Builds the transparent landmark layer above the camera preview.
  Widget buildHandLandmarkOverlay() {
    final imageSize = detectionImageSize;

    // Nothing can be drawn before coordinates and hands are available.
    if (imageSize == null || detectedHands.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: HandLandmarkPainter(
            hands: detectedHands,
            imageSize: imageSize,
          ),
        ),
      ),
    );
  }

  /// Builds the temporary panel used to inspect raw finger measurements.
  Widget buildMeasurementPanel() {
    if (handMeasurements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              getMeasurementText(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  /// Converts every current hand measurement into readable debug text.
  String getMeasurementText() {
    final handLines = <String>[];

    for (var handIndex = 0; handIndex < handMeasurements.length; handIndex++) {
      final fingerValues = <String>[];

      for (final measurement in handMeasurements[handIndex]) {
        final label = getFingerLabel(measurement.finger);

        final height = measurement.normalizedHeight.toStringAsFixed(2);

        bool fingerIsHigh = false;
        bool fingerIsFlyaway = false;

        if (handIndex < detectedHands.length) {
          final hand = detectedHands[handIndex];

          fingerIsHigh = isFingerExcessivelyHigh(hand, measurement);

          fingerIsFlyaway = isFingerConfirmedFlyaway(hand, measurement.finger);
        }

        if (fingerIsFlyaway) {
          fingerValues.add('$label: $height FLYAWAY');
        } else if (fingerIsHigh) {
          fingerValues.add('$label: $height HIGH');
        } else {
          fingerValues.add('$label: $height');
        }
      }

      final handLabel = getHandLabel(handIndex);

      handLines.add('$handLabel   ${fingerValues.join('   ')}');
    }

    return handLines.join('\n');
  }

  /// Returns a short display label for one finger.
  String getFingerLabel(FlyawayFinger finger) {
    switch (finger) {
      case FlyawayFinger.thumb:
        return 'T';
      case FlyawayFinger.indexFinger:
        return 'I';
      case FlyawayFinger.middle:
        return 'M';
      case FlyawayFinger.ring:
        return 'R';
      case FlyawayFinger.pinky:
        return 'P';
    }
  }

  /// Returns the detector's left/right label for one detected hand.
  /// A numbered label is used when handedness is unavailable.
  String getHandLabel(int handIndex) {
    if (handIndex >= detectedHands.length) {
      return 'Hand ${handIndex + 1}';
    }

    final handedness = detectedHands[handIndex].handedness;

    if (handedness == Handedness.left) {
      return 'Left hand';
    } else if (handedness == Handedness.right) {
      return 'Right hand';
    } else {
      return 'Hand ${handIndex + 1}';
    }
  }

  @override
  void dispose() {
    // Release the camera and detector resources owned by this screen.
    cameraController?.dispose();
    handTrackingService.dispose();

    // Return the rest of the application to portrait orientation.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }
}
