import 'package:soundsight/services/processing_job_service.dart';
import 'package:soundsight/widgets/processing_job_card.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:gap/gap.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/music_sheet/dialogs/music_sheet_omr_dialogs.dart';
import 'package:soundsight/screens/music_sheet/services/music_sheet_omr_service.dart';
import 'package:soundsight/screens/music_sheet/services/music_sheet_transcription_service.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_audio_preview.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_omr_status_card.dart';
import 'package:soundsight/screens/players/ar/ar_practice_screen.dart';
import 'package:soundsight/screens/players/sight_reading/music_sheet_reading_screen.dart';
import 'package:soundsight/screens/players/synthesia/synthesia_screen.dart';
import 'package:soundsight/screens/players/synthesia/models/synthesia_score_source.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

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
  late final DocumentReference<Map<String, dynamic>> sheetReference;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sheetSubscription;
  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> sheetSnapshot =
      const AsyncSnapshot.waiting();
  StreamSubscription<void>? jobStateSubscription;
  final Map<String, Future<Uint8List?>> imageFutures = {};
  final MusicSheetOmrService omrService = MusicSheetOmrService();
  final MusicSheetTranscriptionService transcriptionService =
      MusicSheetTranscriptionService();
  final MusicSheetAudioPreviewController audioPreviewController =
      MusicSheetAudioPreviewController();
  Future<Uint8List?>? pdfFuture;
  Future<Uint8List?>? recognizedPdfFuture;
  String? recognizedPdfCacheKey;
  bool isConverting = false;
  String? submissionError;
  bool canSubmitConversion = false;
  bool showRecognizedPdf = true;
  Timer? transcriptionStatusTimer;

  @override
  void initState() {
    super.initState();
    sheetReference = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.ownerId)
        .collection('musicSheets')
        .doc(widget.sheetId);
    sheetSubscription = sheetReference
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(() {
              sheetSnapshot = AsyncSnapshot.withData(
                ConnectionState.active,
                snapshot,
              );
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) return;
            setState(() {
              sheetSnapshot = sheetSnapshot.hasData
                  ? sheetSnapshot.inState(ConnectionState.none)
                  : AsyncSnapshot.withError(
                      ConnectionState.none,
                      error,
                      stackTrace,
                    );
            });
          },
        );
    jobStateSubscription = ProcessingJobService.changes.listen((_) {
      if (mounted) setState(() {});
    });
    files = List<Map<String, dynamic>>.from(widget.files);
    if (widget.type == 'audio') {
      transcriptionStatusTimer = Timer.periodic(const Duration(minutes: 1), (
        _,
      ) {
        if (mounted) setState(() {});
      });
    }
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
  void dispose() {
    sheetSubscription?.cancel();
    jobStateSubscription?.cancel();
    transcriptionStatusTimer?.cancel();
    super.dispose();
  }

  String get submissionPath =>
      '/music-sheets/${Uri.encodeComponent(widget.sheetId)}/'
      '${widget.type == 'audio' ? 'transcribe-audio' : 'recognize'}';

  bool get submissionBusy =>
      isConverting ||
      ProcessingJobService.isBusy(widget.ownerId, submissionPath);

  Map<String, dynamic> currentSheetData() {
    final snapshot = sheetSnapshot;
    final document = snapshot.data;
    final data = document?.data() ?? <String, dynamic>{};
    final status =
        data[widget.type == 'audio' ? 'transcriptionStatus' : 'omrStatus'];
    // A newly opened route may first receive an old cached document. Do not
    // offer another conversion until Firebase confirms the current lock.
    canSubmitConversion =
        document != null &&
        document.exists &&
        snapshot.connectionState == ConnectionState.active &&
        !snapshot.hasError &&
        !document.metadata.isFromCache &&
        !submissionBusy &&
        data['activeJobId'] == null &&
        status != 'queued' &&
        status != 'processing' &&
        data['lastJobStatus'] != 'queued' &&
        data['lastJobStatus'] != 'processing';
    final job = ProcessingJobService.activeJob(widget.ownerId, submissionPath);
    if (job == null) {
      if (submissionBusy && data['activeJobId'] == null) {
        return {...data, 'lastJobStatus': 'submitting'};
      }
      if (submissionError != null &&
          data['activeJobId'] == null &&
          status != 'queued' &&
          status != 'processing') {
        return {...data, 'lastJobStatus': 'submissionFailed'};
      }
      return data;
    }
    return {
      ...data,
      'activeJobId': job.id,
      'lastJobStatus': job.status,
      if (widget.type == 'audio')
        'transcriptionStatus': job.status
      else
        'omrStatus': job.status,
    };
  }

  Widget buildSheetLoadingState(bool hasError) => Center(
    child: hasError
        ? Text(
            context.l10n.musicSheetsLoadError,
            style: TextStyle(color: widget.colors.secondaryTextColor),
          )
        : CircularProgressIndicator(color: widget.colors.primaryColor),
  );

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final sheetData = currentSheetData();

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: buildPlayButton(colors),
      body: buildSheetBody(sheetData),
    );
  }

  Widget buildSheetBody(Map<String, dynamic> sheetData) {
    if (!sheetSnapshot.hasData) {
      return buildSheetLoadingState(sheetSnapshot.hasError);
    }
    if (widget.type == 'audio') return buildSavedAudioViewer(sheetData);
    final recognizedPdfStoragePath =
        sheetData['recognizedPdfStoragePath'] as String? ?? '';
    if (files.isEmpty && recognizedPdfStoragePath.isEmpty) {
      return buildEmptyState();
    }
    return buildViewerBody(sheetData);
  }

  Widget buildPlayButton(AppThemeColors colors) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: SizedBox(
      width: double.infinity,
      child: FloatingActionButton.extended(
        onPressed: showPlayModeDialog,
        backgroundColor: colors.primaryColor,
        foregroundColor: colors.backgroundColor,
        label: Text(context.l10n.play),
      ),
    ),
  );

  bool hasPlayableAudioScore(Map<String, dynamic>? sheetData) =>
      sheetData?['transcriptionStatus'] == 'completed' &&
      (sheetData?['midiStoragePath'] as String? ?? '').isNotEmpty &&
      (sheetData?['musicXmlStoragePath'] as String? ?? '').isNotEmpty &&
      (sheetData?['recognizedPdfStoragePath'] as String? ?? '').isNotEmpty &&
      (sheetData?['previewAudioStoragePath'] as String? ?? '').isNotEmpty;

  bool hasConvertedScore(Map<String, dynamic>? sheetData) =>
      widget.type == 'audio'
      ? hasPlayableAudioScore(sheetData)
      : sheetData?['omrStatus'] == 'completed';

  Widget buildSavedAudioViewer(Map<String, dynamic> sheetData) {
    final storagePath = files.isEmpty
        ? ''
        : (files.first['storagePath'] as String? ?? '');
    if (storagePath.isEmpty) return buildEmptyState();
    final hasScore = hasPlayableAudioScore(sheetData);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProcessingJobCard(
              colors: widget.colors,
              status: sheetData['lastJobStatus'] as String?,
              errorMessage: sheetData['lastJobStatus'] == 'submissionFailed'
                  ? submissionError
                  : null,
              jobId: sheetData['activeJobId'] as String?,
              onRetry: canSubmitConversion
                  ? () => transcribeAudio(
                      isReconversion: hasPlayableAudioScore(sheetData),
                    )
                  : null,
            ),
            buildAudioTranscriptionCard(sheetData),
            Gap(AppSpacing.md),
            MusicSheetAudioPreview(
              colors: widget.colors,
              storagePath: storagePath,
              streamFromStorage: true,
              title: context.l10n.audioFileType,
              controller: audioPreviewController,
            ),
            Gap(AppSpacing.md),
            if (hasScore)
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                child: buildRecognizedPdfViewer(
                  sheetData['recognizedPdfStoragePath'] as String,
                  sheetData['transcriptionProcessedAt'],
                ),
              )
            else
              Text(
                context.l10n.audioNoScoreYet,
                style: TextStyle(color: widget.colors.secondaryTextColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildAudioTranscriptionCard(Map<String, dynamic> sheetData) {
    if (submissionBusy ||
        sheetData['lastJobStatus'] == 'submissionFailed' ||
        sheetData['activeJobId'] != null ||
        sheetData['lastJobStatus'] == 'submitting' ||
        sheetData['lastJobStatus'] == 'queued' ||
        sheetData['lastJobStatus'] == 'processing') {
      return const SizedBox.shrink();
    }
    final storedStatus = sheetData['transcriptionStatus'] as String? ?? '';
    final status = storedStatus;
    final l10n = context.l10n;
    final title = switch (status) {
      'completed' => l10n.audioMidiReady,
      'processing' => l10n.audioMidiProcessing,
      'failed' => l10n.audioMidiFailed,
      _ => l10n.audioConvertToMidi,
    };
    final description = switch (status) {
      'completed' => l10n.audioMidiReadyDescription,
      'processing' => l10n.audioMidiLoadingDescription,
      'failed' => l10n.audioMidiFailedDescription,
      _ => l10n.audioMidiStartDescription,
    };

    return MusicSheetOmrStatusCard(
      colors: widget.colors,
      status: status,
      partCount: 0,
      noteCount: (sheetData['transcriptionNoteCount'] as num?)?.toInt() ?? 0,
      isConverting: submissionBusy,
      showAction: canSubmitConversion,
      onRecognize: () => transcribeAudio(isReconversion: status == 'completed'),
      titleOverride: title,
      subtitleOverride: description,
      buttonLabelOverride: status == 'completed'
          ? l10n.reconvert
          : status == 'failed'
          ? l10n.retry
          : l10n.translate,
      initialIcon: Icons.music_note_outlined,
    );
  }

  Future<void> transcribeAudio({bool isReconversion = false}) async {
    if (submissionBusy || !canSubmitConversion) return;
    final shouldConvert = await showDialog<bool>(
      context: context,
      builder: (_) => RecognizeMusicSheetDialog(
        colors: widget.colors,
        title: widget.title,
        isReconversion: isReconversion,
        headingOverride: isReconversion
            ? context.l10n.audioReconvertQuestion
            : context.l10n.audioMidiQuestion,
        descriptionOverride: isReconversion
            ? context.l10n.audioReconvertDescription
            : context.l10n.audioMidiConfirmDescription,
        actionLabelOverride: isReconversion
            ? context.l10n.reconvert
            : context.l10n.translate,
      ),
    );
    if (shouldConvert != true ||
        !mounted ||
        submissionBusy ||
        !canSubmitConversion) {
      return;
    }

    setState(() {
      isConverting = true;
      submissionError = null;
    });
    try {
      final job = await transcriptionService.transcribeAudio(
        sheetId: widget.sheetId,
      );
      if (mounted) {
        showSubmissionResult(job);
      }
    } catch (error) {
      if (mounted) {
        showSubmissionError(error);
      }
    } finally {
      if (mounted) setState(() => isConverting = false);
    }
  }

  void showJobMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    ScaffoldMessenger.of(context).showLatestSnackBar(
      appSnackBar(colors: widget.colors, message: message, type: type),
    );
  }

  void showSubmissionError(Object error) {
    final message = error is ProcessingJobException
        ? error.message(context)
        : context.l10n.jobSubmissionUnconfirmed;
    setState(() => submissionError = message);
    showJobMessage(message, type: AppSnackBarType.error);
  }

  void showSubmissionResult(ProcessingJob job) {
    if (job.isActive) {
      showJobMessage(context.l10n.jobAccepted);
    } else if (job.status == 'completed') {
      showJobMessage(
        context.l10n.jobCompletedTitle,
        type: AppSnackBarType.success,
      );
    } else if (job.status == 'failed') {
      showJobMessage(
        context.l10n.jobFailedNotification,
        type: AppSnackBarType.error,
      );
    }
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
                onTap: () {
                  Navigator.of(dialogContext).pop('sightReading');
                },
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
                onTap: () {
                  Navigator.of(dialogContext).pop('synthesia');
                },
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
                onTap: () {
                  Navigator.of(dialogContext).pop('ar');
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedMode == null) {
      return;
    }

    await audioPreviewController.stop();
    if (!mounted) return;

    if (selectedMode == 'sightReading') {
      await openSightReading();
      return;
    }

    if (selectedMode == 'synthesia') {
      await openSynthesia();
      return;
    }

    if (selectedMode == 'ar') {
      await openArPractice();
    }
  }

  Future<void> openSynthesia() async {
    try {
      final sheetSnapshot = await sheetReference.get();
      final sheetData = sheetSnapshot.data();

      if (!mounted) return;

      final midiUrl = sheetData?['midiUrl'] as String? ?? '';
      final midiStoragePath = sheetData?['midiStoragePath'] as String? ?? '';

      if (!hasConvertedScore(sheetData)) {
        ScaffoldMessenger.of(context).showLatestSnackBar(
          appSnackBar(
            colors: widget.colors,
            message: widget.type == 'audio'
                ? context.l10n.convertRecordingBeforeSynthesia
                : context.l10n.translateBeforeSynthesia,
            type: AppSnackBarType.warning,
          ),
        );
        return;
      }

      if (midiUrl.trim().isEmpty && midiStoragePath.trim().isEmpty) {
        ScaffoldMessenger.of(context).showLatestSnackBar(
          appSnackBar(
            colors: widget.colors,
            message: context.l10n.translatedMidiMissing,
            type: AppSnackBarType.warning,
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SynthesiaScreen(
            colors: widget.colors,
            source: SynthesiaDocumentSource(
              documentPath: sheetReference.path,
              fallbackTitle: widget.title,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showLatestSnackBar(
        appSnackBar(
          colors: widget.colors,
          message: context.l10n.openSynthesiaFailed,
          type: AppSnackBarType.error,
        ),
      );
    }
  }

  Future<void> openArPractice() async {
    try {
      final sheetSnapshot = await sheetReference.get();
      final sheetData = sheetSnapshot.data();

      if (!mounted) return;

      final midiUrl = sheetData?['midiUrl'] as String? ?? '';
      final midiStoragePath = sheetData?['midiStoragePath'] as String? ?? '';

      if (!hasConvertedScore(sheetData)) {
        ScaffoldMessenger.of(context).showLatestSnackBar(
          appSnackBar(
            colors: widget.colors,
            message: widget.type == 'audio'
                ? context.l10n.convertRecordingBeforeAr
                : context.l10n.translateBeforeAr,
            type: AppSnackBarType.warning,
          ),
        );
        return;
      }

      if (midiUrl.trim().isEmpty && midiStoragePath.trim().isEmpty) {
        ScaffoldMessenger.of(context).showLatestSnackBar(
          appSnackBar(
            colors: widget.colors,
            message: context.l10n.translatedMidiMissing,
            type: AppSnackBarType.warning,
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArPracticeScreen(
            colors: widget.colors,
            scoreDocumentPath: sheetReference.path,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showLatestSnackBar(
        appSnackBar(
          colors: widget.colors,
          message: context.l10n.openArFailed,
          type: AppSnackBarType.error,
        ),
      );
    }
  }

  Future<void> openSightReading() async {
    try {
      final sheetSnapshot = await sheetReference.get();
      final sheetData = sheetSnapshot.data();

      if (!mounted) {
        return;
      }

      final musicXmlStoragePath =
          sheetData?['musicXmlStoragePath'] as String? ?? '';

      final midiStoragePath = sheetData?['midiStoragePath'] as String? ?? '';
      final previewAudioStoragePath =
          sheetData?['previewAudioStoragePath'] as String? ?? '';

      if (!hasConvertedScore(sheetData)) {
        ScaffoldMessenger.of(context).showLatestSnackBar(
          appSnackBar(
            colors: widget.colors,
            message: widget.type == 'audio'
                ? context.l10n.convertRecordingBeforeSightReading
                : context.l10n.translateBeforeSightReading,
            type: AppSnackBarType.warning,
          ),
        );

        return;
      }

      if (musicXmlStoragePath.isEmpty ||
          midiStoragePath.isEmpty ||
          previewAudioStoragePath.isEmpty) {
        ScaffoldMessenger.of(context).showLatestSnackBar(
          appSnackBar(
            colors: widget.colors,
            message: context.l10n.translatedPracticeFilesMissing,
            type: AppSnackBarType.warning,
          ),
        );

        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MusicSheetReadingScreen(
            scoreDocumentPath: sheetReference.path,
            source: SightReadingSource.musicSheet,
            colors: widget.colors,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showLatestSnackBar(
        appSnackBar(
          colors: widget.colors,
          message: context.l10n.openSightReadingFailed,
          type: AppSnackBarType.error,
        ),
      );
    }
  }

  Widget buildViewerBody(Map<String, dynamic> sheetData) {
    final recognizedPdfStoragePath =
        sheetData['recognizedPdfStoragePath'] as String? ?? '';
    final hasRecognizedPdf = recognizedPdfStoragePath.isNotEmpty;
    final isPdfPreview =
        hasRecognizedPdf && showRecognizedPdf || widget.type == 'pdf';
    final sheetViewer = hasRecognizedPdf && showRecognizedPdf
        ? buildRecognizedPdfViewer(
            recognizedPdfStoragePath,
            sheetData['omrProcessedAt'],
          )
        : buildOriginalViewer();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildOmrSection(sheetData),
            if (hasRecognizedPdf) buildSourceToggle(),
            if (isPdfPreview)
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                child: sheetViewer,
              )
            else
              sheetViewer,
          ],
        ),
      ),
    );
  }

  Widget buildOmrSection(Map<String, dynamic> sheetData) {
    final status = sheetData['omrStatus'] as String? ?? 'notStarted';
    final jobStatus = sheetData['lastJobStatus'] as String?;
    final partCount = (sheetData['omrPartCount'] as num?)?.toInt() ?? 0;
    final noteCount = (sheetData['omrNoteCount'] as num?)?.toInt() ?? 0;
    final previewAudioStoragePath =
        sheetData['previewAudioStoragePath'] as String? ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ProcessingJobCard.isVisible(jobStatus))
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: ProcessingJobCard(
              colors: widget.colors,
              status: jobStatus,
              errorMessage: jobStatus == 'submissionFailed'
                  ? submissionError
                  : null,
              jobId: sheetData['activeJobId'] as String?,
              onRetry: canSubmitConversion
                  ? () => recognizeMusicSheet(
                      isReconversion: sheetData['omrStatus'] == 'completed',
                    )
                  : null,
            ),
          ),
        if (!submissionBusy &&
            sheetData['activeJobId'] == null &&
            jobStatus != 'submitting' &&
            jobStatus != 'submissionFailed' &&
            jobStatus != 'queued' &&
            jobStatus != 'processing')
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
              isConverting: submissionBusy,
              showAction: canSubmitConversion,
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
              controller: audioPreviewController,
            ),
          ),
      ],
    );
  }

  Widget buildSourceToggle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: widget.colors.borderColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: buildSourceToggleSegment(
                  selected: showRecognizedPdf,
                  label: context.l10n.recognized,
                  icon: Icons.auto_fix_high_rounded,
                  onTap: () => selectSource(true),
                ),
              ),
              Container(
                width: 1,
                constraints: const BoxConstraints(minHeight: 52),
                color: widget.colors.borderColor,
              ),
              Expanded(
                child: buildSourceToggleSegment(
                  selected: !showRecognizedPdf,
                  label: context.l10n.original,
                  icon: Icons.description_outlined,
                  onTap: () => selectSource(false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSourceToggleSegment({
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final foregroundColor = selected
        ? widget.colors.backgroundColor
        : widget.colors.primaryColor;

    return Semantics(
      button: true,
      excludeSemantics: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? widget.colors.primaryColor
            : widget.colors.surfaceColor,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: foregroundColor),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
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

  void selectSource(bool showConverted) {
    if (showRecognizedPdf == showConverted) return;
    setState(() {
      showRecognizedPdf = showConverted;
    });
  }

  Widget buildOriginalViewer({bool scrollableImages = false}) {
    if (files.isEmpty) return buildEmptyState();
    return widget.type == 'pdf'
        ? buildPdfViewer()
        : buildImageViewer(scrollable: scrollableImages);
  }

  Widget buildRecognizedPdfViewer(String storagePath, dynamic processedAt) {
    final processedAtVersion = processedAt is Timestamp
        ? processedAt.millisecondsSinceEpoch.toString()
        : processedAt?.toString() ?? '';
    final cacheKey = '$storagePath:$processedAtVersion';

    if (recognizedPdfCacheKey != cacheKey) {
      recognizedPdfCacheKey = cacheKey;
      recognizedPdfFuture = loadFile(storagePath, maxPdfFileSize);
    }

    return FutureBuilder<Uint8List?>(
      future: recognizedPdfFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: widget.colors.primaryColor),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return buildRecognizedPdfFallback();
        }

        return Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: buildPdfPreview(
              snapshot.data!,
              '${widget.title} - ${context.l10n.recognized}',
            ),
          ),
        );
      },
    );
  }

  Widget buildRecognizedPdfFallback() {
    if (widget.type == 'audio') {
      return buildLoadError(() {
        setState(() {
          recognizedPdfCacheKey = null;
          recognizedPdfFuture = null;
        });
      });
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
              Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.recognizedPdfLoadFailed,
                  style: TextStyle(
                    color: widget.colors.primaryColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    recognizedPdfCacheKey = null;
                    recognizedPdfFuture = null;
                  });
                },
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
        Expanded(child: buildOriginalViewer(scrollableImages: true)),
      ],
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
            child: buildPdfPreview(snapshot.data!, widget.title),
          ),
        );
      },
    );
  }

  Widget buildPdfPreview(Uint8List pdfBytes, String sourceName) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: context.l10n.fullScreen,
      onTap: () => showPdfDialog(pdfBytes, sourceName),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: PdfViewer.data(
              pdfBytes,
              sourceName: sourceName,
              params: PdfViewerParams(
                margin: AppSpacing.sm,
                backgroundColor: widget.colors.backgroundColor,
                sizeDelegateProvider: const PdfViewerSizeDelegateProviderSmart(
                  smartMaxScale: 2,
                  maxPagesVisible: 1,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: () => showPdfDialog(pdfBytes, sourceName)),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.colors.surfaceColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: widget.colors.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    Icons.open_in_full_rounded,
                    color: widget.colors.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showPdfDialog(Uint8List pdfBytes, String sourceName) {
    final screenSize = MediaQuery.sizeOf(context);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: widget.colors.surfaceColor,
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
                        sourceName,
                        maxLines: 2,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: widget.colors.primaryColor,
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
                        color: widget.colors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: widget.colors.borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: PdfViewer.data(
                      pdfBytes,
                      sourceName: sourceName,
                      params: PdfViewerParams(
                        margin: AppSpacing.sm,
                        backgroundColor: widget.colors.backgroundColor,
                        sizeDelegateProvider:
                            const PdfViewerSizeDelegateProviderSmart(
                              smartMaxScale: 2,
                              maxPagesVisible: 1,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildImageViewer({bool scrollable = false}) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.md),
      shrinkWrap: !scrollable,
      physics: scrollable ? null : const NeverScrollableScrollPhysics(),
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
          context.l10n.pageNumber(pageNumber),
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
        context.l10n.musicSheetHasNoFiles,
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
              context.l10n.fileLoadFailed,
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
              child: Text(context.l10n.tryAgain),
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
    if (submissionBusy || !canSubmitConversion) return;

    final shouldRecognize = await showDialog<bool>(
      context: context,
      builder: (_) => RecognizeMusicSheetDialog(
        colors: widget.colors,
        title: widget.title,
        isReconversion: isReconversion,
      ),
    );

    if (shouldRecognize != true ||
        !mounted ||
        submissionBusy ||
        !canSubmitConversion) {
      return;
    }

    setState(() {
      isConverting = true;
      submissionError = null;
    });
    try {
      final job = await omrService.recognizeMusicSheet(sheetId: widget.sheetId);
      if (mounted) {
        showSubmissionResult(job);
      }
    } catch (error) {
      if (mounted) {
        showSubmissionError(error);
      }
    } finally {
      if (mounted) setState(() => isConverting = false);
    }
  }
}
