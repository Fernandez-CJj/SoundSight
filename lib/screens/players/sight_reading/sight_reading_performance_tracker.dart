import 'dart:math' as math;

import 'midi_file_duration_calculator.dart';

class SightReadingPerformanceTracker {
  SightReadingPerformanceTracker({
    this.timingTolerance = const Duration(milliseconds: 300),
    this.chordPressWindow = const Duration(milliseconds: 200),
  });

  Duration timingTolerance;
  final Duration chordPressWindow;

  List<MidiTimelineEvent> timelineEvents = const [];
  final Map<int, PerformanceEventAttempt> eventAttempts = {};

  int cursorEventIndex = 0;
  int nextEvaluationIndex = 0;
  int evaluatedEventCount = 0;
  int correctEventCount = 0;
  int wrongEventCount = 0;
  int missedEventCount = 0;
  bool cursorIsWrong = false;
  String resultText = 'Ready';

  bool get hasTimeline => timelineEvents.isNotEmpty;

  int get totalEventCount => timelineEvents.length;

  int get totalMistakes => wrongEventCount + missedEventCount;

  int get timingAccuracyPercentage => totalEventCount == 0
      ? 0
      : (correctEventCount / totalEventCount * 100).round();

  String get scoreText => '$correctEventCount/$totalEventCount';

  Set<int> get currentExpectedNotes {
    if (timelineEvents.isEmpty || cursorEventIndex >= timelineEvents.length) {
      return const {};
    }

    return timelineEvents[cursorEventIndex].midiNotes;
  }

  void applySkillLevel(String skillLevel) {
    if (skillLevel == 'beginner') {
      timingTolerance = const Duration(milliseconds: 400);
    } else if (skillLevel == 'advanced') {
      timingTolerance = const Duration(milliseconds: 200);
    } else {
      timingTolerance = const Duration(milliseconds: 300);
    }
  }

  void loadTimeline(List<MidiTimelineEvent> events) {
    timelineEvents = List<MidiTimelineEvent>.unmodifiable(events);
    resetAttempt();
  }

  void resetAttempt() {
    eventAttempts.clear();
    cursorEventIndex = 0;
    nextEvaluationIndex = 0;
    evaluatedEventCount = 0;
    correctEventCount = 0;
    wrongEventCount = 0;
    missedEventCount = 0;
    cursorIsWrong = false;
    resultText = timelineEvents.isEmpty ? 'Waiting for MIDI file' : 'Ready';
  }

  PerformanceTimelineUpdate updateElapsedTime(int elapsedMilliseconds) {
    if (timelineEvents.isEmpty) {
      return const PerformanceTimelineUpdate();
    }

    final previousCursorIndex = cursorEventIndex;

    while (cursorEventIndex + 1 < timelineEvents.length &&
        elapsedMilliseconds >=
            timelineEvents[cursorEventIndex + 1]
                .scheduledTime
                .inMilliseconds) {
      cursorEventIndex++;
    }

    var stateChanged = cursorEventIndex != previousCursorIndex;

    if (stateChanged) {
      cursorIsWrong = false;
      resultText = 'Play on time';
    }

    while (nextEvaluationIndex < timelineEvents.length) {
      final event = timelineEvents[nextEvaluationIndex];
      final evaluationTime =
          event.scheduledTime.inMilliseconds + timingTolerance.inMilliseconds;

      if (elapsedMilliseconds < evaluationTime) {
        break;
      }

      finalizeEvent(nextEvaluationIndex);
      nextEvaluationIndex++;
      stateChanged = true;
    }

    return PerformanceTimelineUpdate(
      cursorAdvances: cursorEventIndex - previousCursorIndex,
      stateChanged: stateChanged,
      finished: nextEvaluationIndex >= timelineEvents.length,
    );
  }

  void recordNoteOn(int midiNote, int elapsedMilliseconds) {
    if (timelineEvents.isEmpty || nextEvaluationIndex >= timelineEvents.length) {
      return;
    }

    final candidateIndex = findClosestEventIndex(elapsedMilliseconds);

    if (candidateIndex == null) {
      recordTimingMistake(midiNote, elapsedMilliseconds);
      return;
    }

    final event = timelineEvents[candidateIndex];
    final attempt = eventAttempts.putIfAbsent(
      candidateIndex,
      PerformanceEventAttempt.new,
    );

    if (!event.midiNotes.contains(midiNote)) {
      attempt.hadMistake = true;
      resultText = 'Wrong note';

      if (candidateIndex == cursorEventIndex) {
        cursorIsWrong = true;
      }

      return;
    }

    attempt.notePressedAt.putIfAbsent(midiNote, () => elapsedMilliseconds);

    final allExpectedNotesWerePressed = event.midiNotes.every(
      attempt.notePressedAt.containsKey,
    );

    if (!allExpectedNotesWerePressed) {
      resultText = 'Complete the chord';
      return;
    }

    final pressTimes = event.midiNotes
        .map((note) => attempt.notePressedAt[note]!)
        .toList()
      ..sort();

    final chordSpread = pressTimes.last - pressTimes.first;

    if (chordSpread > chordPressWindow.inMilliseconds) {
      attempt.hadMistake = true;
      resultText = 'Chord notes were not together';

      if (candidateIndex == cursorEventIndex) {
        cursorIsWrong = true;
      }

      return;
    }

    attempt.matched = true;
    resultText = attempt.hadMistake ? 'Correct after mistake' : 'Correct';

    if (candidateIndex == cursorEventIndex) {
      cursorIsWrong = false;
    }
  }

  int? findClosestEventIndex(int elapsedMilliseconds) {
    int? closestIndex;
    var closestDistance = timingTolerance.inMilliseconds + 1;
    final firstCandidate = math.max(0, cursorEventIndex - 1);
    final finalCandidate = math.min(
      timelineEvents.length - 1,
      cursorEventIndex + 1,
    );

    for (
      var eventIndex = firstCandidate;
      eventIndex <= finalCandidate;
      eventIndex++
    ) {
      if (eventIndex < nextEvaluationIndex) {
        continue;
      }

      final eventTime =
          timelineEvents[eventIndex].scheduledTime.inMilliseconds;
      final distance = (elapsedMilliseconds - eventTime).abs();

      if (distance <= timingTolerance.inMilliseconds &&
          distance < closestDistance) {
        closestIndex = eventIndex;
        closestDistance = distance;
      }
    }

    return closestIndex;
  }

  void recordTimingMistake(int midiNote, int elapsedMilliseconds) {
    var eventIndex = cursorEventIndex;

    if (cursorEventIndex + 1 < timelineEvents.length) {
      final nextEvent = timelineEvents[cursorEventIndex + 1];

      if (nextEvent.midiNotes.contains(midiNote) &&
          elapsedMilliseconds < nextEvent.scheduledTime.inMilliseconds) {
        eventIndex = cursorEventIndex + 1;
      }
    }

    final attempt = eventAttempts.putIfAbsent(
      eventIndex,
      PerformanceEventAttempt.new,
    );
    attempt.hadMistake = true;

    final scheduledTime =
        timelineEvents[eventIndex].scheduledTime.inMilliseconds;

    resultText = elapsedMilliseconds < scheduledTime ? 'Too early' : 'Too late';

    if (eventIndex == cursorEventIndex) {
      cursorIsWrong = true;
    }
  }

  void finalizeEvent(int eventIndex) {
    final attempt = eventAttempts.putIfAbsent(
      eventIndex,
      PerformanceEventAttempt.new,
    );

    if (attempt.finalized) {
      return;
    }

    attempt.finalized = true;
    evaluatedEventCount++;
    final isCurrentCursorEvent = eventIndex == cursorEventIndex;

    if (attempt.matched && !attempt.hadMistake) {
      correctEventCount++;

      if (isCurrentCursorEvent) {
        cursorIsWrong = false;
        resultText = 'Correct';
      }
    } else if (attempt.hadMistake) {
      wrongEventCount++;

      if (isCurrentCursorEvent) {
        cursorIsWrong = true;
        resultText = 'Wrong';
      }
    } else {
      missedEventCount++;

      if (isCurrentCursorEvent) {
        cursorIsWrong = true;
        resultText = 'Missed';
      }
    }
  }
}

class PerformanceEventAttempt {
  final Map<int, int> notePressedAt = {};
  bool hadMistake = false;
  bool matched = false;
  bool finalized = false;
}

class PerformanceTimelineUpdate {
  const PerformanceTimelineUpdate({
    this.cursorAdvances = 0,
    this.stateChanged = false,
    this.finished = false,
  });

  final int cursorAdvances;
  final bool stateChanged;
  final bool finished;
}
