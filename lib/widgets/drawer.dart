import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/auth/login_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    return Drawer(
      backgroundColor: colors.surfaceColor,
      width: 265,

      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Image.asset(
                  colors.logoPath,
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
                const Gap(AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SoundSight',
                      style: TextStyle(
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryColor,
                      ),
                    ),
                    Text(
                      'Piano Player',
                      style: TextStyle(
                        fontSize: AppTextSizes.label,
                        color: colors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_outline,
                    color: colors.primaryColor,
                    size: AppIconSizes.md,
                  ),
                  const Gap(AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skill Level',
                        style: TextStyle(
                          fontSize: AppTextSizes.caption,
                          color: colors.secondaryTextColor,
                        ),
                      ),
                      Text(
                        'Beginner',
                        style: TextStyle(
                          fontSize: AppTextSizes.body,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.home_outlined, color: colors.primaryColor),
              title: Text(
                'Home',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              tileColor: colors.backgroundColor,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.library_music_outlined,
                color: colors.primaryColor,
              ),
              title: Text(
                'Music Sheets',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.add_photo_alternate_outlined,
                color: colors.primaryColor,
              ),
              title: Text(
                'Upload / Capture Sheet',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.view_in_ar_outlined,
                color: colors.primaryColor,
              ),
              title: Text(
                'AR Practice',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(color: colors.borderColor),
            ListTile(
              leading: Icon(Icons.bookmark_border, color: colors.primaryColor),
              title: Text(
                'Saved Sheets',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.primaryColor),
              title: Text(
                'Composition',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.bar_chart_outlined,
                color: colors.primaryColor,
              ),
              title: Text(
                'Practice Results',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(color: colors.borderColor),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: Icon(
                isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: colors.primaryColor,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              value: isDarkMode,
              activeThumbColor: colors.surfaceColor,
              activeTrackColor: colors.primaryColor,
              inactiveThumbColor: colors.primaryColor,
              inactiveTrackColor: colors.borderColor,
              onChanged: _updateTheme,
            ),
            ListTile(
              leading: Icon(Icons.logout, color: colors.primaryColor),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final shouldLogout = await _showLogoutDialog(context, colors);

                if (!context.mounted || !shouldLogout) return;

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTheme(bool value) async {
    onDarkModeChanged(value);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'theme': value ? 'dark' : 'light',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> _showLogoutDialog(
    BuildContext context,
    AppThemeColors colors,
  ) async {
    return await showDialog<bool>(
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
                      color: colors.primaryColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: colors.surfaceColor,
                      size: AppIconSizes.sm,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Logout?',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.body,
                  height: 1.4,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryColor,
                            side: BorderSide(
                              color: colors.borderColor,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryColor,
                            foregroundColor: colors.surfaceColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
