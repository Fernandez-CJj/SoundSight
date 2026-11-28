import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class SheetMusicCheckingDialog extends StatelessWidget {
  const SheetMusicCheckingDialog({
    super.key,
    required this.colors,
    required this.page,
    required this.total,
    required this.onCancel,
  });

  final AppThemeColors colors;
  final int page;
  final int total;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colors.surfaceColor,
        surfaceTintColor: colors.surfaceColor,
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        icon: Icon(Icons.document_scanner_outlined, color: colors.primaryColor),
        title: Text(
          context.l10n.checkingSheetMusic,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.checkingSheetMusicDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.label,
                  height: 1.4,
                ),
              ),
              Gap(AppSpacing.md),
              LinearProgressIndicator(
                color: colors.primaryColor,
                backgroundColor: colors.borderColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                semanticsLabel: context.l10n.checkingSheetMusic,
              ),
              if (total > 1) ...[
                Gap(AppSpacing.sm),
                Text(
                  context.l10n.checkingSheetPage(page, total),
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: colors.primaryColor),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class SheetMusicValidationDialog extends StatelessWidget {
  const SheetMusicValidationDialog({
    super.key,
    required this.colors,
    required this.isUncertain,
  });

  final AppThemeColors colors;
  final bool isUncertain;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: colors.surfaceColor,
      scrollable: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: Icon(
        isUncertain ? Icons.help_outline_rounded : Icons.image_not_supported_outlined,
        color: isUncertain ? colors.primaryColor : colors.destructiveColor,
        size: 32,
      ),
      title: Text(
        isUncertain
            ? context.l10n.sheetMusicUncertainTitle
            : context.l10n.sheetMusicNotDetectedTitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        isUncertain
            ? context.l10n.sheetMusicUncertainDescription
            : context.l10n.sheetMusicNotDetectedDescription,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.label,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: colors.primaryColor),
          child: Text(context.l10n.backToSelection),
        ),
        if (isUncertain)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: colors.backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Text(context.l10n.useSheetAnyway),
          ),
      ],
    );
  }
}
