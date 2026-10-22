import '../../ar/services/ar_practice_performance_tracker.dart';
import '../../ar/utils/midi_note_utils.dart';
import '../../sight_reading/practice_result_models.dart';

class SynthesiaPerformanceReportBuilder {
  const SynthesiaPerformanceReportBuilder();

  SightReadingPerformanceReport build({
    required ArPracticePerformanceTracker tracker,
    required String scoreDocumentPath,
    required String source,
    required String pieceTitle,
    required int targetDurationMs,
    required int elapsedDurationMs,
    required SynthesiaPerformanceReportMessages messages,
  }) {
    Map<int, int> noteTotals = <int, int>{};
    Map<int, int> noteErrors = <int, int>{};
    Map<int, int> noteMisses = <int, int>{};
    Map<int, int> wrongPlayedCounts = <int, int>{};
    List<PracticeResultErrorEvent> errorEvents = tracker.performanceErrorEvents;

    for (ArPracticeNoteGroup group in tracker.noteGroups) {
      for (int midiNote in group.midiNotes) {
        noteTotals.update(midiNote, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    for (PracticeResultErrorEvent event in errorEvents) {
      bool wasMissed = event.issueTypes.contains(PerformanceIssueType.missed);
      for (int midiNote in event.expectedMidiNotes) {
        noteErrors.update(midiNote, (value) => value + 1, ifAbsent: () => 1);
        if (wasMissed) {
          noteMisses.update(midiNote, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      Set<int> expected = event.expectedMidiNotes.toSet();
      for (int midiNote in event.playedMidiNotes) {
        if (!expected.contains(midiNote)) {
          wrongPlayedCounts.update(
            midiNote,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    Set<int> allNotes = <int>{...noteTotals.keys, ...wrongPlayedCounts.keys};
    List<NotePerformanceBreakdown> noteBreakdown = allNotes.map((midiNote) {
      return NotePerformanceBreakdown(
        midiNote: midiNote,
        totalCount: noteTotals[midiNote] ?? 0,
        errorCount: noteErrors[midiNote] ?? 0,
        missedCount: noteMisses[midiNote] ?? 0,
        wrongPlayedCount: wrongPlayedCounts[midiNote] ?? 0,
      );
    }).toList()
      ..sort((first, second) {
        int errorComparison = second.errorCount.compareTo(first.errorCount);
        return errorComparison != 0
            ? errorComparison
            : second.wrongPlayedCount.compareTo(first.wrongPlayedCount);
      });

    List<String> suggestions = _buildSuggestions(
      tracker: tracker,
      noteBreakdown: noteBreakdown,
      errorEvents: errorEvents,
      messages: messages,
    );
    PracticeResultSummary summary = PracticeResultSummary(
      practiceType: PracticeResultType.synthesia,
      ownerId: '',
      scoreDocumentPath: scoreDocumentPath,
      source: source,
      pieceTitle: pieceTitle,
      completedAt: null,
      targetDurationMs: targetDurationMs,
      elapsedDurationMs: elapsedDurationMs,
      correctCount: tracker.correctGroupCount,
      wrongCount: tracker.wrongGroupCount,
      missedCount: tracker.missedGroupCount,
      totalCount: tracker.totalGroupCount,
      timingAccuracyPercentage: tracker.accuracyPercentage,
      noteBreakdown: noteBreakdown,
      clefBreakdown: const <ClefPerformanceBreakdown>[],
      suggestions: suggestions,
      errorEventCount: errorEvents.length,
    );

    return SightReadingPerformanceReport(
      summary: summary,
      errorEvents: errorEvents,
      suggestions: suggestions,
    );
  }

  List<String> _buildSuggestions({
    required ArPracticePerformanceTracker tracker,
    required List<NotePerformanceBreakdown> noteBreakdown,
    required List<PracticeResultErrorEvent> errorEvents,
    required SynthesiaPerformanceReportMessages messages,
  }) {
    if (errorEvents.isEmpty) {
      return <String>[messages.perfectPerformance];
    }

    Map<PerformanceIssueType, int> issueCounts =
        <PerformanceIssueType, int>{};
    for (PracticeResultErrorEvent event in errorEvents) {
      for (PerformanceIssueType issue in event.issueTypes) {
        issueCounts.update(issue, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    List<String> suggestions = <String>[];
    int closeThreshold = (tracker.totalGroupCount * 0.10).ceil();
    if (closeThreshold < 1) closeThreshold = 1;
    if (errorEvents.length <= closeThreshold) {
      suggestions.add(
        messages.almostPerfect,
      );
    }

    List<NotePerformanceBreakdown> difficultNotes = noteBreakdown
        .where((item) => item.errorCount > 0)
        .toList()
      ..sort((first, second) => second.errorCount.compareTo(first.errorCount));
    if (difficultNotes.isNotEmpty && suggestions.length < 3) {
      NotePerformanceBreakdown note = difficultNotes.first;
      suggestions.add(
        messages.difficultNote(
          MidiNoteUtils.nameForMidiNote(note.midiNote),
        ),
      );
    }

    int releasedEarly = issueCounts[PerformanceIssueType.releasedEarly] ?? 0;
    int missed = issueCounts[PerformanceIssueType.missed] ?? 0;
    int early = issueCounts[PerformanceIssueType.early] ?? 0;
    int late = issueCounts[PerformanceIssueType.late] ?? 0;
    int chordTiming = issueCounts[PerformanceIssueType.chordTiming] ?? 0;
    int wrongNotes = issueCounts[PerformanceIssueType.wrongNote] ?? 0;

    if (releasedEarly > 0 && suggestions.length < 3) {
      suggestions.add(
        messages.releasedTooSoon,
      );
    }
    if (missed > 0 && suggestions.length < 3) {
      suggestions.add(
        messages.missedNotes,
      );
    }
    if (late > early && suggestions.length < 3) {
      suggestions.add(
        messages.playedLate,
      );
    } else if (early > late && suggestions.length < 3) {
      suggestions.add(
        messages.playedEarly,
      );
    }
    if (chordTiming > 0 && suggestions.length < 3) {
      suggestions.add(
        messages.chordTiming,
      );
    }
    if (wrongNotes > 0 && suggestions.length < 3) {
      suggestions.add(
        messages.wrongNotes,
      );
    }
    if (suggestions.isEmpty) {
      suggestions.add(
        messages.generalPractice,
      );
    }
    return suggestions.take(3).toList(growable: false);
  }
}

class SynthesiaPerformanceReportMessages {
  const SynthesiaPerformanceReportMessages({
    required this.perfectPerformance,
    required this.almostPerfect,
    required this.difficultNote,
    required this.releasedTooSoon,
    required this.missedNotes,
    required this.playedLate,
    required this.playedEarly,
    required this.chordTiming,
    required this.wrongNotes,
    required this.generalPractice,
  });

  final String perfectPerformance;
  final String almostPerfect;
  final String Function(String note) difficultNote;
  final String releasedTooSoon;
  final String missedNotes;
  final String playedLate;
  final String playedEarly;
  final String chordTiming;
  final String wrongNotes;
  final String generalPractice;
}
