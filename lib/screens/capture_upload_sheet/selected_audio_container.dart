import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_audio_file.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class SelectedAudioContainer extends StatefulWidget {
  const SelectedAudioContainer({
    super.key,
    required this.colors,
    required this.file,
    required this.isSaving,
  });

  final AppThemeColors colors;
  final SelectedAudioFile file;
  final bool isSaving;

  @override
  State<SelectedAudioContainer> createState() => _SelectedAudioContainerState();
}

class _SelectedAudioContainerState extends State<SelectedAudioContainer>
    with WidgetsBindingObserver {
  AudioPlayer? audioPlayer;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<PlayerState>? stateSubscription;
  StreamSubscription<void>? completionSubscription;
  Duration position = Duration.zero;
  bool isPlaying = false;
  bool isReady = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      final player = AudioPlayer();
      audioPlayer = player;
      positionSubscription = player.onPositionChanged.listen((value) {
        if (mounted) setState(() => position = value);
      });
      stateSubscription = player.onPlayerStateChanged.listen((value) {
        if (mounted) setState(() => isPlaying = value == PlayerState.playing);
      });
      completionSubscription = player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            isPlaying = false;
            position = Duration.zero;
          });
        }
      });
      await player.setSource(DeviceFileSource(widget.file.path));
      if (mounted) setState(() => isReady = true);
    } catch (_) {
      if (mounted) setState(() => hasError = true);
    }
  }

  @override
  void didUpdateWidget(covariant SelectedAudioContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSaving && !oldWidget.isSaving) unawaited(_pause());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_pause());
  }

  Future<void> _pause() async {
    await audioPlayer?.pause();
  }

  Future<void> _toggle() async {
    if (!isReady || widget.isSaving) return;
    try {
      if (isPlaying) {
        await _pause();
      } else if (audioPlayer != null) {
        if (position >= widget.file.duration) {
          await audioPlayer!.seek(Duration.zero);
        }
        await audioPlayer!.resume();
      }
    } catch (_) {
      if (mounted) setState(() => hasError = true);
    }
  }

  Future<void> _seek(double milliseconds) async {
    final target = Duration(milliseconds: milliseconds.round());
    try {
      await audioPlayer?.seek(target);
      if (mounted) setState(() => position = target);
    } catch (_) {
      if (mounted) setState(() => hasError = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(positionSubscription?.cancel());
    unawaited(stateSubscription?.cancel());
    unawaited(completionSubscription?.cancel());
    unawaited(audioPlayer?.dispose());
    super.dispose();
  }

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final accentColor = colors.synthesiaResultColor;
    final durationMs = widget.file.duration.inMilliseconds;
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.selectedAudioFile,
              style: TextStyle(color: colors.primaryColor,
                  fontWeight: FontWeight.w700)),
          Gap(AppSpacing.sm),
          Row(children: [
            Icon(Icons.audio_file_rounded, color: accentColor, size: 34),
            Gap(AppSpacing.sm),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.file.name, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.primaryColor,
                        fontWeight: FontWeight.w600)),
                Text('${widget.file.extension.toUpperCase()} · '
                    '${(widget.file.sizeBytes / 1000000).toStringAsFixed(1)} MB · '
                    '${_time(widget.file.duration)}',
                    style: TextStyle(color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption)),
              ],
            )),
            IconButton(
              tooltip: isPlaying ? context.l10n.pause : context.l10n.play,
              onPressed: isReady && !hasError && !widget.isSaving ? _toggle : null,
              color: colors.primaryColor,
              disabledColor: colors.secondaryTextColor,
              icon: !isReady && !hasError
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primaryColor,
                      ))
                  : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primaryColor,
              inactiveTrackColor: colors.borderColor,
              thumbColor: colors.primaryColor,
              overlayColor: colors.primaryColor.withValues(alpha: 0.1),
              disabledActiveTrackColor: colors.borderColor,
              disabledInactiveTrackColor: colors.borderColor,
              disabledThumbColor: colors.secondaryTextColor,
            ),
            child: Slider(
              min: 0,
              max: durationMs > 0 ? durationMs.toDouble() : 1,
              value: position.inMilliseconds.clamp(0, durationMs > 0 ? durationMs : 1)
                  .toDouble(),
              onChanged: isReady && !hasError && !widget.isSaving ? _seek : null,
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_time(position), style: TextStyle(color: colors.secondaryTextColor)),
            Text(_time(widget.file.duration),
                style: TextStyle(color: colors.secondaryTextColor)),
          ]),
          if (hasError) Text(context.l10n.audioPlaybackError,
              style: TextStyle(color: colors.primaryColor)),
          Text(context.l10n.audioOnlyPreviewNote,
              style: TextStyle(color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption)),
        ],
      ),
    );
  }
}
