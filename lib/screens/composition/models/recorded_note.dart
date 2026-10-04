class RecordedNote {
  const RecordedNote({
    required this.noteNumber,
    required this.velocity,
    required this.startTime,
    required this.endTime,
  });

  final int noteNumber;
  final int velocity;
  final Duration startTime;
  final Duration endTime;

  Duration get duration => endTime - startTime;
}
