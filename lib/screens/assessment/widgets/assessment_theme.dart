import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Applies the user's saved SoundSight theme to one assessment route.
class AssessmentTheme extends StatelessWidget {
  const AssessmentTheme({
    super.key,
    required this.isDarkMode,
    required this.builder,
  });

  final bool isDarkMode;
  final WidgetBuilder builder;

  static ThemeData dataFor(bool isDarkMode) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    final baseScheme = isDarkMode
        ? const ColorScheme.dark()
        : const ColorScheme.light();
    final onPrimaryColor = isDarkMode
        ? colors.backgroundColor
        : colors.surfaceColor;
    final colorScheme = baseScheme.copyWith(
      primary: colors.primaryColor,
      onPrimary: onPrimaryColor,
      surface: colors.surfaceColor,
      onSurface: colors.primaryColor,
      onSurfaceVariant: colors.secondaryTextColor,
      outline: colors.borderColor,
      outlineVariant: colors.borderColor,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.backgroundColor,
    );

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        bodyColor: colors.primaryColor,
        displayColor: colors.primaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      dividerTheme: DividerThemeData(color: colors.borderColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryColor,
          foregroundColor: onPrimaryColor,
          disabledBackgroundColor: colors.secondaryTextColor.withValues(
            alpha: 0.35,
          ),
          disabledForegroundColor: colors.surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryColor,
          side: BorderSide(color: colors.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.primaryColor),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primaryColor,
        linearTrackColor: colors.borderColor,
        circularTrackColor: colors.borderColor,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.primaryColor,
        contentTextStyle: TextStyle(color: colors.backgroundColor),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: dataFor(isDarkMode),
      child: Builder(builder: builder),
    );
  }
}

/// Keeps assessment content readable on phones, tablets, and wide displays.
class AssessmentPageBody extends StatelessWidget {
  const AssessmentPageBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}
