import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class PlayerProgressContainer extends StatelessWidget {
  const PlayerProgressContainer({
    super.key,
    required this.colors,
    required this.skillLevel,
    required this.level,
    required this.experiencePoints,
    required this.experienceToNextLevel,
  });

  final AppThemeColors colors;
  final String skillLevel;
  final int level;
  final int experiencePoints;
  final int experienceToNextLevel;

  @override
  Widget build(BuildContext context) {
    final progress = experienceToNextLevel <= 0
        ? 0.0
        : (experiencePoints / experienceToNextLevel).clamp(0.0, 1.0).toDouble();
    final remainingExperience = (experienceToNextLevel - experiencePoints)
        .clamp(0, experienceToNextLevel);
    final normalizedSkillLevel = skillLevel.trim();
    final isUnderAssessment = normalizedSkillLevel.isEmpty;
    final localizedSkillLevel = switch (normalizedSkillLevel.toLowerCase()) {
      'beginner' => context.l10n.beginner,
      'intermediate' => context.l10n.intermediate,
      'advanced' => context.l10n.advanced,
      _ when normalizedSkillLevel.isNotEmpty =>
        '${normalizedSkillLevel[0].toUpperCase()}${normalizedSkillLevel.substring(1)}',
      _ => '',
    };
    final rank = isUnderAssessment
        ? context.l10n.underAssessment
        : context.l10n.rankLabel(localizedSkillLevel);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Icon(
                  Icons.military_tech_outlined,
                  color: colors.primaryColor,
                  size: 28,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.playerProgress,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      rank,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
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
                  color: colors.primaryColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  context.l10n.levelLabel(level),
                  style: TextStyle(
                    color: colors.backgroundColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Gap(AppSpacing.md),
          Row(
            children: [
              Text(
                context.l10n.experience,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
              Spacer(),
              Text(
                '$experiencePoints / $experienceToNextLevel XP',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: colors.backgroundColor,
              color: colors.primaryColor,
            ),
          ),
          Gap(AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: colors.primaryColor, size: 17),
              Gap(AppSpacing.xs),
              Text(
                context.l10n.xpNeeded(remainingExperience),
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
              Spacer(),
              Text(
                context.l10n.nextLevel,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
