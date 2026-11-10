import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:video_player/video_player.dart';

import '../services/performance_recording_controller.dart';

/// Owns the result-route lifetime, including Back and programmatic exits.
Future<void> showRecordedPerformanceDialog({
  required BuildContext context,
  required PerformanceRecordingController recording,
  required AppThemeColors colors,
  required WidgetBuilder builder,
}) async {
  final attemptId = recording.attemptId;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: colors.backgroundColor.withValues(alpha: 0.72),
      builder: (context) => ListenableBuilder(
        listenable: recording,
        builder: (context, _) => PopScope(
          canPop: !recording.isSaving,
          child: TooltipTheme(
            data: TooltipThemeData(
              decoration: BoxDecoration(
                color: colors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(color: colors.backgroundColor),
            ),
            child: AbsorbPointer(
              absorbing: recording.isSaving,
              child: builder(context),
            ),
          ),
        ),
      ),
    );
  } finally {
    if (attemptId != null) {
      await recording.discard(expectedAttemptId: attemptId);
    }
  }
}

class PerformanceRecordingPreview extends StatefulWidget {
  const PerformanceRecordingPreview({
    super.key,
    required this.recording,
    required this.pieceTitle,
    required this.colors,
  });
  final PerformanceRecordingController recording;
  final String pieceTitle;
  final AppThemeColors colors;
  @override
  State<PerformanceRecordingPreview> createState() =>
      _PerformanceRecordingPreviewState();
}

class _PerformanceRecordingPreviewState
    extends State<PerformanceRecordingPreview> {
  VideoPlayerController? _player;
  Future<void>? _release;
  bool _previewFailed = false;
  bool _released = false;

  @override
  void initState() {
    super.initState();
    widget.recording.releasePreview = release;
    final path = widget.recording.path;
    if (path != null) {
      final player = VideoPlayerController.file(File(path));
      _player = player;
      unawaited(
        player
            .initialize()
            .then((_) {
              if (mounted && !_released) setState(() {});
            })
            .catchError((Object _) {
              if (mounted && !_released) setState(() => _previewFailed = true);
            }),
      );
    }
  }

  Future<void> release() => _release ??= _releasePlayer();
  Future<void> _releasePlayer() async {
    _released = true;
    // video_player.dispose waits for native creation itself. Waiting for the
    // initialized event here would hang cleanup for an unplayable video.
    await _player?.dispose();
    _player = null;
  }

  @override
  void dispose() {
    unawaited(release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.recording,
    builder: (context, _) {
      final l10n = context.l10n;
      final recording = widget.recording;
      final colors = widget.colors;
      final controlStyle = IconButton.styleFrom(
        foregroundColor: colors.primaryColor,
        disabledForegroundColor: colors.secondaryTextColor,
        backgroundColor: colors.surfaceColor,
        hoverColor: colors.borderColor,
        focusColor: colors.borderColor,
        highlightColor: colors.borderColor,
      );
      if (recording.state == PerformanceRecordingState.idle ||
          recording.state == PerformanceRecordingState.disposed) {
        return const SizedBox.shrink();
      }
      if (recording.state == PerformanceRecordingState.saved) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l10n.performanceVideoSaved,
            style: TextStyle(color: colors.completedStageColor),
          ),
        );
      }
      if (recording.state == PerformanceRecordingState.unavailable) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l10n.performanceVideoUnavailable,
            style: TextStyle(color: colors.secondaryTextColor),
          ),
        );
      }
      final player = _player;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.performanceVideoQuestion,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_previewFailed)
              Text(
                l10n.performanceVideoPreviewFailed,
                style: TextStyle(color: colors.destructiveColor),
              )
            else if (player == null || !player.value.isInitialized)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primaryColor,
                      backgroundColor: colors.borderColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(
                    l10n.performanceVideoPreparing,
                    style: TextStyle(color: colors.secondaryTextColor),
                  )),
                ],
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  maxWidth: 440,
                ),
                child: AspectRatio(
                  aspectRatio: player.value.aspectRatio,
                  child: ColoredBox(
                    color: colors.backgroundColor,
                    child: VideoPlayer(player),
                  ),
                ),
              ),
            if (player != null && player.value.isInitialized && !_previewFailed)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: player,
                builder: (context, value, _) => Row(
                  children: [
                    IconButton(
                      style: controlStyle,
                      tooltip: value.isPlaying
                          ? l10n.pause
                          : l10n.performanceVideoPlay,
                      icon: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: () async {
                        if (value.isPlaying) {
                          await player.pause();
                        } else {
                          if (value.position >= value.duration) {
                            await player.seekTo(Duration.zero);
                          }
                          await player.play();
                        }
                      },
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        player,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: colors.primaryColor,
                          bufferedColor: colors.secondaryTextColor,
                          backgroundColor: colors.borderColor,
                        ),
                      ),
                    ),
                    IconButton(
                      style: controlStyle,
                      tooltip: value.volume == 0
                          ? l10n.performanceVideoUnmute
                          : l10n.performanceVideoMute,
                      icon: Icon(
                        value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                      ),
                      onPressed: () =>
                          player.setVolume(value.volume == 0 ? 1 : 0),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: colors.backgroundColor,
                disabledBackgroundColor: colors.borderColor,
                disabledForegroundColor: colors.secondaryTextColor,
                overlayColor: colors.backgroundColor.withValues(alpha: 0.12),
                shadowColor: colors.borderColor,
                surfaceTintColor: colors.surfaceColor,
              ),
              onPressed: recording.isSaving || recording.path == null
                  ? null
                  : () async {
                      await player?.pause();
                      await recording.save(widget.pieceTitle);
                    },
              icon: recording.isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.secondaryTextColor,
                        backgroundColor: colors.borderColor,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                recording.isSaving
                    ? l10n.performanceVideoSaving
                    : l10n.saveRecordedVideo,
              ),
            ),
            if (recording.saveFailed) Text(
              l10n.recordedVideoSaveFailed,
              style: TextStyle(color: colors.destructiveColor),
            ),
            Text(
              l10n.performanceVideoDiscardNotice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    },
  );
}
