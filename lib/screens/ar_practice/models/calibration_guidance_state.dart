import 'arcore_tracking_status.dart';

// Lists the guidance conditions that can be shown during calibration.
// These states convert technical ARCore results into instructions that are
// easier for the user to understand.
enum CalibrationGuidanceState {
  preparing,
  ready,
  moreLightNeeded,
  moveSlowly,
  pointAtKeyboard,
  trackingLost,
  cameraUnavailable,
  installationRequired,
  permissionRequired,
  unsupported,
  failed,
}

// Converts a calibration guidance state into an instruction that can be shown
// on the camera screen.
String getCalibrationGuidanceMessage(CalibrationGuidanceState guidanceState) {
  switch (guidanceState) {
    case CalibrationGuidanceState.preparing:
      return 'Preparing AR tracking';

    case CalibrationGuidanceState.ready:
      return 'Ready to scan';

    case CalibrationGuidanceState.moreLightNeeded:
      return 'Add more light around the keyboard';

    case CalibrationGuidanceState.moveSlowly:
      return 'Move the phone more slowly';

    case CalibrationGuidanceState.pointAtKeyboard:
      return 'Point the camera at the keyboard';

    case CalibrationGuidanceState.trackingLost:
      return 'Hold the phone still while tracking recovers';

    case CalibrationGuidanceState.cameraUnavailable:
      return 'The rear camera is unavailable';

    case CalibrationGuidanceState.installationRequired:
      return 'Install or update Google Play Services for AR';

    case CalibrationGuidanceState.permissionRequired:
      return 'Allow camera access to continue';

    case CalibrationGuidanceState.unsupported:
      return 'AR calibration is unsupported on this device';

    case CalibrationGuidanceState.failed:
      return 'AR calibration could not continue';
  }
}

// Converts the technical tracking status received from ARCore into the
// calibration guidance state that should be shown to the user.
CalibrationGuidanceState getCalibrationGuidanceState(
  ArCoreTrackingStatus trackingStatus,
) {
  switch (trackingStatus) {
    case ArCoreTrackingStatus.initializing:
      return CalibrationGuidanceState.preparing;

    case ArCoreTrackingStatus.tracking:
      return CalibrationGuidanceState.ready;

    case ArCoreTrackingStatus.paused:
      return CalibrationGuidanceState.trackingLost;

    case ArCoreTrackingStatus.stopped:
      return CalibrationGuidanceState.trackingLost;

    case ArCoreTrackingStatus.insufficientLight:
      return CalibrationGuidanceState.moreLightNeeded;

    case ArCoreTrackingStatus.excessiveMotion:
      return CalibrationGuidanceState.moveSlowly;

    case ArCoreTrackingStatus.insufficientFeatures:
      return CalibrationGuidanceState.pointAtKeyboard;

    case ArCoreTrackingStatus.cameraUnavailable:
      return CalibrationGuidanceState.cameraUnavailable;

    case ArCoreTrackingStatus.badState:
      return CalibrationGuidanceState.trackingLost;

    case ArCoreTrackingStatus.installRequired:
      return CalibrationGuidanceState.installationRequired;

    case ArCoreTrackingStatus.permissionMissing:
      return CalibrationGuidanceState.permissionRequired;

    case ArCoreTrackingStatus.unsupported:
      return CalibrationGuidanceState.unsupported;

    case ArCoreTrackingStatus.failed:
      return CalibrationGuidanceState.failed;
  }
}

// Returns the basic setup instructions that must be followed before scanning
// the piano keyboard.
String getCalibrationPreparationInstructions() {
  String instructions =
      'Keep the keyboard stationary.\n'
      'Use the rear 1x camera.\n'
      'Do not zoom.\n'
      'Keep the phone in landscape.\n'
      'Make sure the keyboard has enough light.';

  return instructions;
}
