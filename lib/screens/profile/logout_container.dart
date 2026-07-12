import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/auth/login_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

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

    return Container(
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
                            'Log out?',
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
                      'Are you sure you want to log out of your account?',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.body,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(
                          'Cancel',
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
                        child: Text('Log Out'),
                      ),
                    ],
                  );
                },
              ) ??
              false;

          if (!context.mounted || !shouldLogout) return;

          await FirebaseAuth.instance.signOut();

          if (!context.mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        icon: Icon(Icons.logout_rounded, size: 20),
        label: Text(
          'Log Out',
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
