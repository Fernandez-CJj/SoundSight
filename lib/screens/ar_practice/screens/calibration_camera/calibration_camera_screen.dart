import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/keyboard_profile.dart';
import 'widgets/arcore_camera_view.dart';
import '../../models/arcore_tracking_status.dart';
import '../../models/calibration_guidance_state.dart';
import '../../models/keyboard_detection_result.dart';
import '../../models/keyboard_detection_status.dart';
import '../../models/keyboard_detection_reason.dart';

// Receives the selected keyboard profile and displays the native ARCore camera.
// The screen also converts ARCore tracking updates into readable calibration
// guidance and hides calibration overlays whenever tracking is unreliable.
class CalibrationCameraScreen extends StatefulWidget {
  const CalibrationCameraScreen({super.key, required this.keyboardProfile});

  final KeyboardProfile keyboardProfile;

  @override
  State<CalibrationCameraScreen> createState() {
    return CalibrationCameraScreenState();
  }
}

class CalibrationCameraScreenState extends State<CalibrationCameraScreen> {
  ArCoreTrackingStatus trackingStatus = ArCoreTrackingStatus.initializing;

  // Stores the latest safely parsed computer-vision result.
  // Null means no valid keyboard-detection result is currently available.
  KeyboardDetectionResult? keyboardDetectionResult;

  // Requires the same minimum confidence as the native detector before Flutter
  // considers keyboard geometry safe for an overlay.
  final double minimumSafeOverlayConfidence = 0.70;

  // Stores the controller after Android finishes creating the native camera view.
  ArCoreCameraController? cameraController;

  // Prevents the automatic scanner from sending the start command more than once.
  // It becomes true before the asynchronous Kotlin command is sent.
  bool keyboardScanStartRequested = false;

  // Restricts calibration to landscape because the keyboard must fit
  // horizontally inside the camera view.
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Restores SoundSight's normal supported orientations when calibration closes.
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Converts the current ARCore status into guidance that is easier to
    // understand, then prepares the text shown over the camera preview.
    CalibrationGuidanceState guidanceState = getCalibrationGuidanceState(
      trackingStatus,
    );

    String guidanceMessage = getCalibrationGuidanceMessage(guidanceState);

    String preparationInstructions = getCalibrationPreparationInstructions();

    // Checks all tracking and computer-vision requirements before allowing any
    // keyboard overlay to appear.
    bool keyboardOverlaySafe = isKeyboardOverlaySafe();

    // Converts the safety result into readable temporary diagnostic text.
    String overlayStatus = keyboardOverlaySafe ? 'safe' : 'hidden';

    // Converts the current computer-vision result into temporary readable text for
    // Phase 5 phone testing.
    String detectionStatusText = getDetectionStatusText();

    String detectionReasonText = getDetectionReasonText();

    int detectedBlackKeyCount = getDetectedBlackKeyCount();
    int detectedWhiteBoundaryCount = getDetectedWhiteBoundaryCount();

    String detectionConfidenceText = getDetectionConfidenceText();
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ArCoreCameraView(
              onTrackingStatusChanged: handleTrackingStatusChanged,
              onCameraControllerCreated: handleCameraControllerCreated,
              onKeyboardDetectionResultChanged:
                  handleKeyboardDetectionResultChanged,
            ),
          ),
          // Shows the temporary test overlay only after tracking, detection confidence,
          // region validation, and multi-frame stability have all passed.
          Positioned.fill(
            child: IgnorePointer(
              child: Visibility(
                visible: keyboardOverlaySafe,
                child: const Center(
                  child: Icon(Icons.add, color: Colors.green, size: 40),
                ),
              ),
            ),
          ),
          Positioned(
            top: 64.0,
            left: 16.0,
            // Shows temporary calibration instructions and tracking information.
            // The final screen design will replace this diagnostic presentation.
            child: Text(
              'Selected keyboard: ${widget.keyboardProfile.name}\n\n'
              '$preparationInstructions\n\n'
              'Current guidance: $guidanceMessage\n'
              'Keyboard detection: $detectionStatusText\n'
              'Detection reason: $detectionReasonText\n'
              'Black-key candidates: $detectedBlackKeyCount\n'
              'White-key boundaries: $detectedWhiteBoundaryCount\n'
              'Detection confidence: $detectionConfidenceText\n'
              'Overlays: $overlayStatus',
            ),
          ),

          // Keeps a back button available after removing the AppBar.
          // SafeArea prevents it from overlapping the phone's system areas.
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                tooltip: 'Back',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Receives the newest tracking condition and immediately removes old keyboard
  // geometry whenever ARCore tracking becomes unreliable. Reliable tracking also
  // attempts to start keyboard scanning automatically.
  Future<void> handleTrackingStatusChanged(
    ArCoreTrackingStatus newTrackingStatus,
  ) async {
    if (mounted == false || trackingStatus == newTrackingStatus) {
      return;
    }

    setState(() {
      trackingStatus = newTrackingStatus;

      if (newTrackingStatus != ArCoreTrackingStatus.tracking) {
        keyboardDetectionResult = null;
      }
    });

    if (newTrackingStatus == ArCoreTrackingStatus.tracking) {
      await tryStartKeyboardScanningAutomatically();
    }
  }

  // Receives the latest parsed keyboard-detection result from the camera widget.
  // Invalid native data produces null so old detection data is removed safely.
  void handleKeyboardDetectionResultChanged(
    KeyboardDetectionResult? newKeyboardDetectionResult,
  ) {
    if (mounted == false) {
      return;
    }

    setState(() {
      keyboardDetectionResult = newKeyboardDetectionResult;
    });
  }

  // Stores the controller belonging to the current native camera view. A new
  // controller receives its own automatic keyboard-scanning start request.
  Future<void> handleCameraControllerCreated(
    ArCoreCameraController newCameraController,
  ) async {
    bool controllerChanged = cameraController != newCameraController;

    cameraController = newCameraController;

    if (controllerChanged) {
      keyboardScanStartRequested = false;
    }

    await tryStartKeyboardScanningAutomatically();
  }

  // Reports whether ARCore currently has a reliable camera pose.
  // Future piano overlays must only be visible while this returns true.
  // Every initializing, paused, stopped, or failure status returns false.
  bool isTrackingReliable() {
    return trackingStatus == ArCoreTrackingStatus.tracking;
  }

  // Converts the current keyboard-detection enum into readable temporary text.
  // This diagnostic method can be replaced when the final screen is designed.
  String getDetectionStatusText() {
    KeyboardDetectionResult? currentDetectionResult = keyboardDetectionResult;

    if (currentDetectionResult == null) {
      return 'No result';
    }

    KeyboardDetectionStatus currentStatus = currentDetectionResult.status;

    if (currentStatus == KeyboardDetectionStatus.notStarted) {
      return 'Not started';
    } else if (currentStatus == KeyboardDetectionStatus.searching) {
      return 'Searching';
    } else if (currentStatus == KeyboardDetectionStatus.tooFewKeysVisible) {
      return 'Too few keys visible';
    } else if (currentStatus == KeyboardDetectionStatus.uncertain) {
      return 'Uncertain';
    } else if (currentStatus == KeyboardDetectionStatus.keyboardDetected) {
      return 'Keyboard detected';
    } else {
      return 'Failed';
    }
  }

  // Converts the current diagnostic-reason enum into readable temporary text.
  // This explains which computer-vision or stability check produced the result.
  String getDetectionReasonText() {
    KeyboardDetectionResult? currentDetectionResult = keyboardDetectionResult;

    if (currentDetectionResult == null) {
      return 'No reason';
    }

    KeyboardDetectionReason currentReason =
        currentDetectionResult.diagnosticReason;

    if (currentReason == KeyboardDetectionReason.none) {
      return 'None';
    } else if (currentReason == KeyboardDetectionReason.openCvNotReady) {
      return 'OpenCV not ready';
    } else if (currentReason == KeyboardDetectionReason.noKeyboardContour) {
      return 'No keyboard contour';
    } else if (currentReason == KeyboardDetectionReason.invalidKeyboardRegion) {
      return 'Invalid keyboard region';
    } else if (currentReason == KeyboardDetectionReason.tooFewBlackKeys) {
      return 'Too few black keys';
    } else if (currentReason ==
        KeyboardDetectionReason.tooFewWhiteKeyBoundaries) {
      return 'Too few white-key boundaries';
    } else if (currentReason == KeyboardDetectionReason.tooFewKeyFeatures) {
      return 'Too few key features';
    } else if (currentReason ==
        KeyboardDetectionReason.inconsistentWhiteKeySpacing) {
      return 'Inconsistent white-key spacing';
    } else if (currentReason ==
        KeyboardDetectionReason.inconsistentBlackKeyPattern) {
      return 'Inconsistent black-key pattern';
    } else if (currentReason == KeyboardDetectionReason.lowConfidence) {
      return 'Low confidence';
    } else if (currentReason == KeyboardDetectionReason.stabilizing) {
      return 'Stabilizing';
    } else if (currentReason == KeyboardDetectionReason.trackingUnreliable) {
      return 'Tracking unreliable';
    } else if (currentReason == KeyboardDetectionReason.processingFailed) {
      return 'Processing failed';
    } else {
      return 'Unknown';
    }
  }

  // Returns the number of possible black keys stored in the latest result.
  // Zero is returned when no valid detection result is currently available.
  int getDetectedBlackKeyCount() {
    KeyboardDetectionResult? currentDetectionResult = keyboardDetectionResult;

    if (currentDetectionResult == null) {
      return 0;
    }

    return currentDetectionResult.blackKeyCandidates.length;
  }

  // Returns the number of white-key boundary lines stored in the latest result.
  // This is a boundary count, not the final number of identified white keys.
  int getDetectedWhiteBoundaryCount() {
    KeyboardDetectionResult? currentDetectionResult = keyboardDetectionResult;

    if (currentDetectionResult == null) {
      return 0;
    }

    return currentDetectionResult.whiteKeyBoundaryPositions.length;
  }

  // Returns the latest detection confidence as readable temporary test text.
  // Two decimal places make the value easy to compare with the required 0.70.
  String getDetectionConfidenceText() {
    KeyboardDetectionResult? currentDetectionResult = keyboardDetectionResult;

    if (currentDetectionResult == null) {
      return '0.00';
    }

    double confidence = currentDetectionResult.confidence;

    return confidence.toStringAsFixed(2);
  }

  // Returns true only when both ARCore and computer vision currently provide
  // reliable keyboard geometry. Every failed condition hides the overlay.
  bool isKeyboardOverlaySafe() {
    if (isTrackingReliable() == false) {
      return false;
    }

    KeyboardDetectionResult? currentDetectionResult = keyboardDetectionResult;

    if (currentDetectionResult == null) {
      return false;
    }

    if (currentDetectionResult.status !=
        KeyboardDetectionStatus.keyboardDetected) {
      return false;
    }

    if (currentDetectionResult.keyboardRegion == null) {
      return false;
    }

    if (currentDetectionResult.confidence.isFinite == false) {
      return false;
    }

    if (currentDetectionResult.confidence < minimumSafeOverlayConfidence) {
      return false;
    }

    return true;
  }

  // Starts keyboard scanning automatically after both ARCore tracking and the
  // native camera controller are ready. Repeated start attempts are ignored.
  Future<void> tryStartKeyboardScanningAutomatically() async {
    if (keyboardScanStartRequested) {
      return;
    }

    if (isTrackingReliable() == false) {
      return;
    }

    ArCoreCameraController? currentCameraController = cameraController;

    if (currentCameraController == null) {
      return;
    }

    keyboardScanStartRequested = true;

    try {
      await currentCameraController.startKeyboardScan();
    } on PlatformException catch (error) {
      keyboardScanStartRequested = false;

      if (mounted == false) {
        return;
      }

      String errorMessage =
          error.message ?? 'Keyboard scanning could not start.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}
