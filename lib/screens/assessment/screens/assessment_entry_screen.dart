import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/models/assessment_questionnaire.dart';
import 'package:soundsight/screens/assessment/screens/assessment_introduction_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_notation_reading_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_piano_execution_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_questionnaire_screen.dart';
import 'package:soundsight/screens/assessment/screens/assessment_results_screen.dart';
import 'package:soundsight/screens/assessment/services/assessment_attempt_service.dart';
import 'package:soundsight/screens/assessment/widgets/assessment_theme.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';

/// Displays the user's current assessment status and available action.
class AssessmentEntryScreen extends StatefulWidget {
  const AssessmentEntryScreen({
    super.key,
    this.initialAttempt,
    this.isDarkMode = false,
    this.returnToPreviousScreenOnDone = false,
  });

  /// An attempt already loaded during login.
  ///
  /// Passing it avoids an unnecessary initial Firestore request.
  final AssessmentAttempt? initialAttempt;

  final bool isDarkMode;

  /// Returns through both the result and entry routes when Assessment was
  /// opened from an existing screen such as Profile.
  final bool returnToPreviousScreenOnDone;

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
        _errorMessage = context.l10n.assessmentUnableToLoad;
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
        _errorMessage = context.l10n.assessmentUnableToStart;
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
            isDarkMode: widget.isDarkMode,
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
                  SnackBar(
                    content: Text(
                      introductionContext.l10n.assessmentUnableToContinue,
                    ),
                  ),
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
          isDarkMode: widget.isDarkMode,
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
        return Theme(
          data: AssessmentTheme.dataFor(widget.isDarkMode),
          child: AlertDialog(
            title: Text(dialogContext.l10n.assessmentAcceptBeginnerQuestion),
            content: Text(
              dialogContext.l10n.assessmentAcceptBeginnerDescription,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          child: Text(
                            dialogContext.l10n.assessmentReviewAnswers,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          child: Text(
                            dialogContext.l10n.assessmentAcceptBeginner,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          isDarkMode: widget.isDarkMode,
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
          isDarkMode: widget.isDarkMode,
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
      builder: (resultsContext) {
        return AssessmentResultsScreen(
          attempt: attempt,
          isDarkMode: widget.isDarkMode,
          onDone: () async {
            // The assessment is already permanent. Done only copies its
            // trusted final level into the user's main profile document.
            await _assessmentService.applyCompletedSkillLevel();

            if (!mounted || !resultsContext.mounted) {
              return;
            }

            if (widget.returnToPreviousScreenOnDone) {
              Navigator.of(resultsContext).pop();

              if (mounted) {
                Navigator.of(context).pop();
              }
            } else {
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
        return Theme(
          data: AssessmentTheme.dataFor(widget.isDarkMode),
          child: AlertDialog(
            title: Text(dialogContext.l10n.assessmentStartQuestion),
            content: Text(dialogContext.l10n.assessmentStartWarning),
            actionsPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          child: Text(
                            dialogContext.l10n.cancel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          child: Text(
                            dialogContext.l10n.start,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      MaterialPageRoute(
        builder: (_) => HomeScreen(isDarkMode: widget.isDarkMode),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AssessmentTheme(
      isDarkMode: widget.isDarkMode,
      builder: (themedContext) {
        return Scaffold(
          appBar: AppBar(title: Text(themedContext.l10n.assessment)),
          body: AssessmentPageBody(
            child: _buildBody(themedContext),
          ),
        );
      },
    );
  }

  /// Selects the correct body for loading, error, or loaded state.
  Widget _buildBody(BuildContext themedContext) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildAssessmentState(themedContext);
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
            child: Text(context.l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  /// Displays the current status and its available primary action.
  Widget _buildAssessmentState(BuildContext themedContext) {
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
          _buildRemainingTime(themedContext, attempt!),
        ],
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: ElevatedButton(
            onPressed: _primaryButtonAction(status),
            child: _isSubmitting
                ? SizedBox(
                    width: AppIconSizes.md,
                    height: AppIconSizes.md,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(themedContext).colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    _primaryButtonText(status),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
        if (status == null ||
            status == AssessmentAttemptStatus.inProgress) ...[
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: TextButton(
              onPressed: _isSubmitting ? null : _continueToHome,
              child: Text(
                status == null
                    ? context.l10n.assessmentSkipForNow
                    : context.l10n.assessmentContinueLater,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Displays the trusted remaining duration for an active attempt.
  Widget _buildRemainingTime(
    BuildContext themedContext,
    AssessmentAttempt attempt,
  ) {
    final colorScheme = Theme.of(themedContext).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.assessmentTimeRemaining,
            style: const TextStyle(
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
      return context.l10n.assessmentSkillAssessment;
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return context.l10n.assessmentInProgressTitle;
      case AssessmentAttemptStatus.completed:
        return context.l10n.assessmentCompletedTitle;
      case AssessmentAttemptStatus.expired:
        return context.l10n.assessmentExpiredTitle;
    }
  }

  /// Returns the message for the current assessment state.
  String _statusDescription(AssessmentAttemptStatus? status) {
    if (status == null) {
      return context.l10n.assessmentSkillDescription;
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return context.l10n.assessmentActiveDescription;
      case AssessmentAttemptStatus.completed:
        return context.l10n.assessmentCompleteDescription;
      case AssessmentAttemptStatus.expired:
        return context.l10n.assessmentExpiredFullDescription;
    }
  }

  /// Selects the button label for the current state.
  String _primaryButtonText(AssessmentAttemptStatus? status) {
    if (status == null) {
      return context.l10n.startAssessment;
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return context.l10n.resumeAssessment;
      case AssessmentAttemptStatus.completed:
        return context.l10n.assessmentViewResults;
      case AssessmentAttemptStatus.expired:
        return context.l10n.assessmentContinueHome;
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
      return context.l10n.assessmentDurationDays(days, hours, minutes);
    }

    if (hours > 0) {
      return context.l10n.assessmentDurationHours(hours, minutes);
    }

    return context.l10n.assessmentDurationMinutes(minutes);
  }
}
