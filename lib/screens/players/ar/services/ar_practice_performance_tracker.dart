import 'dart:math' as math;

import '../models/ar_score_timeline.dart';
import '../../sight_reading/practice_result_models.dart';

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
    this.noteDurations = const <int, Duration>{},
  });

  /// Time at which this group reaches the hit line.
  final Duration startTime;
  /// Unique MIDI pitches that must be played together.
  final Set<int> midiNotes;
  /// Score-defined hold duration for each pitch in this group.
  final Map<int, Duration> noteDurations;

  Duration durationFor(int midiNote) {
    return noteDurations[midiNote] ?? Duration.zero;
  }

  Duration get longestNoteDuration {
    Duration longest = Duration.zero;

    for (Duration duration in noteDurations.values) {
      if (duration > longest) {
        longest = duration;
      }
    }

    return longest;
  }
}

/// Evaluates MIDI attacks against an AR score in Performance or Wait Mode.
///
/// Results are kept in memory for the current attempt only; this service does
/// not write challenge points or progress to Firebase.
class ArPracticePerformanceTracker {
  ArPracticePerformanceTracker({
    this.timingTolerance = const Duration(milliseconds: 300),
    this.chordPressWindow = const Duration(milliseconds: 200),
    this.evaluateNoteDurations = false,
    this.minimumHoldRatio = 0.6,
  });

  /// Allowed early/late distance from the target time in Performance Mode.
  Duration timingTolerance;
  /// Maximum difference between first and last attacks in a chord.
  final Duration chordPressWindow;
  /// Enables release-time scoring for AR without changing Synthesia behavior.
  final bool evaluateNoteDurations;
  /// Minimum portion of the written duration that must be held.
  final double minimumHoldRatio;

  List<ArPracticeNoteGroup> noteGroups = const <ArPracticeNoteGroup>[];
  final Map<int, _ArPracticeAttempt> _attempts =
      <int, _ArPracticeAttempt>{};
  final Map<int, int> _activePerformanceGroupByMidiNote = <int, int>{};

  int nextEvaluationIndex = 0;
  int nextInputIndex = 0;
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

  /// Score positions whose Performance Mode evaluation is fully complete.
  Set<int> get finalizedGroupStartMicroseconds {
    Set<int> finalizedStarts = <int>{};

    for (final MapEntry<int, _ArPracticeAttempt> entry in _attempts.entries) {
      if (!entry.value.finalized ||
          entry.key < 0 ||
          entry.key >= noteGroups.length) {
        continue;
      }

      finalizedStarts.add(noteGroups[entry.key].startTime.inMicroseconds);
    }

    return Set<int>.unmodifiable(finalizedStarts);
  }

  /// Detailed Performance Mode mistakes used by the shared Practice Results UI.
  List<PracticeResultErrorEvent> get performanceErrorEvents {
    List<PracticeResultErrorEvent> events = <PracticeResultErrorEvent>[];

    for (int groupIndex = 0; groupIndex < noteGroups.length; groupIndex++) {
      _ArPracticeAttempt? attempt = _attempts[groupIndex];

      if (attempt == null ||
          (!attempt.hadMistake && attempt.issueTypes.isEmpty)) {
        continue;
      }

      List<PerformanceIssueType> issueTypes = attempt.issueTypes.toList()
        ..sort((first, second) => first.index.compareTo(second.index));
      List<int> timingOffsets = attempt.timingOffsetsMs;
      int? representativeTimingOffset;

      if (timingOffsets.isNotEmpty) {
        representativeTimingOffset = timingOffsets.reduce(
          (first, second) => first.abs() >= second.abs() ? first : second,
        );
      }

      ArPracticeNoteGroup group = noteGroups[groupIndex];
      events.add(
        PracticeResultErrorEvent(
          positionIndex: groupIndex,
          measureNumber: null,
          scheduledTimeMs: group.startTime.inMilliseconds,
          expectedMidiNotes: group.midiNotes.toList()..sort(),
          playedMidiNotes: attempt.playedMidiNotes.toList()..sort(),
          clefs: const <String>['unknown'],
          staffNumbers: const <int>[],
          issueTypes: issueTypes,
          timingOffsetMs: representativeTimingOffset,
          eventuallyMatched: attempt.matched,
        ),
      );
    }

    return List<PracticeResultErrorEvent>.unmodifiable(events);
  }

  /// Percentage of all groups completed without a recorded mistake.
  int get accuracyPercentage {
    if (totalGroupCount == 0) {
      return 0;
    }

    return (correctGroupCount / totalGroupCount * 100).round();
  }

  /// Applies the same rank-based timing window used by Sight Reading.
  void applySkillLevel(String skillLevel) {
    switch (skillLevel.trim().toLowerCase()) {
      case 'beginner':
        timingTolerance = const Duration(milliseconds: 400);
        break;
      case 'advanced':
        timingTolerance = const Duration(milliseconds: 200);
        break;
      default:
        timingTolerance = const Duration(milliseconds: 300);
    }
  }

  /// Groups simultaneous timeline events and resets all attempt statistics.
  void loadTimeline(ArScoreTimeline timeline) {
    Map<int, Map<int, Duration>> notesByStartTime =
        <int, Map<int, Duration>>{};

    for (final noteEvent in timeline.noteEvents) {
      Map<int, Duration> noteDurations = notesByStartTime.putIfAbsent(
        noteEvent.startTime.inMicroseconds,
        () => <int, Duration>{},
      );
      Duration? existingDuration = noteDurations[noteEvent.midiNote];

      if (existingDuration == null || noteEvent.duration > existingDuration) {
        noteDurations[noteEvent.midiNote] = noteEvent.duration;
      }
    }

    List<int> sortedStartTimes = notesByStartTime.keys.toList()..sort();

    noteGroups = List<ArPracticeNoteGroup>.unmodifiable(
      sortedStartTimes.map((int startMicroseconds) {
        return ArPracticeNoteGroup(
          startTime: Duration(microseconds: startMicroseconds),
          midiNotes: Set<int>.unmodifiable(
            notesByStartTime[startMicroseconds]!.keys,
          ),
          noteDurations: Map<int, Duration>.unmodifiable(
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
    _activePerformanceGroupByMidiNote.clear();
    nextEvaluationIndex = 0;
    nextInputIndex = 0;
    evaluatedGroupCount = 0;
    correctGroupCount = 0;
    wrongGroupCount = 0;
    missedGroupCount = 0;
    mistakeCount = 0;
    feedbackText = noteGroups.isEmpty ? 'No notes available' : 'Ready';
    feedbackKind = ArPracticeFeedbackKind.neutral;
  }

  /// Clears the latest temporary result without changing attempt statistics.
  bool clearImmediateFeedback() {
    if (feedbackText == 'Ready' &&
        feedbackKind == ArPracticeFeedbackKind.neutral) {
      return false;
    }

    feedbackText = 'Ready';
    feedbackKind = ArPracticeFeedbackKind.neutral;
    return true;
  }

  /// Evaluates one MIDI attack against the nearest pending timed group.
  ///
  /// Correct pitches outside [timingTolerance] become yellow timing mistakes;
  /// unrelated pitches become red mistakes. The return value indicates whether
  /// visible feedback changed and the widget should rebuild.
  bool recordPerformanceNoteOn(int midiNote, int elapsedMilliseconds) {
    int inputIndex = evaluateNoteDurations
        ? nextInputIndex
        : nextEvaluationIndex;

    if (noteGroups.isEmpty || inputIndex >= noteGroups.length) {
      return false;
    }

    int? candidateIndex = _findClosestPendingGroup(elapsedMilliseconds);

    if (candidateIndex == null) {
      if (inputIndex > 0) {
        int previousGroupIndex = inputIndex - 1;
        ArPracticeNoteGroup previousGroup =
            noteGroups[previousGroupIndex];

        if (previousGroup.midiNotes.contains(midiNote) &&
            elapsedMilliseconds > previousGroup.startTime.inMilliseconds) {
          _recordPerformanceIssue(
            previousGroupIndex,
            PerformanceIssueType.late,
            playedMidiNote: midiNote,
            timingOffsetMs:
                elapsedMilliseconds -
                previousGroup.startTime.inMilliseconds,
          );
          _recordLatePerformanceTimingMistake(previousGroupIndex);
          return true;
        }
      }

      ArPracticeNoteGroup targetGroup = noteGroups[inputIndex];
      int timingOffset =
          elapsedMilliseconds - targetGroup.startTime.inMilliseconds;
      bool tooEarly =
          elapsedMilliseconds <
          targetGroup.startTime.inMilliseconds -
              timingTolerance.inMilliseconds;

      if (targetGroup.midiNotes.contains(midiNote)) {
        _recordPerformanceIssue(
          inputIndex,
          tooEarly ? PerformanceIssueType.early : PerformanceIssueType.late,
          playedMidiNote: midiNote,
          timingOffsetMs: timingOffset,
        );
        _recordAttemptMistake(
          inputIndex,
          tooEarly ? 'Too early' : 'Too late',
          result: ArPracticeNoteResult.timingMistake,
        );
      } else {
        _recordPerformanceIssue(
          inputIndex,
          PerformanceIssueType.wrongNote,
          playedMidiNote: midiNote,
          timingOffsetMs: timingOffset,
        );
        _recordAttemptMistake(
          inputIndex,
          'Wrong note',
          result: ArPracticeNoteResult.incorrect,
        );
      }

      return true;
    }

    ArPracticeNoteGroup group = noteGroups[candidateIndex];
    _ArPracticeAttempt attempt = _attemptFor(candidateIndex);
    int timingOffset =
        elapsedMilliseconds - group.startTime.inMilliseconds;
    attempt.playedMidiNotes.add(midiNote);
    attempt.timingOffsetsMs.add(timingOffset);

    if (!group.midiNotes.contains(midiNote)) {
      attempt.issueTypes.add(PerformanceIssueType.wrongNote);
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

    if (evaluateNoteDurations) {
      _activePerformanceGroupByMidiNote[midiNote] = candidateIndex;
    }

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
      attempt.issueTypes.add(PerformanceIssueType.chordTiming);
      _recordAttemptMistake(
        candidateIndex,
        'Chord notes were not together',
        result: ArPracticeNoteResult.timingMistake,
      );
      return true;
    }

    attempt.matched = true;
    attempt.result ??= ArPracticeNoteResult.correct;

    if (evaluateNoteDurations && candidateIndex == nextInputIndex) {
      nextInputIndex++;
    }

    feedbackText = evaluateNoteDurations
        ? 'Correct notes — keep holding'
        : attempt.hadMistake
        ? 'Correct after mistake'
        : 'Correct';
    feedbackKind = ArPracticeFeedbackKind.correct;
    return true;
  }

  /// Evaluates how long a Performance Mode key was held.
  bool recordPerformanceNoteOff(int midiNote, int elapsedMilliseconds) {
    if (!evaluateNoteDurations) {
      return false;
    }

    int? groupIndex = _activePerformanceGroupByMidiNote.remove(midiNote);

    if (groupIndex == null || groupIndex >= noteGroups.length) {
      return false;
    }

    _ArPracticeAttempt attempt = _attemptFor(groupIndex);
    int? pressedAt = attempt.notePressedAt[midiNote];

    if (pressedAt == null || attempt.finalized) {
      return false;
    }

    attempt.noteReleasedAt[midiNote] = elapsedMilliseconds;
    int heldMilliseconds = math.max(0, elapsedMilliseconds - pressedAt);
    int requiredMilliseconds = requiredHoldDurationFor(
      groupIndex,
      midiNote,
    ).inMilliseconds;

    if (heldMilliseconds < requiredMilliseconds) {
      attempt.issueTypes.add(PerformanceIssueType.releasedEarly);
      _recordAttemptMistake(
        groupIndex,
        'Released too soon',
        result: ArPracticeNoteResult.timingMistake,
      );
      return true;
    }

    feedbackText = 'Duration complete';
    feedbackKind = ArPracticeFeedbackKind.correct;
    return true;
  }

  /// Finalizes every group whose late-tolerance window has elapsed.
  ///
  /// Returns whether counters or colors changed.
  bool updatePerformanceTime(int elapsedMilliseconds) {
    bool stateChanged = false;

    if (evaluateNoteDurations) {
      while (nextInputIndex < noteGroups.length &&
          elapsedMilliseconds >=
              noteGroups[nextInputIndex].startTime.inMilliseconds +
                  timingTolerance.inMilliseconds) {
        nextInputIndex++;
      }
    }

    while (nextEvaluationIndex < noteGroups.length) {
      ArPracticeNoteGroup group = noteGroups[nextEvaluationIndex];
      int evaluationTime =
          group.startTime.inMilliseconds + timingTolerance.inMilliseconds;

      if (evaluateNoteDurations) {
        evaluationTime = math.max(
          evaluationTime,
          group.startTime.inMilliseconds +
              group.longestNoteDuration.inMilliseconds,
        );
        _ArPracticeAttempt? attempt = _attempts[nextEvaluationIndex];

        if (attempt != null) {
          for (int midiNote in group.midiNotes) {
            int? pressedAt = attempt.notePressedAt[midiNote];

            if (pressedAt != null) {
              evaluationTime = math.max(
                evaluationTime,
                pressedAt +
                    requiredHoldDurationFor(
                      nextEvaluationIndex,
                      midiNote,
                    ).inMilliseconds,
              );
            }
          }
        }
      }

      if (elapsedMilliseconds < evaluationTime) {
        break;
      }

      _finalizePerformanceGroup(nextEvaluationIndex, elapsedMilliseconds);
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

  /// Records an early release or excessive hold during Wait Mode.
  void recordWaitModeDurationMistake(int groupIndex, String message) {
    if (groupIndex < 0 || groupIndex >= noteGroups.length) {
      return;
    }

    _recordAttemptMistake(
      groupIndex,
      message,
      result: ArPracticeNoteResult.timingMistake,
    );
  }

  /// Shows duration guidance without modifying the attempt counters.
  void showDurationFeedback(String message, {bool isError = false}) {
    feedbackText = message;
    feedbackKind = isError
        ? ArPracticeFeedbackKind.warning
        : ArPracticeFeedbackKind.neutral;
  }

  /// Minimum accepted hold time for one note, matching Sight Reading's 60% rule.
  Duration requiredHoldDurationFor(int groupIndex, int midiNote) {
    if (groupIndex < 0 || groupIndex >= noteGroups.length) {
      return Duration.zero;
    }

    Duration duration = noteGroups[groupIndex].durationFor(midiNote);
    return Duration(
      milliseconds: math.max(
        0,
        (duration.inMilliseconds * minimumHoldRatio).round(),
      ),
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
    nextEvaluationIndex = math.max(nextEvaluationIndex, groupIndex + 1);

    if (attempt.hadMistake) {
      wrongGroupCount++;
      feedbackText = 'Correct after mistake';
    } else {
      correctGroupCount++;
      feedbackText = 'Correct';
    }

    feedbackKind = ArPracticeFeedbackKind.correct;
  }

  /// Reopens Wait Mode groups from [groupIndex] after an overlapping hold error.
  ///
  /// Finalized counters and transient note data are reversed, while genuine
  /// mistake flags remain so replaying a passage cannot erase an earlier error.
  void rewindWaitModeFromGroup(int groupIndex) {
    if (groupIndex < 0 || groupIndex >= noteGroups.length) {
      return;
    }

    for (MapEntry<int, _ArPracticeAttempt> entry in _attempts.entries) {
      if (entry.key < groupIndex) {
        continue;
      }

      _ArPracticeAttempt attempt = entry.value;

      if (attempt.finalized) {
        evaluatedGroupCount = math.max(0, evaluatedGroupCount - 1);

        if (attempt.matched && !attempt.hadMistake) {
          correctGroupCount = math.max(0, correctGroupCount - 1);
        } else if (attempt.hadMistake) {
          wrongGroupCount = math.max(0, wrongGroupCount - 1);
        } else {
          missedGroupCount = math.max(0, missedGroupCount - 1);
        }
      }

      attempt.notePressedAt.clear();
      attempt.noteReleasedAt.clear();
      attempt.matched = false;
      attempt.finalized = false;

      if (!attempt.hadMistake) {
        attempt.result = null;
      }
    }

    nextEvaluationIndex = groupIndex;
    nextInputIndex = math.min(nextInputIndex, groupIndex);
  }

  /// Marks all still-pending groups when timed playback reaches its end.
  void finalizeRemainingPerformanceGroups() {
    while (nextEvaluationIndex < noteGroups.length) {
      ArPracticeNoteGroup group = noteGroups[nextEvaluationIndex];
      _finalizePerformanceGroup(
        nextEvaluationIndex,
        group.startTime.inMilliseconds +
            group.longestNoteDuration.inMilliseconds,
      );
      nextEvaluationIndex++;
    }
  }

  /// Finds the closest current/next group inside the timing tolerance window.
  int? _findClosestPendingGroup(int elapsedMilliseconds) {
    int? closestIndex;
    int closestDistance = timingTolerance.inMilliseconds + 1;
    int firstCandidate = evaluateNoteDurations
        ? nextInputIndex
        : nextEvaluationIndex;
    int finalCandidate = (firstCandidate + 1)
        .clamp(0, noteGroups.length - 1)
        .toInt();

    for (
      int groupIndex = firstCandidate;
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

  void _recordPerformanceIssue(
    int groupIndex,
    PerformanceIssueType issueType, {
    int? playedMidiNote,
    int? timingOffsetMs,
  }) {
    _ArPracticeAttempt attempt = _attemptFor(groupIndex);
    attempt.issueTypes.add(issueType);

    if (playedMidiNote != null) {
      attempt.playedMidiNotes.add(playedMidiNote);
    }

    if (timingOffsetMs != null) {
      attempt.timingOffsetsMs.add(timingOffsetMs);
    }
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
  void _finalizePerformanceGroup(int groupIndex, int elapsedMilliseconds) {
    _ArPracticeAttempt attempt = _attemptFor(groupIndex);

    if (attempt.finalized) {
      return;
    }

    ArPracticeNoteGroup group = noteGroups[groupIndex];

    if (!group.midiNotes.every(attempt.playedMidiNotes.contains)) {
      attempt.issueTypes.add(PerformanceIssueType.missed);
    }

    if (evaluateNoteDurations && attempt.matched) {

      for (int midiNote in group.midiNotes) {
        int? pressedAt = attempt.notePressedAt[midiNote];

        if (pressedAt == null) {
          continue;
        }

        int heldUntil = attempt.noteReleasedAt[midiNote] ?? elapsedMilliseconds;
        int heldMilliseconds = math.max(0, heldUntil - pressedAt);

        if (heldMilliseconds <
            requiredHoldDurationFor(groupIndex, midiNote).inMilliseconds) {
          attempt.issueTypes.add(PerformanceIssueType.releasedEarly);
          _recordAttemptMistake(
            groupIndex,
            'Released too soon',
            result: ArPracticeNoteResult.timingMistake,
          );
        }
      }
    }

    attempt.finalized = true;
    _activePerformanceGroupByMidiNote.removeWhere(
      (_, int activeGroupIndex) => activeGroupIndex == groupIndex,
    );
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
      attempt.issueTypes.add(PerformanceIssueType.missed);
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
  final Map<int, int> noteReleasedAt = <int, int>{};
  final Set<int> playedMidiNotes = <int>{};
  final Set<PerformanceIssueType> issueTypes = <PerformanceIssueType>{};
  final List<int> timingOffsetsMs = <int>[];
  bool hadMistake = false;
  bool matched = false;
  bool finalized = false;
  ArPracticeNoteResult? result;
}
