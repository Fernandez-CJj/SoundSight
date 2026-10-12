import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
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
        title: const Text('Practice Result'),
      ),
      body: resultId == null
          ? buildUnavailableState()
          : StreamBuilder<List<PracticeResultErrorEvent>>(
              stream: PracticeResultService().watchErrorEvents(resultId),
              builder: (context, snapshot) {
                final events = snapshot.data ?? const [];

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    buildSummaryCard(),
                    const Gap(AppSpacing.md),
                    buildBreakdownCard(events),
                    const Gap(AppSpacing.md),
                    buildSuggestionsCard(),
                    const Gap(AppSpacing.md),
                    buildErrorLog(snapshot, events),
                  ],
                );
              },
            ),
    );
  }

  Widget buildSummaryCard() {
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
                    Text(
                      result.pieceTitle,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      '${sourceLabel(result.source)} · Performance · '
                      '${formatDate(result.completedAt)}',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
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
                    '${result.timingAccuracyPercentage}% played on time',
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              statTile('Correct', '${result.correctCount}'),
              statTile('Wrong notes', '${result.wrongCount}'),
              statTile('Not played', '${result.missedCount}'),
              statTile(
                'Music length',
                formatMilliseconds(result.targetDurationMs),
              ),
              statTile('Your time', formatMilliseconds(result.elapsedDurationMs)),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBreakdownCard(List<PracticeResultErrorEvent> events) {
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
          sectionTitle(Icons.analytics_outlined, 'What to work on'),
          const Gap(AppSpacing.sm),
          Text(
            'How each clef went',
            style: labelStyle(),
          ),
          const Gap(AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: result.clefBreakdown.map((item) {
              return metricChip(
                '${friendlyClefName(item.clef)}: '
                '${item.errorCount} difficult out of ${item.totalCount}',
              );
            }).toList(),
          ),
          const Gap(AppSpacing.md),
          Text('Notes that were difficult', style: labelStyle()),
          const Gap(AppSpacing.xs),
          if (difficultNotes.isEmpty)
            mutedText('No individual note caused repeated trouble.')
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: difficultNotes.map((item) {
                return metricChip(
                  '${midiToNoteName(item.midiNote)}: '
                  'difficult ${item.errorCount} time${item.errorCount == 1 ? '' : 's'}',
                );
              }).toList(),
            ),
          const Gap(AppSpacing.md),
          Text('Other keys you pressed', style: labelStyle()),
          const Gap(AppSpacing.xs),
          if (wrongKeys.isEmpty)
            mutedText('You did not press any extra wrong keys.')
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: wrongKeys.take(8).map((entry) {
                return metricChip(
                  '${midiToNoteName(entry.key)} pressed ${entry.value} time${entry.value == 1 ? '' : 's'}',
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildSuggestionsCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(Icons.lightbulb_outline_rounded, 'How to improve'),
          const Gap(AppSpacing.sm),
          ...result.suggestions.map((suggestion) {
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
    AsyncSnapshot<List<PracticeResultErrorEvent>> snapshot,
    List<PracticeResultErrorEvent> events,
  ) {
    return buildCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        iconColor: colors.primaryColor,
        collapsedIconColor: colors.secondaryTextColor,
        title: Text(
          'Notes to review (${result.errorEventCount})',
          style: TextStyle(
            color: colors.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          'Only the parts that need more practice',
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
              child: mutedText('The detailed error log could not be loaded.'),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: mutedText('No errors were recorded for this attempt.'),
            )
          else
            ...events.map(buildErrorEvent),
        ],
      ),
    );
  }

  Widget buildErrorEvent(PracticeResultErrorEvent event) {
    final expected = event.expectedMidiNotes.map(midiToNoteName).join(' + ');
    final played = event.playedMidiNotes.isEmpty
        ? 'None'
        : event.playedMidiNotes.map(midiToNoteName).join(' + ');
    final issueLabels = event.issueTypes.map((issue) => issue.label).join(', ');
    final timing = friendlyTiming(event.timingOffsetMs);

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
            'Note group ${event.positionIndex + 1}'
            '${event.measureNumber == null ? '' : ' · Measure ${event.measureNumber}'}',
            style: TextStyle(
              color: colors.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            '$issueLabels · ${event.clefs.map(friendlyClefName).join(' / ')} · '
            'At ${formatMilliseconds(event.scheduledTimeMs)}',
            style: TextStyle(
              color: const Color(0xFFDC2626),
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            'The score showed: $expected   You played: $played',
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
            const Text(
              'You found the right notes after the first mistake.',
              style: TextStyle(
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
            style: TextStyle(
              color: colors.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: AppTextSizes.body,
            ),
          ),
          Text(
            label,
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
        Text(
          label,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.body,
            fontWeight: FontWeight.w800,
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

  Widget buildUnavailableState() {
    return Center(
      child: Text(
        'This practice result is unavailable.',
        style: TextStyle(color: colors.secondaryTextColor),
      ),
    );
  }

  String sourceLabel(String source) {
    return source == 'composition' ? 'Composition' : 'Music Sheet';
  }

  String formatMilliseconds(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Just now';
    }

    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} · $hour:$minute $period';
  }

  String friendlyClefName(String clef) {
    switch (clef.toLowerCase()) {
      case 'treble':
        return 'Treble clef (higher notes)';
      case 'bass':
        return 'Bass clef (lower notes)';
      case 'alto':
        return 'Alto clef';
      case 'tenor':
        return 'Tenor clef';
      case 'percussion':
        return 'Percussion';
      default:
        return 'Score section';
    }
  }

  String friendlyTiming(int? timingOffsetMs) {
    if (timingOffsetMs == null) {
      return 'No correct note was played at this point.';
    }

    final absoluteMilliseconds = timingOffsetMs.abs();
    if (absoluteMilliseconds < 100) {
      return 'Your timing was almost exactly on the beat.';
    }

    final seconds = (absoluteMilliseconds / 1000).toStringAsFixed(1);
    return timingOffsetMs < 0
        ? 'You played about $seconds seconds before the beat.'
        : 'You played about $seconds seconds after the beat.';
  }

}
