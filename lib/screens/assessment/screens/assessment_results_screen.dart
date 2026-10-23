import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/assessment/assessment_localization.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/models/assessment_notation_question.dart';
import 'package:soundsight/screens/assessment/models/assessment_piano_task.dart';
import 'package:soundsight/screens/assessment/models/assessment_questionnaire.dart';
import 'package:soundsight/screens/assessment/widgets/assessment_theme.dart';

/// Called when the user accepts the saved result and presses Done.
typedef AssessmentResultDoneCallback = Future<void> Function();

/// Reviews the answers and permanent placement from a completed assessment.
class AssessmentResultsScreen extends StatefulWidget {
  const AssessmentResultsScreen({
    super.key,
    required this.attempt,
    required this.onDone,
    this.isDarkMode = false,
  });

  /// Contains every saved answer, section score, and calculated level.
  final AssessmentAttempt attempt;

  /// Applies the saved final level to the profile and opens Home.
  final AssessmentResultDoneCallback onDone;

  final bool isDarkMode;

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
        _errorMessage = context.l10n.assessmentApplyLevelFailed;
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

    final colorScheme = AssessmentTheme.dataFor(
      widget.isDarkMode,
    ).colorScheme;
    final scoredSummary = <Widget>[];

    if (usedBeginnerShortcut) {
      scoredSummary.add(
        Text(
          context.l10n.assessmentBeginnerShortcutSummary,
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
          title: context.l10n.assessmentNotationSection,
          level: savedNotationLevel,
          scoreText: context.l10n.assessmentCorrectScore(
            savedNotationScore.totalCorrect,
            AssessmentNotationScore.totalQuestions,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionResult(
          context: context,
          title: context.l10n.assessmentPianoSection,
          level: savedPianoLevel,
          scoreText: context.l10n.assessmentCorrectGroupsScore(
            savedPianoScore.totalCorrectGroups,
            savedPianoScore.totalGroups,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.assessmentFinalLevelExplanation,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: AppTextSizes.body, height: 1.4),
        ),
      ]);
    }

    return Theme(
      data: AssessmentTheme.dataFor(widget.isDarkMode),
      child: PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.assessmentReview),
            ),
          ),
          body: AssessmentPageBody(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.workspace_premium_outlined,
                                color: colorScheme.primary,
                                size: AppIconSizes.lg,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                context.l10n.assessmentYourLevel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: AppTextSizes.sectionTitle,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _displayLevel(finalLevel),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: AppTextSizes.screenTitle,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
                      color: AssessmentTheme.dataFor(
                        widget.isDarkMode,
                      ).colorScheme.error,
                      fontSize: AppTextSizes.label,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: ElevatedButton(
                    onPressed: _isApplyingLevel ? null : _finishReview,
                    child: _isApplyingLevel
                        ? SizedBox(
                            width: AppIconSizes.md,
                            height: AppIconSizes.md,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AssessmentTheme.dataFor(
                                widget.isDarkMode,
                              ).colorScheme.onPrimary,
                            ),
                          )
                        : Text(context.l10n.done),
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
          ? context.l10n.assessmentNoSavedAnswer
          : localizedQuestionnaireOption(
              context.l10n,
              matchingOptions.first,
            );

      rows.add(
        _buildAnswerRow(
          title: localizedQuestionnaireQuestion(context.l10n, question),
          answer: selectedLabel,
        ),
      );
    }

    return _buildReviewGroup(
      context: context,
      title: context.l10n.assessmentBackgroundAnswers,
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
          ? context.l10n.assessmentNoSavedAnswer
          : localizedNotationOption(context.l10n, selectedOptions.first);
      final correctLabel = correctOptions.isEmpty
          ? question.correctOptionId
          : localizedNotationOption(context.l10n, correctOptions.first);

      rows.add(
        _buildAnswerRow(
          title: localizedNotationPrompt(context.l10n, question),
          answer: selectedLabel,
          detail: selectedId == question.correctOptionId
              ? context.l10n.assessmentCorrect
              : context.l10n.assessmentCorrectAnswer(correctLabel),
        ),
      );
    }

    return _buildReviewGroup(
      context: context,
      title: context.l10n.assessmentNotationAnswers,
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
          title: localizedPianoTaskTitle(context.l10n, task),
          answer: result == null
              ? context.l10n.assessmentNoSavedResult
              : context.l10n.assessmentCorrectGroupsScore(
                  result.correctGroupCount,
                  result.totalGroupCount,
                ),
          detail: result == null
              ? null
              : context.l10n.assessmentPianoResultDetails(
                  result.wrongGroupCount,
                  result.missedGroupCount,
                  result.timingMistakeCount,
                ),
        ),
      );
    }

    return _buildReviewGroup(
      context: context,
      title: context.l10n.assessmentPianoTaskResults,
      children: rows,
    );
  }

  /// Displays one complete review group without requiring another tap.
  Widget _buildReviewGroup({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = AssessmentTheme.dataFor(
      widget.isDarkMode,
    ).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...children,
        ],
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
    final colorScheme = AssessmentTheme.dataFor(
      widget.isDarkMode,
    ).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
        return context.l10n.beginner;
      case AssessmentSkillLevel.intermediate:
        return context.l10n.intermediate;
      case AssessmentSkillLevel.advanced:
        return context.l10n.advanced;
    }
  }

  /// Handles an older or incomplete result without exposing a broken screen.
  Widget _buildUnavailableResult() {
    return Theme(
      data: AssessmentTheme.dataFor(widget.isDarkMode),
      child: PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.assessmentReview),
            ),
          ),
          body: AssessmentPageBody(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Text(
                  context.l10n.assessmentResultUnavailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppTextSizes.body,
                    height: 1.4,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AssessmentTheme.dataFor(
                        widget.isDarkMode,
                      ).colorScheme.error,
                      fontSize: AppTextSizes.label,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: ElevatedButton(
                    onPressed: _isApplyingLevel ? null : _finishReview,
                    child: _isApplyingLevel
                        ? SizedBox(
                            width: AppIconSizes.md,
                            height: AppIconSizes.md,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AssessmentTheme.dataFor(
                                widget.isDarkMode,
                              ).colorScheme.onPrimary,
                            ),
                          )
                        : Text(context.l10n.done),
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
