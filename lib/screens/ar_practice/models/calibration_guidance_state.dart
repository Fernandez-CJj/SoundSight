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
