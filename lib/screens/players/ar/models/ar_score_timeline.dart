import 'ar_note_event.dart';

/// Immutable, time-ordered collection of notes used by AR practice.
class ArScoreTimeline {
  ArScoreTimeline({
    required List<ArNoteEvent> noteEvents,
    required this.totalDuration,
    this.pieceTitle = 'Untitled score',
  }) : noteEvents = List<ArNoteEvent>.unmodifiable(noteEvents);

  /// Every pitched event parsed from the score's MIDI file.
  final List<ArNoteEvent> noteEvents;
  /// Full playback length, including the final note's duration.
  final Duration totalDuration;

  /// User-facing score title stored with completed practice results.
  final String pieceTitle;

  /// Number of individual note events, including notes within chords.
  int get noteCount {
    return noteEvents.length;
  }

  /// Whether the score contains no playable note events.
  bool get isEmpty {
    return noteEvents.isEmpty;
  }
}
