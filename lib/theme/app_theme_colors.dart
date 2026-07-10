import 'package:flutter/material.dart';
import 'package:soundsight/theme/app_colors.dart';

class AppThemeColors {
  const AppThemeColors({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.logoPath,
  });

  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final String logoPath;

  factory AppThemeColors.fromDarkMode(bool isDarkMode) {
    return isDarkMode
        ? const AppThemeColors(
            backgroundColor: AppColors.darkBackground,
            surfaceColor: AppColors.darkSurface,
            primaryColor: AppColors.darkPrimary,
            secondaryTextColor: AppColors.darkSecondaryText,
            borderColor: AppColors.darkBorder,
            logoPath: 'assets/images/logo_image_dark.png',
          )
        : const AppThemeColors(
            backgroundColor: AppColors.lightBackground,
            surfaceColor: AppColors.lightSurface,
            primaryColor: AppColors.lightPrimary,
            secondaryTextColor: AppColors.lightSecondaryText,
            borderColor: AppColors.lightBorder,
            logoPath: 'assets/images/logo_image_light.png',
          );
  }
}
