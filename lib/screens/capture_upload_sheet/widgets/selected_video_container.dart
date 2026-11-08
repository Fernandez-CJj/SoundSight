import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/capture_upload_sheet/models/selected_video_file.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:video_player/video_player.dart';

class SelectedVideoContainer extends StatefulWidget {
  const SelectedVideoContainer({
    super.key,
    required this.colors,
    required this.file,
    required this.isSaving,
    this.headingBuilder,
  });

  final AppThemeColors colors;
  final SelectedVideoFile file;
  final bool isSaving;
  final Widget Function(Widget)? headingBuilder;

  @override
  State<SelectedVideoContainer> createState() => _SelectedVideoContainerState();
}

class _SelectedVideoContainerState extends State<SelectedVideoContainer>
    with WidgetsBindingObserver {
  late final VideoPlayerController player;
  bool isReady = false;
  bool hasError = false;

  Widget _heading(Widget child) => widget.headingBuilder?.call(child) ?? child;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    player = VideoPlayerController.file(File(widget.file.path));
    player.addListener(_onPlayerChanged);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      await player.initialize();
      if (mounted) setState(() => isReady = true);
    } catch (_) {
      if (mounted) setState(() => hasError = true);
    }
  }

  void _onPlayerChanged() {
    if (mounted && isReady) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SelectedVideoContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSaving && !oldWidget.isSaving) unawaited(player.pause());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(player.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.removeListener(_onPlayerChanged);
    unawaited(player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!isReady || hasError || widget.isSaving) return;
    try {
      if (player.value.isPlaying) {
        await player.pause();
      } else {
        if (player.value.position >= player.value.duration) {
          await player.seekTo(Duration.zero);
        }
        await player.play();
      }
    } catch (_) {
      if (mounted) setState(() => hasError = true);
    }
  }

  Future<void> _seek(double milliseconds) async {
    try {
      await player.seekTo(Duration(milliseconds: milliseconds.round()));
    } catch (_) {
      if (mounted) setState(() => hasError = true);
    }
  }

  String _time(Duration value) =>
      '${value.inMinutes}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final durationMs = widget.file.duration.inMilliseconds;
    final position = isReady ? player.value.position : Duration.zero;

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
          _heading(Text(
            context.l10n.selectedVideoFile,
            style: TextStyle(
              color: colors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          )),
          Gap(AppSpacing.sm),
          Text(
            widget.file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${(widget.file.sizeBytes / 1000000).toStringAsFixed(1)} MB | ${_time(widget.file.duration)}',
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
          Gap(AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ColoredBox(
                color: Colors.black,
                child: hasError
                    ? Center(
                        child: Text(
                          context.l10n.videoUnreadable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : !isReady
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: player.value.aspectRatio,
                              child: VideoPlayer(player),
                            ),
                          ),
                          Center(
                            child: IconButton.filled(
                              tooltip: player.value.isPlaying
                                  ? context.l10n.pause
                                  : context.l10n.play,
                              onPressed: widget.isSaving ? null : _toggle,
                              style: IconButton.styleFrom(
                                backgroundColor: colors.primaryColor,
                                foregroundColor: colors.backgroundColor,
                              ),
                              icon: Icon(
                                player.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primaryColor,
              inactiveTrackColor: colors.borderColor,
              thumbColor: colors.primaryColor,
            ),
            child: Slider(
              min: 0,
              max: durationMs > 0 ? durationMs.toDouble() : 1,
              value: position.inMilliseconds
                  .clamp(0, durationMs > 0 ? durationMs : 1)
                  .toDouble(),
              onChanged: isReady && !hasError && !widget.isSaving ? _seek : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _time(position),
                style: TextStyle(color: colors.secondaryTextColor),
              ),
              Text(
                _time(widget.file.duration),
                style: TextStyle(color: colors.secondaryTextColor),
              ),
            ],
          ),
          Gap(AppSpacing.sm),
          Text(
            context.l10n.videoAudioOnlyNote,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
        ],
      ),
    );
  }
}
