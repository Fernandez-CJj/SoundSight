/// Tracks a Wait Mode hold using only time spent advancing through the score.
class SightReadingWaitHeldNote {
  SightReadingWaitHeldNote({
    required this.midiNote,
    required this.originPositionIndex,
    required DateTime pressedAt,
    required this.noteDuration,
    required this.overholdTolerance,
  }) : _pressedAt = pressedAt;

  // Match the Synthesia and AR Wait Mode release tolerances.
  static const double minimumHoldRatio = 0.9;
  static const Duration releaseGrace = Duration(milliseconds: 40);

  final int midiNote;
  final int originPositionIndex;
  final Duration noteDuration;
  final Duration overholdTolerance;
  DateTime _pressedAt;
  DateTime? _pausedAt;

  Duration heldDurationAt(DateTime now, {DateTime? segmentEnd}) {
    var evaluationTime = _pausedAt ?? now;
    if (segmentEnd != null &&
        evaluationTime.isAfter(segmentEnd) &&
        segmentEnd.difference(_pressedAt) < noteDuration) {
      evaluationTime = segmentEnd;
    }
    final elapsed = evaluationTime.difference(_pressedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  void pauseAt(DateTime time) {
    // Finished notes still need to be released before their deadline.
    if (_pausedAt == null && heldDurationAt(time) < noteDuration) {
      _pausedAt = time;
    }
  }

  void resumeAt(DateTime time) {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    final excludedWait = time.difference(pausedAt);
    if (excludedWait > Duration.zero) {
      _pressedAt = _pressedAt.add(excludedWait);
    }
    _pausedAt = null;
  }

  bool isReleasedEarlyAt(DateTime time, {DateTime? segmentEnd}) {
    final requiredHold = Duration(
      microseconds: (noteDuration.inMicroseconds * minimumHoldRatio).round(),
    );
    return heldDurationAt(time, segmentEnd: segmentEnd) + releaseGrace <
        requiredHold;
  }

  bool isDueForReleaseAt(DateTime time, {DateTime? segmentEnd}) =>
      heldDurationAt(time, segmentEnd: segmentEnd) >= noteDuration;

  bool isOverheldAt(DateTime time, {DateTime? segmentEnd}) =>
      heldDurationAt(time, segmentEnd: segmentEnd) >
      noteDuration + overholdTolerance;
}
