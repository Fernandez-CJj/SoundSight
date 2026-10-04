class QuantizedNote {
  const QuantizedNote({
    required this.noteNumber,
    required this.velocity,
    required this.startTick,
    required this.durationTicks,
  });

  final int noteNumber;
  final int velocity;
  final int startTick;
  final int durationTicks;

  int get endTick => startTick + durationTicks;
}
