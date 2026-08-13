// Represents the current stage of calibration.
// These values show whether the app is checking support, requesting permission,
// scanning the keyboard, pausing, saving, or stopping safely.
enum CalibrationStatus {
  notStarted,
  checkingDeviceSupport,
  requestingCameraPermission,
  readyToOpenCamera,
  openingCamera,
  scanning,
  paused,
  processing,
  reviewing,
  saving,
  completed,
  unavailable,
  failed,
}

// Describes why calibration cannot continue normally.
// Some problems, such as low light, may only pause calibration. Other problems,
// such as an unsupported device, prevent the AR feature from starting.
enum CalibrationError {
  arCoreNotSupported,
  arCoreNotInstalled,
  arCoreUpdateRequired,
  cameraPermissionDenied,
  cameraPermissionPermanentlyDenied,
  cameraUnavailable,
  cameraOpenFailed,
  trackingLost,
  alignmentLost,
  movementTooFast,
  insufficientLighting,
  cameraTooClose,
  cameraTooFar,
  tooFewKeysVisible,
  keyboardTooOccluded,
  keyboardMoved,
  keyboardDetectionFailed,
  processingFailed,
  saveFailed,
  unknown,
}

// Stores the current calibration status and optional error.
// A status is always required, but error can be null when nothing is wrong.
class CalibrationState {
  const CalibrationState({required this.status, this.error});

  final CalibrationStatus status;
  final CalibrationError? error;

  // Reports whether an error currently exists.
  // This avoids repeating the same null comparison in different places.
  bool hasError() {
    return error != null;
  }
}
