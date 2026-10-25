import 'package:flutter/material.dart';
import 'package:soundsight/theme/app_colors.dart';

class AppThemeColors {
  const AppThemeColors({
    required this.isDarkMode,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.completedStageColor,
    required this.completedStageSurfaceColor,
    required this.sightReadingResultColor,
    required this.synthesiaResultColor,
    required this.arPerformanceResultColor,
    required this.logoPath,
  });

  final bool isDarkMode;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color completedStageColor;
  final Color completedStageSurfaceColor;
  final Color sightReadingResultColor;
  final Color synthesiaResultColor;
  final Color arPerformanceResultColor;
  final String logoPath;

  factory AppThemeColors.fromDarkMode(bool isDarkMode) {
    return isDarkMode
        ? const AppThemeColors(
            isDarkMode: true,
            backgroundColor: AppColors.darkBackground,
            surfaceColor: AppColors.darkSurface,
            primaryColor: AppColors.darkPrimary,
            secondaryTextColor: AppColors.darkSecondaryText,
            borderColor: AppColors.darkBorder,
            completedStageColor: AppColors.darkCompletedStage,
            completedStageSurfaceColor: AppColors.darkCompletedStageSurface,
            sightReadingResultColor: AppColors.darkSightReadingResult,
            synthesiaResultColor: AppColors.darkSynthesiaResult,
            arPerformanceResultColor: AppColors.darkArPerformanceResult,
            logoPath: 'assets/images/logo_image_dark.png',
          )
        : const AppThemeColors(
            isDarkMode: false,
            backgroundColor: AppColors.lightBackground,
            surfaceColor: AppColors.lightSurface,
            primaryColor: AppColors.lightPrimary,
            secondaryTextColor: AppColors.lightSecondaryText,
            borderColor: AppColors.lightBorder,
            completedStageColor: AppColors.lightCompletedStage,
            completedStageSurfaceColor: AppColors.lightCompletedStageSurface,
            sightReadingResultColor: AppColors.sightReadingResult,
            synthesiaResultColor: AppColors.synthesiaResult,
            arPerformanceResultColor: AppColors.arPerformanceResult,
            logoPath: 'assets/images/logo_image_light.png',
          );
  }
}
