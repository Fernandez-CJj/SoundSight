import '../models/ar_score_timeline.dart';

/// Visual severity used by the immediate feedback banner.
enum ArPracticeFeedbackKind {
  /// No note has been evaluated yet.
  neutral,

  /// The latest required note group was completed correctly.
  correct,

  /// The pitch was correct but timing/chord attack needs improvement.
  warning,

  /// A wrong pitch or fully missed group was recorded.
  incorrect,
}

/// Persistent color result assigned to one falling-note group.
enum ArPracticeNoteResult {
  /// Expected pitches were played within timing tolerances.
  correct,

  /// Correct pitches were played too early, too late, or too far apart.
  timingMistake,

  /// A wrong pitch was attacked or the expected group was not played.
  incorrect,
}

/// Notes that begin at exactly the same score time and form one chord/step.
class ArPracticeNoteGroup {
  const ArPracticeNoteGroup({
    required this.startTime,
    required this.midiNotes,
  });

  /// Time at which this group reaches the hit line.
  final Duration startTime;
  /// Unique MIDI pitches that must be played together.
  final Set<int> midiNotes;
}

/// Evaluates MIDI attacks against an AR score in Performance or Wait Mode.
///
/// Results are kept in memory for the current attempt only; this service does
/// not write challenge points or progress to Firebase.
class ArPracticePerformanceTracker {
  ArPracticePerformanceTracker({
    this.timingTolerance = const Duration(milliseconds: 300),
    this.chordPressWindow = const Duration(milliseconds: 200),
  });

  /// Allowed early/late distance from the target time in Performance Mode.
  final Duration timingTolerance;
  /// Maximum difference between first and last attacks in a chord.
  final Duration chordPressWindow;

  List<ArPracticeNoteGroup> noteGroups = const <ArPracticeNoteGroup>[];
  final Map<int, _ArPracticeAttempt> _attempts =
      <int, _ArPracticeAttempt>{};

  int nextEvaluationIndex = 0;
  int evaluatedGroupCount = 0;
  int correctGroupCount = 0;
  int wrongGroupCount = 0;
  int missedGroupCount = 0;
  int mistakeCount = 0;
  String feedbackText = 'Ready';
  ArPracticeFeedbackKind feedbackKind = ArPracticeFeedbackKind.neutral;

  /// Total number of independently evaluated score times.
  int get totalGroupCount => noteGroups.length;

  /// Snapshot of group results keyed by their start time in microseconds.
  ///
  /// The falling-note painter uses this map to color every note in a chord with
  /// the same green, yellow, or red evaluation result.
  Map<int, ArPracticeNoteResult> get noteResultsByStartMicroseconds {
    Map<int, ArPracticeNoteResult> results = <int, ArPracticeNoteResult>{};

    for (final MapEntry<int, _ArPracticeAttempt> entry in _attempts.entries) {
      ArPracticeNoteResult? result = entry.value.result;

      if (result == null || entry.key < 0 || entry.key >= noteGroups.length) {
        continue;
      }

      results[noteGroups[entry.key].startTime.inMicroseconds] = result;
    }

    return Map<int, ArPracticeNoteResult>.unmodifiable(results);
  }

  /// Percentage of all groups completed without a recorded mistake.
  int get accuracyPercentage {
    if (totalGroupCount == 0) {
      return 0;
    }

    return (correctGroupCount / totalGroupCount * 100).round();
  }

  /// Groups simultaneous timeline events and resets all attempt statistics.
  void loadTimeline(ArScoreTimeline timeline) {
    Map<int, Set<int>> notesByStartTime = <int, Set<int>>{};

    for (final noteEvent in timeline.noteEvents) {
      notesByStartTime
          .putIfAbsent(noteEvent.startTime.inMicroseconds, () => <int>{})
          .add(noteEvent.midiNote);
    }

    List<int> sortedStartTimes = notesByStartTime.keys.toList()..sort();

    noteGroups = List<ArPracticeNoteGroup>.unmodifiable(
      sortedStartTimes.map((int startMicroseconds) {
        return ArPracticeNoteGroup(
          startTime: Duration(microseconds: startMicroseconds),
          midiNotes: Set<int>.unmodifiable(
            notesByStartTime[startMicroseconds]!,
          ),
        );
      }),
    );

    resetAttempt();
  }

  /// Clears per-group attempts, counters, and immediate feedback.
  void resetAttempt() {
    _attempts.clear();
    nextEvaluationIndex = 0;
    evaluatedGroupCount = 0;
    correctGroupCount = 0;
    wrongGroupCount = 0;
    missedGroupCount = 0;
    mistakeCount = 0;
    feedbackText = noteGroups.isEmpty ? 'No notes available' : 'Ready';
    feedbackKind = ArPracticeFeedbackKind.neutral;
  }

  /// Evaluates one MIDI attack against the nearest pending timed group.
  ///
  /// Correct pitches outside [timingTolerance] become yellow timing mistakes;
  /// unrelated pitches become red mistakes. The return value indicates whether
  /// visible feedback changed and the widget should rebuild.
  bool recordPerformanceNoteOn(int midiNote, int elapsedMilliseconds) {
    if (noteGroups.isEmpty || nextEvaluationIndex >= noteGroups.length) {
      return false;
    }

    int? candidateIndex = _findClosestPendingGroup(elapsedMilliseconds);

    if (candidateIndex == null) {
      if (nextEvaluationIndex > 0) {
        int previousGroupIndex = nextEvaluationIndex - 1;
        ArPracticeNoteGroup previousGroup =
            noteGroups[previousGroupIndex];

        if (previousGroup.midiNotes.contains(midiNote) &&
            elapsedMilliseconds > previousGroup.startTime.inMilliseconds) {
          _recordLatePerformanceTimingMistake(previousGroupIndex);
          return true;
        }
      }

      ArPracticeNoteGroup targetGroup = noteGroups[nextEvaluationIndex];
      bool tooEarly =
          elapsedMilliseconds <
          targetGroup.startTime.inMilliseconds -
              timingTolerance.inMilliseconds;

      if (targetGroup.midiNotes.contains(midiNote)) {
        _recordAttemptMistake(
          nextEvaluationIndex,
          tooEarly ? 'Too early' : 'Too late',
          result: ArPracticeNoteResult.timingMistake,
        );
      } else {
        _recordAttemptMistake(
          nextEvaluationIndex,
          'Wrong note',
          result: ArPracticeNoteResult.incorrect,
        );
      }

      return true;
    }

    ArPracticeNoteGroup group = noteGroups[candidateIndex];
    _ArPracticeAttempt attempt = _attemptFor(candidateIndex);

    if (!group.midiNotes.contains(midiNote)) {
      _recordAttemptMistake(
        candidateIndex,
        'Wrong note',
        result: ArPracticeNoteResult.incorrect,
      );
      return true;
    }

    attempt.notePressedAt.putIfAbsent(
      midiNote,
      () => elapsedMilliseconds,
    );

    bool allExpectedNotesWerePressed = group.midiNotes.every(
      attempt.notePressedAt.containsKey,
    );

    if (!allExpectedNotesWerePressed) {
      feedbackText = 'Complete the chord';
      feedbackKind = ArPracticeFeedbackKind.warning;
      return true;
    }

    List<int> pressTimes = group.midiNotes
        .map((int note) => attempt.notePressedAt[note]!)
        .toList()
      ..sort();

    if (pressTimes.last - pressTimes.first > chordPressWindow.inMilliseconds) {
      _recordAttemptMistake(
        candidateIndex,
        'Chord notes were not together',
        result: ArPracticeNoteResult.timingMistake,
      );
      return true;
    }

    attempt.matched = true;
    attempt.result ??= ArPracticeNoteResult.correct;
    feedbackText = attempt.hadMistake ? 'Correct after mistake' : 'Correct';
    feedbackKind = ArPracticeFeedbackKind.correct;
    return true;
  }

  /// Finalizes every group whose late-tolerance window has elapsed.
  ///
  /// Returns whether counters or colors changed.
  bool updatePerformanceTime(int elapsedMilliseconds) {
    bool stateChanged = false;

    while (nextEvaluationIndex < noteGroups.length) {
      ArPracticeNoteGroup group = noteGroups[nextEvaluationIndex];
      int evaluationTime =
          group.startTime.inMilliseconds + timingTolerance.inMilliseconds;

      if (elapsedMilliseconds < evaluationTime) {
        break;
      }

      _finalizePerformanceGroup(nextEvaluationIndex);
      nextEvaluationIndex++;
      stateChanged = true;
    }

    return stateChanged;
  }

  /// Records wrong attacks while Wait Mode is stopped on [groupIndex].
  ///
  /// Correct single notes need no immediate message; chord notes request the
  /// remaining pitches until the screen confirms the complete held set.
  bool recordWaitModeNoteOn(int groupIndex, int midiNote) {
    if (groupIndex < 0 || groupIndex >= noteGroups.length) {
      return false;
    }

    ArPracticeNoteGroup group = noteGroups[groupIndex];

    if (group.midiNotes.contains(midiNote)) {
      if (group.midiNotes.length > 1) {
        feedbackText = 'Complete the chord';
        feedbackKind = ArPracticeFeedbackKind.warning;
        return true;
      }

      return false;
    }

    _recordAttemptMistake(
      groupIndex,
      'Wrong note',
      result: ArPracticeNoteResult.incorrect,
    );
    return true;
  }

  /// Marks a Wait Mode chord whose notes were attacked too far apart.
  void recordWaitModeTimingMistake(int groupIndex) {
    if (groupIndex < 0 || groupIndex >= noteGroups.length) {
      return;
    }

    _recordAttemptMistake(
      groupIndex,
      'Chord notes were not together',
      result: ArPracticeNoteResult.timingMistake,
    );
  }

  /// Finalizes a Wait Mode group after the screen verifies required held notes.
  void completeWaitModeGroup(int groupIndex) {
    if (groupIndex < 0 || groupIndex >= noteGroups.length) {
      return;
    }

    _ArPracticeAttempt attempt = _attemptFor(groupIndex);

    if (attempt.finalized) {
      return;
    }

    attempt.matched = true;
    attempt.finalized = true;
    attempt.result ??= ArPracticeNoteResult.correct;
    evaluatedGroupCount++;
    nextEvaluationIndex = groupIndex + 1;

    if (attempt.hadMistake) {
      wrongGroupCount++;
      feedbackText = 'Correct after mistake';
    } else {
      correctGroupCount++;
      feedbackText = 'Correct';
    }

    feedbackKind = ArPracticeFeedbackKind.correct;
  }

  /// Marks all still-pending groups when timed playback reaches its end.
  void finalizeRemainingPerformanceGroups() {
    while (nextEvaluationIndex < noteGroups.length) {
      _finalizePerformanceGroup(nextEvaluationIndex);
      nextEvaluationIndex++;
    }
  }

  /// Finds the closest current/next group inside the timing tolerance window.
  int? _findClosestPendingGroup(int elapsedMilliseconds) {
    int? closestIndex;
    int closestDistance = timingTolerance.inMilliseconds + 1;
    int finalCandidate = (nextEvaluationIndex + 1)
        .clamp(0, noteGroups.length - 1)
        .toInt();

    for (
      int groupIndex = nextEvaluationIndex;
      groupIndex <= finalCandidate;
      groupIndex++
    ) {
      int groupTime = noteGroups[groupIndex].startTime.inMilliseconds;
      int distance = (elapsedMilliseconds - groupTime).abs();

      if (distance <= timingTolerance.inMilliseconds &&
          distance < closestDistance) {
        closestIndex = groupIndex;
        closestDistance = distance;
      }
    }

    return closestIndex;
  }

  /// Records only the first mistake count while preserving red over yellow.
  void _recordAttemptMistake(
    int groupIndex,
    String message, {
    required ArPracticeNoteResult result,
  }) {
    _ArPracticeAttempt attempt = _attemptFor(groupIndex);

    if (!attempt.hadMistake) {
      attempt.hadMistake = true;
      mistakeCount++;
    }

    if (attempt.result != ArPracticeNoteResult.incorrect) {
      attempt.result = result;
    }

    feedbackText = message;
    feedbackKind = attempt.result == ArPracticeNoteResult.timingMistake
        ? ArPracticeFeedbackKind.warning
        : ArPracticeFeedbackKind.incorrect;
  }

  /// Converts a previously missed group into a timing error after a late pitch.
  ///
  /// Already finalized correct/wrong results are not reclassified by duplicate
  /// late attacks.
  void _recordLatePerformanceTimingMistake(int groupIndex) {
    _ArPracticeAttempt attempt = _attemptFor(groupIndex);

    if (attempt.result == ArPracticeNoteResult.incorrect &&
        attempt.finalized &&
        !attempt.hadMistake) {
      if (missedGroupCount > 0) {
        missedGroupCount--;
      }
      wrongGroupCount++;
      attempt.result = ArPracticeNoteResult.timingMistake;
      attempt.hadMistake = true;
    } else if (attempt.finalized) {
      feedbackText = 'Too late';
      feedbackKind = attempt.result == ArPracticeNoteResult.incorrect
          ? ArPracticeFeedbackKind.incorrect
          : ArPracticeFeedbackKind.warning;
      return;
    } else {
      _recordAttemptMistake(
        groupIndex,
        'Too late',
        result: ArPracticeNoteResult.timingMistake,
      );
    }

    feedbackText = 'Too late';
    feedbackKind = attempt.result == ArPracticeNoteResult.incorrect
        ? ArPracticeFeedbackKind.incorrect
        : ArPracticeFeedbackKind.warning;
  }

  /// Commits one group's counters, result color, and feedback exactly once.
  void _finalizePerformanceGroup(int groupIndex) {
    _ArPracticeAttempt attempt = _attemptFor(groupIndex);

    if (attempt.finalized) {
      return;
    }

    attempt.finalized = true;
    evaluatedGroupCount++;

    if (attempt.matched && !attempt.hadMistake) {
      correctGroupCount++;
      attempt.result = ArPracticeNoteResult.correct;
      feedbackText = 'Correct';
      feedbackKind = ArPracticeFeedbackKind.correct;
    } else if (attempt.hadMistake) {
      wrongGroupCount++;
      if (attempt.result == ArPracticeNoteResult.timingMistake) {
        feedbackText = 'Timing missed';
        feedbackKind = ArPracticeFeedbackKind.warning;
      } else {
        attempt.result = ArPracticeNoteResult.incorrect;
        feedbackText = 'Wrong';
        feedbackKind = ArPracticeFeedbackKind.incorrect;
      }
    } else {
      missedGroupCount++;
      mistakeCount++;
      attempt.result = ArPracticeNoteResult.incorrect;
      feedbackText = 'Missed';
      feedbackKind = ArPracticeFeedbackKind.incorrect;
    }
  }

  /// Returns existing mutable attempt state or lazily creates it.
  _ArPracticeAttempt _attemptFor(int groupIndex) {
    return _attempts.putIfAbsent(groupIndex, _ArPracticeAttempt.new);
  }
}

/// Internal mutable state accumulated while one group is being evaluated.
class _ArPracticeAttempt {
  final Map<int, int> notePressedAt = <int, int>{};
  bool hadMistake = false;
  bool matched = false;
  bool finalized = false;
  ArPracticeNoteResult? result;
}
