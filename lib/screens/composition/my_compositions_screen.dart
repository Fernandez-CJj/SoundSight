import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/composition.dart';
import 'package:soundsight/screens/composition/composition_card.dart';
import 'package:soundsight/screens/composition/composition_details_screen.dart';
import 'package:soundsight/screens/composition/composition_dialogs.dart';
import 'package:soundsight/screens/composition/composition_editor_screen.dart';
import 'package:soundsight/screens/composition/composition_playback_service.dart';
import 'package:soundsight/screens/composition/composition_service.dart';
import 'package:soundsight/screens/composition/new_composition_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

class MyCompositionsScreen extends StatefulWidget {
  const MyCompositionsScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<MyCompositionsScreen> createState() => _MyCompositionsScreenState();
}

class _MyCompositionsScreenState extends State<MyCompositionsScreen> {
  final CompositionService compositionService = CompositionService();
  final CompositionPlaybackService playbackService =
      CompositionPlaybackService();

  final Set<String> deletingCompositionIds = {};

  late bool isDarkMode;
  late final String? userId;

  Stream<List<Composition>>? compositionsStream;
  String? playingCompositionId;
  bool isPlaybackTransitioning = false;
  int playbackRequestId = 0;

  @override
  void initState() {
    super.initState();

    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      compositionsStream = compositionService.getUserCompositions(userId!);
    }

    loadTheme();
  }

  @override
  void dispose() {
    playbackRequestId++;
    playbackService.dispose();
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
          'My Compositions',
          style: TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New composition',
            onPressed: openNewComposition,
            icon: const Icon(Icons.add_rounded, size: AppIconSizes.lg),
          ),
        ],
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.composition,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: compositionsStream == null
          ? buildSignedOutState(colors)
          : StreamBuilder<List<Composition>>(
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

                return buildCompositionList(colors, compositions);
              },
            ),
    );
  }

  Widget buildCompositionList(
    AppThemeColors colors,
    List<Composition> compositions,
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
          return buildListHeader(colors, compositions.length);
        }

        final composition = compositions[index - 1];

        return CompositionCard(
          colors: colors,
          composition: composition,
          isDeleting: deletingCompositionIds.contains(composition.id),
          isPlaying: playingCompositionId == composition.id,
          isPlaybackBusy: isPlaybackTransitioning,
          onOpen: () {
            openCompositionDetails(colors, composition);
          },
          onEdit: () {
            editComposition(colors, composition);
          },
          onPlay: () {
            playComposition(composition);
          },
          onDelete: () {
            deleteComposition(colors, composition);
          },
        );
      },
    );
  }

  Widget buildListHeader(AppThemeColors colors, int compositionCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your piano pieces',
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.screenTitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  Text(
                    'Create, play, and manage your simple melodies.',
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.label,
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
        ),
        const Gap(AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: openNewComposition,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New Composition',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: colors.backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
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
                Icons.edit_note_rounded,
                color: colors.primaryColor,
                size: AppIconSizes.xl,
              ),
            ),
            const Gap(AppSpacing.lg),
            Text(
              'No compositions yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.sm),
            Text(
              'Create your first piano piece using melodies, chords, '
              'and custom measures.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                height: 1.4,
              ),
            ),
            const Gap(AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: openNewComposition,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Composition'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: colors.backgroundColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
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
              'Your compositions could not be loaded.',
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
        'Sign in to view your compositions.',
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

  Future<void> playComposition(Composition composition) async {
    if (isPlaybackTransitioning) return;

    if (composition.notes.isEmpty) {
      showMessage('"${composition.title}" does not have any notes yet.');
      return;
    }

    final isStoppingCurrentComposition =
        playingCompositionId == composition.id;
    final currentRequestId = ++playbackRequestId;

    setState(() {
      isPlaybackTransitioning = true;

      if (!isStoppingCurrentComposition) {
        playingCompositionId = composition.id;
      }
    });

    try {
      await playbackService.stop();

      if (!mounted || currentRequestId != playbackRequestId) return;

      if (isStoppingCurrentComposition) {
        showMessage('Playback stopped.');
        return;
      }

      await playbackService.playComposition(
        composition: composition,
        onPlaybackStarted: () {
          if (!mounted || currentRequestId != playbackRequestId) return;

          setState(() {
            isPlaybackTransitioning = false;
          });

          showMessage('Playing "${composition.title}".');
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Composition playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted && currentRequestId == playbackRequestId) {
        showMessage(
          'The composition could not be played. '
          'Check the piano audio files.',
        );
      }
    } finally {
      if (mounted && currentRequestId == playbackRequestId) {
        setState(() {
          playingCompositionId = null;
          isPlaybackTransitioning = false;
        });
      }
    }
  }

  Future<void> stopPlayback() async {
    final currentRequestId = ++playbackRequestId;

    if (mounted) {
      setState(() {
        isPlaybackTransitioning = true;
      });
    }

    await playbackService.stop();

    if (!mounted || currentRequestId != playbackRequestId) return;

    setState(() {
      playingCompositionId = null;
      isPlaybackTransitioning = false;
    });
  }

  Future<void> openNewComposition() async {
    await stopPlayback();

    if (!mounted) return;

    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    final savedCompositionId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => NewCompositionScreen(colors: colors)),
    );

    if (!mounted || savedCompositionId == null) return;

    showMessage('Composition saved.');
  }

  Future<void> openCompositionDetails(
    AppThemeColors colors,
    Composition composition,
  ) async {
    await stopPlayback();

    if (!mounted) return;

    final wasDeleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CompositionDetailsScreen(colors: colors, composition: composition),
      ),
    );

    if (!mounted || wasDeleted != true) return;

    showMessage('"${composition.title}" was deleted.');
  }

  Future<void> editComposition(
    AppThemeColors colors,
    Composition composition,
  ) async {
    await stopPlayback();

    if (!mounted) return;

    final savedCompositionId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            CompositionEditorScreen(colors: colors, composition: composition),
      ),
    );

    if (!mounted || savedCompositionId == null) return;

    showMessage('Composition updated.');
  }

  Future<void> deleteComposition(
    AppThemeColors colors,
    Composition composition,
  ) async {
    await stopPlayback();

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return DeleteCompositionDialog(
          colors: colors,
          compositionTitle: composition.title,
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      deletingCompositionIds.add(composition.id);
    });

    try {
      await compositionService.deleteComposition(composition.id);

      if (!mounted) return;

      showMessage('"${composition.title}" was deleted.');
    } catch (_) {
      if (mounted) {
        showMessage('The composition could not be deleted.');
      }
    } finally {
      if (mounted) {
        setState(() {
          deletingCompositionIds.remove(composition.id);
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
