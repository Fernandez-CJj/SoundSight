/// Contains normalized microphone loudness measurements for one audio window.
class MicrophoneAudioLevel {
  /// Creates an immutable level reading for one captured PCM window.
  const MicrophoneAudioLevel({
    required this.rms,
    required this.peak,
    required this.capturedAt,
  });

  /// Root-mean-square loudness normalized to the range 0.0 to 1.0.
  final double rms;

  /// Highest absolute sample value normalized to the range 0.0 to 1.0.
  final double peak;

  /// Monotonic time elapsed since the current capture session started.
  final Duration capturedAt;
}
