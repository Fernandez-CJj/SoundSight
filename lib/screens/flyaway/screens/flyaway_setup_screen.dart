import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool restingCalibrationActive = false;
  bool calibrationReady = false;

  static const int preparationDurationSeconds = 3;
  static const int restingCalibrationDurationSeconds = 3;
  static const int movementCalibrationDurationSeconds = 7;
  static const int minimumRestingSampleCount = 5;

  Timer? calibrationTimer;

  int preparationSecondsRemaining = 0;
  int restingSecondsRemaining = 0;
  int movementSecondsRemaining = 0;

  final Map<Handedness, Map<FlyawayFinger, FingerCalibrationRange>>
  calibrationRanges =
      <Handedness, Map<FlyawayFinger, FingerCalibrationRange>>{};

  final Map<Handedness, Map<FlyawayFinger, List<double>>> restingDepthSamples =
      <Handedness, Map<FlyawayFinger, List<double>>>{};

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

          // Left-side layer: calibrated depth ranges for each finger.
          buildCalibrationRangePanel(),

          // Middle layer: temporary finger-depth measurement display.
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

  /// Builds the visible calibration status and restart button.
  Widget buildCalibrationButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: startCalibrationSequence,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              minimumSize: const Size(280, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: const BorderSide(color: Colors.white, width: 1.5),
              elevation: 6,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(getCalibrationButtonLabel()),
          ),
        ),
      ),
    );
  }

  /// Returns the current calibration status and restart instruction.
  String getCalibrationButtonLabel() {
    if (preparationSecondsRemaining > 0) {
      return 'Get ready: $preparationSecondsRemaining | Tap to restart';
    } else if (restingCalibrationActive) {
      return 'Rest fingers on keys: $restingSecondsRemaining | Tap to restart';
    } else if (calibrationActive) {
      return 'Move normally: $movementSecondsRemaining | Tap to restart';
    } else if (calibrationReady) {
      return 'Recalibrate';
    } else {
      return 'Start calibration';
    }
  }

  /// Starts the preparation countdown before measurement collection.
  void startCalibrationSequence() {
    calibrationTimer?.cancel();

    setState(() {
      calibrationRanges.clear();
      restingDepthSamples.clear();
      flyawayTrackers.clear();
      confirmedFlyawayFingers.clear();

      calibrationReady = false;
      calibrationActive = false;
      restingCalibrationActive = false;
      preparationSecondsRemaining = preparationDurationSeconds;
      restingSecondsRemaining = restingCalibrationDurationSeconds;
      movementSecondsRemaining = movementCalibrationDurationSeconds;
    });

    calibrationTimer = Timer.periodic(
      const Duration(seconds: 1),
      handleCalibrationTimerTick,
    );
  }

  /// Advances preparation and calibration by one second.
  void handleCalibrationTimerTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    var calibrationFinished = false;

    setState(() {
      if (preparationSecondsRemaining > 1) {
        preparationSecondsRemaining--;
      } else if (preparationSecondsRemaining == 1) {
        preparationSecondsRemaining = 0;

        previousHandMeasurements.clear();
        flyawayTrackers.clear();
        confirmedFlyawayFingers.clear();

        calibrationActive = true;
        restingCalibrationActive = true;
      } else if (restingCalibrationActive) {
        if (restingSecondsRemaining > 1) {
          restingSecondsRemaining--;
        } else {
          restingSecondsRemaining = 0;
          restingCalibrationActive = false;

          createRestingCalibrationProfiles();
          previousHandMeasurements.clear();
        }
      } else if (calibrationActive) {
        if (movementSecondsRemaining > 1) {
          movementSecondsRemaining--;
        } else {
          movementSecondsRemaining = 0;
          calibrationActive = false;

          timer.cancel();
          calibrationTimer = null;

          calibrationFinished = true;
        }
      }
    });

    if (calibrationFinished) {
      showCalibrationResultDialog();
    }
  }

  /// Checks whether at least one complete hand calibration was captured.
  bool calibrationWasSuccessful() {
    if (calibrationRanges.isEmpty) {
      return false;
    }

    for (final fingerRanges in calibrationRanges.values) {
      if (fingerRanges.length == FlyawayFinger.values.length) {
        var everyFingerHasNormalMovement = true;

        for (final fingerRange in fingerRanges.values) {
          if (fingerRange.normalMovementSampleCount == 0) {
            everyFingerHasNormalMovement = false;
          }
        }

        if (everyFingerHasNormalMovement) {
          return true;
        }
      }
    }

    return false;
  }

  /// Shows whether calibration captured enough hand information.
  void showCalibrationResultDialog() {
    if (!mounted) {
      return;
    }

    final calibrationSucceeded = calibrationWasSuccessful();

    IconData dialogIcon;
    Color dialogIconColor;
    String dialogTitle;
    String dialogMessage;
    String dialogButtonLabel;

    if (calibrationSucceeded) {
      dialogIcon = Icons.check_circle;
      dialogIconColor = Colors.green;
      dialogTitle = 'Calibration complete';
      dialogMessage =
          "You're ready to perform! Your resting finger reference and "
          'normal movement range '
          'was captured. Keep the phone in the same position.';
      dialogButtonLabel = 'Start analysis';
    } else {
      dialogIcon = Icons.error;
      dialogIconColor = Colors.red;
      dialogTitle = 'Calibration unsuccessful';
      dialogMessage =
          'No complete hand measurements were captured. Keep your hands '
          'inside the camera view and try again.';
      dialogButtonLabel = 'Try again';
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(dialogIcon, color: dialogIconColor, size: 52),
          title: Text(dialogTitle),
          content: Text(dialogMessage),
          actions: [
            FilledButton(
              onPressed: () {
                handleCalibrationDialogAction(
                  dialogContext,
                  calibrationSucceeded,
                );
              },
              child: Text(dialogButtonLabel),
            ),
          ],
        );
      },
    );
  }

  /// Handles the success or retry action selected from the result dialog.
  void handleCalibrationDialogAction(
    BuildContext dialogContext,
    bool calibrationSucceeded,
  ) {
    Navigator.of(dialogContext).pop();

    if (calibrationSucceeded) {
      setState(() {
        previousHandMeasurements.clear();
        flyawayTrackers.clear();
        confirmedFlyawayFingers.clear();

        calibrationReady = true;
      });
    } else {
      startCalibrationSequence();
    }
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

      final smoothedDepth =
          previousMeasurement.relativeDepth * previousWeight +
          currentMeasurement.relativeDepth * currentWeight;

      final smoothedMeasurement = FingerMeasurement(
        finger: currentMeasurement.finger,
        relativeDepth: smoothedDepth,
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

  /// Sends current measurements to the active calibration stage.
  void collectCalibrationMeasurements(
    List<Hand> hands,
    List<List<FingerMeasurement>> measurements,
  ) {
    if (!calibrationActive) {
      return;
    }

    if (restingCalibrationActive) {
      collectRestingDepthSamples(hands, measurements);
    } else {
      collectNormalMovementLifts(hands, measurements);
    }
  }

  /// Collects several depth readings while fingers rest on the keys.
  void collectRestingDepthSamples(
    List<Hand> hands,
    List<List<FingerMeasurement>> measurements,
  ) {
    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      if (handIndex >= measurements.length) {
        return;
      }

      final handedness = hands[handIndex].handedness;

      if (handedness != null) {
        var handSamples = restingDepthSamples[handedness];

        if (handSamples == null) {
          handSamples = <FlyawayFinger, List<double>>{};
          restingDepthSamples[handedness] = handSamples;
        }

        for (final measurement in measurements[handIndex]) {
          var fingerSamples = handSamples[measurement.finger];

          if (fingerSamples == null) {
            fingerSamples = <double>[];
            handSamples[measurement.finger] = fingerSamples;
          }

          fingerSamples.add(measurement.relativeDepth);
        }
      }
    }
  }

  /// Creates one stable resting reference from each finger's samples.
  void createRestingCalibrationProfiles() {
    calibrationRanges.clear();

    for (final handEntry in restingDepthSamples.entries) {
      final fingerRanges = <FlyawayFinger, FingerCalibrationRange>{};

      for (final finger in FlyawayFinger.values) {
        final samples = handEntry.value[finger];

        if (samples != null && samples.length >= minimumRestingSampleCount) {
          final restingDepth = calculateMedian(samples);

          fingerRanges[finger] = FingerCalibrationRange(
            restingDepth: restingDepth,
          );
        }
      }

      if (fingerRanges.isNotEmpty) {
        calibrationRanges[handEntry.key] = fingerRanges;
      }
    }
  }

  /// Returns the middle sample so one extreme reading cannot set the baseline.
  double calculateMedian(List<double> samples) {
    final sortedSamples = List<double>.from(samples);
    sortedSamples.sort();

    final middleIndex = sortedSamples.length ~/ 2;

    if (sortedSamples.length.isOdd) {
      return sortedSamples[middleIndex];
    } else {
      final lowerMiddle = sortedSamples[middleIndex - 1];
      final upperMiddle = sortedSamples[middleIndex];

      return (lowerMiddle + upperMiddle) / 2;
    }
  }

  /// Records how far each finger normally moves above its resting reference.
  void collectNormalMovementLifts(
    List<Hand> hands,
    List<List<FingerMeasurement>> measurements,
  ) {
    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      if (handIndex >= measurements.length) {
        return;
      }

      final handedness = hands[handIndex].handedness;

      if (handedness != null) {
        final fingerRanges = calibrationRanges[handedness];

        if (fingerRanges != null) {
          final liftAmounts = calculateLiftAmounts(
            fingerRanges,
            measurements[handIndex],
          );

          for (final measurement in measurements[handIndex]) {
            final fingerRange = fingerRanges[measurement.finger];
            final liftAmount = liftAmounts[measurement.finger];
            final independentLift = calculateIndependentLift(
              measurement.finger,
              liftAmounts,
            );

            if (fingerRange != null &&
                liftAmount != null &&
                independentLift != null) {
              fingerRange.includeNormalMovement(
                liftAmount: liftAmount,
                independentLift: independentLift,
              );
            }
          }
        }
      }
    }
  }

  /// Calculates every finger's lift above its resting reference.
  Map<FlyawayFinger, double> calculateLiftAmounts(
    Map<FlyawayFinger, FingerCalibrationRange> fingerRanges,
    List<FingerMeasurement> measurements,
  ) {
    final liftAmounts = <FlyawayFinger, double>{};

    for (final measurement in measurements) {
      final fingerRange = fingerRanges[measurement.finger];

      if (fingerRange != null) {
        final liftAmount =
            measurement.relativeDepth - fingerRange.restingDepth;

        liftAmounts[measurement.finger] = liftAmount;
      }
    }

    return liftAmounts;
  }

  /// Returns the fingers directly beside one finger.
  List<FlyawayFinger> getAdjacentFingers(FlyawayFinger finger) {
    switch (finger) {
      case FlyawayFinger.thumb:
        return <FlyawayFinger>[FlyawayFinger.indexFinger];
      case FlyawayFinger.indexFinger:
        return <FlyawayFinger>[
          FlyawayFinger.thumb,
          FlyawayFinger.middle,
        ];
      case FlyawayFinger.middle:
        return <FlyawayFinger>[
          FlyawayFinger.indexFinger,
          FlyawayFinger.ring,
        ];
      case FlyawayFinger.ring:
        return <FlyawayFinger>[
          FlyawayFinger.middle,
          FlyawayFinger.pinky,
        ];
      case FlyawayFinger.pinky:
        return <FlyawayFinger>[FlyawayFinger.ring];
    }
  }

  /// Measures how much one finger rises beyond its adjacent fingers.
  double? calculateIndependentLift(
    FlyawayFinger finger,
    Map<FlyawayFinger, double> liftAmounts,
  ) {
    final fingerLift = liftAmounts[finger];

    if (fingerLift == null) {
      return null;
    }

    final adjacentFingers = getAdjacentFingers(finger);
    var adjacentLiftTotal = 0.0;
    var adjacentLiftCount = 0;

    for (final adjacentFinger in adjacentFingers) {
      final adjacentLift = liftAmounts[adjacentFinger];

      if (adjacentLift != null) {
        adjacentLiftTotal += adjacentLift;
        adjacentLiftCount++;
      }
    }

    if (adjacentLiftCount == 0) {
      return null;
    }

    final averageAdjacentLift = adjacentLiftTotal / adjacentLiftCount;

    return fingerLift - averageAdjacentLift;
  }

  /// Returns all calibrated lift amounts for one detected hand.
  Map<FlyawayFinger, double>? getLiftAmountsForHand(
    Hand hand,
    List<FingerMeasurement> measurements,
  ) {
    final handedness = hand.handedness;

    if (handedness == null) {
      return null;
    }

    final fingerRanges = calibrationRanges[handedness];

    if (fingerRanges == null) {
      return null;
    }

    return calculateLiftAmounts(fingerRanges, measurements);
  }

  /// Checks both total lift and lift beyond neighboring fingers.
  bool isFingerExcessivelyHigh(
    Hand hand,
    FingerMeasurement measurement,
    List<FingerMeasurement> measurements,
  ) {
    if (!calibrationReady) {
      return false;
    }

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

    final liftAmounts = calculateLiftAmounts(fingerRanges, measurements);
    final liftAmount = liftAmounts[measurement.finger];
    final independentLift = calculateIndependentLift(
      measurement.finger,
      liftAmounts,
    );

    if (liftAmount == null || independentLift == null) {
      return false;
    }

    final flyawayThreshold = calculateLiftThreshold(fingerRange);
    final independentThreshold = calculateIndependentLiftThreshold(fingerRange);

    if (liftAmount <= flyawayThreshold) {
      return false;
    }

    if (independentLift <= independentThreshold) {
      return false;
    }

    return true;
  }

  /// Calculates the lift amount a finger must pass to become HIGH.
  double calculateLiftThreshold(FingerCalibrationRange fingerRange) {
    return calculateThresholdFromMaximum(fingerRange.maximumNormalLift);
  }

  /// Calculates the independent lift a finger must pass to become HIGH.
  double calculateIndependentLiftThreshold(
    FingerCalibrationRange fingerRange,
  ) {
    return calculateThresholdFromMaximum(
      fingerRange.maximumNormalIndependentLift,
    );
  }

  /// Adds the shared safety margin to a calibrated normal maximum.
  double calculateThresholdFromMaximum(double maximumNormalLift) {
    const liftMarginPercentage = 0.20;
    const minimumLiftMargin = 0.5;

    final percentageMargin = maximumNormalLift * liftMarginPercentage;

    double allowedLiftMargin;

    if (percentageMargin > minimumLiftMargin) {
      allowedLiftMargin = percentageMargin;
    } else {
      allowedLiftMargin = minimumLiftMargin;
    }

    return maximumNormalLift + allowedLiftMargin;
  }

  /// Returns the current lift above one finger's resting reference.
  double? getLiftAmount(Hand hand, FingerMeasurement measurement) {
    final handedness = hand.handedness;

    if (handedness == null) {
      return null;
    }

    final fingerRanges = calibrationRanges[handedness];

    if (fingerRanges == null) {
      return null;
    }

    final fingerRange = fingerRanges[measurement.finger];

    if (fingerRange == null) {
      return null;
    }

    return measurement.relativeDepth - fingerRange.restingDepth;
  }

  /// Returns the current lift above the average of adjacent fingers.
  double? getIndependentLiftAmount(
    Hand hand,
    FlyawayFinger finger,
    List<FingerMeasurement> measurements,
  ) {
    final liftAmounts = getLiftAmountsForHand(hand, measurements);

    if (liftAmounts == null) {
      return null;
    }

    return calculateIndependentLift(finger, liftAmounts);
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

    if (!calibrationReady) {
      flyawayTrackers.clear();
      return confirmedFlyaways;
    }

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
            final fingerIsHigh = isFingerExcessivelyHigh(
              hand,
              measurement,
              measurements[handIndex],
            );

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

  /// Builds the left-side panel containing calibrated lift references.
  Widget buildCalibrationRangePanel() {
    if (calibrationRanges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      top: 72,
      child: SafeArea(
        child: IgnorePointer(
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white54, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIFT CALIBRATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getCalibrationRangeText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Converts the calibrated lift references into readable debug text.
  String getCalibrationRangeText() {
    final handSections = <String>[];

    for (final handEntry in calibrationRanges.entries) {
      final fingerLines = <String>[];

      final handLabel = getCalibrationHandednessLabel(handEntry.key);
      fingerLines.add(handLabel);

      for (final finger in FlyawayFinger.values) {
        final fingerRange = handEntry.value[finger];

        if (fingerRange != null) {
          final fingerLabel = getFingerLabel(finger);

          final resting = fingerRange.restingDepth.toStringAsFixed(2);
          final maximum = fingerRange.maximumNormalLift.toStringAsFixed(2);
          final independentMaximum = fingerRange.maximumNormalIndependentLift
              .toStringAsFixed(2);

          final threshold = calculateLiftThreshold(
            fingerRange,
          ).toStringAsFixed(2);

          final independentThreshold = calculateIndependentLiftThreshold(
            fingerRange,
          ).toStringAsFixed(2);

          fingerLines.add(
            '$fingerLabel  base $resting  raw $maximum/$threshold  '
            'ind $independentMaximum/$independentThreshold',
          );
        }
      }

      handSections.add(fingerLines.join('\n'));
    }

    return handSections.join('\n\n');
  }

  /// Returns the display name for a calibrated hand.
  String getCalibrationHandednessLabel(Handedness handedness) {
    if (handedness == Handedness.left) {
      return 'LEFT HAND';
    } else {
      return 'RIGHT HAND';
    }
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

        final depth = measurement.relativeDepth.toStringAsFixed(2);
        var measurementText = 'Z $depth';

        bool fingerIsHigh = false;
        bool fingerIsFlyaway = false;

        if (handIndex < detectedHands.length) {
          final hand = detectedHands[handIndex];

          final liftAmount = getLiftAmount(hand, measurement);
          final independentLift = getIndependentLiftAmount(
            hand,
            measurement.finger,
            handMeasurements[handIndex],
          );

          if (liftAmount != null) {
            final lift = liftAmount.toStringAsFixed(2);
            measurementText = 'Z $depth L $lift';
          }

          if (independentLift != null) {
            final independent = independentLift.toStringAsFixed(2);
            measurementText = '$measurementText IL $independent';
          }

          fingerIsHigh = isFingerExcessivelyHigh(
            hand,
            measurement,
            handMeasurements[handIndex],
          );

          fingerIsFlyaway = isFingerConfirmedFlyaway(hand, measurement.finger);
        }

        if (fingerIsFlyaway) {
          fingerValues.add('$label: $measurementText FLYAWAY');
        } else if (fingerIsHigh) {
          fingerValues.add('$label: $measurementText HIGH');
        } else {
          fingerValues.add('$label: $measurementText');
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
    calibrationTimer?.cancel();
    calibrationTimer = null;

    // Release the camera and detector resources owned by this screen.
    cameraController?.dispose();
    handTrackingService.dispose();

    // Return the rest of the application to portrait orientation.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }
}
