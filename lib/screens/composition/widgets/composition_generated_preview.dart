import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_audio_preview.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionGeneratedPreview extends StatefulWidget {
  const CompositionGeneratedPreview({
    super.key,
    required this.colors,
    required this.title,
    required this.pdfStoragePath,
    required this.mp3StoragePath,
  });

  final AppThemeColors colors;
  final String title;
  final String pdfStoragePath;
  final String mp3StoragePath;

  @override
  State<CompositionGeneratedPreview> createState() =>
      _CompositionGeneratedPreviewState();
}

class _CompositionGeneratedPreviewState
    extends State<CompositionGeneratedPreview> {
  static const int maximumPdfSize = 20 * 1024 * 1024;

  late Future<Uint8List?> pdfFuture;

  @override
  void initState() {
    super.initState();
    pdfFuture = loadPdf();
  }

  @override
  void didUpdateWidget(covariant CompositionGeneratedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pdfStoragePath != widget.pdfStoragePath) {
      pdfFuture = loadPdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: colors.isDarkMode ? 0.16 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.preview_rounded,
                  color: colors.primaryColor,
                  size: AppIconSizes.md,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generated preview',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Review your sheet music and listen before publishing.',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          buildSheetMusicPreview(),
          const Gap(AppSpacing.md),
          MusicSheetAudioPreview(
            colors: colors,
            storagePath: widget.mp3StoragePath,
            title: 'Composition playback',
            loadingText: 'Loading your composition...',
            playingText: 'Playing your composition',
            idleText: 'Listen to the generated composition',
          ),
        ],
      ),
    );
  }

  Widget buildSheetMusicPreview() {
    final colors = widget.colors;
    final previewHeight = (MediaQuery.sizeOf(context).height * 0.55).clamp(
      360.0,
      580.0,
    ).toDouble();

    return FutureBuilder<Uint8List?>(
      future: pdfFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: previewHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.borderColor),
            ),
            child: CircularProgressIndicator(color: colors.primaryColor),
          );
        }

        final pdfBytes = snapshot.data;

        if (snapshot.hasError || pdfBytes == null || pdfBytes.isEmpty) {
          return buildLoadError(previewHeight);
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sheet music',
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    openFullScreenPreview(pdfBytes);
                  },
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('Full screen'),
                ),
              ],
            ),
            const Gap(AppSpacing.xs),
            Container(
              height: previewHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: PdfViewer.data(
                pdfBytes,
                sourceName: widget.title,
                params: PdfViewerParams(
                  margin: AppSpacing.sm,
                  backgroundColor: colors.backgroundColor,
                  sizeDelegateProvider:
                      const PdfViewerSizeDelegateProviderSmart(
                        smartMaxScale: 2,
                        maxPagesVisible: 1,
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildLoadError(double height) {
    final colors = widget.colors;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            color: colors.secondaryTextColor,
            size: AppIconSizes.xl,
          ),
          const Gap(AppSpacing.md),
          Text(
            'The sheet music could not be loaded.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Check your connection, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
          const Gap(AppSpacing.md),
          OutlinedButton.icon(
            onPressed: retryLoading,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> loadPdf() {
    if (widget.pdfStoragePath.isEmpty) {
      return Future.value(null);
    }

    return FirebaseStorage.instance
        .ref(widget.pdfStoragePath)
        .getData(maximumPdfSize);
  }

  void retryLoading() {
    setState(() {
      pdfFuture = loadPdf();
    });
  }

  void openFullScreenPreview(Uint8List pdfBytes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CompositionPdfPreviewScreen(
          colors: widget.colors,
          title: widget.title,
          pdfBytes: pdfBytes,
        ),
      ),
    );
  }
}

class _CompositionPdfPreviewScreen extends StatelessWidget {
  const _CompositionPdfPreviewScreen({
    required this.colors,
    required this.title,
    required this.pdfBytes,
  });

  final AppThemeColors colors;
  final String title;
  final Uint8List pdfBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: PdfViewer.data(
            pdfBytes,
            sourceName: title,
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
      ),
    );
  }
}
