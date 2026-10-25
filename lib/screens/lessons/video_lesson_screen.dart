import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:video_player/video_player.dart';

class VideoLessonScreen extends StatefulWidget {
  const VideoLessonScreen({
    super.key,
    required this.title,
    required this.videoAssetPath,
    this.onStartQuiz,
    this.onViewPdf,
    this.restoreOrientations = const [DeviceOrientation.portraitUp],
  });

  final String title;
  final String videoAssetPath;
  final Future<void> Function()? onStartQuiz;
  final Future<void> Function()? onViewPdf;
  final List<DeviceOrientation> restoreOrientations;

  @override
  State<VideoLessonScreen> createState() {
    return _VideoLessonScreenState();
  }
}

class _VideoLessonScreenState extends State<VideoLessonScreen>
    with WidgetsBindingObserver {
  late final VideoPlayerController videoController;
  late final Future<void> videoInitialization;
  bool controlsVisible = true;

  void seekBy(Duration amount) {
    var newPosition = videoController.value.position + amount;
    final videoDuration = videoController.value.duration;

    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    } else if (newPosition > videoDuration) {
      newPosition = videoDuration;
    }

    videoController.seekTo(newPosition);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    videoController = VideoPlayerController.asset(widget.videoAssetPath);

    videoInitialization = videoController.initialize();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(widget.restoreOrientations);
    videoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_pauseVideo());
    }
  }

  Future<void> _pauseVideo() async {
    if (videoController.value.isInitialized) {
      await videoController.pause();
    }
  }

  Future<void> _openQuiz() async {
    if (widget.onStartQuiz == null) return;
    await _pauseVideo();
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (!mounted) return;
    try {
      await widget.onStartQuiz!();
    } finally {
      if (mounted) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  Future<void> _openPdf() async {
    final onViewPdf = widget.onViewPdf;
    if (onViewPdf == null) return;
    await _pauseVideo();
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (!mounted) return;
    try {
      await onViewPdf();
    } finally {
      if (mounted) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: videoInitialization,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      context.l10n.lessonVideoLoadFailed,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: videoController.value.size.width,
                          height: videoController.value.size.height,
                          child: VideoPlayer(videoController),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  controlsVisible = !controlsVisible;
                                });
                              },
                              onDoubleTap: () {
                                seekBy(const Duration(seconds: -5));
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  controlsVisible = !controlsVisible;
                                });
                              },
                              onDoubleTap: () {
                                seekBy(const Duration(seconds: 5));
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controlsVisible)
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: videoController,
                        builder: (context, videoState, child) {
                          return IconButton(
                            onPressed: () {
                              if (videoState.isPlaying) {
                                videoController.pause();
                              } else {
                                videoController.play();
                              }
                            },
                            tooltip: videoState.isPlaying
                                ? context.l10n.lessonPauseVideo
                                : context.l10n.lessonPlayVideo,
                            icon: Icon(
                              videoState.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            iconSize: 56,
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          );
                        },
                      ),
                    if (controlsVisible)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          child: Container(
                            color: Colors.black87,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder<VideoPlayerValue>(
                                  valueListenable: videoController,
                                  builder: (context, videoState, child) {
                                    final durationMilliseconds =
                                        videoState.duration.inMilliseconds;
                                    final positionMilliseconds = videoState
                                        .position
                                        .inMilliseconds
                                        .clamp(0, durationMilliseconds);

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SliderTheme(
                                          data: SliderTheme.of(context)
                                              .copyWith(
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 8,
                                                    ),
                                              ),
                                          child: Slider(
                                            value: positionMilliseconds
                                                .toDouble(),
                                            min: 0,
                                            max: durationMilliseconds > 0
                                                ? durationMilliseconds
                                                      .toDouble()
                                                : 1,
                                            activeColor: Colors.white,
                                            inactiveColor: Colors.white38,
                                            onChanged: durationMilliseconds > 0
                                                ? (value) {
                                                    videoController.seekTo(
                                                      Duration(
                                                        milliseconds: value
                                                            .round(),
                                                      ),
                                                    );
                                                  }
                                                : null,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formatVideoTime(
                                                videoState.position,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              formatVideoTime(
                                                videoState.duration,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              right: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 12),
                child: IconButton(
                  onPressed: () async {
                    await _pauseVideo();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  tooltip: context.l10n.lessonBackToPractice,
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ),
          ),
          if (widget.onStartQuiz != null) Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              left: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: _openQuiz,
                    icon: const Icon(Icons.quiz_outlined, size: 20),
                    label: Text(
                      context.l10n.lessonStartQuiz,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: colorScheme.onPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.onViewPdf != null)
            Positioned(
              top: 72,
              right: 24,
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: _openPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(context.l10n.lessonViewPdf),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String formatVideoTime(Duration time) {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    final secondText = seconds.toString().padLeft(2, '0');

    return '$minutes:$secondText';
  }
}
