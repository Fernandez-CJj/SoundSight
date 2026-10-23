import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/widgets/assessment_theme.dart';

/// Displays the rules and requirements before the assessment sections begin.
class AssessmentIntroductionScreen extends StatefulWidget {
  const AssessmentIntroductionScreen({
    super.key,
    required this.attempt,
    required this.onContinue,
    this.isDarkMode = false,
  });

  /// The current assessment returned after a Firestore server-time check.
  final AssessmentAttempt attempt;

  /// Opens the next assessment section.
  final VoidCallback onContinue;

  final bool isDarkMode;

  @override
  State<AssessmentIntroductionScreen> createState() {
    return _AssessmentIntroductionScreenState();
  }
}

class _AssessmentIntroductionScreenState
    extends State<AssessmentIntroductionScreen> {
  /// The trusted duration received from the assessment model.
  late final Duration _trustedRemainingTime;

  /// Measures elapsed time without depending on the phone's date setting.
  late final Stopwatch _elapsedStopwatch;

  /// The remaining time currently displayed on the screen.
  late Duration _displayedRemainingTime;

  /// Refreshes the displayed countdown once per second.
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _trustedRemainingTime = widget.attempt.remainingTime;
    _displayedRemainingTime = _trustedRemainingTime;
    _elapsedStopwatch = Stopwatch();

    if (widget.attempt.canContinue) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _elapsedStopwatch.stop();

    super.dispose();
  }

  /// Starts a display countdown from the last trusted server duration.
  void _startCountdown() {
    if (_trustedRemainingTime <= Duration.zero) {
      return;
    }

    _elapsedStopwatch.start();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  /// Updates the countdown using monotonic elapsed time.
  void _updateCountdown() {
    final calculatedRemaining =
        _trustedRemainingTime - _elapsedStopwatch.elapsed;

    final nextRemaining = calculatedRemaining.isNegative
        ? Duration.zero
        : calculatedRemaining;

    if (!mounted) {
      return;
    }

    setState(() {
      _displayedRemainingTime = nextRemaining;
    });

    if (nextRemaining == Duration.zero) {
      _countdownTimer?.cancel();
      _elapsedStopwatch.stop();
    }
  }

  /// Determines whether the user can continue to the next section.
  bool get _canContinue {
    return widget.attempt.canContinue &&
        _displayedRemainingTime > Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    return AssessmentTheme(
      isDarkMode: widget.isDarkMode,
      builder: (themedContext) {
        return Scaffold(
          appBar: AppBar(title: Text(themedContext.l10n.assessment)),
          body: AssessmentPageBody(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                    Text(
                      themedContext.l10n.assessmentBeforeYouBegin,
                      style: const TextStyle(
                        fontSize: AppTextSizes.screenTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      themedContext.l10n.assessmentReadCarefully,
                      style: const TextStyle(
                        fontSize: AppTextSizes.body,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRemainingTime(themedContext),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      themedContext.l10n.assessmentImportantInformation,
                      style: const TextStyle(
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentLevelExplanation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentTimingExplanation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentPassingExplanation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentChordExplanation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentOneAttempt,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentDeadlineExplanation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentExpirationExplanation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentLeaveExplanation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InstructionItem(
                      text: themedContext.l10n.assessmentPreparationExplanation,
                    ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionButton(),
                ],
              ),
          ),
        );
      },
    );
  }

  /// Displays the remaining duration with minimal visual styling.
  Widget _buildRemainingTime(BuildContext themedContext) {
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
            _canContinue
                ? context.l10n.assessmentTimeRemaining
                : context.l10n.assessmentExpiredTitle,
            style: const TextStyle(
              fontSize: AppTextSizes.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _canContinue
                ? _formatDuration(_displayedRemainingTime)
                : context.l10n.assessmentNoTimeRemaining,
            style: TextStyle(
              color: _canContinue ? colorScheme.onSurface : colorScheme.error,
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Continues when active or returns when the attempt has expired.
  Widget _buildActionButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: ElevatedButton(
        onPressed: _canContinue
            ? widget.onContinue
            : () {
                Navigator.of(context).pop();
              },
        child: Text(
          _canContinue
              ? context.l10n.assessmentContinue
              : context.l10n.returnAction,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Formats the remaining duration for the countdown.
  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return context.l10n.assessmentDurationDays(days, hours, minutes);
    }

    final paddedHours = hours.toString().padLeft(2, '0');
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    final paddedSeconds = seconds.toString().padLeft(2, '0');

    return '$paddedHours:$paddedMinutes:$paddedSeconds';
  }
}

/// Displays one aligned instruction with a simple bullet icon.
class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle_outline, size: AppIconSizes.sm),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: AppTextSizes.body, height: 1.4),
          ),
        ),
      ],
    );
  }
}
