import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class DeleteCompositionDialog extends StatelessWidget {
  const DeleteCompositionDialog({
    super.key,
    required this.colors,
    required this.compositionTitle,
  });

  final AppThemeColors colors;
  final String compositionTitle;

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
          color: colors.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderColor),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colors.primaryColor,
          size: AppIconSizes.lg,
        ),
      ),
      title: Text(
        'Delete composition?',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "$compositionTitle"? '
        'This action cannot be undone.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
          height: 1.4,
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
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
                  child: Text('Cancel'),
                ),
              ),
            ),
            Gap(AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: colors.backgroundColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Delete',
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
