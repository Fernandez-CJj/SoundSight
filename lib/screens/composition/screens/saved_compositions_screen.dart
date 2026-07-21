import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/controllers/published_composition_playback_controller.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/widgets/published_composition_card.dart';
import 'package:soundsight/screens/composition/screens/published_composition_comments_screen.dart';
import 'package:soundsight/screens/composition/services/published_composition_social_service.dart';
import 'package:soundsight/screens/composition/screens/published_composition_viewer_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

class SavedCompositionsScreen extends StatefulWidget {
  const SavedCompositionsScreen({
    super.key,
    this.isDarkMode,
  });

  final bool? isDarkMode;

  @override
  State<SavedCompositionsScreen> createState() =>
      _SavedCompositionsScreenState();
}

class _SavedCompositionsScreenState
    extends State<SavedCompositionsScreen> {
  final PublishedCompositionSocialService socialService =
      PublishedCompositionSocialService();
  final PublishedCompositionPlaybackController playbackController =
      PublishedCompositionPlaybackController();

  late bool isDarkMode;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;
    playbackController.addListener(updatePlaybackState);
    loadTheme();
  }

  @override
  void dispose() {
    playbackController.removeListener(updatePlaybackState);
    playbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Saved Sheets',
          style: TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.savedSheets,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: userId == null
          ? buildMessage(
              colors,
              icon: Icons.login_rounded,
              title: 'Sign in to view saved sheets.',
              message: 'Your saved composition versions will appear here.',
            )
          : StreamBuilder<List<PublishedComposition>>(
              stream: socialService.getSavedCompositions(userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return buildMessage(
                    colors,
                    icon: Icons.cloud_off_outlined,
                    title: 'Saved sheets could not be loaded.',
                    message: 'Check your connection and try again.',
                  );
                }

                final compositions = snapshot.data ?? [];

                if (compositions.isEmpty) {
                  return buildMessage(
                    colors,
                    icon: Icons.bookmark_border_rounded,
                    title: 'No saved sheets yet',
                    message: 'Save a published version to find it here.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  itemCount: compositions.length,
                  separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final composition = compositions[index];

                    return PublishedCompositionCard(
                      colors: colors,
                      composition: composition,
                      canUnpublish: false,
                      isUnpublishing: false,
                      isPlaying: playbackController.isPlaying(composition),
                      isPlaybackBusy: playbackController.isBusy,
                      onOpen: () {
                        openComposition(colors, composition);
                      },
                      onPlay: () {
                        playComposition(composition);
                      },
                      onComments: () {
                        openComments(colors, composition);
                      },
                      onUnpublish: () {},
                    );
                  },
                );
              },
            ),
    );
  }

  Widget buildMessage(
    AppThemeColors colors, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.secondaryTextColor, size: AppIconSizes.xl),
            const Gap(AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadTheme() async {
    if (userId == null) return;

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final theme = userDocument.data()?['theme'] ?? 'light';

    if (!mounted) return;

    setState(() {
      isDarkMode = theme == 'dark';
    });
  }

  void openComposition(
    AppThemeColors colors,
    PublishedComposition composition,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedCompositionViewerScreen(
          colors: colors,
          composition: composition,
        ),
      ),
    );
  }

  void openComments(
    AppThemeColors colors,
    PublishedComposition composition,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedCompositionCommentsScreen(
          colors: colors,
          composition: composition,
        ),
      ),
    );
  }

  Future<void> playComposition(
    PublishedComposition composition,
  ) async {
    final resultMessage = await playbackController.togglePlayback(
      composition,
      onPlaybackStarted: () {
        showMessage('Playing "${composition.title}".');
      },
    );

    if (!mounted || resultMessage == null) return;

    showMessage(resultMessage);
  }

  void updatePlaybackState() {
    if (mounted) {
      setState(() {});
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
