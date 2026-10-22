import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/controllers/published_composition_playback_controller.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';
import 'package:soundsight/screens/players/ar/ar_practice_screen.dart';
import 'package:soundsight/screens/players/sight_reading/music_sheet_reading_screen.dart';
import 'package:soundsight/screens/players/synthesia/synthesia_screen.dart';
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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

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
          child: FloatingActionButton.extended(
            onPressed: showPlayModeDialog,
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.backgroundColor,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.l10n.play),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Column(
          children: [
            if (!isLandscape) buildInformationHeader(),
            Expanded(child: buildPdfViewer()),
          ],
        ),
      ),
    );
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

    return Container(
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
      child: Row(
        children: [
          Icon(
            Icons.music_note_rounded,
            color: colors.primaryColor,
            size: AppIconSizes.sm,
          ),
          const Gap(AppSpacing.xs),
          Expanded(
            child: Text(
              widget.composition.keySignature,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            context.l10n.versionLabel(widget.composition.currentVersion),
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            '${widget.composition.tempo} BPM',
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            '${widget.composition.beatsPerMeasure}/'
            '${widget.composition.beatUnit}',
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPdfViewer() {
    final colors = widget.colors;

    return FutureBuilder<Uint8List?>(
      future: pdfFuture,
      builder: (context, snapshot) {
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
            child: PdfViewer.data(
              snapshot.data!,
              sourceName: widget.composition.title,
              params: PdfViewerParams(
                margin: AppSpacing.sm,
                backgroundColor: colors.backgroundColor,
                sizeDelegateProvider: const PdfViewerSizeDelegateProviderSmart(
                  smartMaxScale: 2,
                  maxPagesVisible: 1,
                ),
              ),
            ),
          ),
        );
      },
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

    showMessage(localizedMessage);
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
