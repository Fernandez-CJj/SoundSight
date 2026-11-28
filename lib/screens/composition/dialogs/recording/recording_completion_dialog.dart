import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:video_player/video_player.dart';

enum RecordingCompletionAction { discard, generate }

class RecordingCompletionDialog extends StatefulWidget {
  const RecordingCompletionDialog({
    super.key,
    required this.colors,
    required this.compositionTitle,
    required this.durationText,
    required this.noteCount,
    required this.videoPath,
    this.prepareVideo,
    this.onPreviewReleaseReady,
    required this.detectedTempo,
    required this.measureCount,
  });

  final AppThemeColors colors;
  final String compositionTitle;
  final String durationText;
  final int noteCount;
  final String videoPath;
  final Future<String> Function()? prepareVideo;
  final void Function(Future<void> Function())? onPreviewReleaseReady;
  final int detectedTempo;
  final int measureCount;

  @override
  State<RecordingCompletionDialog> createState() =>
      _RecordingCompletionDialogState();
}

class _RecordingCompletionDialogState extends State<RecordingCompletionDialog> {
  static const videoChannel = MethodChannel('soundsight/recorded_video');
  bool isSavingVideo = false;
  bool videoSaved = false;
  bool isPreparingVideo = false;
  bool isClosing = false;
  bool previewFailed = false;
  bool previewReleased = false;
  VideoPlayerController? videoPlayer;
  Future<void>? previewRelease;
  String? preparedVideoPath;
  String? saveError;

  @override
  void initState() {
    super.initState();
    widget.onPreviewReleaseReady?.call(releasePreview);
    if (widget.prepareVideo == null) {
      preparedVideoPath = widget.videoPath;
      unawaited(initializePreview(widget.videoPath));
    } else {
      unawaited(prepareVideo());
    }
  }

  Future<void> prepareVideo() async {
    if (isPreparingVideo || isSavingVideo || isClosing) return;
    setState(() {
      isPreparingVideo = true;
      saveError = null;
    });
    try {
      final path = await widget.prepareVideo!();
      if (!mounted || previewReleased) return;
      setState(() => preparedVideoPath = path);
      unawaited(initializePreview(path));
    } catch (_) {
      if (mounted) {
        setState(() => saveError = context.l10n.midiRecordingPreparationFailed);
      }
    } finally {
      if (mounted) setState(() => isPreparingVideo = false);
    }
  }

  Future<void> initializePreview(String path) async {
    if (!mounted || previewReleased) return;
    final player = VideoPlayerController.file(File(path));
    videoPlayer = player;
    try {
      await player.initialize();
      if (mounted && !previewReleased) setState(() {});
    } catch (_) {
      if (mounted && !previewReleased) setState(() => previewFailed = true);
    }
  }

  Future<void> releasePreview() => previewRelease ??= _releasePreview();

  Future<void> _releasePreview() async {
    previewReleased = true;
    final player = videoPlayer;
    videoPlayer = null;
    try {
      await player?.dispose();
    } catch (_) {
      // Continue releasing the recording even if the native player failed.
    }
  }

  Future<void> closeDialog(RecordingCompletionAction action) async {
    if (isSavingVideo || isPreparingVideo || isClosing) return;
    setState(() => isClosing = true);
    await releasePreview();
    if (mounted) Navigator.pop(context, action);
  }

  Future<void> controlPreview(Future<void> Function() action) async {
    if (isSavingVideo || isPreparingVideo || isClosing || previewReleased) return;
    try {
      await action();
    } catch (_) {
      if (mounted && !previewReleased) setState(() => previewFailed = true);
    }
  }

  Future<void> saveVideo() async {
    if (isSavingVideo || isPreparingVideo || isClosing || videoSaved || preparedVideoPath == null) return;
    setState(() {
      isSavingVideo = true;
      saveError = null;
    });
    try {
      final player = videoPlayer;
      if (player != null && player.value.isInitialized) {
        try {
          await player.pause();
        } catch (_) {
          // A preview failure must not block saving the prepared video.
        }
      }
      final safeTitle = widget.compositionTitle
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final name = safeTitle.isEmpty
          ? 'SoundSight recording.mp4'
          : '$safeTitle.mp4';
      final saved = await videoChannel.invokeMethod<bool>('saveVideo', {
        'path': preparedVideoPath,
        'name': name,
      });
      if (mounted) {
        setState(() {
          videoSaved = saved == true;
          if (!videoSaved) saveError = context.l10n.recordedVideoSaveFailed;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => saveError = context.l10n.recordedVideoSaveFailed);
      }
    } finally {
      if (mounted) setState(() => isSavingVideo = false);
    }
  }

  @override
  void dispose() {
    unawaited(releasePreview());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final maximumHeight = MediaQuery.sizeOf(context).height * 0.82;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: colors.surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: maximumHeight),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.video_file_rounded, color: colors.primaryColor),
                    Gap(AppSpacing.sm),
                    Expanded(
                      child: Text(
                        context.l10n.recordingComplete,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.sectionTitle,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.recordedVideoSaveQuestion,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Gap(AppSpacing.xs),
                        Text(
                          context.l10n.recordedVideoSaveDescription,
                          style: TextStyle(color: colors.secondaryTextColor),
                        ),
                        Gap(AppSpacing.sm),
                        if (isPreparingVideo) ...[
                          LinearProgressIndicator(
                            color: colors.primaryColor,
                            backgroundColor: colors.borderColor,
                          ),
                          Gap(AppSpacing.sm),
                          Text(
                            context.l10n.performanceVideoPreparing,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.primaryColor),
                          ),
                          Gap(AppSpacing.sm),
                        ],
                        if (preparedVideoPath != null && !previewReleased) ...[
                          buildVideoPreview(context),
                          Gap(AppSpacing.sm),
                        ],
                        OutlinedButton(
                          onPressed: isSavingVideo || isPreparingVideo || isClosing || videoSaved ||
                                  preparedVideoPath == null
                              ? null
                              : saveVideo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryColor,
                            side: BorderSide(color: colors.borderColor),
                            alignment: Alignment.center,
                            textStyle: buttonTextStyle(context),
                          ),
                          child: Text(
                            videoSaved
                                ? context.l10n.recordedVideoSaved
                                : context.l10n.saveRecordedVideo,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (saveError != null) ...[
                          Gap(AppSpacing.xs),
                          Text(
                            saveError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          if (preparedVideoPath == null && !isPreparingVideo)
                            TextButton(
                              onPressed: prepareVideo,
                              style: TextButton.styleFrom(foregroundColor: colors.primaryColor),
                              child: Text(context.l10n.tryAgain),
                            ),
                        ],
                        Gap(AppSpacing.md),
                        _informationRow(
                          context.l10n.compositionTitle,
                          widget.compositionTitle,
                        ),
                        _informationRow(
                          context.l10n.performance,
                          widget.durationText,
                        ),
                        _informationRow(
                          context.l10n.capturedNotes,
                          '${widget.noteCount}',
                        ),
                        _informationRow(
                          context.l10n.detectedTempo,
                          '${widget.detectedTempo} BPM',
                        ),
                        _informationRow(
                          context.l10n.calculatedMeasures,
                          '${widget.measureCount}',
                        ),
                      ],
                    ),
                  ),
                ),
                Gap(AppSpacing.md),
                buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle buttonTextStyle(BuildContext context) =>
      (Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 14))
          .copyWith(height: 1.1);

  Widget buildActions(BuildContext context) {
    final colors = widget.colors;
    final style = buttonTextStyle(context);
    final busy = isSavingVideo || isPreparingVideo || isClosing;
    final recordAgain = OutlinedButton(
      onPressed: busy ? null : () => closeDialog(RecordingCompletionAction.discard),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primaryColor,
        side: BorderSide(color: colors.borderColor),
        textStyle: style,
        alignment: Alignment.center,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(context.l10n.recordAgain, textAlign: TextAlign.center),
    );
    final prepareMusic = ElevatedButton(
      onPressed: busy ? null : () => closeDialog(RecordingCompletionAction.generate),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primaryColor,
        foregroundColor: colors.backgroundColor,
        textStyle: style,
        alignment: Alignment.center,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(context.l10n.generate, textAlign: TextAlign.center),
    );
    return LayoutBuilder(builder: (context, constraints) {
      double labelWidth(String text) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final width = painter.width;
        painter.dispose();
        return width;
      }
      final availableWidth = (constraints.maxWidth - AppSpacing.sm) / 2 - 32;
      if (labelWidth(context.l10n.recordAgain) > availableWidth ||
          labelWidth(context.l10n.generate) > availableWidth) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [recordAgain, Gap(AppSpacing.sm), prepareMusic],
        );
      }
      return Row(children: [
        Expanded(child: recordAgain),
        Gap(AppSpacing.sm),
        Expanded(child: prepareMusic),
      ]);
    });
  }

  Widget buildVideoPreview(BuildContext context) {
    final colors = widget.colors;
    final player = videoPlayer;
    Widget failedPreview() => Text(
      context.l10n.performanceVideoPreviewFailed,
      textAlign: TextAlign.center,
      style: TextStyle(color: colors.destructiveColor),
    );
    if (previewFailed) return failedPreview();
    if (player == null || !player.value.isInitialized) {
      return Center(child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: CircularProgressIndicator(
          color: colors.primaryColor,
          backgroundColor: colors.borderColor,
        ),
      ));
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: player,
      builder: (context, value, _) {
        if (value.hasError) return failedPreview();
        final enabled = !isSavingVideo && !isPreparingVideo && !isClosing;
        final controls = IconButton.styleFrom(
          foregroundColor: colors.primaryColor,
          disabledForegroundColor: colors.secondaryTextColor,
          hoverColor: colors.borderColor,
          focusColor: colors.borderColor,
          highlightColor: colors.borderColor,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (MediaQuery.sizeOf(context).height * 0.28)
                    .clamp(72.0, 240.0).toDouble(),
                maxWidth: 440,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: ColoredBox(color: Colors.black, child: VideoPlayer(player)),
                ),
              ),
            )),
            Row(children: [
              IconButton(
                style: controls,
                tooltip: value.isPlaying ? context.l10n.pause : context.l10n.performanceVideoPlay,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: !enabled ? null : () => controlPreview(() async {
                  if (player.value.isPlaying) {
                    await player.pause();
                  } else {
                    if (player.value.position >= player.value.duration) {
                      await player.seekTo(Duration.zero);
                    }
                    if (!mounted || previewReleased || isClosing || isSavingVideo) return;
                    await player.play();
                  }
                }),
              ),
              Expanded(child: VideoProgressIndicator(
                player,
                allowScrubbing: enabled,
                colors: VideoProgressColors(
                  playedColor: colors.primaryColor,
                  bufferedColor: colors.secondaryTextColor,
                  backgroundColor: colors.borderColor,
                ),
              )),
              IconButton(
                style: controls,
                tooltip: value.volume == 0
                    ? context.l10n.performanceVideoUnmute : context.l10n.performanceVideoMute,
                icon: Icon(value.volume == 0 ? Icons.volume_off : Icons.volume_up),
                onPressed: !enabled ? null : () => controlPreview(
                  () => player.setVolume(player.value.volume == 0 ? 1 : 0),
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _informationRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: widget.colors.secondaryTextColor),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: widget.colors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
