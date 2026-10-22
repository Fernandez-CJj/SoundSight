import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../piano_calibration/models/piano_calibration_summary.dart';
import '../../piano_calibration/piano_calibration_screen.dart';
import '../../piano_calibration/services/piano_calibration_firestore_service.dart';
import '../../piano_calibration/models/saved_piano_calibration.dart';
import '../../piano_calibration/widgets/calibration_walkthrough_dialog.dart';
import 'models/ar_score_timeline.dart';
import 'services/ar_score_timeline_loader.dart';

/// Entry screen for choosing which saved keyboard calibration to use in AR.
///
/// [scoreDocumentPath] identifies a challenge, translated music sheet,
/// composition, or published-composition version containing the MIDI source.
/// The timeline is loaded only after the user chooses a calibration.
class ArPracticeScreen extends StatefulWidget {
  const ArPracticeScreen({
    super.key,
    required this.scoreDocumentPath,
    required this.colors,
  });

  /// Full Firestore document path of the score and its MIDI source.
  final String scoreDocumentPath;

  /// Active application palette supplied by the screen that opened AR.
  final AppThemeColors colors;

  @override
  /// Creates stream, loading, and navigation state for calibration selection.
  State<ArPracticeScreen> createState() {
    return ArPracticeScreenState();
  }
}

/// Watches saved calibrations and prepares the selected score/calibration pair.
class ArPracticeScreenState extends State<ArPracticeScreen> {
  final PianoCalibrationFirestoreService calibrationFirestoreService =
      PianoCalibrationFirestoreService();

  final ArScoreTimelineLoader scoreTimelineLoader = ArScoreTimelineLoader();

  late Stream<List<PianoCalibrationSummary>> calibrationSummaries;
  String? loadingCalibrationId;
  bool isOpeningNewCalibration = false;
  final Set<String> deletingCalibrationIds = <String>{};
  bool deletingCalibrationInProgress = false;
  bool deletingAllCalibrations = false;

  @override
  /// Starts the user's saved-calibration stream when the screen opens.
  void initState() {
    super.initState();
    loadCalibrationSummaries();
  }

  @override
  /// Builds the calibration picker and new-calibration action.
  Widget build(BuildContext context) {
    AppThemeColors colors = widget.colors;
    Color destructiveColor = colors.isDarkMode
        ? const Color(0xFFFF8A80)
        : const Color(0xFFB3261E);

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
          context.l10n.pianoSetupScreenTitle,
          style: const TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (deletingAllCalibrations)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primaryColor,
                ),
              ),
            )
          else
            IconButton(
              tooltip: context.l10n.deleteAllPianoSetupsTooltip,
              onPressed:
                  loadingCalibrationId != null ||
                      isOpeningNewCalibration ||
                      deletingCalibrationInProgress ||
                      deletingAllCalibrations
                  ? null
                  : deleteAllSavedCalibrations,
              color: destructiveColor,
              disabledColor: colors.secondaryTextColor,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            loadingCalibrationId == null &&
                !isOpeningNewCalibration &&
                !deletingCalibrationInProgress &&
                !deletingAllCalibrations
            ? openNewCalibration
            : null,
        backgroundColor: colors.primaryColor,
        foregroundColor: colors.backgroundColor,
        elevation: 0,
        icon: isOpeningNewCalibration
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.backgroundColor,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(
          isOpeningNewCalibration
              ? context.l10n.preparingSong
              : context.l10n.newPianoSetup,
          textAlign: TextAlign.center,
          softWrap: true,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                88,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildIntroduction(colors),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: buildCalibrationList(colors)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Labels the saved piano-setup list without taking space from its cards.
  Widget buildIntroduction(AppThemeColors colors) {
    return Text(
      context.l10n.choosePianoSetup,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.primaryColor,
        fontSize: AppTextSizes.sectionTitle,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  /// Builds loading, error, empty, or populated states from Firestore snapshots.
  Widget buildCalibrationList(AppThemeColors colors) {
    return StreamBuilder<List<PianoCalibrationSummary>>(
      stream: calibrationSummaries,
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildLoadingState(colors);
        }

        if (snapshot.hasError) {
          return buildLoadError(colors);
        }

        List<PianoCalibrationSummary> calibrations = (snapshot.data ?? [])
            .where(
              (calibration) =>
                  !deletingCalibrationIds.contains(calibration.documentId),
            )
            .toList(growable: false);

        if (calibrations.isEmpty) {
          return buildEmptyState(colors);
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          itemCount: calibrations.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (BuildContext context, int index) {
            return buildCalibrationCard(colors, calibrations[index]);
          },
        );
      },
    );
  }

  /// Builds one saved-calibration tile and its per-item loading indicator.
  Widget buildCalibrationCard(
    AppThemeColors colors,
    PianoCalibrationSummary calibration,
  ) {
    DateTime? lastSavedAt = calibration.updatedAt ?? calibration.createdAt;
    Color accentColor = colors.primaryColor;

    bool isLoading = loadingCalibrationId == calibration.documentId;
    bool loadingAnotherCalibration =
        isOpeningNewCalibration ||
        (loadingCalibrationId != null && !isLoading);

    bool deletionDisabled =
        loadingCalibrationId != null ||
        isOpeningNewCalibration ||
        deletingCalibrationInProgress ||
        deletingAllCalibrations;

    return Dismissible(
      key: ValueKey(calibration.documentId),
      direction: deletionDisabled
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) => confirmDeleteCalibration(calibration),
      onDismissed: (_) {
        dismissCalibration(calibration);
      },
      background: buildDeleteBackground(colors),
      child: Opacity(
        opacity: loadingAnotherCalibration || deletingAllCalibrations
            ? 0.55
            : 1,
        child: Material(
          color: colors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: colors.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                loadingCalibrationId == null &&
                    !isOpeningNewCalibration &&
                    !deletingAllCalibrations
                ? () {
                    openSavedCalibration(calibration);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.piano_rounded,
                      color: accentColor,
                      size: AppIconSizes.lg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calibration.name,
                          softWrap: true,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.body,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: colors.secondaryTextColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                buildLastSavedText(lastSavedAt),
                                softWrap: true,
                                style: TextStyle(
                                  color: colors.secondaryTextColor,
                                  fontSize: AppTextSizes.caption,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (isLoading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accentColor,
                      ),
                    )
                  else
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accentColor,
                        size: AppIconSizes.sm,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Matches the red swipe action used by other dismissible lists.
  Widget buildDeleteBackground(AppThemeColors colors) {
    Color destructiveColor = colors.isDarkMode
        ? const Color(0xFFFF8A80)
        : const Color(0xFFB3261E);

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: destructiveColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.l10n.delete,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Confirms permanent deletion of one saved keyboard calibration.
  Future<bool> confirmDeleteCalibration(
    PianoCalibrationSummary calibration,
  ) async {
    AppThemeColors colors = widget.colors;
    Color destructiveColor = colors.isDarkMode
        ? const Color(0xFFFF8A80)
        : const Color(0xFFB3261E);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              scrollable: true,
              backgroundColor: colors.surfaceColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: Text(
                context.l10n.deletePianoSetupQuestion,
                style: TextStyle(color: colors.primaryColor),
              ),
              content: Text(
                context.l10n.deletePianoSetupDescription(calibration.name),
                style: TextStyle(color: colors.secondaryTextColor),
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryColor,
                            side: BorderSide(color: colors.borderColor),
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(
                            context.l10n.cancel,
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: destructiveColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(
                            context.l10n.delete,
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
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

  /// Deletes a dismissed calibration and restores it when the write fails.
  Future<void> dismissCalibration(
    PianoCalibrationSummary calibration,
  ) async {
    setState(() {
      deletingCalibrationIds.add(calibration.documentId);
      deletingCalibrationInProgress = true;
    });

    try {
      await calibrationFirestoreService.deleteCalibration(
        documentId: calibration.documentId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pianoSetupDeleted(calibration.name))),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        deletingCalibrationIds.remove(calibration.documentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pianoSetupDeleteFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          deletingCalibrationInProgress = false;
        });
      }
    }
  }

  /// Confirms and permanently removes every saved calibration.
  Future<void> deleteAllSavedCalibrations() async {
    AppThemeColors colors = widget.colors;
    Color destructiveColor = colors.isDarkMode
        ? const Color(0xFFFF8A80)
        : const Color(0xFFB3261E);
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            context.l10n.deleteAllPianoSetupsQuestion,
            style: TextStyle(color: colors.primaryColor),
          ),
          content: Text(
            context.l10n.deleteAllPianoSetupsDescription,
            style: TextStyle(color: colors.secondaryTextColor),
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.borderColor),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        context.l10n.cancel,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: destructiveColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        context.l10n.deleteAll,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      deletingAllCalibrations = true;
    });

    try {
      await calibrationFirestoreService.deleteAllCalibrations();

      if (!mounted) return;

      setState(() {
        deletingCalibrationIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.allPianoSetupsDeleted)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.somePianoSetupsDeleteFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          deletingAllCalibrations = false;
        });
      }
    }
  }

  /// Explains how to create the user's first keyboard mapping.
  Widget buildEmptyState(AppThemeColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                Icons.piano_outlined,
                size: AppIconSizes.xl,
                color: colors.primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.noSavedPianoSetups,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.createPianoSetupDescription,
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

  /// Shows a themed progress state while saved mappings are being fetched.
  Widget buildLoadingState(AppThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primaryColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.loadingYourPianoSetups,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.label,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a retry action when the calibration stream reports an error.
  Widget buildLoadError(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppIconSizes.xl,
              color: colors.secondaryTextColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.pianoSetupsLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.checkConnectionThenTryAgain,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: retryLoadingCalibrations,
              icon: const Icon(Icons.refresh),
              label: Text(
                context.l10n.tryAgain,
                textAlign: TextAlign.center,
                softWrap: true,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a Firestore timestamp using the device's locale and time zone.
  String buildLastSavedText(DateTime? lastSavedAt) {
    if (lastSavedAt == null) {
      return context.l10n.savedPianoSetup;
    }

    DateTime localTime = lastSavedAt.toLocal();
    MaterialLocalizations localizations = MaterialLocalizations.of(context);
    String date = localizations.formatShortDate(localTime);
    String time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localTime),
    );

    return context.l10n.pianoSetupLastSaved(date, time);
  }

  /// Replaces [calibrationSummaries] with a fresh signed-in-user stream.
  void loadCalibrationSummaries() {
    calibrationSummaries = calibrationFirestoreService
        .watchCalibrationSummaries();
  }

  /// Rebuilds the stream after a loading failure.
  void retryLoadingCalibrations() {
    setState(loadCalibrationSummaries);
  }

  /// Loads full geometry and the score timeline before opening review/practice.
  ///
  /// A loading ID disables duplicate taps while both network operations run.
  Future<void> openSavedCalibration(PianoCalibrationSummary summary) async {
    if (loadingCalibrationId != null || isOpeningNewCalibration) {
      return;
    }

    setState(() {
      loadingCalibrationId = summary.documentId;
    });

    try {
      SavedPianoCalibration savedCalibration = await calibrationFirestoreService
          .loadCalibration(documentId: summary.documentId);

      ArScoreTimeline scoreTimeline = await scoreTimelineLoader.load(
        scoreDocumentPath: widget.scoreDocumentPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        loadingCalibrationId = null;
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return PianoCalibrationScreen(
              colors: widget.colors,
              savedCalibration: savedCalibration,
              scoreTimeline: scoreTimeline,
              scoreDocumentPath: widget.scoreDocumentPath,
            );
          },
        ),
      );
    } catch (error) {
      debugPrint('Calibration or score loading failed: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        loadingCalibrationId = null;
      });

      String errorMessage = error is ArScoreTimelineLoadException
          ? context.l10n.songPreparationForArFailed
          : context.l10n.selectedPianoSetupLoadFailed;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  /// Loads the current song before opening a new piano setup.
  Future<void> openNewCalibration() async {
    if (isOpeningNewCalibration || loadingCalibrationId != null) {
      return;
    }

    bool? shouldContinue = await showCalibrationPreparationDialog();

    if (shouldContinue != true || !mounted) {
      return;
    }

    setState(() {
      isOpeningNewCalibration = true;
    });

    try {
      ArScoreTimeline scoreTimeline = await scoreTimelineLoader.load(
        scoreDocumentPath: widget.scoreDocumentPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isOpeningNewCalibration = false;
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PianoCalibrationScreen(
            colors: widget.colors,
            scoreTimeline: scoreTimeline,
            scoreDocumentPath: widget.scoreDocumentPath,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Could not prepare a new piano setup: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        isOpeningNewCalibration = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.songPreparationForArFailed)),
      );
    }
  }

  Future<bool?> showCalibrationPreparationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CalibrationWalkthroughDialog(colors: widget.colors),
    );
  }

  @override
  /// Closes the timeline loader's owned HTTP client.
  void dispose() {
    scoreTimelineLoader.dispose();
    super.dispose();
  }
}
