import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/controllers/published_composition_playback_controller.dart';
import 'package:soundsight/screens/composition/services/composition_publish_service.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/widgets/published_composition_card.dart';
import 'package:soundsight/screens/composition/screens/published_composition_comments_screen.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';
import 'package:soundsight/screens/composition/screens/published_composition_viewer_screen.dart';
import 'package:soundsight/screens/composition/dialogs/unpublish_composition_dialog.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

class PublishedCompositionsScreen extends StatefulWidget {
  const PublishedCompositionsScreen({
    super.key,
    this.isDarkMode,
  });

  final bool? isDarkMode;

  @override
  State<PublishedCompositionsScreen> createState() =>
      _PublishedCompositionsScreenState();
}

class _PublishedCompositionsScreenState
    extends State<PublishedCompositionsScreen> {
  final PublishedCompositionService compositionService =
      PublishedCompositionService();
  final CompositionPublishService publishService =
      CompositionPublishService();
  final PublishedCompositionPlaybackController playbackController =
      PublishedCompositionPlaybackController();

  final Set<String> unpublishingCompositionIds = {};

  late bool isDarkMode;
  late final String? userId;

  Stream<List<PublishedComposition>>? compositionsStream;

  @override
  void initState() {
    super.initState();

    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      compositionsStream = compositionService.getPublishedCompositions();
    }

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
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Published Compositions',
          style: TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.publishedCompositions,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: compositionsStream == null
          ? buildSignedOutState(colors)
          : StreamBuilder<List<PublishedComposition>>(
              stream: compositionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return buildErrorState(colors);
                }

                final compositions = snapshot.data ?? [];

                if (compositions.isEmpty) {
                  return buildEmptyState(colors);
                }

                return buildCompositionList(
                  colors,
                  compositions,
                );
              },
            ),
    );
  }

  Widget buildCompositionList(
    AppThemeColors colors,
    List<PublishedComposition> compositions,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: compositions.length + 1,
      separatorBuilder: (_, index) {
        return Gap(index == 0 ? AppSpacing.md : AppSpacing.sm);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return buildListHeader(
            colors,
            compositions.length,
          );
        }

        final composition = compositions[index - 1];

        return PublishedCompositionCard(
          colors: colors,
          composition: composition,
          canUnpublish: composition.ownerId == userId,
          isUnpublishing: unpublishingCompositionIds.contains(
            composition.id,
          ),
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
          onUnpublish: () {
            unpublishComposition(colors, composition);
          },
        );
      },
    );
  }

  Widget buildListHeader(
    AppThemeColors colors,
    int compositionCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore music',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.screenTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(AppSpacing.xs),
              Text(
                'View music sheets shared by other SoundSight users.',
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.label,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.primaryColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Text(
            '$compositionCount',
            style: TextStyle(
              color: colors.backgroundColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState(AppThemeColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderColor),
              ),
              child: Icon(
                Icons.public_rounded,
                color: colors.primaryColor,
                size: AppIconSizes.xl,
              ),
            ),
            const Gap(AppSpacing.lg),
            Text(
              'No published compositions yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.sm),
            Text(
              'Published music sheets from the SoundSight community '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorState(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: colors.secondaryTextColor,
              size: AppIconSizes.xl,
            ),
            const Gap(AppSpacing.md),
            Text(
              'Published compositions could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              'Check your connection and Firestore permissions.',
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

  Widget buildSignedOutState(AppThemeColors colors) {
    return Center(
      child: Text(
        'Sign in to view published compositions.',
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
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

  Future<void> unpublishComposition(
    AppThemeColors colors,
    PublishedComposition composition,
  ) async {
    if (composition.ownerId != userId) return;

    final shouldUnpublish = await showDialog<bool>(
      context: context,
      builder: (_) {
        return UnpublishCompositionDialog(
          colors: colors,
          compositionTitle: composition.title,
        );
      },
    );

    if (shouldUnpublish != true || !mounted) return;

    setState(() {
      unpublishingCompositionIds.add(composition.id);
    });

    final loadingDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return UnpublishingCompositionDialog(
          colors: colors,
        );
      },
    );

    var resultMessage =
        'The composition could not be unpublished. '
        'Make sure the backend is running.';

    try {
      await publishService.unpublishComposition(
        compositionId: composition.compositionId,
        ownerId: composition.ownerId,
      );

      if (!mounted) return;

      resultMessage = '"${composition.title}" was unpublished.';
    } catch (error, stackTrace) {
      debugPrint('Unpublishing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await loadingDialog;

        setState(() {
          unpublishingCompositionIds.remove(composition.id);
        });
      }
    }

    if (!mounted) return;

    showMessage(resultMessage);
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
