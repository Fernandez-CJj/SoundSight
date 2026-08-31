/// User-facing advice selected from the current detection conditions.
enum PianoDetectionGuidance {
  /// No usable keyboard pattern is currently visible.
  pointCameraAtKeyboard,
  /// Too few complete octaves are visible in the frame.
  moveFartherBack,
  /// Objects or hands may be obstructing the black-key pattern.
  keepKeyboardClear,
  /// A plausible pattern exists but has not remained stable long enough.
  holdPhoneSteady,
  /// A stable playable keyboard area has been found.
  pianoDetected,
}
