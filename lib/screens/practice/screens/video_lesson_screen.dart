import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoLessonScreen extends StatefulWidget {
  const VideoLessonScreen({
    super.key,
    required this.title,
    required this.videoAssetPath,
    this.onStartQuiz,
    this.onViewPdf,
  });

  final String title;
  final String videoAssetPath;
  final VoidCallback? onStartQuiz;
  final VoidCallback? onViewPdf;

  @override
  State<VideoLessonScreen> createState() {
    return _VideoLessonScreenState();
  }
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
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
    videoController = VideoPlayerController.asset(widget.videoAssetPath);

    videoInitialization = videoController.initialize();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    videoController.dispose();
    super.dispose();
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
                  return const Center(
                    child: Text(
                      'Could not load the video.',
                      style: TextStyle(color: Colors.white),
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
                                ? 'Pause video'
                                : 'Play video',
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  tooltip: 'Back to Practice',
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ),
          ),
<<<<<<< HEAD
          // Show lesson resources together at the upper-right of the video.
          if (controlsVisible &&
              (widget.onStartQuiz != null || widget.onViewPdf != null))
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                left: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onViewPdf != null) ...[
                        _LessonActionButton(
                          colorScheme: colorScheme,
                          icon: Icons.picture_as_pdf_outlined,
                          label: 'View PDF',
                          onPressed: () async {
                            await videoController.pause();
                            widget.onViewPdf?.call();
                          },
=======
          Positioned(
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
                    onPressed: () async {
                      await SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      if (!context.mounted) return;

                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const Level1Screen()),
                      );
                      if (!context.mounted) return;

                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                    },
                    icon: const Icon(Icons.quiz_outlined, size: 20),
                    label: const Text(
                      'Start Quiz',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
>>>>>>> b1fdf03620384fc72b0adf8f839c1ac7c112d170
                        ),
                        if (widget.onStartQuiz != null)
                          const SizedBox(width: 8),
                      ],
                      if (widget.onStartQuiz != null)
                        _LessonActionButton(
                          colorScheme: colorScheme,
                          icon: Icons.quiz_outlined,
                          label: 'Start Quiz',
                          onPressed: () async {
                            // Stop video and audio before opening the quiz route.
                            await videoController.pause();
                            widget.onStartQuiz?.call();
                          },
                        ),
                    ],
                  ),
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

class _LessonActionButton extends StatelessWidget {
  const _LessonActionButton({
    required this.colorScheme,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final ColorScheme colorScheme;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 4)),
      ],
    ),
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.onPrimary.withValues(alpha: 0.3)),
        ),
      ),
    ),
  );
}
