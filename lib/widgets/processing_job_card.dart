import 'package:flutter/material.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/services/processing_job_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Job state is separate from output availability: failed retries keep old files.
class ProcessingJobCard extends StatefulWidget {
  const ProcessingJobCard({
    super.key,
    required this.colors,
    required this.status,
    this.jobId,
    this.onRetry,
    this.embedded = false,
    this.errorMessage,
  });
  final AppThemeColors colors;
  final String? status;
  final String? jobId;
  final VoidCallback? onRetry;
  final bool embedded;
  final String? errorMessage;

  static bool isVisible(String? status) =>
      status == 'submitting' ||
      status == 'submissionFailed' ||
      status == 'queued' ||
      status == 'processing' ||
      status == 'failed';

  @override
  State<ProcessingJobCard> createState() => _ProcessingJobCardState();
}

class _ProcessingJobCardState extends State<ProcessingJobCard> {
  bool cancelling = false;

  @override
  Widget build(BuildContext context) {
    final submitting = widget.status == 'submitting';
    final queued = widget.status == 'queued';
    final processing = widget.status == 'processing';
    final submissionFailed = widget.status == 'submissionFailed';
    final failed = widget.status == 'failed' || submissionFailed;
    if (!ProcessingJobCard.isVisible(widget.status)) {
      return const SizedBox.shrink();
    }
    final colors = widget.colors;
    final hasAction =
        (queued && widget.jobId != null) || (failed && widget.onRetry != null);
    final action = OutlinedButton(
      onPressed: cancelling
          ? null
          : queued
          ? cancel
          : widget.onRetry,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primaryColor,
        disabledForegroundColor: colors.secondaryTextColor,
        side: BorderSide(color: colors.borderColor),
        backgroundColor: colors.surfaceColor,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: AppTextSizes.caption,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(
        cancelling
            ? context.l10n.jobCancellingTitle
            : queued
            ? context.l10n.cancel
            : context.l10n.tryAgain,
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: widget.embedded ? colors.backgroundColor : colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actionOnNextLine = constraints.maxWidth < 240;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (processing || submitting)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primaryColor,
                        backgroundColor: colors.borderColor,
                      ),
                    )
                  else
                    Icon(
                      queued
                          ? Icons.schedule_rounded
                          : Icons.error_outline_rounded,
                      size: 20,
                      color: colors.primaryColor,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      submitting
                          ? context.l10n.jobSubmittingTitle
                          : queued
                          ? context.l10n.jobQueuedTitle
                          : processing
                          ? context.l10n.jobProcessingTitle
                          : submissionFailed
                          ? context.l10n.jobSubmissionUnconfirmedTitle
                          : context.l10n.jobFailedTitle,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (hasAction && !actionOnNextLine) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: queued
                          ? context.l10n.jobCancelQueued
                          : context.l10n.retry,
                      child: action,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.errorMessage ??
                    (submitting
                        ? context.l10n.jobSubmittingDescription
                        : failed
                        ? context.l10n.jobFailedDescription
                        : context.l10n.jobLeaveScreen),
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  height: 1.5,
                ),
              ),
              if (hasAction && actionOnNextLine)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Tooltip(
                      message: queued
                          ? context.l10n.jobCancelQueued
                          : context.l10n.retry,
                      child: action,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> cancel() async {
    setState(() => cancelling = true);
    try {
      await ProcessingJobService().cancel(widget.jobId!);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showLatestSnackBar(
          appSnackBar(
            colors: widget.colors,
            message: error is ProcessingJobException
                ? error.message(context)
                : context.l10n.jobSubmissionUnconfirmed,
            type: AppSnackBarType.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }
}
