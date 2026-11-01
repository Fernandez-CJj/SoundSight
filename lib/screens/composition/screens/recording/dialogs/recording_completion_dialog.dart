import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

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
  static const videoChannel = MethodChannel('soundsight/recorded_video');
  bool isSavingVideo = false;
  bool videoSaved = false;
  String? saveError;

  Future<void> saveVideo() async {
    if (isSavingVideo || videoSaved) return;
    setState(() {
      isSavingVideo = true;
      saveError = null;
    });
    try {
      final safeTitle = widget.compositionTitle
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final name = safeTitle.isEmpty ? 'SoundSight recording.mp4' : '$safeTitle.mp4';
      final saved = await videoChannel.invokeMethod<bool>('saveVideo', {
        'path': widget.videoPath,
        'name': name,
      });
      if (mounted && saved == true) setState(() => videoSaved = true);
    } catch (_) {
      if (mounted) {
        setState(() => saveError = context.l10n.recordedVideoSaveFailed);
      }
    } finally {
      if (mounted) setState(() => isSavingVideo = false);
    }
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
                        OutlinedButton.icon(
                          onPressed: isSavingVideo || videoSaved ? null : saveVideo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryColor,
                            side: BorderSide(color: colors.borderColor),
                          ),
                          icon: isSavingVideo
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  videoSaved
                                      ? Icons.check_rounded
                                      : Icons.download_rounded,
                                ),
                          label: Text(
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSavingVideo ? null : () => Navigator.pop(
                          context,
                          RecordingCompletionAction.discard,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primaryColor,
                          side: BorderSide(color: colors.borderColor),
                        ),
                        child: Text(
                          context.l10n.recordAgain,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Gap(AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSavingVideo ? null : () => Navigator.pop(
                          context,
                          RecordingCompletionAction.generate,
                        ),
                        child: Text(
                          context.l10n.generate,
                          textAlign: TextAlign.center,
                        ),
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
