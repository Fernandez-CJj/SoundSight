import 'package:soundsight/screens/onboarding/widgets/screen_feature_tour.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:gap/gap.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/controllers/published_composition_playback_controller.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';
import 'package:soundsight/screens/composition/screens/published_composition_comments_screen.dart';
import 'package:soundsight/screens/composition/widgets/published_composition_social_actions.dart';
import 'package:soundsight/screens/players/ar/screens/ar_practice_screen.dart';
import 'package:soundsight/screens/players/sight_reading/screens/music_sheet_reading_screen.dart';
import 'package:soundsight/screens/players/synthesia/screens/synthesia_screen.dart';
import 'package:soundsight/screens/players/synthesia/models/synthesia_score_source.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class PublishedCompositionViewerScreen extends StatefulWidget {
  const PublishedCompositionViewerScreen({
    super.key,
    required this.colors,
    required this.composition,
  });

  final AppThemeColors colors;
  final PublishedComposition composition;

  @override
  State<PublishedCompositionViewerScreen> createState() =>
      _PublishedCompositionViewerScreenState();
}

class _PublishedCompositionViewerScreenState
    extends State<PublishedCompositionViewerScreen> {
  final PublishedCompositionService compositionService =
      PublishedCompositionService();
  final PublishedCompositionPlaybackController playbackController =
      PublishedCompositionPlaybackController();

  late Future<Uint8List?> pdfFuture;
  bool _tourPdfPending = true;

  @override
  void initState() {
    super.initState();
    pdfFuture = compositionService.loadPdf(widget.composition.pdfStoragePath);
    playbackController.addListener(updatePlaybackState);
  }

  @override
  void dispose() {
    playbackController.removeListener(updatePlaybackState);
    playbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return ScreenFeatureTour(featureId: 'published_details', key: ValueKey('published_details'), colors: widget.colors, canStart: () => !playbackController.isBusy && playbackController.playingVersionId == null && !_tourPdfPending, child: Scaffold(
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
          widget.composition.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderColor),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: playbackController.isPlaying(widget.composition)
                    ? context.l10n.stopPlaybackTooltip
                    : context.l10n.playCompositionTooltip,
                onPressed: playbackController.isBusy ? null : playComposition,
                icon: playbackController.isBusy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primaryColor,
                        ),
                      )
                    : Icon(
                        playbackController.isPlaying(widget.composition)
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: AppIconSizes.md,
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          child: FeatureTourTarget(id: 'practice', child: FloatingActionButton.extended(
            onPressed: showPlayModeDialog,
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.backgroundColor,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.l10n.play),
          )),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.4,
                  ),
                  child: SingleChildScrollView(child: buildInformationHeader()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: FeatureTourTarget(id: 'social', child: PublishedCompositionSocialActions(
                    key: ValueKey(
                      '${widget.composition.id}/${widget.composition.currentVersion}',
                    ),
                    colors: colors,
                    composition: widget.composition,
                    onComments: openComments,
                  )),
                ),
                Expanded(child: buildPdfViewer()),
              ],
            );
          },
        ),
      ),
    ));
  }

  Future<void> showPlayModeDialog() async {
    final selectedMode = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: widget.colors.surfaceColor,
          title: Text(
            context.l10n.choosePlayMode,
            style: TextStyle(color: widget.colors.primaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.music_note_rounded,
                  color: widget.colors.primaryColor,
                ),
                title: Text(
                  context.l10n.sightReading,
                  style: TextStyle(color: widget.colors.primaryColor),
                ),
                onTap: () => Navigator.of(dialogContext).pop('sightReading'),
              ),
              ListTile(
                leading: Icon(
                  Icons.piano_rounded,
                  color: widget.colors.primaryColor,
                ),
                title: Text(
                  context.l10n.synthesia,
                  style: TextStyle(color: widget.colors.primaryColor),
                ),
                onTap: () => Navigator.of(dialogContext).pop('synthesia'),
              ),
              ListTile(
                leading: Icon(
                  Icons.view_in_ar_rounded,
                  color: widget.colors.primaryColor,
                ),
                title: Text(
                  context.l10n.arPractice,
                  style: TextStyle(color: widget.colors.primaryColor),
                ),
                onTap: () => Navigator.of(dialogContext).pop('ar'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (selectedMode == 'sightReading') {
      if (!widget.composition.hasSightReadingFiles) {
        showMessage(
          context.l10n.publishedSightReadingUnavailable,
          type: AppSnackBarType.warning,
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MusicSheetReadingScreen(
            scoreDocumentPath:
                'compositionPosts/${widget.composition.id}/versions/${widget.composition.currentVersion}',
            source: SightReadingSource.composition,
            colors: widget.colors,
          ),
        ),
      );
      return;
    }

    if (selectedMode == 'synthesia') {
      await playbackController.playbackService.stop();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SynthesiaScreen(
            colors: widget.colors,
            source: SynthesiaPublishedCompositionSource(widget.composition),
          ),
        ),
      );
      return;
    }

    if (selectedMode == 'ar') {
      if (widget.composition.publishedFilesVersion != 1 ||
          widget.composition.midiStoragePath.trim().isEmpty) {
        showMessage(
          context.l10n.publishedArFileUnavailable,
          type: AppSnackBarType.warning,
        );
        return;
      }

      await playbackController.playbackService.stop();
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArPracticeScreen(
            colors: widget.colors,
            scoreDocumentPath:
                'compositionPosts/${widget.composition.id}/versions/${widget.composition.currentVersion}',
          ),
        ),
      );
    }
  }

  Widget buildInformationHeader() {
    final colors = widget.colors;
    final composition = widget.composition;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return FeatureTourTarget(id: 'details', child: Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildCompositionIdentity(),
          const Gap(AppSpacing.sm),
          ExpansionTile(
            initiallyExpanded: !isLandscape,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
            iconColor: colors.primaryColor,
            collapsedIconColor: colors.primaryColor,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              context.l10n.compositionDetails,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.label,
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    buildInformationChip(
                      Icons.history_rounded,
                      context.l10n.versionLabel(composition.currentVersion),
                    ),
                    buildInformationChip(
                      Icons.music_note_rounded,
                      composition.keySignature,
                    ),
                    buildInformationChip(
                      Icons.speed_rounded,
                      '${composition.tempo} BPM',
                    ),
                    buildInformationChip(
                      Icons.music_note_outlined,
                      '${composition.beatsPerMeasure}/${composition.beatUnit}',
                    ),
                    buildInformationChip(
                      Icons.grid_view_rounded,
                      context.l10n.compositionMeasureCount(composition.measureCount),
                    ),
                    buildInformationChip(
                      Icons.notes_rounded,
                      context.l10n.compositionNoteCount(composition.noteCount),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget buildCompositionIdentity() {
    final colors = widget.colors;
    final composition = widget.composition;
    final publishedAt = composition.publishedAt;
    final publishedDate = publishedAt == null
        ? context.l10n.recentlyPublished
        : context.l10n.publishedOn(
            MaterialLocalizations.of(context).formatFullDate(publishedAt.toLocal()),
          );
    final placeholder = Icon(
      Icons.person_rounded,
      color: colors.primaryColor,
      size: AppIconSizes.lg,
    );

    return FeatureTourTarget(id: 'identity', child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: composition.authorProfileImageUrl.isEmpty
              ? placeholder
              : Image.network(
                  composition.authorProfileImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
        const Gap(AppSpacing.sm),
        Text(
          composition.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(AppSpacing.xs),
        Text(
          context.l10n.publishedBy(composition.authorName),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(AppSpacing.xs),
        Text(
          publishedDate,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.secondaryTextColor,
            fontSize: AppTextSizes.caption,
          ),
        ),
      ],
    ));
  }

  Widget buildInformationChip(IconData icon, String text) {
    final colors = widget.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.secondaryTextColor, size: AppIconSizes.sm),
          const Gap(AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openComments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishedCompositionCommentsScreen(
          colors: widget.colors,
          composition: widget.composition,
        ),
      ),
    );
  }

  Widget buildPdfViewer() {
    final colors = widget.colors;

    return FutureBuilder<Uint8List?>(
      future: pdfFuture,
      builder: (context, snapshot) {
        _tourPdfPending = snapshot.connectionState == ConnectionState.waiting;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colors.primaryColor),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return buildLoadError();
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildPdfDocument(snapshot.data!),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Material(
                    color: colors.surfaceColor.withValues(alpha: 0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(color: colors.borderColor),
                    ),
                    child: FeatureTourTarget(id: 'preview', child: IconButton(
                      tooltip: context.l10n.fullScreen,
                      onPressed: () => showPdfDialog(snapshot.data!),
                      icon: Icon(
                        Icons.open_in_full_rounded,
                        color: colors.primaryColor,
                        size: 20,
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPdfDocument(Uint8List pdfBytes) {
    return PdfViewer.data(
      pdfBytes,
      sourceName: widget.composition.title,
      params: PdfViewerParams(
        margin: AppSpacing.sm,
        backgroundColor: widget.colors.backgroundColor,
        sizeDelegateProvider: const PdfViewerSizeDelegateProviderSmart(
          smartMaxScale: 2,
          maxPagesVisible: 1,
        ),
      ),
    );
  }

  Future<void> showPdfDialog(Uint8List pdfBytes) {
    final colors = widget.colors;
    final screenSize = MediaQuery.sizeOf(context);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: colors.surfaceColor,
        insetPadding: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: SizedBox(
          width: double.infinity,
          height: screenSize.height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.composition.title,
                        maxLines: 2,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.close,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: buildPdfDocument(pdfBytes),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoadError() {
    final colors = widget.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              color: colors.secondaryTextColor,
              size: AppIconSizes.xl,
            ),
            const Gap(AppSpacing.md),
            Text(
              context.l10n.publishedSheetLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              context.l10n.checkConnectionStoragePermissions,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
              ),
            ),
            const Gap(AppSpacing.md),
            OutlinedButton.icon(
              onPressed: retryLoading,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.tryAgain),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
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

  void retryLoading() {
    setState(() {
      pdfFuture = compositionService.loadPdf(widget.composition.pdfStoragePath);
    });
  }

  Future<void> playComposition() async {
    final resultMessage = await playbackController.togglePlayback(
      widget.composition,
      onPlaybackStarted: () {
        showMessage(context.l10n.communityPlaying(widget.composition.title));
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

    ScaffoldMessenger.of(context)
      .showLatestSnackBar(
        appSnackBar(colors: widget.colors, message: message, type: type),
      );
  }
}
