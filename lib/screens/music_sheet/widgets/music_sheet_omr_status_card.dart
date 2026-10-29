import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class MusicSheetOmrStatusCard extends StatelessWidget {
  const MusicSheetOmrStatusCard({
    super.key,
    required this.colors,
    required this.status,
    required this.partCount,
    required this.noteCount,
    required this.isConverting,
    required this.onRecognize,
    this.titleOverride,
    this.subtitleOverride,
    this.buttonLabelOverride,
    this.initialIcon,
    this.showCompletedAction = true,
    this.showAction = true,
  });

  final AppThemeColors colors;
  final String status;
  final int partCount;
  final int noteCount;
  final bool isConverting;
  final VoidCallback onRecognize;
  final String? titleOverride;
  final String? subtitleOverride;
  final String? buttonLabelOverride;
  final IconData? initialIcon;
  final bool showCompletedAction;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final isProcessing = status == 'processing' || isConverting;
    final isCompleted = status == 'completed';
    final isFailed = status == 'failed';
    final l10n = context.l10n;
    final accentColor = isCompleted
        ? const Color(0xFF16A34A)
        : isFailed
        ? const Color(0xFFDC2626)
        : colors.primaryColor;
    final icon = isCompleted
        ? Icons.check_rounded
        : isFailed
        ? Icons.refresh_rounded
        : initialIcon ?? Icons.document_scanner_outlined;
    final defaultTitle = isCompleted
        ? l10n.translationReady
        : isFailed
        ? l10n.translationFailed
        : isProcessing
        ? l10n.translatingMusicSheet
        : l10n.translate;
    final defaultSubtitle = isCompleted
        ? l10n.translationSummary(noteCount, partCount)
        : isFailed
        ? l10n.translationFailedDescription
        : isProcessing
        ? l10n.translationProcessingDescription
        : l10n.translationStartDescription;

    final title = titleOverride ?? defaultTitle;
    final subtitle = subtitleOverride ?? defaultSubtitle;
    final buttonLabel = buttonLabelOverride ??
        (isCompleted
            ? l10n.reconvert
            : isFailed
            ? l10n.retry
            : l10n.translate);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: isProcessing
                ? Padding(
                    padding: EdgeInsets.all(AppSpacing.sm + 2),
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(icon, color: accentColor, size: AppIconSizes.md),
          ),
          Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ],
            ),
          ),
          if (showAction && !isProcessing && (!isCompleted || showCompletedAction)) ...[
            Gap(AppSpacing.sm),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: onRecognize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? colors.backgroundColor
                      : colors.primaryColor,
                  foregroundColor: isCompleted
                      ? colors.primaryColor
                      : colors.backgroundColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  side: isCompleted
                      ? BorderSide(color: colors.borderColor)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
