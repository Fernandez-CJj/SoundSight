import 'package:flutter/material.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

ThemeData helpCenterTheme(BuildContext context, AppThemeColors colors) {
  final theme = Theme.of(context);
  return theme.copyWith(
    brightness: colors.isDarkMode ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme(
      brightness: colors.isDarkMode ? Brightness.dark : Brightness.light,
      primary: colors.primaryColor,
      onPrimary: colors.backgroundColor,
      secondary: colors.primaryColor,
      onSecondary: colors.backgroundColor,
      error: colors.destructiveColor,
      onError: colors.onDestructiveColor,
      surface: colors.surfaceColor,
      onSurface: colors.primaryColor,
      onSurfaceVariant: colors.secondaryTextColor,
      outline: colors.borderColor,
      outlineVariant: colors.borderColor,
      surfaceTint: colors.surfaceColor,
      shadow: colors.primaryColor,
      scrim: colors.backgroundColor,
    ),
    scaffoldBackgroundColor: colors.backgroundColor,
    canvasColor: colors.surfaceColor,
    dividerColor: colors.borderColor,
    disabledColor: colors.secondaryTextColor,
    splashColor: colors.primaryColor.withValues(alpha: 0.08),
    highlightColor: colors.primaryColor.withValues(alpha: 0.04),
    hoverColor: colors.primaryColor.withValues(alpha: 0.04),
    focusColor: colors.primaryColor.withValues(alpha: 0.12),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primaryColor,
      linearTrackColor: colors.borderColor,
      circularTrackColor: colors.borderColor,
    ),
    iconTheme: IconThemeData(color: colors.primaryColor),
    textTheme: theme.textTheme.apply(
      bodyColor: colors.primaryColor,
      displayColor: colors.primaryColor,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.primaryColor,
      selectionColor: colors.primaryColor.withValues(alpha: 0.2),
      selectionHandleColor: colors.primaryColor,
    ),
  );
}
