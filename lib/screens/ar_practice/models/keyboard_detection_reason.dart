// Describes why the current keyboard-detection result was rejected,
// accepted, or kept hidden while the result is still stabilizing.
enum KeyboardDetectionReason {
  none,
  openCvNotReady,
  noKeyboardContour,
  invalidKeyboardRegion,
  tooFewBlackKeys,
  tooFewWhiteKeyBoundaries,
  tooFewKeyFeatures,
  inconsistentWhiteKeySpacing,
  inconsistentBlackKeyPattern,
  lowConfidence,
  stabilizing,
  trackingUnreliable,
  processingFailed,
  unknown,
}
