// Describes the current result of computer-vision keyboard detection.
// Tracking problems such as low light and fast movement are handled separately
// by ArCoreTrackingStatus.
enum KeyboardDetectionStatus {
  notStarted,
  searching,
  keyboardDetected,
  tooFewKeysVisible,
  uncertain,
  failed,
}
