import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/keyboard_profile.dart';
import 'widgets/arcore_camera_view.dart';
import '../../models/arcore_tracking_status.dart';

// Receives the selected keyboard profile and prepares a screen where
// the native ARCore camera view will be added during Phase 3.
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
    // Gets the readable message for the latest tracking status every time
    // setState rebuilds this screen.
    String trackingMessage = getTrackingMessage();

    // Checks whether the current ARCore pose is safe for future overlays.
    bool trackingReliable = isTrackingReliable();

    // Converts the true or false safety result into readable temporary test text.
    String overlayStatus = trackingReliable ? 'safe' : 'hidden';
    return Scaffold(
      appBar: AppBar(title: const Text('Piano Calibration')),
      body: Stack(
        children: [
          Positioned.fill(
            child: ArCoreCameraView(
              onTrackingStatusChanged: handleTrackingStatusChanged,
            ),
          ),
          Positioned(
            top: 16.0,
            left: 16.0,
            // Shows temporary diagnostic information for testing the native AR system.
            // The actual piano overlays will use trackingReliable later.
            child: Text(
              'Selected keyboard: ${widget.keyboardProfile.name}\n'
              'AR status: $trackingMessage\n'
              'Overlays: $overlayStatus',
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

  // Converts the current ARCore tracking status into a message that can be
  // understood by the user. The method reads trackingStatus, checks which enum
  // value it contains, and returns the matching instruction for the screen.
  String getTrackingMessage() {
    switch (trackingStatus) {
      case ArCoreTrackingStatus.initializing:
        return 'Initializing AR tracking';

      case ArCoreTrackingStatus.tracking:
        return 'Tracking ready';

      case ArCoreTrackingStatus.paused:
        return 'Tracking paused';

      case ArCoreTrackingStatus.stopped:
        return 'Tracking stopped';

      case ArCoreTrackingStatus.insufficientLight:
        return 'More light is needed';

      case ArCoreTrackingStatus.excessiveMotion:
        return 'Move the phone more slowly';

      case ArCoreTrackingStatus.insufficientFeatures:
        return 'Point the camera at the keyboard';

      case ArCoreTrackingStatus.cameraUnavailable:
        return 'Camera is unavailable';

      case ArCoreTrackingStatus.badState:
        return 'Tracking needs to recover';

      case ArCoreTrackingStatus.installRequired:
        return 'ARCore installation or update is required';

      case ArCoreTrackingStatus.permissionMissing:
        return 'Camera permission is required';

      case ArCoreTrackingStatus.unsupported:
        return 'ARCore is unavailable on this device';

      case ArCoreTrackingStatus.failed:
        return 'AR tracking failed';
    }
  }

  // Reports whether ARCore currently has a reliable camera pose.
  // Future piano overlays must only be visible while this returns true.
  // Every initializing, paused, stopped, or failure status returns false.
  bool isTrackingReliable() {
    return trackingStatus == ArCoreTrackingStatus.tracking;
  }
}
