import 'package:soundsight/screens/onboarding/widgets/screen_feature_tour.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/controllers/published_composition_playback_controller.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/widgets/published_composition_card.dart';
import 'package:soundsight/screens/composition/screens/published_composition_comments_screen.dart';
import 'package:soundsight/screens/composition/services/published_composition_social_service.dart';
import 'package:soundsight/screens/composition/screens/published_composition_viewer_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

class SavedCompositionsScreen extends StatefulWidget {
  const SavedCompositionsScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<SavedCompositionsScreen> createState() =>
      _SavedCompositionsScreenState();
}

class _SavedCompositionsScreenState extends State<SavedCompositionsScreen> {
  final PublishedCompositionSocialService socialService =
      PublishedCompositionSocialService();
  final PublishedCompositionPlaybackController playbackController =
      PublishedCompositionPlaybackController();

  PublishedComposition? _tutorialComposition;
  late bool isDarkMode;
  late final String? userId;
  late final Stream<List<PublishedComposition>>? savedCompositionsStream;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;
    savedCompositionsStream = userId == null
        ? null
        : socialService.getSavedCompositions(userId!);
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

    return ScreenFeatureTour(
      featureId: 'saved_compositions',
      key: ValueKey('saved_compositions'),
      colors: colors,
      canStart: () =>
          !playbackController.isBusy &&
          playbackController.playingVersionId == null,
      openNext: _openTutorialItem,
      nextScreens: const {'published_details'},
      canContinue: () => _tutorialComposition != null,
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          backgroundColor: colors.backgroundColor,
          foregroundColor: colors.primaryColor,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            context.l10n.drawerSavedSheets,
            style: const TextStyle(
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
                title: context.l10n.signInForSavedSheets,
                message: context.l10n.savedSheetsSignedOutDescription,
              )
            : StreamBuilder<List<PublishedComposition>>(
                stream: savedCompositionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
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
                      title: context.l10n.savedSheetsLoadFailed,
                      message: context.l10n.checkConnectionTryAgain,
                    );
                  }

                  final compositions = snapshot.data ?? [];

                  _tutorialComposition = compositions.isEmpty
                      ? null
                      : compositions.first;
                  if (compositions.isEmpty) {
                    return buildMessage(
                      colors,
                      icon: Icons.bookmark_border_rounded,
                      title: context.l10n.noSavedSheets,
                      message: context.l10n.noSavedSheetsDescription,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    itemCount: (compositions.length / 2).ceil(),
                    separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final firstIndex = index * 2;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: buildCompositionCard(
                              colors,
                              compositions[firstIndex],
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: firstIndex + 1 < compositions.length
                                ? buildCompositionCard(
                                    colors,
                                    compositions[firstIndex + 1],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<Object?> _openTutorialItem() async {
    final item = _tutorialComposition;
    if (item == null || !mounted) return null;
    final colors = AppThemeColors.fromDarkMode(isDarkMode);
    return Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) =>
            PublishedCompositionViewerScreen(colors: colors, composition: item),
      ),
    );
  }

  Widget buildCompositionCard(
    AppThemeColors colors,
    PublishedComposition composition,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PublishedCompositionCard(
          key: ValueKey('${composition.id}/${composition.currentVersion}'),
          compact: constraints.maxWidth < 300,
          colors: colors,
          composition: composition,
          canUnpublish: false,
          isUnpublishing: false,
          isPlaying: playbackController.isPlaying(composition),
          isPlaybackBusy: playbackController.isBusyFor(composition),
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
            FeatureTourTarget(
              id: 'empty',
              enabled: icon == Icons.bookmark_border_rounded,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w700,
                ),
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

  void openComments(AppThemeColors colors, PublishedComposition composition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedCompositionCommentsScreen(
          colors: colors,
          composition: composition,
        ),
      ),
    );
  }

  Future<void> playComposition(PublishedComposition composition) async {
    final resultMessage = await playbackController.togglePlayback(
      composition,
      onPlaybackStarted: () {
        showMessage(context.l10n.communityPlaying(composition.title));
      },
    );

    if (!mounted || resultMessage == null) return;

    final localizedMessage = switch (resultMessage) {
      'Playback stopped.' => context.l10n.communityPlaybackStopped,
      'This version has no playback data. Republish it first.' =>
        context.l10n.communityNoPlaybackData,
      _ => context.l10n.communityPlaybackFailed,
    };

    showMessage(localizedMessage, type: AppSnackBarType.error);
  }

  void updatePlaybackState() {
    if (mounted) {
      setState(() {});
    }
  }

  void showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showLatestSnackBar(
      appSnackBar(
        colors: AppThemeColors.fromDarkMode(isDarkMode),
        message: message,
        type: type,
      ),
    );
  }
}
