import 'package:flutter/material.dart';

import '../../../constants/constant.dart';
import '../../../localization/localization_extension.dart';
import '../assessment_localization.dart';
import '../models/assessment_notation_question.dart';
import '../widgets/assessment_notation_view.dart';
import '../widgets/assessment_theme.dart';

/// Called after the user answers every notation-reading question.
typedef NotationReadingSubmitCallback = Future<void> Function(
  Map<String, String> answers,
);

/// Presents the notation-reading assessment one question at a time.
class AssessmentNotationReadingScreen extends StatefulWidget {
  const AssessmentNotationReadingScreen({
    super.key,
    required this.onSubmit,
    this.initialAnswers = const {},
    this.isDarkMode = false,
  });

  /// Saves the completed answer map and advances the assessment.
  final NotationReadingSubmitCallback onSubmit;

  /// Restores valid answers if the user resumes this section.
  final Map<String, String> initialAnswers;

  final bool isDarkMode;

  @override
  State<AssessmentNotationReadingScreen> createState() {
    return _AssessmentNotationReadingScreenState();
  }
}

class _AssessmentNotationReadingScreenState
    extends State<AssessmentNotationReadingScreen> {
  /// Holds answers only while the user works through this section.
  final Map<String, String> _answers = {};

  /// Identifies the question currently displayed on the screen.
  int _currentQuestionIndex = 0;

  /// Prevents changes and repeated submissions while saving.
  bool _isSubmitting = false;

  /// Displays a readable submission error without clearing answers.
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _restoreValidInitialAnswers();
  }

  /// Copies only known question and option IDs into the local answer map.
  void _restoreValidInitialAnswers() {
    for (final question in assessmentNotationQuestions) {
      final savedOptionId = widget.initialAnswers[question.id];

      final isKnownOption = question.options.any(
        (option) => option.id == savedOptionId,
      );

      if (savedOptionId != null && isKnownOption) {
        _answers[question.id] = savedOptionId;
      }
    }
  }

  /// Records the selected option for the visible question.
  void _selectAnswer(String? optionId) {
    if (_isSubmitting || optionId == null) {
      return;
    }

    final question = assessmentNotationQuestions[_currentQuestionIndex];

    final isKnownOption = question.options.any(
      (option) => option.id == optionId,
    );

    if (!isKnownOption) {
      return;
    }

    setState(() {
      _answers[question.id] = optionId;
      _submissionError = null;
    });
  }

  /// Moves to the previous question without deleting the current answer.
  void _showPreviousQuestion() {
    if (_isSubmitting || _currentQuestionIndex == 0) {
      return;
    }

    setState(() {
      _currentQuestionIndex--;
      _submissionError = null;
    });
  }

  /// Moves to the next question without revealing answer correctness.
  void _showNextQuestion() {
    if (_isSubmitting ||
        _currentQuestionIndex >= assessmentNotationQuestions.length - 1) {
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _submissionError = null;
    });
  }

  /// Requires all questions before sending an immutable answer map.
  Future<void> _submitAnswers() async {
    if (_isSubmitting) {
      return;
    }

    final firstMissingIndex = assessmentNotationQuestions.indexWhere(
      (question) => !_answers.containsKey(question.id),
    );

    if (firstMissingIndex != -1) {
      setState(() {
        _currentQuestionIndex = firstMissingIndex;
        _submissionError = context.l10n.assessmentAnswerEveryNotationQuestion;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.assessmentPleaseAnswerEveryNotationQuestion,
            ),
          ),
        );

      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      await widget.onSubmit(
        Map<String, String>.unmodifiable(_answers),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submissionError = context.l10n.assessmentSaveNotationFailed;
      });
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
    final question = assessmentNotationQuestions[_currentQuestionIndex];
    final selectedOptionId = _answers[question.id];
    final isLastQuestion =
        _currentQuestionIndex == assessmentNotationQuestions.length - 1;

    return AssessmentTheme(
      isDarkMode: widget.isDarkMode,
      builder: (themedContext) {
        return PopScope(
          canPop: !_isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(themedContext.l10n.assessmentNotationReading),
              ),
            ),
            body: AssessmentPageBody(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                _buildProgress(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          localizedNotationPrompt(
                            themedContext.l10n,
                            question,
                          ),
                          style: const TextStyle(
                            fontSize: AppTextSizes.sectionTitle,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Theme.of(themedContext).colorScheme.surface,
                            border: Border.all(
                              color: Theme.of(
                                themedContext,
                              ).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: AssessmentNotationView(question: question),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        RadioGroup<String>(
                          groupValue: selectedOptionId,
                          onChanged: _selectAnswer,
                          child: Column(
                            children: question.options.map((option) {
                              return RadioListTile<String>(
                                value: option.id,
                                enabled: !_isSubmitting,
                                title: Text(
                                  localizedNotationOption(
                                    themedContext.l10n,
                                    option,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ),
                        if (_submissionError != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _submissionError!,
                            style: TextStyle(
                              color: Theme.of(
                                themedContext,
                              ).colorScheme.error,
                              fontSize: AppTextSizes.body,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _currentQuestionIndex == 0 || _isSubmitting
                            ? null
                            : _showPreviousQuestion,
                        child: Text(
                          themedContext.l10n.previous,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : isLastQuestion
                            ? _submitAnswers
                            : _showNextQuestion,
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
                                isLastQuestion
                                    ? themedContext.l10n.submit
                                    : themedContext.l10n.next,
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),
                  ],
                ),
            ),
          ),
        );
      },
    );
  }

  /// Shows the current question number and answered-question count.
  Widget _buildProgress() {
    final questionNumber = _currentQuestionIndex + 1;
    final questionCount = assessmentNotationQuestions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.assessmentQuestionProgress(
                  questionNumber,
                  questionCount,
                ),
                style: const TextStyle(
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                context.l10n.assessmentAnsweredCount(_answers.length),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: AppTextSizes.label),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: questionNumber / questionCount,
        ),
      ],
    );
  }
}
