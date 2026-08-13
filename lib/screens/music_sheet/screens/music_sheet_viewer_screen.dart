import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/music_sheet/dialogs/music_sheet_omr_dialogs.dart';
import 'package:soundsight/screens/music_sheet/models/omr_conversion_result.dart';
import 'package:soundsight/screens/music_sheet/services/music_sheet_omr_service.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_audio_preview.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_omr_status_card.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import '../../ar_practice/screens/keyboard_setup/keyboard_setup_screen.dart';

class MusicSheetViewerScreen extends StatefulWidget {
  const MusicSheetViewerScreen({
    super.key,
    required this.colors,
    required this.sheetId,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.files,
  });

  final AppThemeColors colors;
  final String sheetId;
  final String ownerId;
  final String title;
  final String type;
  final List<Map<String, dynamic>> files;

  @override
  State<MusicSheetViewerScreen> createState() => _MusicSheetViewerScreenState();
}

class _MusicSheetViewerScreenState extends State<MusicSheetViewerScreen> {
  static const int maxImageFileSize = 5 * 1024 * 1024;
  static const int maxPdfFileSize = 20 * 1024 * 1024;

  late final List<Map<String, dynamic>> files;
  final Map<String, Future<Uint8List?>> imageFutures = {};
  final MusicSheetOmrService omrService = MusicSheetOmrService();
  Future<Uint8List?>? pdfFuture;
  bool isConverting = false;

  @override
  void initState() {
    super.initState();
    files = List<Map<String, dynamic>>.from(widget.files);
    files.sort((first, second) {
      final firstPage = (first['pageNumber'] as num?)?.toInt() ?? 0;
      final secondPage = (second['pageNumber'] as num?)?.toInt() ?? 0;
      return firstPage.compareTo(secondPage);
    });

    if (widget.type == 'pdf' && files.isNotEmpty) {
      pdfFuture = loadFile(files.first['storagePath'], maxPdfFileSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

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
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppTextSizes.sectionTitle,
          ),
        ),
      ),
      bottomNavigationBar: files.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  border: Border(top: BorderSide(color: colors.borderColor)),
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: showArConfirmation,
                    icon: Icon(Icons.view_in_ar_rounded, size: AppIconSizes.md),
                    label: Text(
                      'Play with AR',
                      style: TextStyle(
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w700,
                      ),
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
              ),
            ),
      body: files.isEmpty ? buildEmptyState() : buildViewerBody(),
    );
  }

  Widget buildViewerBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final sheetViewer = widget.type == 'pdf'
            ? buildPdfViewer()
            : buildImageViewer();

        if (isLandscape) {
          final sidePanelWidth = (constraints.maxWidth * 0.36)
              .clamp(280.0, 360.0)
              .toDouble();

          return Row(
            children: [
              SizedBox(
                width: sidePanelWidth,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: buildOmrSection(),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: widget.colors.borderColor,
              ),
              Expanded(child: sheetViewer),
            ],
          );
        }

        return Column(
          children: [
            buildOmrSection(),
            Expanded(child: sheetViewer),
          ],
        );
      },
    );
  }

  Widget buildOmrSection() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('musicSheets')
          .doc(widget.sheetId)
          .snapshots(),
      builder: (context, snapshot) {
        final sheetData = snapshot.data?.data() ?? {};
        final status = sheetData['omrStatus'] as String? ?? 'notStarted';
        final partCount = (sheetData['omrPartCount'] as num?)?.toInt() ?? 0;
        final noteCount = (sheetData['omrNoteCount'] as num?)?.toInt() ?? 0;
        final previewAudioStoragePath =
            sheetData['previewAudioStoragePath'] as String? ?? '';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: MusicSheetOmrStatusCard(
                colors: widget.colors,
                status: status,
                partCount: partCount,
                noteCount: noteCount,
                isConverting: isConverting,
                onRecognize: () =>
                    recognizeMusicSheet(isReconversion: status == 'completed'),
              ),
            ),
            if (status != 'processing' && previewAudioStoragePath.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: MusicSheetAudioPreview(
                  colors: widget.colors,
                  storagePath: previewAudioStoragePath,
                ),
              ),
          ],
        );
      },
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
          return buildLoadError(() {
            setState(() {
              pdfFuture = loadFile(files.first['storagePath'], maxPdfFileSize);
            });
          });
        }

        return Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: PdfViewer.data(snapshot.data!, sourceName: widget.title),
          ),
        );
      },
    );
  }

  Widget buildImageViewer() {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: files.length,
      separatorBuilder: (context, index) => Gap(AppSpacing.md),
      itemBuilder: (context, index) {
        return buildImagePage(files[index], index);
      },
    );
  }

  Widget buildImagePage(Map<String, dynamic> file, int index) {
    final colors = widget.colors;
    final storagePath = file['storagePath'] as String? ?? '';
    final pageNumber = (file['pageNumber'] as num?)?.toInt() ?? index + 1;
    final future = imageFutures.putIfAbsent(
      storagePath,
      () => loadFile(storagePath, maxImageFileSize),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Page $pageNumber',
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(AppSpacing.sm),
        Container(
          height: MediaQuery.sizeOf(context).height * 0.62,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder<Uint8List?>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colors.primaryColor),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return buildLoadError(() {
                  setState(() {
                    imageFutures.remove(storagePath);
                  });
                });
              }

              return InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState() {
    final colors = widget.colors;

    return Center(
      child: Text(
        'This music sheet does not contain any files.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.secondaryTextColor),
      ),
    );
  }

  Widget buildLoadError(VoidCallback onRetry) {
    final colors = widget.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: colors.secondaryTextColor,
              size: 42,
            ),
            Gap(AppSpacing.sm),
            Text(
              'The file could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryTextColor),
            ),
            Gap(AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> loadFile(dynamic storagePath, int maxSize) {
    final path = storagePath is String ? storagePath : '';
    if (path.isEmpty) return Future.value(null);
    return FirebaseStorage.instance
        .ref(path)
        .getData(maxSize)
        .timeout(const Duration(minutes: 1));
  }

  Future<void> recognizeMusicSheet({bool isReconversion = false}) async {
    if (isConverting) return;

    final shouldRecognize = await showDialog<bool>(
      context: context,
      builder: (_) => RecognizeMusicSheetDialog(
        colors: widget.colors,
        title: widget.title,
        isReconversion: isReconversion,
      ),
    );

    if (shouldRecognize != true || !mounted) return;

    setState(() {
      isConverting = true;
    });

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MusicSheetOmrLoadingDialog(colors: widget.colors),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));

    OmrConversionResult? result;
    Object? conversionError;

    try {
      result = await omrService.recognizeMusicSheet(
        sheetId: widget.sheetId,
        ownerId: widget.ownerId,
      );
    } catch (error) {
      conversionError = error;
    }

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    setState(() {
      isConverting = false;
    });

    if (result != null) {
      await showDialog<void>(
        context: context,
        builder: (_) =>
            MusicSheetOmrSuccessDialog(colors: widget.colors, result: result!),
      );
      return;
    }

    final errorMessage = conversionError.toString().replaceFirst(
      'Exception: ',
      '',
    );

    await showDialog<void>(
      context: context,
      builder: (_) => MusicSheetOmrErrorDialog(
        colors: widget.colors,
        message: errorMessage.isEmpty
            ? 'The music sheet could not be translated.'
            : errorMessage,
      ),
    );
  }

  Future<void> showArConfirmation() async {
    final colors = widget.colors;

    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.view_in_ar_rounded,
              color: colors.backgroundColor,
              size: AppIconSizes.lg,
            ),
          ),
          title: Text(
            'Open AR note guide?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will align note overlays with the keys on your physical '
            'piano. No music sheet translation is required.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.body,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(
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
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                Gap(AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('Start'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldStart != true || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const KeyboardSetupScreen();
        },
      ),
    );
  }
}
