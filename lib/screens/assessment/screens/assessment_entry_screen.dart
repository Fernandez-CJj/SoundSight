import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/models/assessment_questionnaire.dart';
import 'package:soundsight/screens/assessment/screens/assessment_introduction_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_notation_reading_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_piano_execution_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_questionnaire_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_results_screen.dart';
import 'package:soundsight/screens/assessment/services/assessment_attempt_service.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';

/// Displays the user's current assessment status and available action.
class AssessmentEntryScreen extends StatefulWidget {
  const AssessmentEntryScreen({super.key, this.initialAttempt});

  /// An attempt already loaded during login.
  ///
  /// Passing it avoids an unnecessary initial Firestore request.
  final AssessmentAttempt? initialAttempt;

  @override
  State<AssessmentEntryScreen> createState() {
    return _AssessmentEntryScreenState();
  }
}

class _AssessmentEntryScreenState extends State<AssessmentEntryScreen> {
  /// Handles all Firestore assessment lifecycle operations.
  final AssessmentAttemptService _assessmentService =
      AssessmentAttemptService();

  /// The user's current assessment, or null if it has not started.
  AssessmentAttempt? _attempt;

  /// Controls the initial loading indicator.
  bool _isLoading = true;

  /// Prevents repeated Start or Resume button presses.
  bool _isSubmitting = false;

  /// Stores a readable loading error for the user.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.initialAttempt != null) {
      _attempt = widget.initialAttempt;
      _isLoading = false;
    } else {
      _loadAttempt();
    }
  }

  /// Loads the fixed assessment document using Firestore server time.
  Future<void> _loadAttempt() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final attempt = await _assessmentService.loadCurrentAttempt();

      if (!mounted) {
        return;
      }

      setState(() {
        _attempt = attempt;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load the assessment. Please try again.';
      });
    }
  }

  /// Starts the first attempt or refreshes and resumes an active attempt.
  Future<void> _startOrResumeAssessment() async {
    if (_isSubmitting) {
      return;
    }

    if (_attempt == null) {
      final confirmed = await _showStartConfirmation();

      if (!confirmed) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final attempt = await _assessmentService.startOrResumeAttempt();

      if (!mounted) {
        return;
      }

      setState(() {
        _attempt = attempt;
        _isSubmitting = false;
      });

      if (attempt.effectiveStatus == AssessmentAttemptStatus.inProgress) {
        await _openCurrentSection(attempt);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Unable to start the assessment. Please try again.';
      });
    }
  }

  /// Opens the introduction for an assessment that has not reached
  /// the questionnaire yet.
  Future<void> _openIntroduction(AssessmentAttempt attempt) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (introductionContext) {
          return AssessmentIntroductionScreen(
            attempt: attempt,
            onContinue: () async {
              try {
                // Save the introduction-to-questionnaire transition.
                final updatedAttempt = await _assessmentService
                    .advanceToSection(AssessmentSection.questionnaire);

                if (!mounted || !introductionContext.mounted) {
                  return;
                }

                setState(() {
                  _attempt = updatedAttempt;
                });

                // Replace the introduction with the questionnaire.
                await _openQuestionnaire(
                  currentScreenContext: introductionContext,
                  attempt: updatedAttempt,
                  replaceCurrentScreen: true,
                );
              } catch (error) {
                if (!introductionContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(introductionContext).showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            },
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadAttempt();
  }

  /// Opens the questionnaire and restores previously saved answers.
  ///
  /// Successful submission saves the answers and advances the assessment
  /// to notation reading.
  Future<void> _openQuestionnaire({
    required BuildContext currentScreenContext,
    required AssessmentAttempt attempt,
    required bool replaceCurrentScreen,
  }) async {
    final route = MaterialPageRoute<void>(
      builder: (questionnaireContext) {
        return AssessmentQuestionnaireScreen(
          initialAnswers: attempt.questionnaireAnswers,
          onSubmit: (answers) async {
            // An explicit Beginner declaration can safely skip both objective
            // sections because it can never award a higher placement.
            if (shouldAssignBeginnerFromBackgroundAnswers(answers)) {
              final accepted = await _showBeginnerPlacementConfirmation(
                questionnaireContext,
              );

              if (!accepted || !questionnaireContext.mounted) {
                return;
              }

              final updatedAttempt = await _assessmentService
                  .completeQuestionnaireAsBeginner(answers);

              if (!mounted) {
                return;
              }

              setState(() {
                _attempt = updatedAttempt;
              });

              if (questionnaireContext.mounted) {
                await _openResults(
                  currentScreenContext: questionnaireContext,
                  attempt: updatedAttempt,
                  replaceCurrentScreen: true,
                );
              }

              return;
            }

            final updatedAttempt = await _assessmentService
                .submitQuestionnaire(answers);

            if (!mounted) {
              return;
            }

            // Keep the entry screen synchronized with Firestore.
            setState(() {
              _attempt = updatedAttempt;
            });

            // Replace the questionnaire with the required notation section.
            if (questionnaireContext.mounted) {
              await _openNotationReading(
                currentScreenContext: questionnaireContext,
                attempt: updatedAttempt,
                replaceCurrentScreen: true,
              );
            }
          },
        );
      },
    );

    if (replaceCurrentScreen) {
      // Remove the introduction so Back cannot return to it.
      await Navigator.of(currentScreenContext).pushReplacement(route);
    } else {
      // Resume directly from the questionnaire.
      await Navigator.of(currentScreenContext).push(route);
    }
  }

  /// Confirms a permanent Beginner result before skipping the scored sections.
  Future<bool> _showBeginnerPlacementConfirmation(
    BuildContext currentContext,
  ) async {
    final accepted = await showDialog<bool>(
      context: currentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Accept Beginner level?'),
          content: const Text(
            'Based on your answers, at least one required skill is at the '
            'Beginner level. Accepting will skip Notation Reading and Piano '
            'Execution. This result is permanent and cannot be attempted again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Review Answers'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Accept Beginner'),
            ),
          ],
        );
      },
    );

    return accepted ?? false;
  }

  /// Opens notation reading and restores any valid saved answers.
  Future<void> _openNotationReading({
    required BuildContext currentScreenContext,
    required AssessmentAttempt attempt,
    required bool replaceCurrentScreen,
  }) async {
    final route = MaterialPageRoute<void>(
      builder: (notationContext) {
        return AssessmentNotationReadingScreen(
          initialAnswers: attempt.notationReadingAnswers,
          onSubmit: (answers) async {
            final updatedAttempt = await _assessmentService
                .submitNotationReading(answers);

            if (!mounted) {
              return;
            }

            // Keep the entry screen synchronized with the saved result.
            setState(() {
              _attempt = updatedAttempt;
            });

            // Replace notation reading with the piano-execution section.
            if (notationContext.mounted) {
              await _openPianoExecution(
                currentScreenContext: notationContext,
                replaceCurrentScreen: true,
              );
            }
          },
        );
      },
    );

    if (replaceCurrentScreen) {
      // Remove the completed questionnaire from the navigation stack.
      await Navigator.of(currentScreenContext).pushReplacement(route);
    } else {
      // Resume directly from notation reading.
      await Navigator.of(currentScreenContext).push(route);
    }
  }

  /// Opens the MIDI-based piano-execution section.
  Future<void> _openPianoExecution({
    required BuildContext currentScreenContext,
    required bool replaceCurrentScreen,
  }) async {
    final route = MaterialPageRoute<void>(
      builder: (pianoContext) {
        return AssessmentPianoExecutionScreen(
          onSubmit: (results) async {
            final updatedAttempt = await _assessmentService
                .submitPianoExecution(results);

            if (!mounted) {
              return;
            }

            // Keep the entry screen synchronized with the completed result.
            setState(() {
              _attempt = updatedAttempt;
            });

            // Replace piano execution with the permanent result screen.
            if (pianoContext.mounted) {
              await _openResults(
                currentScreenContext: pianoContext,
                attempt: updatedAttempt,
                replaceCurrentScreen: true,
              );
            }
          },
        );
      },
    );

    if (replaceCurrentScreen) {
      // Remove the completed notation section from the navigation stack.
      await Navigator.of(currentScreenContext).pushReplacement(route);
    } else {
      // Resume directly from piano execution.
      await Navigator.of(currentScreenContext).push(route);
    }
  }

  /// Opens the permanent result produced after piano execution finishes.
  Future<void> _openResults({
    required BuildContext currentScreenContext,
    required AssessmentAttempt attempt,
    required bool replaceCurrentScreen,
  }) async {
    final route = MaterialPageRoute<void>(
      builder: (_) {
        return AssessmentResultsScreen(
          attempt: attempt,
          onDone: () async {
            // The assessment is already permanent. Done only copies its
            // trusted final level into the user's main profile document.
            await _assessmentService.applyCompletedSkillLevel();

            if (mounted) {
              _continueToHome();
            }
          },
        );
      },
    );

    if (replaceCurrentScreen) {
      // The completed piano screen must not be reachable with Back.
      await Navigator.of(currentScreenContext).pushReplacement(route);
    } else {
      // A returning user may reopen their permanent result from the entry page.
      await Navigator.of(currentScreenContext).push(route);
    }
  }

  /// Reopens saved results for a user whose assessment is already complete.
  Future<void> _openCompletedResults() async {
    final attempt = _attempt;

    if (attempt == null) {
      return;
    }

    await _openResults(
      currentScreenContext: context,
      attempt: attempt,
      replaceCurrentScreen: false,
    );
  }

  /// Opens the correct screen based on the progress saved in Firestore.
  Future<void> _openCurrentSection(AssessmentAttempt attempt) async {
    switch (attempt.currentSection) {
      case AssessmentSection.introduction:
        await _openIntroduction(attempt);
        return;

      case AssessmentSection.questionnaire:
        await _openQuestionnaire(
          currentScreenContext: context,
          attempt: attempt,
          replaceCurrentScreen: false,
        );

        if (mounted) {
          await _loadAttempt();
        }

        return;

      case AssessmentSection.notationReading:
        await _openNotationReading(
          currentScreenContext: context,
          attempt: attempt,
          replaceCurrentScreen: false,
        );

        if (mounted) {
          await _loadAttempt();
        }

        return;

      case AssessmentSection.pianoExecution:
        await _openPianoExecution(
          currentScreenContext: context,
          replaceCurrentScreen: false,
        );

        if (mounted) {
          await _loadAttempt();
        }

        return;

      case AssessmentSection.results:
        await _openResults(
          currentScreenContext: context,
          attempt: attempt,
          replaceCurrentScreen: false,
        );
        return;
    }
  }

  /// Warns the user before beginning their only assessment attempt.
  Future<bool> _showStartConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start assessment?'),
          content: const Text(
            'Your 72-hour deadline will begin immediately. '
            'You only receive one attempt, and an expired '
            'assessment will permanently assign Beginner level.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Opens Home without creating, restarting, or changing an assessment.
  ///
  /// Before Start, this leaves the 72-hour timer untouched. For an active
  /// attempt, its existing server deadline continues while the user is away.
  void _continueToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _buildBody(),
        ),
      ),
    );
  }

  /// Selects the correct body for loading, error, or loaded state.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildAssessmentState();
  }

  /// Displays an error and lets the user retry the server request.
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTextSizes.body, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: _loadAttempt,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Displays the current status and its available primary action.
  Widget _buildAssessmentState() {
    final attempt = _attempt;
    final status = attempt?.effectiveStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _statusTitle(status),
          style: const TextStyle(
            fontSize: AppTextSizes.screenTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _statusDescription(status),
          style: const TextStyle(fontSize: AppTextSizes.body, height: 1.4),
        ),
        if (status == AssessmentAttemptStatus.inProgress) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildRemainingTime(attempt!),
        ],
        const Spacer(),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _primaryButtonAction(status),
            child: _isSubmitting
                ? const SizedBox(
                    width: AppIconSizes.md,
                    height: AppIconSizes.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_primaryButtonText(status)),
          ),
        ),
        if (status == null ||
            status == AssessmentAttemptStatus.inProgress) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _isSubmitting ? null : _continueToHome,
              child: Text(
                status == null ? 'Skip for Now' : 'Continue Later',
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Displays the trusted remaining duration for an active attempt.
  Widget _buildRemainingTime(AssessmentAttempt attempt) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time remaining',
            style: TextStyle(
              fontSize: AppTextSizes.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatDuration(attempt.remainingTime),
            style: const TextStyle(
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the heading for the current assessment state.
  String _statusTitle(AssessmentAttemptStatus? status) {
    if (status == null) {
      return 'Skill assessment';
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return 'Assessment in progress';
      case AssessmentAttemptStatus.completed:
        return 'Assessment completed';
      case AssessmentAttemptStatus.expired:
        return 'Assessment expired';
    }
  }

  /// Returns the message for the current assessment state.
  String _statusDescription(AssessmentAttemptStatus? status) {
    if (status == null) {
      return 'Complete the assessment to determine your '
          'SoundSight Level. Your 72-hour deadline begins '
          'only after you press Start.';
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return 'Your assessment has started. Continue before '
            'the deadline to receive your SoundSight Level.';
      case AssessmentAttemptStatus.completed:
        return 'Your assessment is complete. View your permanent '
            'SoundSight Level and section results.';
      case AssessmentAttemptStatus.expired:
        return 'The assessment was not completed within 72 hours. '
            'Your SoundSight Level is Beginner, and this assessment '
            'cannot be attempted again.';
    }
  }

  /// Selects the button label for the current state.
  String _primaryButtonText(AssessmentAttemptStatus? status) {
    if (status == null) {
      return 'Start Assessment';
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return 'Resume Assessment';
      case AssessmentAttemptStatus.completed:
        return 'View Results';
      case AssessmentAttemptStatus.expired:
        return 'Continue to Home';
    }
  }

  /// Selects the button behavior for the current state.
  VoidCallback? _primaryButtonAction(AssessmentAttemptStatus? status) {
    if (_isSubmitting) {
      return null;
    }

    if (status == AssessmentAttemptStatus.completed) {
      return _openCompletedResults;
    }

    if (status == AssessmentAttemptStatus.expired) {
      return _continueToHome;
    }

    return _startOrResumeAssessment;
  }

  /// Formats the trusted remaining duration for display.
  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }
}
