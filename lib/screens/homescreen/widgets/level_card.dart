import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class TopCard extends StatelessWidget {
  const TopCard({super.key, required this.colors, required this.skillLevel});

  final AppThemeColors colors;
  final String skillLevel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: colors.borderColor),
      ),
      child: ListTile(
        horizontalTitleGap: AppSpacing.sm,
        contentPadding: EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          radius: AppRadius.xl,
          backgroundColor: colors.backgroundColor,
          child: Icon(
            Icons.signal_cellular_alt_rounded,
            color: colors.primaryColor,
            size: AppRadius.xxl,
          ),
        ),
        title: Text(
          skillLevel,
          style: TextStyle(
            fontSize: AppTextSizes.body,
            fontWeight: FontWeight.w600,
            color: colors.primaryColor,
          ),
        ),
        subtitle: Text(
          'Your current skill level',
          style: TextStyle(
            fontSize: AppTextSizes.caption,
            fontWeight: FontWeight.w400,
            color: colors.secondaryTextColor,
          ),
        ),
        trailing: CircleAvatar(
          radius: 24,
          backgroundColor: colors.backgroundColor,
          child: Icon(
            Icons.workspace_premium_outlined,
            color: colors.primaryColor,
            size: 32,
          ),
        ),
      ),
    );
  }
}
