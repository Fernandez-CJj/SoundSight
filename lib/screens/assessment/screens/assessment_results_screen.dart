import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/models/assessment_notation_question.dart';
import 'package:soundsight/screens/assessment/models/assessment_piano_task.dart';
import 'package:soundsight/screens/assessment/models/assessment_questionnaire.dart';

/// Called when the user accepts the saved result and presses Done.
typedef AssessmentResultDoneCallback = Future<void> Function();

/// Reviews the answers and permanent placement from a completed assessment.
class AssessmentResultsScreen extends StatefulWidget {
  const AssessmentResultsScreen({
    super.key,
    required this.attempt,
    required this.onDone,
  });

  /// Contains every saved answer, section score, and calculated level.
  final AssessmentAttempt attempt;

  /// Applies the saved final level to the profile and opens Home.
  final AssessmentResultDoneCallback onDone;

  @override
  State<AssessmentResultsScreen> createState() {
    return _AssessmentResultsScreenState();
  }
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen> {
  bool _isApplyingLevel = false;
  String? _errorMessage;

  AssessmentAttempt get _attempt => widget.attempt;

  /// Applies the already-saved level without repeating any assessment work.
  Future<void> _finishReview() async {
    if (_isApplyingLevel) {
      return;
    }

    setState(() {
      _isApplyingLevel = true;
      _errorMessage = null;
    });

    try {
      await widget.onDone();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isApplyingLevel = false;
        _errorMessage =
            'Unable to apply your saved skill level. Please try again.\n$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notationScore = _attempt.notationReadingScore;
    final pianoScore = _attempt.pianoExecutionScore;
    final notationLevel = _attempt.notationReadingLevel;
    final pianoLevel = _attempt.pianoExecutionLevel;
    final finalLevel = _attempt.finalSkillLevel;
    final usedBeginnerShortcut =
        _attempt.placementMethod ==
        AssessmentPlacementMethod.selfReportedBeginner;

    // Beginner shortcut results intentionally contain no scored sections.
    final fullResultIsMissing =
        !usedBeginnerShortcut &&
        (notationScore == null ||
            pianoScore == null ||
            notationLevel == null ||
            pianoLevel == null);

    if (finalLevel == null || fullResultIsMissing) {
      return _buildUnavailableResult();
    }

    final scoredSummary = <Widget>[];

    if (usedBeginnerShortcut) {
      scoredSummary.add(
        const Text(
          'Your background answers show that at least one required skill is '
          'entirely new to you. The scored sections were skipped and Beginner '
          'was assigned.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: AppTextSizes.body, height: 1.4),
        ),
      );
    } else {
      final savedNotationScore = notationScore!;
      final savedPianoScore = pianoScore!;
      final savedNotationLevel = notationLevel!;
      final savedPianoLevel = pianoLevel!;

      scoredSummary.addAll([
        _buildSectionResult(
          context: context,
          title: 'Notation reading',
          level: savedNotationLevel,
          scoreText:
              '${savedNotationScore.totalCorrect} of '
              '${AssessmentNotationScore.totalQuestions} correct',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionResult(
          context: context,
          title: 'Piano execution',
          level: savedPianoLevel,
          scoreText:
              '${savedPianoScore.totalCorrectGroups} of '
              '${savedPianoScore.totalGroups} correct groups',
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Your final level uses the lower of your notation and piano levels. '
          'Strength in one required skill cannot hide a weaker required skill.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: AppTextSizes.body, height: 1.4),
        ),
      ]);
    }

    return PopScope(
      // Done is the only exit because it applies the result to the profile.
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Assessment Review'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Your SoundSight Level',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTextSizes.sectionTitle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _displayLevel(finalLevel),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: AppTextSizes.screenTitle,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ...scoredSummary,
                        const SizedBox(height: AppSpacing.lg),
                        _buildBackgroundReview(context),
                        if (!usedBeginnerShortcut) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildNotationReview(context),
                          const SizedBox(height: AppSpacing.md),
                          _buildPianoReview(context),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: AppTextSizes.label,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isApplyingLevel ? null : _finishReview,
                    child: _isApplyingLevel
                        ? const SizedBox(
                            width: AppIconSizes.md,
                            height: AppIconSizes.md,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the labels selected in the background questionnaire.
  Widget _buildBackgroundReview(BuildContext context) {
    final rows = <Widget>[];

    for (final question in assessmentQuestionnaireQuestions) {
      final selectedId = _attempt.questionnaireAnswers[question.id] ?? '';
      final matchingOptions = question.options.where(
        (option) => option.id == selectedId,
      );
      final selectedLabel = matchingOptions.isEmpty
          ? 'No saved answer'
          : matchingOptions.first.label;

      rows.add(
        _buildAnswerRow(title: question.title, answer: selectedLabel),
      );
    }

    return _buildReviewGroup(
      context: context,
      title: 'Background answers',
      children: rows,
    );
  }

  /// Shows each selected notation answer and its correct answer.
  Widget _buildNotationReview(BuildContext context) {
    final rows = <Widget>[];

    for (final question in assessmentNotationQuestions) {
      final selectedId = _attempt.notationReadingAnswers[question.id] ?? '';
      final selectedOptions = question.options.where(
        (option) => option.id == selectedId,
      );
      final correctOptions = question.options.where(
        (option) => option.id == question.correctOptionId,
      );
      final selectedLabel = selectedOptions.isEmpty
          ? 'No saved answer'
          : selectedOptions.first.label;
      final correctLabel = correctOptions.isEmpty
          ? question.correctOptionId
          : correctOptions.first.label;

      rows.add(
        _buildAnswerRow(
          title: question.prompt,
          answer: selectedLabel,
          detail: selectedId == question.correctOptionId
              ? 'Correct'
              : 'Correct answer: $correctLabel',
        ),
      );
    }

    return _buildReviewGroup(
      context: context,
      title: 'Notation answers',
      children: rows,
    );
  }

  /// Shows the recorded statistics for each piano task.
  Widget _buildPianoReview(BuildContext context) {
    final rows = <Widget>[];

    for (final task in assessmentPianoTasks) {
      final result = _attempt.pianoTaskResults[task.id];

      rows.add(
        _buildAnswerRow(
          title: task.title,
          answer: result == null
              ? 'No saved result'
              : '${result.correctGroupCount} of '
                  '${result.totalGroupCount} correct groups',
          detail: result == null
              ? null
              : '${result.wrongGroupCount} wrong, '
                  '${result.missedGroupCount} missed, '
                  '${result.timingMistakeCount} timing mistakes',
        ),
      );
    }

    return _buildReviewGroup(
      context: context,
      title: 'Piano task results',
      children: rows,
    );
  }

  /// Keeps a long answer review compact until the user opens each group.
  Widget _buildReviewGroup({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppTextSizes.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: children,
      ),
    );
  }

  /// Displays one saved answer or piano result in a readable vertical row.
  Widget _buildAnswerRow({
    required String title,
    required String answer,
    String? detail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTextSizes.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(answer, style: const TextStyle(fontSize: AppTextSizes.label)),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail,
              style: const TextStyle(fontSize: AppTextSizes.caption),
            ),
          ],
        ],
      ),
    );
  }

  /// Displays one required skill with its placement and raw score.
  Widget _buildSectionResult({
    required BuildContext context,
    required String title,
    required AssessmentSkillLevel level,
    required String scoreText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTextSizes.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  scoreText,
                  style: const TextStyle(fontSize: AppTextSizes.label),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _displayLevel(level),
            style: const TextStyle(
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Keeps every saved lowercase level readable in the interface.
  String _displayLevel(AssessmentSkillLevel level) {
    switch (level) {
      case AssessmentSkillLevel.beginner:
        return 'Beginner';
      case AssessmentSkillLevel.intermediate:
        return 'Intermediate';
      case AssessmentSkillLevel.advanced:
        return 'Advanced';
    }
  }

  /// Handles an older or incomplete result without exposing a broken screen.
  Widget _buildUnavailableResult() {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Assessment Review'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The assessment is complete, but its saved result details '
                  'could not be displayed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppTextSizes.body, height: 1.4),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: AppTextSizes.label,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isApplyingLevel ? null : _finishReview,
                    child: _isApplyingLevel
                        ? const SizedBox(
                            width: AppIconSizes.md,
                            height: AppIconSizes.md,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
