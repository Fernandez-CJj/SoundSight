import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/assessment/assessment_localization.dart';
import 'package:soundsight/screens/assessment/models/assessment_questionnaire.dart';
import 'package:soundsight/screens/assessment/widgets/assessment_theme.dart';

/// Defines the function used to submit completed questionnaire answers.
typedef QuestionnaireSubmitCallback =
    Future<void> Function(Map<String, String> answers);

/// Collects the user's background information before performance assessment.
class AssessmentQuestionnaireScreen extends StatefulWidget {
  const AssessmentQuestionnaireScreen({
    super.key,
    required this.onSubmit,
    this.initialAnswers = const {},
    this.isDarkMode = false,
  });

  /// Called after every required question has a valid selected answer.
  final QuestionnaireSubmitCallback onSubmit;

  /// Previously saved answers used when the user resumes this section.
  final Map<String, String> initialAnswers;

  final bool isDarkMode;

  @override
  State<AssessmentQuestionnaireScreen> createState() {
    return _AssessmentQuestionnaireScreenState();
  }
}

class _AssessmentQuestionnaireScreenState
    extends State<AssessmentQuestionnaireScreen> {
  /// Stores question IDs and their selected option IDs.
  late final Map<String, String> _selectedAnswers;

  /// Controls validation messages after an incomplete submission.
  bool _showMissingAnswers = false;

  /// Prevents repeated submission while the callback is running.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Copy the supplied map so this screen does not modify its parent data.
    _selectedAnswers = Map<String, String>.from(widget.initialAnswers);
  }

  /// Checks whether a question has one of its defined answer options.
  bool _hasValidAnswer(AssessmentQuestionnaireQuestion question) {
    final selectedOptionId = _selectedAnswers[question.id];

    if (selectedOptionId == null) {
      return false;
    }

    return question.options.any((option) => option.id == selectedOptionId);
  }

  /// Every required question must have a valid selected answer.
  bool get _allQuestionsAnswered {
    return assessmentQuestionnaireQuestions.every(_hasValidAnswer);
  }

  /// Validates and sends an immutable copy of the selected answers.
  Future<void> _submitQuestionnaire() async {
    if (_isSubmitting) {
      return;
    }

    if (!_allQuestionsAnswered) {
      setState(() {
        _showMissingAnswers = true;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.assessmentAnswerEveryQuestion),
          ),
        );

      return;
    }

    setState(() {
      _showMissingAnswers = false;
      _isSubmitting = true;
    });

    try {
      final answers = Map<String, String>.unmodifiable(
        Map<String, String>.from(_selectedAnswers),
      );

      await widget.onSubmit(answers);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.assessmentSaveAnswersFailed),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AssessmentTheme(
      isDarkMode: widget.isDarkMode,
      builder: (themedContext) {
        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(themedContext.l10n.assessmentBackgroundQuestions),
            ),
          ),
          body: AssessmentPageBody(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                    Text(
                      themedContext.l10n.assessmentExperienceHeading,
                      style: const TextStyle(
                        fontSize: AppTextSizes.screenTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      themedContext.l10n.assessmentExperienceDescription,
                      style: const TextStyle(
                        fontSize: AppTextSizes.body,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      themedContext.l10n.assessmentDeadlineContinues,
                      style: const TextStyle(
                        fontSize: AppTextSizes.label,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (
                      var questionIndex = 0;
                      questionIndex < assessmentQuestionnaireQuestions.length;
                      questionIndex++
                    ) ...[
                      _buildQuestion(
                        themedContext: themedContext,
                        questionIndex: questionIndex,
                        question:
                            assessmentQuestionnaireQuestions[questionIndex],
                      ),
                      if (questionIndex <
                          assessmentQuestionnaireQuestions.length - 1)
                        const SizedBox(height: AppSpacing.lg),
                    ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitQuestionnaire,
                      child: _isSubmitting
                          ? SizedBox(
                              width: AppIconSizes.md,
                              height: AppIconSizes.md,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(
                                  themedContext,
                                ).colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              themedContext.l10n.continueAction,
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ],
              ),
          ),
        );
      },
    );
  }

  /// Builds one question and its mutually exclusive answer options.
  Widget _buildQuestion({
    required BuildContext themedContext,
    required int questionIndex,
    required AssessmentQuestionnaireQuestion question,
  }) {
    final hasValidAnswer = _hasValidAnswer(question);
    final shouldShowError = _showMissingAnswers && !hasValidAnswer;
    final colorScheme = Theme.of(themedContext).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: shouldShowError
              ? colorScheme.error
              : colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${questionIndex + 1}. '
            '${localizedQuestionnaireQuestion(context.l10n, question)}',
            style: const TextStyle(
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RadioGroup<String>(
            groupValue: _selectedAnswers[question.id],
            onChanged: (selectedOptionId) {
              if (_isSubmitting || selectedOptionId == null) {
                return;
              }

              setState(() {
                _selectedAnswers[question.id] = selectedOptionId;
              });
            },
            child: Column(
              children: [
                for (final option in question.options)
                  RadioListTile<String>(
                    value: option.id,
                    enabled: !_isSubmitting,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      localizedQuestionnaireOption(context.l10n, option),
                      style: const TextStyle(fontSize: AppTextSizes.body),
                    ),
                  ),
              ],
            ),
          ),
          if (shouldShowError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.assessmentSelectOneAnswer,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: AppTextSizes.label,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
