/// One timed MIDI pitch rendered as a falling note in AR practice.
class ArNoteEvent {
  const ArNoteEvent({
    required this.midiNote,
    required this.startTime,
    required this.duration,
  });

  /// Standard MIDI note number, where middle C is 60.
  final int midiNote;
  /// Time at which the note reaches the hit line.
  final Duration startTime;
  /// Score-defined amount of time the note should remain held.
  final Duration duration;

  /// Time at which the held note ends.
  Duration get endTime {
    return startTime + duration;
  }
}
