/// Describes the microphone recognition lifecycle exposed to its screen.
enum MicrophoneInputState {
  stopped,
  starting,
  calibrating,
  ready,
  degraded,
  interrupted,
  failed,
}

/// Describes whether captured audio is usable for piano-note recognition.
enum MicrophoneSignalQuality { unknown, tooQuiet, usable, clipping, tooNoisy }
