import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/keyboard_profile.dart';
import 'widgets/arcore_camera_view.dart';
import '../../models/arcore_tracking_status.dart';
import '../../models/calibration_guidance_state.dart';

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

    // Decides whether the Start Scan button can currently be pressed.
    bool scanCanStart = canStartScan(guidanceState);

    // Checks whether the current ARCore pose is safe for future overlays.
    bool trackingReliable = isTrackingReliable();

    // Converts the true or false safety result into readable temporary test text.
    String overlayStatus = trackingReliable ? 'safe' : 'hidden';
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ArCoreCameraView(
              onTrackingStatusChanged: handleTrackingStatusChanged,
            ),
          ),
          // Shows the temporary test overlay only while ARCore tracking is
          // reliable. Detected piano-key overlays will replace this symbol.
          Positioned.fill(
            child: IgnorePointer(
              child: Visibility(
                visible: trackingReliable,
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
              'Overlays: $overlayStatus',
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: scanCanStart ? handleStartScan : null,
              child: const Text('Start scan'),
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

  // Receives the newest tracking condition from the native camera widget.
  void handleTrackingStatusChanged(ArCoreTrackingStatus newTrackingStatus) {
    if (mounted == false || trackingStatus == newTrackingStatus) {
      return;
    }

    setState(() {
      trackingStatus = newTrackingStatus;
    });
  }

  // Reports whether ARCore currently has a reliable camera pose.
  // Future piano overlays must only be visible while this returns true.
  // Every initializing, paused, stopped, or failure status returns false.
  bool isTrackingReliable() {
    return trackingStatus == ArCoreTrackingStatus.tracking;
  }

  // Allows scanning only when ARCore tracking is ready and reliable.
  bool canStartScan(CalibrationGuidanceState guidanceState) {
    return guidanceState == CalibrationGuidanceState.ready;
  }

  // Temporarily confirms that AR tracking is ready.
  // Phase 5 will replace this message with the real keyboard detection process.
  void handleStartScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tracking is ready for keyboard scanning.')),
    );
  }
}
