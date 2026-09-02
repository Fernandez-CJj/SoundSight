import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/assessment/models/assessment_questionnaire.dart';

/// Defines the function used to submit completed questionnaire answers.
typedef QuestionnaireSubmitCallback =
    Future<void> Function(Map<String, String> answers);

/// Collects the user's background information before performance assessment.
class AssessmentQuestionnaireScreen extends StatefulWidget {
  const AssessmentQuestionnaireScreen({
    super.key,
    required this.onSubmit,
    this.initialAnswers = const {},
  });

  /// Called after every required question has a valid selected answer.
  final QuestionnaireSubmitCallback onSubmit;

  /// Previously saved answers used when the user resumes this section.
  final Map<String, String> initialAnswers;

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
          const SnackBar(
            content: Text('Please answer every question before continuing.'),
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
          const SnackBar(
            content: Text('Unable to save your answers. Please try again.'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Background Questions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'Tell us about your experience',
                      style: TextStyle(
                        fontSize: AppTextSizes.screenTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'These answers help personalize your experience. If you '
                      'are new to piano or have not learned sheet music, you '
                      'may accept Beginner level and skip the remaining parts.',
                      style: TextStyle(
                        fontSize: AppTextSizes.body,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Your assessment deadline continues while answering.',
                      style: TextStyle(
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
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitQuestionnaire,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: AppIconSizes.md,
                          height: AppIconSizes.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds one question and its mutually exclusive answer options.
  Widget _buildQuestion({
    required int questionIndex,
    required AssessmentQuestionnaireQuestion question,
  }) {
    final hasValidAnswer = _hasValidAnswer(question);
    final shouldShowError = _showMissingAnswers && !hasValidAnswer;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
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
            '${questionIndex + 1}. ${question.title}',
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
                      option.label,
                      style: const TextStyle(fontSize: AppTextSizes.body),
                    ),
                  ),
              ],
            ),
          ),
          if (shouldShowError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select one answer.',
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
