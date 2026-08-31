/// Ordered user-interface stages of the piano calibration workflow.
enum PianoCalibrationStage {
  /// Live camera frames are being searched for a stable piano pattern.
  detectingKeyboard,

  /// The user can drag the detected playable-area corners.
  adjustingKeyboardArea,

  /// The user must identify the reference C4 key.
  selectingReferenceKey,

  /// Key names and outlines are ready to review, save, or use.
  mappingConfirmed,
}
