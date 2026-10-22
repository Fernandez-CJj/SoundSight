import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/widgets/composition_card.dart';
import 'package:soundsight/screens/composition/screens/composition_details_screen.dart';
import 'package:soundsight/screens/composition/dialogs/composition_dialogs.dart';
import 'package:soundsight/screens/composition/services/composition_generation_service.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';
import 'package:soundsight/screens/composition/screens/new_composition_screen.dart';
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
  final CompositionGenerationService generationService =
      CompositionGenerationService();

  final Set<String> deletingCompositionIds = {};
  final Set<String> generatingCompositionIds = {};

  late bool isDarkMode;
  late final String? userId;

  Stream<List<Composition>>? compositionsStream;

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
        title: Text(
          context.l10n.myCompositions,
          style: const TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.newComposition,
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
          isGeneratingFiles: generatingCompositionIds.contains(
            composition.id,
          ),
          onOpen: () {
            openCompositionDetails(colors, composition);
          },
          onRetryGeneration: () {
            retryCompositionGeneration(composition);
          },
          onDelete: () => deleteComposition(colors, composition),
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
                    context.l10n.yourPianoPieces,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.screenTitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  Text(
                    context.l10n.compositionsDescription,
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
            label: Text(
              context.l10n.newComposition,
              style: const TextStyle(fontWeight: FontWeight.w700),
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
              context.l10n.noCompositions,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.sm),
            Text(
              context.l10n.noCompositionsDescription,
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
              label: Text(context.l10n.newComposition),
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
              context.l10n.compositionsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              context.l10n.musicSheetsLoadErrorHelp,
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
        context.l10n.signInForCompositions,
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

  Future<void> openNewComposition() async {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    final savedCompositionId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => NewCompositionScreen(colors: colors)),
    );

    if (!mounted || savedCompositionId == null) return;

    try {
      final savedComposition = await compositionService.getComposition(
        userId!,
        savedCompositionId,
      );

      if (!mounted) return;

      if (savedComposition?.generatedFilesAreCurrent == true) {
        showMessage(context.l10n.compositionSavedFilesReady);
      } else {
        showMessage(context.l10n.compositionSavedFilesPending);
      }
    } catch (_) {
      if (mounted) {
        showMessage(context.l10n.compositionSaved);
      }
    }
  }

  Future<void> openCompositionDetails(
    AppThemeColors colors,
    Composition composition,
  ) async {
    final wasDeleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CompositionDetailsScreen(colors: colors, composition: composition),
      ),
    );

    if (!mounted || wasDeleted != true) return;

    showMessage(context.l10n.compositionDeleted(composition.title));
  }

  Future<void> retryCompositionGeneration(Composition composition) async {
    if (generatingCompositionIds.contains(composition.id)) {
      return;
    }

    setState(() {
      generatingCompositionIds.add(composition.id);
    });

    try {
      await generationService.generateCompositionFiles(composition);

      if (!mounted) return;

      showMessage(context.l10n.compositionMusicFilesReady);
    } catch (_) {
      if (!mounted) return;

      showMessage(context.l10n.compositionMusicFilesFailed);
    } finally {
      if (mounted) {
        setState(() {
          generatingCompositionIds.remove(composition.id);
        });
      }
    }
  }

  Future<void> deleteComposition(
    AppThemeColors colors,
    Composition composition,
  ) async {
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
      await compositionService.deleteComposition(
        composition.ownerId,
        composition.id,
      );

      if (!mounted) return;

      showMessage(context.l10n.compositionDeleted(composition.title));
    } catch (_) {
      if (mounted) {
        showMessage(context.l10n.compositionDeleteFailed);
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
