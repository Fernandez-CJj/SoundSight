import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/dialogs/composition_dialogs.dart';
import 'package:soundsight/screens/composition/screens/composition_editor_screen.dart';
import 'package:soundsight/screens/composition/services/composition_playback_service.dart';
import 'package:soundsight/screens/composition/services/composition_publish_service.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';
import 'package:soundsight/screens/composition/dialogs/publish_composition_dialog.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionDetailsScreen extends StatefulWidget {
  const CompositionDetailsScreen({
    super.key,
    required this.colors,
    required this.composition,
  });

  final AppThemeColors colors;
  final Composition composition;

  @override
  State<CompositionDetailsScreen> createState() =>
      _CompositionDetailsScreenState();
}

class _CompositionDetailsScreenState extends State<CompositionDetailsScreen> {
  final CompositionService compositionService = CompositionService();
  final CompositionPlaybackService playbackService =
      CompositionPlaybackService();
  final CompositionPublishService publishService = CompositionPublishService();

  late Composition composition;
  late Duration playbackDuration;

  Duration playbackPosition = Duration.zero;

  bool isLoading = false;
  bool isDeleting = false;
  bool isPlaying = false;
  bool isPaused = false;
  bool isPreparingPlayback = false;
  bool isPublishing = false;

  int playbackRunId = 0;

  @override
  void initState() {
    super.initState();
    composition = widget.composition;
    playbackDuration = getCompositionDuration(composition);
  }

  @override
  void dispose() {
    unawaited(playbackService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return PopScope(
      canPop: !isDeleting && !isPublishing,
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          backgroundColor: colors.backgroundColor,
          foregroundColor: colors.primaryColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: const Text(
            'Composition Details',
            style: TextStyle(
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              enabled: !isDeleting && !isPlaying && !isPublishing,
              color: colors.surfaceColor,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') {
                  editComposition();
                }

                if (value == 'delete') {
                  deleteComposition();
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: colors.primaryColor,
                          size: AppIconSizes.sm,
                        ),
                        const Gap(AppSpacing.sm),
                        Text(
                          'Edit Composition',
                          style: TextStyle(color: colors.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: colors.primaryColor,
                          size: AppIconSizes.sm,
                        ),
                        const Gap(AppSpacing.sm),
                        Text(
                          'Delete Composition',
                          style: TextStyle(color: colors.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(color: colors.primaryColor),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    buildOverviewCard(colors),
                    const Gap(AppSpacing.md),
                    buildPlaybackCard(colors),
                    const Gap(AppSpacing.md),
                    buildSummaryCard(colors),
                    const Gap(AppSpacing.md),
                    buildActionsCard(colors),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildOverviewCard(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: buildCardDecoration(colors),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 132,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.borderColor),
            ),
            child: Icon(
              Icons.piano_rounded,
              color: colors.primaryColor,
              size: AppIconSizes.xl,
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  composition.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.sectionTitle,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const Gap(AppSpacing.xs),
                Text(
                  'Piano Solo',
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.label,
                  ),
                ),
                const Gap(AppSpacing.md),
                buildInformationRow(
                  colors: colors,
                  icon: Icons.music_note_rounded,
                  label: 'Key',
                  value: composition.keySignature,
                ),
                const Gap(AppSpacing.sm),
                buildInformationRow(
                  colors: colors,
                  icon: Icons.speed_rounded,
                  label: 'Tempo',
                  value: '${composition.tempo} BPM',
                ),
                const Gap(AppSpacing.sm),
                buildInformationRow(
                  colors: colors,
                  icon: Icons.grid_view_rounded,
                  label: 'Time',
                  value:
                      '${composition.beatsPerMeasure}/${composition.beatUnit}',
                ),
                const Gap(AppSpacing.sm),
                buildInformationRow(
                  colors: colors,
                  icon: Icons.schedule_rounded,
                  label: 'Edited',
                  value: formatDate(
                    composition.updatedAt ?? composition.createdAt,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInformationRow({
    required AppThemeColors colors,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: colors.primaryColor, size: AppIconSizes.sm),
        const Gap(AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPlaybackCard(AppThemeColors colors) {
    final progress = playbackDuration.inMilliseconds == 0
        ? 0.0
        : (playbackPosition.inMilliseconds / playbackDuration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble();

    final status = isPreparingPlayback
        ? 'Loading'
        : isPaused
        ? 'Paused'
        : isPlaying
        ? 'Playing'
        : 'Ready';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: buildCardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Listen to your composition',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? colors.primaryColor
                            : colors.secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      status,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: colors.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryColor),
            ),
          ),
          const Gap(AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(playbackPosition),
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                formatDuration(playbackDuration),
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildPlaybackButton(
                colors: colors,
                icon: Icons.replay_rounded,
                tooltip: 'Play from beginning',
                onTap:
                    composition.notes.isEmpty ||
                        isDeleting ||
                        isPreparingPlayback
                    ? null
                    : restartComposition,
              ),
              const Gap(AppSpacing.md),
              buildPlaybackButton(
                colors: colors,
                icon: isPreparingPlayback
                    ? Icons.hourglass_top_rounded
                    : isPlaying && !isPaused
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: isPreparingPlayback
                    ? 'Loading'
                    : isPlaying && !isPaused
                    ? 'Pause'
                    : 'Play',
                isPrimary: true,
                onTap: isDeleting || isPreparingPlayback
                    ? null
                    : isPlaying && !isPaused
                    ? pauseComposition
                    : playOrResumeComposition,
              ),
              const Gap(AppSpacing.md),
              buildPlaybackButton(
                colors: colors,
                icon: Icons.stop_rounded,
                tooltip: 'Stop',
                onTap: isPlaying || isPaused || isPreparingPlayback
                    ? stopComposition
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPlaybackButton({
    required AppThemeColors colors,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? isEnabled
                  ? colors.primaryColor
                  : colors.borderColor
            : colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: isPrimary ? 72 : 62,
            height: isPrimary ? 62 : 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isPrimary ? null : Border.all(color: colors.borderColor),
            ),
            child: Icon(
              icon,
              size: isPrimary ? AppIconSizes.lg : AppIconSizes.md,
              color: isPrimary
                  ? isEnabled
                        ? colors.backgroundColor
                        : colors.secondaryTextColor
                  : isEnabled
                  ? colors.primaryColor
                  : colors.secondaryTextColor.withOpacity(0.45),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSummaryCard(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: buildCardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Composition Summary',
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.label,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: buildStatisticCard(
                  colors: colors,
                  icon: Icons.library_music_outlined,
                  label: composition.measureCount == 1 ? 'Measure' : 'Measures',
                  value: '${composition.measureCount}',
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: buildStatisticCard(
                  colors: colors,
                  icon: Icons.music_note_rounded,
                  label: composition.notes.length == 1 ? 'Note' : 'Notes',
                  value: '${composition.notes.length}',
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: buildStatisticCard(
                  colors: colors,
                  icon: Icons.schedule_rounded,
                  label: 'Duration',
                  value: formatDuration(playbackDuration),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStatisticCard({
    required AppThemeColors colors,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colors.primaryColor, size: AppIconSizes.md),
          const Gap(AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionsCard(AppThemeColors colors) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: buildCardDecoration(colors),
      child: Column(
        children: [
          buildActionRow(
            colors: colors,
            icon: Icons.publish_rounded,
            title: isPublishing ? 'Publishing...' : 'Publish Composition',
            isLoading: isPublishing,
            onTap: isDeleting || isPlaying || isPublishing
                ? null
                : publishComposition,
          ),
          Divider(height: 1, color: colors.borderColor),
          buildActionRow(
            colors: colors,
            icon: Icons.edit_outlined,
            title: 'Edit Composition',
            onTap: isDeleting || isPlaying || isPublishing
                ? null
                : editComposition,
          ),
          Divider(height: 1, color: colors.borderColor),
          buildActionRow(
            colors: colors,
            icon: Icons.delete_outline_rounded,
            title: isDeleting ? 'Deleting...' : 'Delete Composition',
            isLoading: isDeleting,
            onTap: isDeleting || isPlaying || isPublishing
                ? null
                : deleteComposition,
          ),
        ],
      ),
    );
  }

  Widget buildActionRow({
    required AppThemeColors colors,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final isEnabled = onTap != null;

    return Material(
      color: colors.surfaceColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.borderColor),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primaryColor,
                        ),
                      )
                    : Icon(
                        icon,
                        color: isEnabled
                            ? colors.primaryColor
                            : colors.secondaryTextColor,
                        size: AppIconSizes.md,
                      ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isEnabled
                        ? colors.primaryColor
                        : colors.secondaryTextColor,
                    fontSize: AppTextSizes.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration buildCardDecoration(AppThemeColors colors) {
    return BoxDecoration(
      color: colors.surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: colors.borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(colors.isDarkMode ? 0.16 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Future<void> playOrResumeComposition() async {
    if (isPaused) {
      await playbackService.resume();

      if (!mounted) return;

      setState(() {
        isPlaying = playbackService.isPlaying;
        isPaused = playbackService.isPaused;
      });

      return;
    }

    if (composition.notes.isEmpty) {
      showMessage('This composition does not have any notes yet.');
      return;
    }

    final validationError = compositionService.validateComposition(composition);
    if (validationError != null) {
      showMessage(validationError);
      return;
    }

    final currentRunId = ++playbackRunId;
    var completed = false;

    setState(() {
      isPlaying = true;
      isPaused = false;
      isPreparingPlayback = true;
      playbackPosition = Duration.zero;
      playbackDuration = getCompositionDuration(composition);
    });

    try {
      await playbackService.playComposition(
        composition: composition,
        onPlaybackStarted: () {
          if (!mounted || currentRunId != playbackRunId) return;
          setState(() {
            isPreparingPlayback = false;
          });
        },
        onProgressChanged: (position, total) {
          if (!mounted || currentRunId != playbackRunId) return;

          setState(() {
            playbackPosition = position;

            if (total.inMilliseconds > 0) {
              playbackDuration = total;
            }
          });
        },
      );

      completed = true;
    } catch (_) {
      if (mounted && currentRunId == playbackRunId) {
        showMessage(
          'The composition could not be played. Check the piano audio files.',
        );
      }
    } finally {
      if (mounted && currentRunId == playbackRunId) {
        setState(() {
          isPlaying = false;
          isPaused = false;
          isPreparingPlayback = false;
          playbackPosition = completed ? playbackDuration : Duration.zero;
        });
      }
    }
  }

  Future<void> pauseComposition() async {
    if (!isPlaying || isPaused || isPreparingPlayback) return;

    await playbackService.pause();

    if (!mounted) return;

    setState(() {
      isPlaying = playbackService.isPlaying;
      isPaused = playbackService.isPaused;
    });
  }

  Future<void> stopComposition() async {
    playbackRunId++;

    await playbackService.stop();

    if (!mounted) return;

    setState(() {
      isPlaying = false;
      isPaused = false;
      isPreparingPlayback = false;
      playbackPosition = Duration.zero;
      playbackDuration = getCompositionDuration(composition);
    });
  }

  Future<void> restartComposition() async {
    if (composition.notes.isEmpty) {
      showMessage('This composition does not have any notes yet.');
      return;
    }

    await stopComposition();

    if (!mounted) return;

    await playOrResumeComposition();
  }

  Duration getCompositionDuration(Composition value) {
    if (value.tempo <= 0) return Duration.zero;

    final totalBeats = value.measureCount * value.beatsPerMeasure;
    final beatLength = 4 / value.beatUnit;
    final milliseconds = (totalBeats * beatLength * 60000 / value.tempo)
        .round();

    return Duration(milliseconds: milliseconds);
  }

  String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Unavailable';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> publishComposition() async {
    if (composition.notes.isEmpty) {
      showMessage('Add at least one note before publishing.');
      return;
    }

    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (_) {
        return PublishCompositionDialog(
          colors: widget.colors,
          composition: composition,
        );
      },
    );

    if (shouldPublish != true || !mounted) return;

    setState(() {
      isPublishing = true;
    });

    try {
      await publishService.publishComposition(composition);

      if (!mounted) return;

      showMessage('Composition published successfully.');
    } catch (_) {
      if (!mounted) return;

      showMessage(
        'The composition could not be published. '
        'Make sure the backend is running.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isPublishing = false;
        });
      }
    }
  }

  Future<void> editComposition() async {
    if (isPlaying || isPublishing) return;

    final savedCompositionId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CompositionEditorScreen(
          colors: widget.colors,
          composition: composition,
        ),
      ),
    );

    if (!mounted || savedCompositionId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final updatedComposition = await compositionService.getComposition(
        savedCompositionId,
      );

      if (!mounted) return;

      if (updatedComposition == null) {
        showMessage('The updated composition could not be loaded.');
        return;
      }

      setState(() {
        composition = updatedComposition;
        playbackPosition = Duration.zero;
        playbackDuration = getCompositionDuration(updatedComposition);
      });
    } catch (_) {
      if (mounted) {
        showMessage('The updated composition could not be loaded.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteComposition() async {
    if (isPlaying || isPublishing) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return DeleteCompositionDialog(
          colors: widget.colors,
          compositionTitle: composition.title,
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await compositionService.deleteComposition(composition.id);

      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      showMessage('The composition could not be deleted.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
