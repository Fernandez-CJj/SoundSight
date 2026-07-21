import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class UnpublishCompositionDialog extends StatelessWidget {
  const UnpublishCompositionDialog({
    super.key,
    required this.colors,
    required this.compositionTitle,
  });

  final AppThemeColors colors;
  final String compositionTitle;

  static const Color dangerColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: dangerColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.public_off_rounded,
          color: dangerColor,
          size: AppIconSizes.lg,
        ),
      ),
      title: Text(
        'Unpublish composition?',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        '"$compositionTitle" and all of its published versions '
        'will be removed from the community feed.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                    side: BorderSide(color: colors.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text(
                    'Unpublish',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class UnpublishingCompositionDialog extends StatelessWidget {
  const UnpublishingCompositionDialog({
    super.key,
    required this.colors,
  });

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colors.surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: colors.primaryColor,
              ),
              const Gap(AppSpacing.lg),
              Text(
                'Unpublishing composition...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(AppSpacing.xs),
              Text(
                'Removing every published version and PDF. '
                'Please wait.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.label,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
