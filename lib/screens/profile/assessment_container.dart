import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class AssessmentContainer extends StatelessWidget {
  const AssessmentContainer({
    super.key,
    required this.colors,
    required this.iconBackgroundColor,
    required this.iconForegroundColor,
    required this.assessmentColor,
    required this.scoreColor,
    required this.assessmentScore,
    required this.dateColor,
    required this.assessmentDateText,
  });

  final AppThemeColors colors;
  final Color iconBackgroundColor;
  final Color iconForegroundColor;
  final Color assessmentColor;
  final Color scoreColor;
  final int? assessmentScore;
  final Color dateColor;
  final String assessmentDateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  color: iconForegroundColor,
                  size: 26,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment status',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: assessmentColor,
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: iconForegroundColor,
                      size: 15,
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      'Done',
                      style: TextStyle(
                        color: iconForegroundColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: scoreColor,
                        size: 28,
                      ),
                      Gap(AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Score',
                            style: TextStyle(
                              color: colors.secondaryTextColor,
                              fontSize: AppTextSizes.caption,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(color: scoreColor),
                              children: [
                                TextSpan(
                                  text: assessmentScore?.toString() ?? '--',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.label,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / 24',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.label,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: dateColor,
                        size: 27,
                      ),
                      Gap(AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: colors.secondaryTextColor,
                              fontSize: AppTextSizes.caption,
                            ),
                          ),
                          Text(
                            assessmentDateText,
                            style: TextStyle(
                              color: dateColor,
                              fontSize: AppTextSizes.label,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
