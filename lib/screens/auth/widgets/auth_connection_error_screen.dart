import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Shown when the saved account cannot be verified during startup.
class AuthConnectionErrorScreen extends StatelessWidget {
  const AuthConnectionErrorScreen({
    super.key,
    required this.onRetry,
    required this.onSignOut,
    this.isDarkMode = false,
  });

  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - AppSpacing.lg * 2).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          colors.logoPath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'SoundSight',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTextSizes.screenTitle,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'See the music. Play with confidence',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: colors.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colors.surfaceColor,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: colors.backgroundColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.borderColor,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.wifi_off_rounded,
                                    size: AppIconSizes.lg,
                                    color: colors.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                header: true,
                                child: Text(
                                  "Let's try that again",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppTextSizes.screenTitle,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                "We couldn't verify your account status. "
                                'Check your connection and try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: AppTextSizes.body,
                                  height: 1.5,
                                  color: colors.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ElevatedButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: AppIconSizes.md,
                                ),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primaryColor,
                                  foregroundColor: colors.surfaceColor,
                                  surfaceTintColor: colors.primaryColor,
                                  elevation: 0,
                                  minimumSize: const Size(0, 56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: AppTextSizes.body,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: onSignOut,
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.secondaryTextColor,
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: AppTextSizes.label,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
