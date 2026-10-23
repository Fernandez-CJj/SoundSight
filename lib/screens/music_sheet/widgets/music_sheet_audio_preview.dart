import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class MusicSheetAudioPreviewController {
  Future<void> Function()? _stopPlayback;

  Future<void> stop() async {
    final stopPlayback = _stopPlayback;
    if (stopPlayback != null) {
      await stopPlayback();
    }
  }
}

class MusicSheetAudioPreview extends StatefulWidget {
  const MusicSheetAudioPreview({
    super.key,
    required this.colors,
    required this.storagePath,
    this.title,
    this.loadingText,
    this.playingText,
    this.pausedText,
    this.idleText,
    this.controller,
  });

  final AppThemeColors colors;
  final String storagePath;
  final String? title;
  final String? loadingText;
  final String? playingText;
  final String? pausedText;
  final String? idleText;
  final MusicSheetAudioPreviewController? controller;

  @override
  State<MusicSheetAudioPreview> createState() => _MusicSheetAudioPreviewState();
}

class _MusicSheetAudioPreviewState extends State<MusicSheetAudioPreview> {
  static const int maximumAudioSize = 30 * 1024 * 1024;

  final AudioPlayer audioPlayer = AudioPlayer();

  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration>? durationSubscription;
  StreamSubscription<void>? completionSubscription;

  Uint8List? audioBytes;
  PlayerState playerState = PlayerState.stopped;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isLoading = false;

  bool get isPlaying => playerState == PlayerState.playing;
  bool get isPaused => playerState == PlayerState.paused;
  bool get canStop =>
      !isLoading && (isPlaying || isPaused || position > Duration.zero);

  @override
  void initState() {
    super.initState();

    widget.controller?._stopPlayback = stopPlayback;

    unawaited(
      audioPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      ),
    );

    unawaited(audioPlayer.setReleaseMode(ReleaseMode.stop));

    playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        playerState = state;
      });
    });

    positionSubscription = audioPlayer.onPositionChanged.listen((newPosition) {
      if (!mounted) return;

      setState(() {
        position = newPosition;
      });
    });

    durationSubscription = audioPlayer.onDurationChanged.listen((newDuration) {
      if (!mounted) return;

      setState(() {
        duration = newDuration;
      });
    });

    completionSubscription = audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        position = Duration.zero;
        playerState = PlayerState.stopped;
      });
    });
  }

  @override
  void didUpdateWidget(covariant MusicSheetAudioPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._stopPlayback == stopPlayback) {
        oldWidget.controller?._stopPlayback = null;
      }
      widget.controller?._stopPlayback = stopPlayback;
    }

    if (oldWidget.storagePath != widget.storagePath) {
      audioBytes = null;
      position = Duration.zero;
      duration = Duration.zero;
      playerState = PlayerState.stopped;
      unawaited(audioPlayer.stop());
    }
  }

  @override
  void dispose() {
    if (widget.controller?._stopPlayback == stopPlayback) {
      widget.controller?._stopPlayback = null;
    }
    unawaited(playerStateSubscription?.cancel());
    unawaited(positionSubscription?.cancel());
    unawaited(durationSubscription?.cancel());
    unawaited(completionSubscription?.cancel());
    unawaited(audioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: colors.primaryColor,
                  size: AppIconSizes.md,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? context.l10n.audioPreview,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      getStatusText(context),
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              buildControlButton(
                tooltip: isPlaying ? context.l10n.pause : context.l10n.play,
                icon: isLoading
                    ? null
                    : isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                isPrimary: true,
                onPressed: isLoading ? null : togglePlayback,
              ),
              Gap(AppSpacing.sm),
              buildControlButton(
                tooltip: context.l10n.stop,
                icon: Icons.stop_rounded,
                isPrimary: false,
                onPressed: canStop ? stopPlayback : null,
              ),
            ],
          ),
          Gap(AppSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primaryColor,
              inactiveTrackColor: colors.borderColor,
              thumbColor: colors.primaryColor,
              overlayColor: colors.primaryColor.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
            ),
            child: Slider(
              min: 0,
              max: duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1,
              value: position.inMilliseconds
                  .clamp(
                    0,
                    duration.inMilliseconds > 0
                        ? duration.inMilliseconds
                        : 1,
                  )
                  .toDouble(),
              onChanged: duration > Duration.zero && !isLoading
                  ? seekTo
                  : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(position),
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
              Text(
                formatDuration(duration),
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildControlButton({
    required String tooltip,
    required IconData? icon,
    required bool isPrimary,
    required VoidCallback? onPressed,
  }) {
    final colors = widget.colors;

    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isPrimary
              ? colors.primaryColor
              : colors.backgroundColor,
          foregroundColor: isPrimary
              ? colors.backgroundColor
              : colors.primaryColor,
          disabledBackgroundColor: colors.borderColor,
          disabledForegroundColor: colors.secondaryTextColor,
          side: isPrimary ? null : BorderSide(color: colors.borderColor),
        ),
        icon: icon == null
            ? SizedBox(
                width: AppIconSizes.sm,
                height: AppIconSizes.sm,
                child: CircularProgressIndicator(
                  color: colors.backgroundColor,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: AppIconSizes.md),
      ),
    );
  }

  Future<void> togglePlayback() async {
    if (isLoading) return;

    if (isPlaying) {
      await audioPlayer.pause();
      return;
    }

    try {
      if (audioBytes == null) {
        setState(() {
          isLoading = true;
        });

        final downloadedBytes = await FirebaseStorage.instance
            .ref(widget.storagePath)
            .getData(maximumAudioSize);

        if (downloadedBytes == null || downloadedBytes.isEmpty) {
          throw StateError('empty-audio-preview');
        }

        audioBytes = downloadedBytes;
        await audioPlayer.setSource(BytesSource(downloadedBytes));
      } else if (playerState == PlayerState.completed) {
        await audioPlayer.seek(Duration.zero);
      }

      await audioPlayer.resume();
    } catch (error) {
      showMessage(context.l10n.audioPlaybackError);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> stopPlayback() async {
    await audioPlayer.stop();

    if (!mounted) return;

    setState(() {
      position = Duration.zero;
      playerState = PlayerState.stopped;
    });
  }

  void seekTo(double milliseconds) {
    unawaited(
      audioPlayer.seek(
        Duration(milliseconds: milliseconds.round()),
      ),
    );
  }

  String getStatusText(BuildContext context) {
    if (isLoading) return widget.loadingText ?? context.l10n.audioLoading;
    if (isPlaying) return widget.playingText ?? context.l10n.audioPlaying;
    if (isPaused) return widget.pausedText ?? context.l10n.audioPaused;
    return widget.idleText ?? context.l10n.audioIdle;
  }

  String formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? context.l10n.audioPlaybackError : message,
          ),
        ),
      );
  }
}
