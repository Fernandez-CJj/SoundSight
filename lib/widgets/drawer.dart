import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/app_language.dart';
import 'package:soundsight/localization/app_locale_controller.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/auth/login/login_screen.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_sheet_screen.dart';
import 'package:soundsight/screens/composition/screens/my_compositions_screen.dart';
import 'package:soundsight/screens/composition/screens/published_compositions_screen.dart';
import 'package:soundsight/screens/composition/screens/saved_compositions_screen.dart';
import 'package:soundsight/screens/flyaway/flyaway_screen.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';
import 'package:soundsight/screens/micNiKen/microphone_screen.dart';
import 'package:soundsight/screens/midi/midi/midi_note_identifier_screen.dart';
import 'package:soundsight/screens/music_sheet/screens/music_sheet_screen.dart';
import 'package:soundsight/screens/practice/practice_screen.dart';
import 'package:soundsight/screens/practice_result/practice_results_screen.dart';
import 'package:soundsight/screens/profile/profile_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer_profile_header.dart';

enum DrawerItem {
  home,
  musicSheets,
  captureUpload,
  practice,
  practiceResults,
  midi,
  mic,
  flyaway,
  savedSheets,
  composition,
  publishedCompositions,
  profile,
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.activeItem = DrawerItem.home,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final DrawerItem activeItem;

  static const Color _logoutColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);
    final l10n = context.l10n;
    final selectedLanguage = AppLocaleScope.of(context).language;

    return Drawer(
      backgroundColor: colors.surfaceColor,
      width: 265,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            DrawerProfileHeader(
              colors: colors,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.profile) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(colors: colors),
                    ),
                  );
                }
              },
            ),
            const Gap(AppSpacing.lg),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.home,
              icon: Icons.home_outlined,
              title: l10n.drawerHome,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.home) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(isDarkMode: isDarkMode),
                    ),
                  );
                }
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.captureUpload,
              icon: Icons.add_photo_alternate_outlined,
              title: l10n.drawerUploadSheet,
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();

                if (activeItem != DrawerItem.captureUpload) {
                  final wasUploaded = await navigator.push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          CaptureUploadSheetScreen(isDarkMode: isDarkMode),
                    ),
                  );

                  if (wasUploaded == true && navigator.mounted) {
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            MusicSheetScreen(isDarkMode: isDarkMode),
                      ),
                    );
                  }
                }
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.musicSheets,
              icon: Icons.library_music_outlined,
              title: l10n.drawerMusicSheets,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.musicSheets) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MusicSheetScreen(isDarkMode: isDarkMode),
                    ),
                  );
                }
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.practice,
              icon: Icons.school_outlined,
              title: l10n.drawerPractice,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.practice) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PracticeScreen()),
                  );
                }
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.practiceResults,
              icon: Icons.insights_outlined,
              title: l10n.drawerPracticeResults,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.practiceResults) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PracticeResultsScreen(isDarkMode: isDarkMode),
                    ),
                  );
                }
              },
            ),
            Divider(color: colors.borderColor),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.composition,
              icon: Icons.edit_outlined,
              title: l10n.drawerComposition,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.composition) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MyCompositionsScreen(isDarkMode: isDarkMode),
                    ),
                  );
                }
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.publishedCompositions,
              icon: Icons.public_rounded,
              title: l10n.drawerPublishedCompositions,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.publishedCompositions) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PublishedCompositionsScreen(isDarkMode: isDarkMode),
                    ),
                  );
                }
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.savedSheets,
              icon: Icons.bookmark_border,
              title: l10n.drawerSavedSheets,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.savedSheets) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SavedCompositionsScreen(isDarkMode: isDarkMode),
                    ),
                  );
                }
              },
            ),
            Divider(color: colors.borderColor),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.midi,
              icon: Icons.usb_outlined,
              title: l10n.drawerMidi,
              onTap: () {
                Navigator.pop(context);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MidiNoteIdentifierScreen(),
                  ),
                );
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.mic,
              icon: Icons.mic_none_outlined,
              title: l10n.drawerMic,
              onTap: () {
                Navigator.pop(context);

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MicrophoneScreen()),
                );
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.flyaway,
              icon: Icons.back_hand_outlined,
              title: l10n.drawerFlyaway,
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.flyaway) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FlyawayScreen()),
                  );
                }
              },
            ),
            Divider(color: colors.borderColor),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.language_rounded, color: colors.primaryColor),
              title: Text(
                l10n.language,
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: colors.primaryColor,
                ),
              ),
              subtitle: Text(
                selectedLanguage == AppLanguage.filipino
                    ? l10n.filipino
                    : l10n.english,
                style: TextStyle(color: colors.secondaryTextColor),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colors.secondaryTextColor,
              ),
              onTap: () => _showLanguageDialog(context, colors),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: Icon(
                isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: colors.primaryColor,
              ),
              title: Text(
                l10n.darkMode,
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
              leading: const Icon(Icons.logout, color: _logoutColor),
              title: Text(
                l10n.logout,
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  color: _logoutColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final shouldLogout = await _showLogoutDialog(context, colors);

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

  Future<void> _showLanguageDialog(
    BuildContext context,
    AppThemeColors colors,
  ) async {
    final l10n = context.l10n;
    final controller = AppLocaleScope.of(context);
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: colors.surfaceColor,
          title: Text(
            l10n.language,
            style: TextStyle(color: colors.primaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  l10n.english,
                  style: TextStyle(color: colors.primaryColor),
                ),
                trailing: controller.language == AppLanguage.english
                    ? Icon(Icons.check_rounded, color: colors.primaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(dialogContext, AppLanguage.english);
                },
              ),
              ListTile(
                title: Text(
                  l10n.filipino,
                  style: TextStyle(color: colors.primaryColor),
                ),
                trailing: controller.language == AppLanguage.filipino
                    ? Icon(Icons.check_rounded, color: colors.primaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(dialogContext, AppLanguage.filipino);
                },
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == controller.language) return;

    final previous = controller.language;
    controller.setLanguage(selected);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'languageCode': selected.code,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      controller.setLanguage(previous);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.languageSaveFailed)),
        );
    }
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
                      color: _logoutColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: AppIconSizes.sm,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.logoutQuestion,
                      style: TextStyle(
                        color: _logoutColor,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w600,
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
                          child: Text(context.l10n.cancel),
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
                            backgroundColor: _logoutColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: Text(context.l10n.logout),
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

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.colors,
    required this.active,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final AppThemeColors colors;
  final bool active;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: AppTextSizes.body,
          color: colors.primaryColor,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      tileColor: active ? colors.backgroundColor : null,
      onTap: onTap,
    );
  }
}
