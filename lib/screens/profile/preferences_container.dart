import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class PreferencesContainer extends StatelessWidget {
  const PreferencesContainer({
    super.key,
    required this.colors,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final AppThemeColors colors;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderColor),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            secondary: Icon(
              isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: colors.primaryColor,
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.label,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'App appearance',
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.caption,
              ),
            ),
            value: isDarkMode,
            activeThumbColor: colors.surfaceColor,
            activeTrackColor: colors.primaryColor,
            inactiveThumbColor: colors.primaryColor,
            inactiveTrackColor: colors.borderColor,
            onChanged: onDarkModeChanged,
          ),
        ),
      ],
    );
  }
}
