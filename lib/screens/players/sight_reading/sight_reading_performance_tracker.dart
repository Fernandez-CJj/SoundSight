import 'dart:math' as math;

import 'midi_file_duration_calculator.dart';
import 'practice_result_models.dart';

class SightReadingPerformanceTracker {
  SightReadingPerformanceTracker({
    this.timingTolerance = const Duration(milliseconds: 300),
    this.chordPressWindow = const Duration(milliseconds: 200),
    this.minimumHoldRatio = 0.6,
  });

  Duration timingTolerance;
  final Duration chordPressWindow;
  final double minimumHoldRatio;

  List<MidiTimelineEvent> timelineEvents = const [];
  List<ScorePositionMetadata> scorePositions = const [];
  final Map<int, ScorePositionMetadata> metadataByEventIndex = {};
  Duration totalDuration = Duration.zero;
  final Map<int, PerformanceEventAttempt> eventAttempts = {};
  final Map<int, int> activePressEventByMidiNote = {};

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
    if (timelineEvents.isEmpty ||
        cursorEventIndex >= timelineEvents.length ||
        nextEvaluationIndex >= timelineEvents.length) {
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

  void loadTimeline(
    List<MidiTimelineEvent> events, {
    required Duration totalDuration,
  }) {
    timelineEvents = List<MidiTimelineEvent>.unmodifiable(events);
    this.totalDuration = totalDuration.isNegative
        ? Duration.zero
        : totalDuration;
    attachScorePositions(scorePositions);
    resetAttempt();
  }

  void attachScorePositions(List<ScorePositionMetadata> positions) {
    scorePositions = List<ScorePositionMetadata>.unmodifiable(positions);
    metadataByEventIndex.clear();

    var nextPositionIndex = 0;

    for (var eventIndex = 0; eventIndex < timelineEvents.length; eventIndex++) {
      final expectedNotes = timelineEvents[eventIndex].midiNotes;
      var matchedIndex = -1;
      final searchEnd = math.min(scorePositions.length, nextPositionIndex + 12);

      for (var index = nextPositionIndex; index < searchEnd; index++) {
        final positionNotes = scorePositions[index].midiNotes.toSet();

        if (positionNotes.length == expectedNotes.length &&
            positionNotes.containsAll(expectedNotes)) {
          matchedIndex = index;
          break;
        }
      }

      if (matchedIndex >= 0) {
        metadataByEventIndex[eventIndex] = scorePositions[matchedIndex];
        nextPositionIndex = matchedIndex + 1;
      }
    }
  }

  void resetAttempt() {
    eventAttempts.clear();
    activePressEventByMidiNote.clear();
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
            timelineEvents[cursorEventIndex + 1].scheduledTime.inMilliseconds) {
      cursorEventIndex++;
    }

    var stateChanged = cursorEventIndex != previousCursorIndex;

    if (stateChanged) {
      cursorIsWrong = false;
      resultText = 'Play on time';
    }

    final currentEvent = timelineEvents[cursorEventIndex];
    final currentAttempt = eventAttempts[cursorEventIndex];
    final pressDeadline = currentEvent.scheduledTime.inMilliseconds +
        timingTolerance.inMilliseconds;
    final currentNoteWasMissed =
        elapsedMilliseconds > pressDeadline &&
        !(currentAttempt?.matched ?? false);

    if (currentNoteWasMissed && !cursorIsWrong) {
      cursorIsWrong = true;
      resultText = 'Missed';
      stateChanged = true;
    }

    while (nextEvaluationIndex < timelineEvents.length) {
      final event = timelineEvents[nextEvaluationIndex];
      final attempt = eventAttempts[nextEvaluationIndex];
      var evaluationTime = math.max(
        event.scheduledTime.inMilliseconds + timingTolerance.inMilliseconds,
        event.scheduledTime.inMilliseconds +
            event.longestNoteDuration.inMilliseconds,
      );

      if (attempt != null) {
        for (final midiNote in event.midiNotes) {
          final pressedAt = attempt.notePressedAt[midiNote];
          if (pressedAt == null) continue;

          final requiredHold = _requiredHoldMilliseconds(event, midiNote);
          evaluationTime = math.max(evaluationTime, pressedAt + requiredHold);
        }
      }

      if (elapsedMilliseconds < evaluationTime) {
        break;
      }

      finalizeEvent(nextEvaluationIndex, elapsedMilliseconds);
      nextEvaluationIndex++;
      stateChanged = true;
    }

    return PerformanceTimelineUpdate(
      cursorAdvances: cursorEventIndex - previousCursorIndex,
      stateChanged: stateChanged,
      finished:
          nextEvaluationIndex >= timelineEvents.length &&
          elapsedMilliseconds >= totalDuration.inMilliseconds,
    );
  }

  void recordNoteOn(int midiNote, int elapsedMilliseconds) {
    if (timelineEvents.isEmpty ||
        nextEvaluationIndex >= timelineEvents.length) {
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
      attempt.playedMidiNotes.add(midiNote);
      attempt.wrongMidiNotes.add(midiNote);
      attempt.issueTypes.add(PerformanceIssueType.wrongNote);
      resultText = 'Wrong note';

      if (candidateIndex == cursorEventIndex) {
        cursorIsWrong = true;
      }

      return;
    }

    attempt.notePressedAt.putIfAbsent(midiNote, () => elapsedMilliseconds);
    activePressEventByMidiNote[midiNote] = candidateIndex;
    attempt.playedMidiNotes.add(midiNote);
    attempt.timingOffsetsMs.add(
      elapsedMilliseconds - event.scheduledTime.inMilliseconds,
    );

    final allExpectedNotesWerePressed = event.midiNotes.every(
      attempt.notePressedAt.containsKey,
    );

    if (!allExpectedNotesWerePressed) {
      resultText = 'Complete the chord';
      return;
    }

    final pressTimes =
        event.midiNotes.map((note) => attempt.notePressedAt[note]!).toList()
          ..sort();

    final chordSpread = pressTimes.last - pressTimes.first;

    if (chordSpread > chordPressWindow.inMilliseconds) {
      attempt.hadMistake = true;
      attempt.issueTypes.add(PerformanceIssueType.chordTiming);
      resultText = 'Chord notes were not together';

      if (candidateIndex == cursorEventIndex) {
        cursorIsWrong = true;
      }

      return;
    }

    attempt.matched = true;
    attempt.eventuallyMatched = true;
    final shouldHold = _requiredHoldMilliseconds(event, midiNote) > 200;
    resultText = attempt.hadMistake
        ? 'Correct after mistake'
        : shouldHold
        ? 'Correct — keep holding'
        : 'Correct';

    if (candidateIndex == cursorEventIndex) {
      cursorIsWrong = false;
    }
  }

  void recordNoteOff(int midiNote, int elapsedMilliseconds) {
    final eventIndex = activePressEventByMidiNote.remove(midiNote);
    if (eventIndex == null || eventIndex >= timelineEvents.length) {
      return;
    }

    final attempt = eventAttempts[eventIndex];
    final pressedAt = attempt?.notePressedAt[midiNote];
    if (attempt == null || pressedAt == null || attempt.finalized) {
      return;
    }

    attempt.noteReleasedAt[midiNote] = elapsedMilliseconds;
    final heldDuration = math.max(0, elapsedMilliseconds - pressedAt);
    final requiredHold = _requiredHoldMilliseconds(
      timelineEvents[eventIndex],
      midiNote,
    );

    if (heldDuration >= requiredHold) {
      return;
    }

    attempt.hadMistake = true;
    attempt.issueTypes.add(PerformanceIssueType.releasedEarly);
    resultText = 'Released too soon';

    if (eventIndex == cursorEventIndex) {
      cursorIsWrong = true;
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

      final eventTime = timelineEvents[eventIndex].scheduledTime.inMilliseconds;
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
    attempt.playedMidiNotes.add(midiNote);

    final scheduledTime =
        timelineEvents[eventIndex].scheduledTime.inMilliseconds;

    final timingOffset = elapsedMilliseconds - scheduledTime;
    attempt.timingOffsetsMs.add(timingOffset);

    if (timelineEvents[eventIndex].midiNotes.contains(midiNote)) {
      attempt.issueTypes.add(
        timingOffset < 0
            ? PerformanceIssueType.early
            : PerformanceIssueType.late,
      );
    } else {
      attempt.wrongMidiNotes.add(midiNote);
      attempt.issueTypes.add(PerformanceIssueType.wrongNote);
    }

    resultText = elapsedMilliseconds < scheduledTime ? 'Too early' : 'Too late';

    if (eventIndex == cursorEventIndex) {
      cursorIsWrong = true;
    }
  }

  void finalizeEvent(int eventIndex, int elapsedMilliseconds) {
    final attempt = eventAttempts.putIfAbsent(
      eventIndex,
      PerformanceEventAttempt.new,
    );

    if (attempt.finalized) {
      return;
    }

    if (attempt.matched) {
      final event = timelineEvents[eventIndex];

      for (final midiNote in event.midiNotes) {
        final pressedAt = attempt.notePressedAt[midiNote];
        if (pressedAt == null) continue;

        final heldUntil =
            attempt.noteReleasedAt[midiNote] ?? elapsedMilliseconds;
        final heldDuration = math.max(0, heldUntil - pressedAt);

        if (heldDuration < _requiredHoldMilliseconds(event, midiNote)) {
          attempt.hadMistake = true;
          attempt.issueTypes.add(PerformanceIssueType.releasedEarly);
        }
      }
    }

    attempt.finalized = true;
    activePressEventByMidiNote.removeWhere(
      (_, activeEventIndex) => activeEventIndex == eventIndex,
    );
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
      attempt.issueTypes.add(PerformanceIssueType.missed);

      if (isCurrentCursorEvent) {
        cursorIsWrong = true;
        resultText = 'Missed';
      }
    }
  }

  int _requiredHoldMilliseconds(MidiTimelineEvent event, int midiNote) {
    final expectedDuration = event.noteDurations[midiNote] ?? Duration.zero;
    return math.max(
      0,
      (expectedDuration.inMilliseconds * minimumHoldRatio).round(),
    );
  }

  SightReadingPerformanceReport buildReport({
    required String ownerId,
    required String scoreDocumentPath,
    required String source,
    required String pieceTitle,
    required int elapsedDurationMs,
    required SightReadingPerformanceReportMessages messages,
  }) {
    final noteTotals = <int, int>{};
    final noteErrors = <int, int>{};
    final noteMisses = <int, int>{};
    final wrongPlayedCounts = <int, int>{};
    final clefTotals = <String, int>{};
    final clefErrors = <String, int>{};
    final clefMisses = <String, int>{};
    final errorEvents = <PracticeResultErrorEvent>[];
    final issueCounts = <PerformanceIssueType, int>{};

    for (var eventIndex = 0; eventIndex < timelineEvents.length; eventIndex++) {
      final event = timelineEvents[eventIndex];
      final attempt = eventAttempts[eventIndex] ?? PerformanceEventAttempt();
      final metadata = metadataByEventIndex[eventIndex];
      final clefs = metadata?.clefs.isNotEmpty == true
          ? metadata!.clefs
          : const <String>['unknown'];
      final issueTypes = attempt.issueTypes.toList()
        ..sort((first, second) => first.index.compareTo(second.index));
      final hasError = issueTypes.isNotEmpty || attempt.hadMistake;
      final isMissed = issueTypes.contains(PerformanceIssueType.missed);

      for (final midiNote in event.midiNotes) {
        noteTotals.update(midiNote, (value) => value + 1, ifAbsent: () => 1);

        if (hasError) {
          noteErrors.update(midiNote, (value) => value + 1, ifAbsent: () => 1);
        }

        if (isMissed) {
          noteMisses.update(midiNote, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      for (final midiNote in attempt.wrongMidiNotes) {
        wrongPlayedCounts.update(
          midiNote,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      for (final clef in clefs.toSet()) {
        clefTotals.update(clef, (value) => value + 1, ifAbsent: () => 1);

        if (hasError) {
          clefErrors.update(clef, (value) => value + 1, ifAbsent: () => 1);
        }

        if (isMissed) {
          clefMisses.update(clef, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      for (final issueType in issueTypes) {
        issueCounts.update(issueType, (value) => value + 1, ifAbsent: () => 1);
      }

      if (hasError) {
        errorEvents.add(
          PracticeResultErrorEvent(
            positionIndex: eventIndex,
            measureNumber: metadata?.measureNumber,
            scheduledTimeMs: event.scheduledTime.inMilliseconds,
            expectedMidiNotes: event.midiNotes.toList()..sort(),
            playedMidiNotes: attempt.playedMidiNotes.toList()..sort(),
            clefs: clefs.toSet().toList(),
            staffNumbers: metadata?.staffNumbers ?? const [],
            issueTypes: issueTypes,
            timingOffsetMs: _representativeTimingOffset(
              attempt.timingOffsetsMs,
            ),
            eventuallyMatched: attempt.eventuallyMatched,
          ),
        );
      }
    }

    final allNotes = <int>{...noteTotals.keys, ...wrongPlayedCounts.keys};
    final noteBreakdown =
        allNotes.map((midiNote) {
          return NotePerformanceBreakdown(
            midiNote: midiNote,
            totalCount: noteTotals[midiNote] ?? 0,
            errorCount: noteErrors[midiNote] ?? 0,
            missedCount: noteMisses[midiNote] ?? 0,
            wrongPlayedCount: wrongPlayedCounts[midiNote] ?? 0,
          );
        }).toList()..sort((first, second) {
          final errorComparison = second.errorCount.compareTo(first.errorCount);
          return errorComparison != 0
              ? errorComparison
              : second.wrongPlayedCount.compareTo(first.wrongPlayedCount);
        });

    final clefBreakdown =
        clefTotals.keys.map((clef) {
          return ClefPerformanceBreakdown(
            clef: clef,
            totalCount: clefTotals[clef] ?? 0,
            errorCount: clefErrors[clef] ?? 0,
            missedCount: clefMisses[clef] ?? 0,
          );
        }).toList()..sort(
          (first, second) => second.errorCount.compareTo(first.errorCount),
        );

    final suggestions = _buildSuggestions(
      noteBreakdown: noteBreakdown,
      clefBreakdown: clefBreakdown,
      issueCounts: issueCounts,
      errorEventCount: errorEvents.length,
      totalEventCount: totalEventCount,
      messages: messages,
    );

    final summary = PracticeResultSummary(
      ownerId: ownerId,
      scoreDocumentPath: scoreDocumentPath,
      source: source,
      pieceTitle: pieceTitle,
      completedAt: null,
      targetDurationMs: totalDuration.inMilliseconds,
      elapsedDurationMs: elapsedDurationMs,
      correctCount: correctEventCount,
      wrongCount: wrongEventCount,
      missedCount: missedEventCount,
      totalCount: totalEventCount,
      timingAccuracyPercentage: timingAccuracyPercentage,
      noteBreakdown: noteBreakdown,
      clefBreakdown: clefBreakdown,
      suggestions: suggestions,
      errorEventCount: errorEvents.length,
    );

    return SightReadingPerformanceReport(
      summary: summary,
      errorEvents: errorEvents,
      suggestions: suggestions,
    );
  }

  int? _representativeTimingOffset(List<int> timingOffsets) {
    if (timingOffsets.isEmpty) {
      return null;
    }

    return timingOffsets.reduce((first, second) {
      return first.abs() <= second.abs() ? first : second;
    });
  }

  List<String> _buildSuggestions({
    required List<NotePerformanceBreakdown> noteBreakdown,
    required List<ClefPerformanceBreakdown> clefBreakdown,
    required Map<PerformanceIssueType, int> issueCounts,
    required int errorEventCount,
    required int totalEventCount,
    required SightReadingPerformanceReportMessages messages,
  }) {
    if (errorEventCount == 0) {
      return [messages.perfectPerformance];
    }

    final suggestions = <String>[];

    if (errorEventCount <= math.max(1, (totalEventCount * 0.10).ceil())) {
      suggestions.add(messages.almostPerfect);
    }

    final weakClefs =
        clefBreakdown.where((item) {
          return item.clef != 'unknown' &&
              item.errorCount >= 3 &&
              item.errorRate >= 0.30;
        }).toList()..sort(
          (first, second) => second.errorRate.compareTo(first.errorRate),
        );

    if (weakClefs.isNotEmpty) {
      final weakClef = weakClefs.first;
      if (weakClef.clef == 'bass') {
        suggestions.add(messages.bassClef);
      } else if (weakClef.clef == 'treble') {
        suggestions.add(messages.trebleClef);
      } else {
        suggestions.add(messages.otherClef(weakClef.clef));
      }
    }

    final difficultNotes =
        noteBreakdown.where((item) {
          return item.totalCount > 0 &&
              item.errorCount >= 3 &&
              item.errorRate >= 0.30;
        }).toList()..sort(
          (first, second) => second.errorRate.compareTo(first.errorRate),
        );

    if (difficultNotes.isNotEmpty && suggestions.length < 3) {
      final note = difficultNotes.first;
      suggestions.add(messages.difficultNote(_midiNoteName(note.midiNote)));
    }

    final missedCount = issueCounts[PerformanceIssueType.missed] ?? 0;
    final earlyCount = issueCounts[PerformanceIssueType.early] ?? 0;
    final lateCount = issueCounts[PerformanceIssueType.late] ?? 0;
    final chordCount = issueCounts[PerformanceIssueType.chordTiming] ?? 0;
    final releasedEarlyCount =
        issueCounts[PerformanceIssueType.releasedEarly] ?? 0;

    if (suggestions.length < 3 && releasedEarlyCount >= 3) {
      suggestions.add(messages.releasedTooSoon);
    }

    if (suggestions.length < 3 && missedCount >= 3) {
      suggestions.add(messages.missedNotes);
    }

    if (suggestions.length < 3 && lateCount >= 3 && lateCount > earlyCount) {
      suggestions.add(messages.playedLate);
    } else if (suggestions.length < 3 &&
        earlyCount >= 3 &&
        earlyCount > lateCount) {
      suggestions.add(messages.playedEarly);
    }

    if (suggestions.length < 3 && chordCount >= 3) {
      suggestions.add(messages.chordTiming);
    }

    if (suggestions.isEmpty) {
      suggestions.add(messages.generalPractice);
    }

    return suggestions.take(3).toList(growable: false);
  }

  String _midiNoteName(int midiNote) {
    const names = <String>[
      'C',
      'C♯',
      'D',
      'D♯',
      'E',
      'F',
      'F♯',
      'G',
      'G♯',
      'A',
      'A♯',
      'B',
    ];
    final normalized = midiNote.clamp(0, 127).toInt();
    final octave = normalized ~/ 12 - 1;
    return '${names[normalized % 12]}$octave';
  }

}

class SightReadingPerformanceReportMessages {
  const SightReadingPerformanceReportMessages({
    required this.perfectPerformance,
    required this.almostPerfect,
    required this.bassClef,
    required this.trebleClef,
    required this.otherClef,
    required this.difficultNote,
    required this.releasedTooSoon,
    required this.missedNotes,
    required this.playedLate,
    required this.playedEarly,
    required this.chordTiming,
    required this.generalPractice,
  });

  final String perfectPerformance;
  final String almostPerfect;
  final String bassClef;
  final String trebleClef;
  final String Function(String clef) otherClef;
  final String Function(String note) difficultNote;
  final String releasedTooSoon;
  final String missedNotes;
  final String playedLate;
  final String playedEarly;
  final String chordTiming;
  final String generalPractice;
}

class PerformanceEventAttempt {
  final Map<int, int> notePressedAt = {};
  final Map<int, int> noteReleasedAt = {};
  final Set<int> playedMidiNotes = {};
  final Set<int> wrongMidiNotes = {};
  final List<int> timingOffsetsMs = [];
  final Set<PerformanceIssueType> issueTypes = {};
  bool hadMistake = false;
  bool matched = false;
  bool eventuallyMatched = false;
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
