import '../../ar/services/ar_practice_performance_tracker.dart';
import '../models/synthesia_wait_note_occurrence.dart';

enum SynthesiaWaitReleaseType {
  ignored,
  completed,
  releasedEarly,
  heldTooLong,
}

class SynthesiaWaitReleaseResult {
  const SynthesiaWaitReleaseResult({
    required this.type,
    this.groupIndex,
    this.midiNote,
    this.groupCompleted = false,
  });

  final SynthesiaWaitReleaseType type;
  final int? groupIndex;
  final int? midiNote;
  final bool groupCompleted;
}

class SynthesiaWaitTickResult {
  const SynthesiaWaitTickResult({
    this.segmentCompleted = false,
    this.overheldGroupIndex,
    this.overheldMidiNote,
  });

  final bool segmentCompleted;
  final int? overheldGroupIndex;
  final int? overheldMidiNote;
}

class SynthesiaWaitHeldNote {
  SynthesiaWaitHeldNote({
    required this.occurrence,
    required this.pressedAt,
    required this.noteDuration,
  });

  final SynthesiaWaitNoteOccurrence occurrence;
  Duration pressedAt;
  final Duration noteDuration;
  bool overholdReported = false;

  int get midiNote => occurrence.midiNote;
  int get groupIndex => occurrence.groupIndex;
}

class SynthesiaWaitModeEngine {
  static const double minimumHoldRatio = 0.9;

  List<ArPracticeNoteGroup> groups = const <ArPracticeNoteGroup>[];
  final Stopwatch clock = Stopwatch();
  final Set<int> pressedNotes = <int>{};
  final Map<int, Duration> pressedAt = <int, Duration>{};
  final Map<SynthesiaWaitNoteOccurrence, SynthesiaWaitHeldNote> heldNotes =
      <SynthesiaWaitNoteOccurrence, SynthesiaWaitHeldNote>{};
  final Map<SynthesiaWaitNoteOccurrence, double> holdProgress =
      <SynthesiaWaitNoteOccurrence, double>{};
  final Set<SynthesiaWaitNoteOccurrence> hiddenOccurrences =
      <SynthesiaWaitNoteOccurrence>{};

  int targetGroupIndex = 0;
  bool waiting = false;
  bool retryAfterRelease = false;
  bool targetRetryAfterRelease = false;
  final Set<int> targetRetryNotes = <int>{};
  bool segmentInProgress = false;
  Duration? segmentStartedAt;
  Duration segmentDuration = Duration.zero;
  int? segmentOriginGroupIndex;
  int? pendingRewindGroupIndex;
  int timelinePreviewAdvanceMicroseconds = 0;
  Duration? heldDurationPausedAt;
  final Set<SynthesiaWaitNoteOccurrence> durationPausedOccurrences =
      <SynthesiaWaitNoteOccurrence>{};

  void loadGroups(List<ArPracticeNoteGroup> value) {
    groups = value;
    reset();
  }

  void start() {
    clock.start();
  }

  void pause() {
    clock.stop();
  }

  void resume() {
    clock.start();
  }

  void reset() {
    clock
      ..stop()
      ..reset();
    targetGroupIndex = 0;
    waiting = false;
    retryAfterRelease = false;
    targetRetryAfterRelease = false;
    targetRetryNotes.clear();
    segmentInProgress = false;
    segmentStartedAt = null;
    segmentDuration = Duration.zero;
    segmentOriginGroupIndex = null;
    pendingRewindGroupIndex = null;
    timelinePreviewAdvanceMicroseconds = 0;
    heldDurationPausedAt = null;
    durationPausedOccurrences.clear();
    pressedNotes.clear();
    pressedAt.clear();
    heldNotes.clear();
    holdProgress.clear();
    hiddenOccurrences.clear();
  }

  void beginWaiting({
    bool preserveBufferedPresses = false,
    Duration? durationPauseAt,
  }) {
    if (heldDurationPausedAt == null) {
      Duration pauseAt = durationPauseAt ?? clock.elapsed;
      heldDurationPausedAt = pauseAt;
      durationPausedOccurrences.clear();

      for (SynthesiaWaitHeldNote heldNote in heldNotes.values) {
        Duration heldDuration = pauseAt - heldNote.pressedAt;
        if (heldDuration < heldNote.noteDuration) {
          durationPausedOccurrences.add(heldNote.occurrence);
        }
      }
    }
    waiting = true;
    targetRetryAfterRelease = false;
    targetRetryNotes.clear();
    if (!preserveBufferedPresses) {
      pressedNotes.clear();
      pressedAt.clear();
    }
  }

  void recordNoteOn(int midiNote) {
    if ((!waiting && !segmentInProgress) ||
        retryAfterRelease ||
        targetRetryAfterRelease) {
      return;
    }
    pressedNotes.add(midiNote);
    pressedAt[midiNote] = clock.elapsed;
  }

  bool get canBufferUpcomingPress {
    if (!segmentInProgress || segmentStartedAt == null) return false;
    Duration remaining = segmentDuration - (clock.elapsed - segmentStartedAt!);
    return remaining <= const Duration(milliseconds: 100);
  }

  void beginTargetRetry(Iterable<int> notesToRelease) {
    targetRetryNotes
      ..clear()
      ..addAll(notesToRelease);
    targetRetryAfterRelease = targetRetryNotes.isNotEmpty;
    pressedNotes.clear();
    pressedAt.clear();
  }

  bool finishTargetRetryIfReleased(Set<int> activeNotes) {
    if (!targetRetryAfterRelease) return false;
    if (activeNotes.any(targetRetryNotes.contains)) return false;

    targetRetryAfterRelease = false;
    targetRetryNotes.clear();
    pressedNotes.clear();
    pressedAt.clear();
    waiting = true;
    return true;
  }

  Set<int> get expectedNotes {
    if (targetGroupIndex < 0 || targetGroupIndex >= groups.length) {
      return const <int>{};
    }
    return groups[targetGroupIndex].midiNotes;
  }

  Set<int> get carriedNotes {
    return heldNotes.values
        .where((note) => note.groupIndex < targetGroupIndex)
        .map((note) => note.midiNote)
        .toSet();
  }

  bool chordTimingMatches(Duration chordWindow) {
    if (expectedNotes.length <= 1) return true;
    List<Duration> times = expectedNotes
        .map((note) => pressedAt[note])
        .whereType<Duration>()
        .toList()
      ..sort();
    return times.length == expectedNotes.length &&
        times.last - times.first <= chordWindow;
  }

  void acceptCurrentGroup() {
    if (targetGroupIndex < 0 || targetGroupIndex >= groups.length) return;
    int groupIndex = targetGroupIndex;
    ArPracticeNoteGroup group = groups[groupIndex];
    Duration now = clock.elapsed;
    _resumeHeldDurations(now);

    for (int midiNote in group.midiNotes) {
      SynthesiaWaitNoteOccurrence occurrence = SynthesiaWaitNoteOccurrence(
        groupIndex: groupIndex,
        groupStartMicroseconds: group.startTime.inMicroseconds,
        midiNote: midiNote,
      );
      heldNotes[occurrence] = SynthesiaWaitHeldNote(
        occurrence: occurrence,
        pressedAt: now,
        noteDuration: group.durationFor(midiNote),
      );
      holdProgress[occurrence] = 0;
    }

    targetGroupIndex = groupIndex + 1;
    waiting = false;
    retryAfterRelease = false;
    targetRetryAfterRelease = false;
    targetRetryNotes.clear();
    pressedNotes.clear();
    pressedAt.clear();
    timelinePreviewAdvanceMicroseconds = 0;

    if (targetGroupIndex < groups.length) {
      segmentOriginGroupIndex = groupIndex;
      segmentStartedAt = now;
      segmentDuration =
          groups[targetGroupIndex].startTime - group.startTime;
      segmentInProgress = true;
    } else {
      segmentOriginGroupIndex = null;
      segmentStartedAt = null;
      segmentDuration = Duration.zero;
      segmentInProgress = false;
    }
  }

  SynthesiaWaitTickResult tick(
    Set<int> activeNotes,
    Duration overholdTolerance,
  ) {
    if (retryAfterRelease) return const SynthesiaWaitTickResult();
    Duration now = clock.elapsed;

    for (SynthesiaWaitHeldNote heldNote in heldNotes.values) {
      if (!activeNotes.contains(heldNote.midiNote)) continue;
      Duration durationNow = _durationEvaluationTime(heldNote, now);
      Duration heldDuration = durationNow - heldNote.pressedAt;
      int durationUs = heldNote.noteDuration.inMicroseconds;
      holdProgress[heldNote.occurrence] = durationUs <= 0
          ? 1
          : (heldDuration.inMicroseconds / durationUs)
                .clamp(0.0, 1.0)
                .toDouble();

      if (heldDuration > heldNote.noteDuration + overholdTolerance &&
          !heldNote.overholdReported) {
        heldNote.overholdReported = true;
        beginRewind(heldNote.groupIndex);
        return SynthesiaWaitTickResult(
          overheldGroupIndex: heldNote.groupIndex,
          overheldMidiNote: heldNote.midiNote,
        );
      }
    }

    Duration? startedAt = segmentStartedAt;
    if (segmentInProgress && startedAt != null) {
      Duration elapsed = now - startedAt;
      timelinePreviewAdvanceMicroseconds = elapsed.inMicroseconds
          .clamp(0, segmentDuration.inMicroseconds)
          .toInt();
      if (elapsed >= segmentDuration) {
        Duration segmentEndedAt = startedAt + segmentDuration;
        segmentInProgress = false;
        segmentStartedAt = null;
        segmentDuration = Duration.zero;
        segmentOriginGroupIndex = null;
        timelinePreviewAdvanceMicroseconds = 0;
        beginWaiting(
          preserveBufferedPresses: true,
          durationPauseAt: segmentEndedAt,
        );
        return const SynthesiaWaitTickResult(segmentCompleted: true);
      }
    }

    return const SynthesiaWaitTickResult();
  }

  SynthesiaWaitReleaseResult releaseNote(
    int midiNote,
    Duration releaseGrace,
    Duration overholdTolerance,
  ) {
    SynthesiaWaitHeldNote? heldNote;
    for (SynthesiaWaitHeldNote candidate in heldNotes.values) {
      if (candidate.midiNote == midiNote) {
        heldNote = candidate;
        break;
      }
    }

    if (heldNote == null || retryAfterRelease) {
      pressedAt.remove(midiNote);
      return const SynthesiaWaitReleaseResult(
        type: SynthesiaWaitReleaseType.ignored,
      );
    }

    Duration heldDuration =
        _durationEvaluationTime(heldNote, clock.elapsed) - heldNote.pressedAt;
    if (heldDuration > heldNote.noteDuration + overholdTolerance) {
      beginRewind(heldNote.groupIndex);
      return SynthesiaWaitReleaseResult(
        type: SynthesiaWaitReleaseType.heldTooLong,
        groupIndex: heldNote.groupIndex,
        midiNote: midiNote,
      );
    }
    if (heldDuration + releaseGrace < requiredHoldDuration(heldNote)) {
      beginRewind(heldNote.groupIndex);
      return SynthesiaWaitReleaseResult(
        type: SynthesiaWaitReleaseType.releasedEarly,
        groupIndex: heldNote.groupIndex,
        midiNote: midiNote,
      );
    }

    holdProgress[heldNote.occurrence] = 1;
    hiddenOccurrences.add(heldNote.occurrence);
    heldNotes.remove(heldNote.occurrence);
    pressedAt.remove(midiNote);
    bool groupCompleted = !heldNotes.values.any(
      (note) => note.groupIndex == heldNote!.groupIndex,
    );
    return SynthesiaWaitReleaseResult(
      type: SynthesiaWaitReleaseType.completed,
      groupIndex: heldNote.groupIndex,
      midiNote: midiNote,
      groupCompleted: groupCompleted,
    );
  }

  bool isReadyForRelease(SynthesiaWaitHeldNote heldNote) {
    Duration heldDuration =
        _durationEvaluationTime(heldNote, clock.elapsed) - heldNote.pressedAt;
    return heldDuration >= requiredHoldDuration(heldNote);
  }

  Duration requiredHoldDuration(SynthesiaWaitHeldNote heldNote) {
    return Duration(
      microseconds:
          (heldNote.noteDuration.inMicroseconds * minimumHoldRatio).round(),
    );
  }

  Duration _durationEvaluationTime(
    SynthesiaWaitHeldNote heldNote,
    Duration now,
  ) {
    Duration? pausedAt = heldDurationPausedAt;
    if (pausedAt != null &&
        durationPausedOccurrences.contains(heldNote.occurrence)) {
      return pausedAt;
    }

    Duration? startedAt = segmentStartedAt;
    if (segmentInProgress && startedAt != null) {
      Duration segmentEnd = startedAt + segmentDuration;
      if (now > segmentEnd) return segmentEnd;
    }

    return now;
  }

  void _resumeHeldDurations(Duration now) {
    Duration? pausedAt = heldDurationPausedAt;
    if (pausedAt == null) return;

    Duration excludedWait = now - pausedAt;
    if (excludedWait > Duration.zero) {
      for (SynthesiaWaitHeldNote heldNote in heldNotes.values) {
        if (durationPausedOccurrences.contains(heldNote.occurrence)) {
          heldNote.pressedAt += excludedWait;
        }
      }
    }
    heldDurationPausedAt = null;
    durationPausedOccurrences.clear();
  }

  void beginRewind(int groupIndex) {
    int earliest = groupIndex;
    for (SynthesiaWaitHeldNote note in heldNotes.values) {
      if (note.groupIndex < earliest) earliest = note.groupIndex;
    }
    int? pending = pendingRewindGroupIndex;
    pendingRewindGroupIndex = pending == null || earliest < pending
        ? earliest
        : pending;
    retryAfterRelease = true;
    targetRetryAfterRelease = false;
    targetRetryNotes.clear();
    waiting = false;
    segmentInProgress = false;
    segmentStartedAt = null;
    segmentDuration = Duration.zero;
    segmentOriginGroupIndex = null;
    timelinePreviewAdvanceMicroseconds = 0;
    heldDurationPausedAt = null;
    durationPausedOccurrences.clear();
  }

  int? finishRewindIfReleased(Set<int> activeNotes) {
    if (!retryAfterRelease || activeNotes.isNotEmpty) return null;
    return finishPendingRewind();
  }

  int? finishPendingRewind() {
    int? groupIndex = pendingRewindGroupIndex;
    if (groupIndex == null) return null;
    hiddenOccurrences.removeWhere(
      (occurrence) => occurrence.groupIndex >= groupIndex,
    );
    holdProgress.removeWhere(
      (occurrence, _) => occurrence.groupIndex >= groupIndex,
    );
    heldNotes.clear();
    pressedNotes.clear();
    pressedAt.clear();
    targetGroupIndex = groupIndex;
    retryAfterRelease = false;
    targetRetryAfterRelease = false;
    targetRetryNotes.clear();
    pendingRewindGroupIndex = null;
    segmentInProgress = false;
    segmentStartedAt = null;
    segmentDuration = Duration.zero;
    segmentOriginGroupIndex = null;
    timelinePreviewAdvanceMicroseconds = 0;
    heldDurationPausedAt = clock.elapsed;
    durationPausedOccurrences.clear();
    waiting = true;
    return groupIndex;
  }

  void interruptForDisconnect() {
    pause();
    pressedNotes.clear();
    pressedAt.clear();
    targetRetryAfterRelease = false;
    targetRetryNotes.clear();
    if (heldNotes.isNotEmpty) {
      int earliest = heldNotes.values
          .map((note) => note.groupIndex)
          .reduce((first, second) => first < second ? first : second);
      beginRewind(earliest);
    }
  }

  void resetFromGroup(int groupIndex) {
    reset();
    targetGroupIndex = groupIndex;
    clock.start();
    beginWaiting();
  }

  bool get isComplete {
    return targetGroupIndex >= groups.length &&
        heldNotes.isEmpty &&
        !segmentInProgress &&
        !retryAfterRelease &&
        !targetRetryAfterRelease;
  }
}
