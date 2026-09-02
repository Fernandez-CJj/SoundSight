import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';

/// Displays the rules and requirements before the assessment sections begin.
class AssessmentIntroductionScreen extends StatefulWidget {
  const AssessmentIntroductionScreen({
    super.key,
    required this.attempt,
    required this.onContinue,
  });

  /// The current assessment returned after a Firestore server-time check.
  final AssessmentAttempt attempt;

  /// Opens the next assessment section.
  final VoidCallback onContinue;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment')),
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
                      'Before you begin',
                      style: TextStyle(
                        fontSize: AppTextSizes.screenTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Please read the following information carefully.',
                      style: TextStyle(
                        fontSize: AppTextSizes.body,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRemainingTime(),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Important information',
                      style: TextStyle(
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InstructionItem(
                      text:
                          'Your SoundSight Level measures your combined '
                          'sheet-reading and piano-playing ability.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InstructionItem(
                      text:
                          'You only receive one assessment attempt. An '
                          'expired attempt cannot be restarted.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InstructionItem(
                      text:
                          'The assessment must be completed within 72 hours '
                          'after it starts.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InstructionItem(
                      text:
                          'If the assessment expires before completion, your '
                          'SoundSight Level will be set to Beginner.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InstructionItem(
                      text:
                          'You may leave between sections and continue later '
                          'while the assessment is still active.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InstructionItem(
                      text:
                          'Prepare your MIDI keyboard, internet connection, '
                          'and a quiet place before continuing.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays the remaining duration with minimal visual styling.
  Widget _buildRemainingTime() {
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
          Text(
            _canContinue ? 'Time remaining' : 'Assessment expired',
            style: const TextStyle(
              fontSize: AppTextSizes.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _canContinue
                ? _formatDuration(_displayedRemainingTime)
                : 'No time remaining',
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
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _canContinue
            ? widget.onContinue
            : () {
                Navigator.of(context).pop();
              },
        child: Text(_canContinue ? 'Continue Assessment' : 'Return'),
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
      return '${days}d ${hours}h ${minutes}m';
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
