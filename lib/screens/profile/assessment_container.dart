import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Provides one consistent Profile entry point for the skill assessment.
class AssessmentContainer extends StatelessWidget {
  const AssessmentContainer({
    super.key,
    required this.colors,
    required this.actionLabel,
    required this.description,
    required this.onTap,
    this.isLoading = false,
  });

  final AppThemeColors colors;
  final String actionLabel;
  final String description;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assessment',
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            leading: Icon(
              Icons.assignment_outlined,
              color: colors.primaryColor,
            ),
            title: Text(
              actionLabel,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.label,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              description,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.caption,
              ),
            ),
            trailing: isLoading
                ? SizedBox(
                    width: AppIconSizes.sm,
                    height: AppIconSizes.sm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primaryColor,
                    ),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: colors.secondaryTextColor,
                  ),
            onTap: isLoading ? null : onTap,
          ),
        ),
      ],
    );
  }
}
