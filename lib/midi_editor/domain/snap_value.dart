enum SnapValue {
  quarter('1/4', 1),
  eighth('1/8', 2),
  sixteenth('1/16', 4),
  thirtySecond('1/32', 8),
  off('Off', 0);

  const SnapValue(this.label, this.divisionsPerQuarter);

  final String label;
  final int divisionsPerQuarter;

  int intervalTicks(int ticksPerQuarter) {
    if (this == SnapValue.off) {
      return 1;
    }
    return (ticksPerQuarter / divisionsPerQuarter).round().clamp(1, 1 << 30);
  }

  int snapTick(int tick, int ticksPerQuarter) {
    if (this == SnapValue.off) {
      return tick.clamp(0, 1 << 31);
    }
    final interval = intervalTicks(ticksPerQuarter);
    return ((tick / interval).round() * interval).clamp(0, 1 << 31);
  }
}
