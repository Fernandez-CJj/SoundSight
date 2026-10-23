import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/auth/login/login_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/localization/app_locale_controller.dart';
import 'package:soundsight/localization/localization_extension.dart';

import '../../constants/constant.dart';

class LogoutContainer extends StatelessWidget {
  const LogoutContainer({
    super.key,
    required this.colors,
  });

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    const logoutColor = Color(0xFFDC2626);

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    backgroundColor: colors.surfaceColor,
                    surfaceTintColor: colors.surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: AppSpacing.xl,
                          height: AppSpacing.xl,
                          decoration: BoxDecoration(
                            color: logoutColor,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: AppIconSizes.sm,
                          ),
                        ),
                        Gap(AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n.logoutQuestion,
                            style: TextStyle(
                              color: logoutColor,
                              fontSize: AppTextSizes.sectionTitle,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      context.l10n.logoutConfirmation,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.body,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(
                          context.l10n.cancel,
                          style: TextStyle(color: colors.secondaryTextColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoutColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        child: Text(context.l10n.logout),
                      ),
                    ],
                  );
                },
              ) ??
              false;

          if (!context.mounted || !shouldLogout) return;

          await FirebaseAuth.instance.signOut();

          if (context.mounted) {
            AppLocaleScope.of(context).reset();
          }

          if (!context.mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        icon: Icon(Icons.logout_rounded, size: 20),
        label: Text(
          context.l10n.logout,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: logoutColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
