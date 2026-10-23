/// Identifies whether microphone recognition detected an attack or release.
enum MicrophoneNoteEventType { noteOn, noteOff }

/// Describes one piano-note event inferred from microphone audio.
class MicrophoneNoteEvent {
  /// Creates one timestamped piano-note event inferred from microphone audio.
  const MicrophoneNoteEvent({
    required this.type,
    required this.noteNumber,
    required this.estimatedVelocity,
    required this.confidence,
    required this.capturedAt,
  });

  final MicrophoneNoteEventType type;
  final int noteNumber;
  final int estimatedVelocity;
  final double confidence;
  final Duration capturedAt;
}
