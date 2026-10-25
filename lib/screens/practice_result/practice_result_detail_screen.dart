import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/lessons/lesson_localization.dart';
import 'package:soundsight/screens/midi/utils/midi_note_converter.dart';
import 'package:soundsight/screens/players/sight_reading/practice_result_models.dart';
import 'package:soundsight/screens/players/sight_reading/practice_result_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class PracticeResultDetailScreen extends StatelessWidget {
  const PracticeResultDetailScreen({
    super.key,
    required this.result,
    required this.colors,
  });

  final PracticeResultSummary result;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final resultId = result.id;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        title: Text(context.l10n.practiceResultTitle),
      ),
      body: resultId == null
          ? buildUnavailableState(context)
          : StreamBuilder<List<PracticeResultErrorEvent>>(
              stream: PracticeResultService().watchErrorEvents(resultId),
              builder: (context, snapshot) {
                final events = snapshot.data ?? const [];

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    buildSummaryCard(context),
                    const Gap(AppSpacing.md),
                    buildBreakdownCard(context, events),
                    const Gap(AppSpacing.md),
                    buildSuggestionsCard(context),
                    const Gap(AppSpacing.md),
                    buildErrorLog(context, snapshot, events),
                  ],
                );
              },
            ),
    );
  }

  Widget buildSummaryCard(BuildContext context) {
    final accentColor = resultTypeColor();

    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            resultTypeIcon(),
                            size: 13,
                            color: accentColor,
                          ),
                          const Gap(AppSpacing.xs),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                practiceTypeLabel(
                                  context,
                                  result.practiceType,
                                ),
                                maxLines: 1,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      localizedLessonResultTitle(
                        context.l10n,
                        result.scoreDocumentPath,
                        result.pieceTitle,
                      ),
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      context.l10n.practiceResultSummaryMetadata(
                        sourceLabel(context, result.source),
                        context.l10n.practiceResultPerformance,
                        formatDate(context, result.completedAt),
                      ),
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Column(
                children: [
                  Text(
                    result.scoreText,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.display,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.l10n.practiceResultPlayedOnTimePercent(
                      result.timingAccuracyPercentage,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              statTile(context.l10n.practiceResultCorrect, '${result.correctCount}'),
              statTile(
                context.l10n.practiceResultWrongNotes,
                '${result.wrongCount}',
              ),
              statTile(
                context.l10n.practiceResultNotPlayed,
                '${result.missedCount}',
              ),
              statTile(
                context.l10n.practiceResultMusicLength,
                formatMilliseconds(result.targetDurationMs),
              ),
              statTile(
                context.l10n.practiceResultYourTime,
                formatMilliseconds(result.elapsedDurationMs),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBreakdownCard(
    BuildContext context,
    List<PracticeResultErrorEvent> events,
  ) {
    final wrongPlayedCounts = <int, int>{};

    for (final event in events) {
      final expected = event.expectedMidiNotes.toSet();

      for (final note in event.playedMidiNotes) {
        if (!expected.contains(note)) {
          wrongPlayedCounts.update(note, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    final difficultNotes = result.noteBreakdown
        .where((item) => item.errorCount > 0)
        .take(8)
        .toList();
    final wrongKeys = wrongPlayedCounts.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(
            Icons.analytics_outlined,
            context.l10n.practiceResultWhatToWorkOn,
          ),
          const Gap(AppSpacing.sm),
          if (result.clefBreakdown.isNotEmpty) ...[
            Text(
              context.l10n.practiceResultHowEachClefWent,
              style: labelStyle(),
            ),
            const Gap(AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: result.clefBreakdown.map((item) {
                return metricChip(
                  context.l10n.practiceResultClefDifficulty(
                    friendlyClefName(context, item.clef),
                    item.errorCount,
                    item.totalCount,
                  ),
                );
              }).toList(),
            ),
            const Gap(AppSpacing.md),
          ],
          Text(
            context.l10n.practiceResultDifficultNotes,
            style: labelStyle(),
          ),
          const Gap(AppSpacing.xs),
          if (difficultNotes.isEmpty)
            mutedText(context.l10n.practiceResultNoDifficultNotes)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: difficultNotes.map((item) {
                return metricChip(
                  context.l10n.practiceResultNoteDifficulty(
                    midiToNoteName(item.midiNote),
                    item.errorCount,
                  ),
                );
              }).toList(),
            ),
          const Gap(AppSpacing.md),
          Text(context.l10n.practiceResultOtherKeys, style: labelStyle()),
          const Gap(AppSpacing.xs),
          if (wrongKeys.isEmpty)
            mutedText(context.l10n.practiceResultNoExtraKeys)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: wrongKeys.take(8).map((entry) {
                return metricChip(
                  context.l10n.practiceResultKeyPressed(
                    midiToNoteName(entry.key),
                    entry.value,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildSuggestionsCard(BuildContext context) {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(
            Icons.lightbulb_outline_rounded,
            context.l10n.practiceResultHowToImprove,
          ),
          const Gap(AppSpacing.sm),
          ...localizedSuggestions(context).map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF16A34A),
                    size: AppIconSizes.sm,
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildErrorLog(
    BuildContext context,
    AsyncSnapshot<List<PracticeResultErrorEvent>> snapshot,
    List<PracticeResultErrorEvent> events,
  ) {
    return buildCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        iconColor: colors.primaryColor,
        collapsedIconColor: colors.secondaryTextColor,
        title: Text(
          context.l10n.practiceResultNotesToReview(result.errorEventCount),
          style: TextStyle(
            color: colors.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          context.l10n.practiceResultReviewDescription,
          style: TextStyle(color: colors.secondaryTextColor),
        ),
        children: [
          if (snapshot.connectionState == ConnectionState.waiting)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(color: colors.primaryColor),
            )
          else if (snapshot.hasError)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: mutedText(context.l10n.practiceResultErrorLogFailed),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: mutedText(context.l10n.practiceResultNoErrors),
            )
          else
            ...events.map((event) => buildErrorEvent(context, event)),
        ],
      ),
    );
  }

  Widget buildErrorEvent(
    BuildContext context,
    PracticeResultErrorEvent event,
  ) {
    final expected = event.expectedMidiNotes.map(midiToNoteName).join(' + ');
    final played = event.playedMidiNotes.isEmpty
        ? context.l10n.practiceResultNone
        : event.playedMidiNotes.map(midiToNoteName).join(' + ');
    final issueLabels = event.issueTypes
        .map((issue) => performanceIssueLabel(context, issue))
        .join(', ');
    final timing = friendlyTiming(context, event.timingOffsetMs);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.measureNumber == null
                ? context.l10n.practiceResultNoteGroup(event.positionIndex + 1)
                : context.l10n.practiceResultNoteGroupMeasure(
                    event.positionIndex + 1,
                    event.measureNumber!,
                  ),
            style: TextStyle(
              color: colors.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            context.l10n.practiceResultIssueSummary(
              issueLabels,
              event.clefs
                  .map((clef) => friendlyClefName(context, clef))
                  .join(' / '),
              formatMilliseconds(event.scheduledTimeMs),
            ),
            style: TextStyle(
              color: const Color(0xFFDC2626),
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            context.l10n.practiceResultExpectedAndPlayed(expected, played),
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            timing,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (event.eventuallyMatched) ...[
            const Gap(AppSpacing.xs),
            Text(
              context.l10n.practiceResultEventuallyMatched,
              style: const TextStyle(
                color: Color(0xFF16A34A),
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderColor),
      ),
      child: child,
    );
  }

  Widget statTile(String label, String value) {
    return Container(
      width: 124,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: AppTextSizes.body,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: colors.primaryColor, size: AppIconSizes.sm),
        const Gap(AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget metricChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.caption,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  TextStyle labelStyle() {
    return TextStyle(
      color: colors.primaryColor,
      fontSize: AppTextSizes.label,
      fontWeight: FontWeight.w700,
    );
  }

  Widget mutedText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: colors.secondaryTextColor,
        fontSize: AppTextSizes.caption,
      ),
    );
  }

  Widget buildUnavailableState(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.practiceResultUnavailable,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.secondaryTextColor),
      ),
    );
  }

  String sourceLabel(BuildContext context, String source) {
    return switch (source) {
      'lesson' => context.l10n.practiceResultsLesson,
      'composition' => context.l10n.practiceResultsComposition,
      'challenge' => context.l10n.practiceResultsChallenge,
      'musicLibrary' => context.l10n.musicLibrary,
      _ => context.l10n.practiceResultsMusicSheet,
    };
  }

  Color resultTypeColor() {
    return switch (result.practiceType) {
      PracticeResultType.sightReading => colors.sightReadingResultColor,
      PracticeResultType.synthesia => colors.synthesiaResultColor,
      PracticeResultType.arPerformance => colors.arPerformanceResultColor,
    };
  }

  IconData resultTypeIcon() {
    return switch (result.practiceType) {
      PracticeResultType.sightReading => Icons.menu_book_rounded,
      PracticeResultType.synthesia => Icons.piano_rounded,
      PracticeResultType.arPerformance => Icons.view_in_ar_rounded,
    };
  }

  String formatMilliseconds(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String formatDate(BuildContext context, DateTime? date) {
    if (date == null) {
      return context.l10n.practiceResultsJustNow;
    }

    final local = date.toLocal();
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return '${DateFormat.yMd(localeName).format(local)} · '
        '${DateFormat.jm(localeName).format(local)}';
  }

  String friendlyClefName(BuildContext context, String clef) {
    switch (clef.toLowerCase()) {
      case 'treble':
        return context.l10n.practiceResultTrebleClef;
      case 'bass':
        return context.l10n.practiceResultBassClef;
      case 'alto':
        return context.l10n.practiceResultAltoClef;
      case 'tenor':
        return context.l10n.practiceResultTenorClef;
      case 'percussion':
        return context.l10n.practiceResultPercussion;
      default:
        return context.l10n.practiceResultScoreSection;
    }
  }

  String friendlyTiming(BuildContext context, int? timingOffsetMs) {
    if (timingOffsetMs == null) {
      return context.l10n.practiceResultNoCorrectNote;
    }

    final absoluteMilliseconds = timingOffsetMs.abs();
    if (absoluteMilliseconds < 100) {
      return context.l10n.practiceResultTimingOnBeat;
    }

    final seconds = (absoluteMilliseconds / 1000).toStringAsFixed(1);
    return timingOffsetMs < 0
        ? context.l10n.practiceResultBeforeBeat(seconds)
        : context.l10n.practiceResultAfterBeat(seconds);
  }

  String practiceTypeLabel(
    BuildContext context,
    PracticeResultType practiceType,
  ) {
    return switch (practiceType) {
      PracticeResultType.sightReading =>
        context.l10n.practiceResultsSightReading,
      PracticeResultType.synthesia => context.l10n.practiceResultsSynthesia,
      PracticeResultType.arPerformance =>
        context.l10n.practiceResultsArPerformance,
    };
  }

  String performanceIssueLabel(
    BuildContext context,
    PerformanceIssueType issue,
  ) {
    return switch (issue) {
      PerformanceIssueType.wrongNote =>
        context.l10n.practiceResultIssueWrongNote,
      PerformanceIssueType.early => context.l10n.practiceResultIssueEarly,
      PerformanceIssueType.late => context.l10n.practiceResultIssueLate,
      PerformanceIssueType.missed => context.l10n.practiceResultIssueMissed,
      PerformanceIssueType.chordTiming =>
        context.l10n.practiceResultIssueChordTiming,
      PerformanceIssueType.releasedEarly =>
        context.l10n.practiceResultIssueReleasedEarly,
    };
  }

  List<String> localizedSuggestions(BuildContext context) {
    final difficultNotes = result.noteBreakdown
        .where((item) => item.errorCount > 0)
        .toList()
      ..sort((first, second) => second.errorCount.compareTo(first.errorCount));
    final difficultNote = difficultNotes.isEmpty
        ? null
        : midiToNoteName(difficultNotes.first.midiNote);
    final suggestions = <String>[];
    final isSightReading =
        result.practiceType == PracticeResultType.sightReading;

    if (result.errorEventCount == 0 &&
        result.wrongCount == 0 &&
        result.missedCount == 0) {
      return <String>[
        isSightReading
            ? context.l10n.sightReadingSuggestionPerfect
            : context.l10n.synthesiaSuggestionPerfect,
      ];
    }

    if (result.timingAccuracyPercentage >= 90) {
      suggestions.add(
        isSightReading
            ? context.l10n.sightReadingSuggestionAlmostPerfect
            : context.l10n.synthesiaSuggestionAlmostPerfect,
      );
    }

    if (difficultNote != null) {
      suggestions.add(
        isSightReading
            ? context.l10n.sightReadingSuggestionDifficultNote(difficultNote)
            : context.l10n.synthesiaSuggestionDifficultNote(difficultNote),
      );
    }

    if (result.missedCount > 0 && suggestions.length < 3) {
      suggestions.add(
        isSightReading
            ? context.l10n.sightReadingSuggestionMissedNotes
            : context.l10n.synthesiaSuggestionMissedNotes,
      );
    }

    if (result.wrongCount > 0 && suggestions.length < 3) {
      suggestions.add(
        isSightReading
            ? context.l10n.sightReadingSuggestionGeneralPractice
            : context.l10n.synthesiaSuggestionWrongNotes,
      );
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        isSightReading
            ? context.l10n.sightReadingSuggestionGeneralPractice
            : context.l10n.synthesiaSuggestionGeneralPractice,
      );
    }

    return suggestions.take(3).toList(growable: false);
  }

}
