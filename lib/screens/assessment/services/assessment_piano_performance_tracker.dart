import 'dart:math' as math;

import '../models/assessment_piano_task.dart';

/// Immediate feedback produced while one piano task is running.
enum AssessmentPianoFeedbackKind {
  neutral,
  correct,
  warning,
  incorrect,
}

/// The finalized result of one expected note or chord group.
enum AssessmentPianoGroupResult {
  correct,
  wrong,
  missed,
}

/// Evaluates MIDI note attacks against one piano-execution task.
///
/// The screen supplies note-on events from the app's existing MidiInputService
/// and elapsed time from a Stopwatch. No phone wall-clock time is used.
class AssessmentPianoPerformanceTracker {
  AssessmentPianoPerformanceTracker({
    this.chordPressWindow = const Duration(milliseconds: 200),
  });

  /// Maximum distance allowed between the first and last note of a chord.
  final Duration chordPressWindow;

  AssessmentPianoTask? _task;
  final Map<int, _AssessmentPianoGroupAttempt> _attempts = {};

  int nextEvaluationIndex = 0;
  int evaluatedGroupCount = 0;
  int correctGroupCount = 0;
  int wrongGroupCount = 0;
  int missedGroupCount = 0;
  int timingMistakeCount = 0;
  String feedbackText = 'Ready';
  AssessmentPianoFeedbackKind feedbackKind =
      AssessmentPianoFeedbackKind.neutral;

  /// The task currently loaded into the tracker.
  AssessmentPianoTask? get task => _task;

  /// True after every expected note or chord has been finalized.
  bool get isFinished {
    final currentTask = _task;

    return currentTask != null &&
        nextEvaluationIndex >= currentTask.noteGroups.length;
  }

  /// The total number of expected note or chord groups.
  int get totalGroupCount {
    return _task?.noteGroups.length ?? 0;
  }

  /// The timing allowance for the current task's difficulty.
  Duration get timingTolerance {
    switch (_task?.difficulty) {
      case AssessmentPianoDifficulty.beginner:
        return const Duration(milliseconds: 500);

      case AssessmentPianoDifficulty.intermediate:
        return const Duration(milliseconds: 350);

      case AssessmentPianoDifficulty.advanced:
        return const Duration(milliseconds: 250);

      case null:
        return Duration.zero;
    }
  }

  /// Loads a new task and clears all previous performance state.
  void loadTask(AssessmentPianoTask task) {
    _task = task;
    resetAttempt();
  }

  /// Clears all recorded attacks, counters, and feedback.
  void resetAttempt() {
    _attempts.clear();
    nextEvaluationIndex = 0;
    evaluatedGroupCount = 0;
    correctGroupCount = 0;
    wrongGroupCount = 0;
    missedGroupCount = 0;
    timingMistakeCount = 0;
    feedbackText = _task == null ? 'No task loaded' : 'Ready';
    feedbackKind = AssessmentPianoFeedbackKind.neutral;
  }

  /// Evaluates one MIDI note-on event against the nearest pending group.
  bool recordNoteOn(int midiNote, int elapsedMilliseconds) {
    final currentTask = _task;

    if (currentTask == null || isFinished) {
      return false;
    }

    final candidateIndex = _findClosestPendingGroup(elapsedMilliseconds);

    if (candidateIndex == null) {
      _recordOutOfWindowAttack(midiNote, elapsedMilliseconds);
      return true;
    }

    final group = currentTask.noteGroups[candidateIndex];
    final attempt = _attemptFor(candidateIndex);

    if (!group.midiNotes.contains(midiNote)) {
      attempt.hadPitchMistake = true;
      feedbackText = 'Wrong note';
      feedbackKind = AssessmentPianoFeedbackKind.incorrect;
      return true;
    }

    // Repeated attacks of the same expected pitch do not replace its first
    // attack time or provide another chance to improve the result.
    attempt.notePressedAt.putIfAbsent(midiNote, () => elapsedMilliseconds);

    final completedGroup = group.midiNotes.every(
      attempt.notePressedAt.containsKey,
    );

    if (!completedGroup) {
      feedbackText = 'Complete the chord';
      feedbackKind = AssessmentPianoFeedbackKind.warning;
      return true;
    }

    final attackTimes = group.midiNotes
        .map((note) => attempt.notePressedAt[note]!)
        .toList()
      ..sort();

    if (attackTimes.last - attackTimes.first >
        chordPressWindow.inMilliseconds) {
      attempt.hadTimingMistake = true;
      feedbackText = 'Chord notes were not together';
      feedbackKind = AssessmentPianoFeedbackKind.warning;
      return true;
    }

    attempt.matched = true;

    if (attempt.hadPitchMistake || attempt.hadTimingMistake) {
      feedbackText = 'Completed after a mistake';
      feedbackKind = AssessmentPianoFeedbackKind.warning;
    } else {
      feedbackText = 'Correct';
      feedbackKind = AssessmentPianoFeedbackKind.correct;
    }

    return true;
  }

  /// Finalizes every group whose late timing window has passed.
  bool updateElapsedTime(int elapsedMilliseconds) {
    final currentTask = _task;

    if (currentTask == null || isFinished) {
      return false;
    }

    var stateChanged = false;

    while (nextEvaluationIndex < currentTask.noteGroups.length) {
      final group = currentTask.noteGroups[nextEvaluationIndex];
      final scheduledMilliseconds = currentTask
          .scheduledTimeFor(group)
          .inMilliseconds;
      final evaluationTime =
          scheduledMilliseconds + timingTolerance.inMilliseconds;

      if (elapsedMilliseconds < evaluationTime) {
        break;
      }

      _finalizeGroup(nextEvaluationIndex);
      nextEvaluationIndex++;
      stateChanged = true;
    }

    return stateChanged;
  }

  /// Finalizes any pending groups when task playback reaches its end.
  void finalizeRemainingGroups() {
    final currentTask = _task;

    if (currentTask == null) {
      return;
    }

    while (nextEvaluationIndex < currentTask.noteGroups.length) {
      _finalizeGroup(nextEvaluationIndex);
      nextEvaluationIndex++;
    }
  }

  /// Returns the immutable result after the task has been finalized.
  AssessmentPianoTaskResult buildResult() {
    final currentTask = _task;

    if (currentTask == null) {
      throw StateError('A piano task must be loaded before building a result.');
    }

    if (!isFinished) {
      throw StateError('The piano task must finish before building a result.');
    }

    return AssessmentPianoTaskResult(
      taskId: currentTask.id,
      difficulty: currentTask.difficulty,
      totalGroupCount: currentTask.noteGroups.length,
      correctGroupCount: correctGroupCount,
      wrongGroupCount: wrongGroupCount,
      missedGroupCount: missedGroupCount,
      timingMistakeCount: timingMistakeCount,
    );
  }

  /// Finds the closest current or next group within the timing allowance.
  int? _findClosestPendingGroup(int elapsedMilliseconds) {
    final currentTask = _task;

    if (currentTask == null || isFinished) {
      return null;
    }

    int? closestIndex;
    var closestDistance = timingTolerance.inMilliseconds + 1;
    final finalCandidate = math.min(
      currentTask.noteGroups.length - 1,
      nextEvaluationIndex + 1,
    );

    for (
      var groupIndex = nextEvaluationIndex;
      groupIndex <= finalCandidate;
      groupIndex++
    ) {
      final scheduledMilliseconds = currentTask
          .scheduledTimeFor(currentTask.noteGroups[groupIndex])
          .inMilliseconds;
      final distance = (elapsedMilliseconds - scheduledMilliseconds).abs();

      if (distance <= timingTolerance.inMilliseconds &&
          distance < closestDistance) {
        closestIndex = groupIndex;
        closestDistance = distance;
      }
    }

    return closestIndex;
  }

  /// Records an early, late, or unrelated attack against the current group.
  void _recordOutOfWindowAttack(int midiNote, int elapsedMilliseconds) {
    final currentTask = _task;

    if (currentTask == null || isFinished) {
      return;
    }

    final group = currentTask.noteGroups[nextEvaluationIndex];
    final attempt = _attemptFor(nextEvaluationIndex);
    final scheduledMilliseconds = currentTask
        .scheduledTimeFor(group)
        .inMilliseconds;

    if (group.midiNotes.contains(midiNote)) {
      attempt.hadTimingMistake = true;
      feedbackText = elapsedMilliseconds < scheduledMilliseconds
          ? 'Too early'
          : 'Too late';
      feedbackKind = AssessmentPianoFeedbackKind.warning;
    } else {
      attempt.hadPitchMistake = true;
      feedbackText = 'Wrong note';
      feedbackKind = AssessmentPianoFeedbackKind.incorrect;
    }
  }

  /// Commits one group's counters exactly once.
  void _finalizeGroup(int groupIndex) {
    final attempt = _attemptFor(groupIndex);

    if (attempt.finalized) {
      return;
    }

    attempt.finalized = true;
    evaluatedGroupCount++;

    if (attempt.matched &&
        !attempt.hadPitchMistake &&
        !attempt.hadTimingMistake) {
      attempt.result = AssessmentPianoGroupResult.correct;
      correctGroupCount++;
      feedbackText = 'Correct';
      feedbackKind = AssessmentPianoFeedbackKind.correct;
      return;
    }

    if (attempt.hadPitchMistake || attempt.hadTimingMistake) {
      attempt.result = AssessmentPianoGroupResult.wrong;
      wrongGroupCount++;

      if (attempt.hadTimingMistake) {
        timingMistakeCount++;
      }

      feedbackText = attempt.hadPitchMistake ? 'Wrong' : 'Timing missed';
      feedbackKind = attempt.hadPitchMistake
          ? AssessmentPianoFeedbackKind.incorrect
          : AssessmentPianoFeedbackKind.warning;
      return;
    }

    attempt.result = AssessmentPianoGroupResult.missed;
    missedGroupCount++;
    feedbackText = 'Missed';
    feedbackKind = AssessmentPianoFeedbackKind.incorrect;
  }

  /// Returns existing mutable state or creates it on the first event.
  _AssessmentPianoGroupAttempt _attemptFor(int groupIndex) {
    return _attempts.putIfAbsent(
      groupIndex,
      _AssessmentPianoGroupAttempt.new,
    );
  }
}

/// Internal mutable state for one expected note or chord group.
class _AssessmentPianoGroupAttempt {
  final Map<int, int> notePressedAt = {};
  bool hadPitchMistake = false;
  bool hadTimingMistake = false;
  bool matched = false;
  bool finalized = false;
  AssessmentPianoGroupResult? result;
}
