import 'dart:io';

import 'package:flutter/material.dart';
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
    required this.detectedTempo,
    required this.measureCount,
  });

  final AppThemeColors colors;
  final String compositionTitle;
  final String durationText;
  final int noteCount;
  final String videoPath;
  final int detectedTempo;
  final int measureCount;

  @override
  State<RecordingCompletionDialog> createState() =>
      _RecordingCompletionDialogState();
}

class _RecordingCompletionDialogState extends State<RecordingCompletionDialog> {
  late final VideoPlayerController videoController;
  bool videoReady = false;

  @override
  void initState() {
    super.initState();
    videoController = VideoPlayerController.file(File(widget.videoPath));
    videoController.initialize().then((_) {
      if (mounted) setState(() => videoReady = true);
    });
  }

  @override
  void dispose() {
    videoController.dispose();
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
                        AspectRatio(
                          aspectRatio: videoReady
                              ? videoController.value.aspectRatio
                              : 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: ColoredBox(
                              color: Colors.black,
                              child: videoReady
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        VideoPlayer(videoController),
                                        Center(
                                          child: IconButton.filled(
                                            onPressed: () {
                                              setState(() {
                                                videoController.value.isPlaying
                                                    ? videoController.pause()
                                                    : videoController.play();
                                              });
                                            },
                                            icon: Icon(
                                              videoController.value.isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          RecordingCompletionAction.discard,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primaryColor,
                          side: BorderSide(color: colors.borderColor),
                        ),
                        child: Text(context.l10n.recordAgain),
                      ),
                    ),
                    Gap(AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          RecordingCompletionAction.generate,
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(context.l10n.generate),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryColor,
                          foregroundColor: colors.backgroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
