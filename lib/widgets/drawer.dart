import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/auth/login_screen.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_sheet_screen.dart';
import 'package:soundsight/screens/composition/screens/my_compositions_screen.dart';
import 'package:soundsight/screens/composition/screens/published_compositions_screen.dart';
import 'package:soundsight/screens/composition/screens/saved_compositions_screen.dart';
import 'package:soundsight/screens/flyaway/flyaway_screen.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';
import 'package:soundsight/screens/midi/midi/midi_note_identifier_screen.dart';
import 'package:soundsight/screens/music_sheet/screens/music_sheet_screen.dart';
import 'package:soundsight/screens/profile/profile_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer_profile_header.dart';

enum DrawerItem {
  home,
  musicSheets,
  captureUpload,
  midi,
  flyaway,
  savedSheets,
  composition,
  publishedCompositions,
  practiceResults,
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
              title: 'Home',
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
              active: activeItem == DrawerItem.musicSheets,
              icon: Icons.library_music_outlined,
              title: 'Music Sheets',
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
              active: activeItem == DrawerItem.captureUpload,
              icon: Icons.add_photo_alternate_outlined,
              title: 'Upload / Capture Sheet',
              onTap: () {
                Navigator.pop(context);

                if (activeItem != DrawerItem.captureUpload) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CaptureUploadSheetScreen(isDarkMode: isDarkMode),
                    ),
                  );
                }
              },
            ),
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.midi,
              icon: Icons.usb_outlined,
              title: 'MIDI',
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
              active: activeItem == DrawerItem.flyaway,
              icon: Icons.back_hand_outlined,
              title: 'Flyaway',
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
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.savedSheets,
              icon: Icons.bookmark_border,
              title: 'Saved Sheets',
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
            _DrawerTile(
              colors: colors,
              active: activeItem == DrawerItem.composition,
              icon: Icons.edit_outlined,
              title: 'Composition',
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
              title: 'Published Compositions',
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
              active: activeItem == DrawerItem.practiceResults,
              icon: Icons.bar_chart_outlined,
              title: 'Practice Results',
              onTap: () {},
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
              leading: const Icon(Icons.logout, color: _logoutColor),
              title: const Text(
                'Logout',
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
                  const Expanded(
                    child: Text(
                      'Logout?',
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
                            backgroundColor: _logoutColor,
                            foregroundColor: Colors.white,
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
