/// Tracks how long one finger remains above its allowed height.
class FlyawayDurationTracker {
  DateTime? highStartedAt;

  /// Returns true after the finger remains high for the required duration.
  bool update({
    required bool fingerIsHigh,
    required DateTime currentTime,
    required Duration requiredHighDuration,
  }) {
    if (!fingerIsHigh) {
      highStartedAt = null;
      return false;
    }

    if (highStartedAt == null) {
      highStartedAt = currentTime;
      return false;
    }

    final timeSpentHigh = currentTime.difference(highStartedAt!);

    if (timeSpentHigh >= requiredHighDuration) {
      return true;
    } else {
      return false;
    }
  }

  /// Removes the previously recorded starting time.
  void reset() {
    highStartedAt = null;
  }
}
