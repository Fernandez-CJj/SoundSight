import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/services/composition_publish_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionCard extends StatelessWidget {
  const CompositionCard({
    super.key,
    required this.colors,
    required this.composition,
    required this.isDeleting,
    required this.isPlaying,
    required this.isPlaybackBusy,
    required this.publicationAction,
    required this.activePublicationAction,
    required this.isPublicationStatusLoading,
    required this.isGeneratingFiles,
    required this.onOpen,
    required this.onPublicationAction,
    required this.onUnpublish,
    required this.onPlay,
    required this.onRetryGeneration,
    required this.onDelete,
  });

  final AppThemeColors colors;
  final Composition composition;
  final bool isDeleting;
  final bool isPlaying;
  final bool isPlaybackBusy;
  final CompositionPublicationAction publicationAction;
  final CompositionPublicationAction? activePublicationAction;
  final bool isPublicationStatusLoading;
  final bool isGeneratingFiles;
  final VoidCallback onOpen;
  final VoidCallback onPublicationAction;
  final VoidCallback onUnpublish;
  final VoidCallback onPlay;
  final VoidCallback onRetryGeneration;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final editedDate = composition.updatedAt ?? composition.createdAt;
    final isRecording =
        composition.creationMethod == Composition.recordingCreationMethod;
    final isPublished =
        publicationAction != CompositionPublicationAction.publish;
    final isPublicationBusy = activePublicationAction != null;
    final hasUnpublishedChanges =
        publicationAction == CompositionPublicationAction.publishUpdate;
    final filesNeedAttention = !composition.generatedFilesAreCurrent;
    final filesAreOutOfDate = composition.generatedFilesAreOutOfDate;
    final generationIsRunning =
        isGeneratingFiles ||
        composition.generationStatus == Composition.generatingStatus;
    final generationColor = generationIsRunning
        ? colors.primaryColor
        : filesAreOutOfDate
        ? const Color(0xFFF59E0B)
        : const Color(0xFFDC2626);
    final creationMethodColor = isRecording
        ? (colors.isDarkMode
              ? const Color(0xFFFF8A80)
              : const Color(0xFFB3261E))
        : (colors.isDarkMode
              ? const Color(0xFF8AB4F8)
              : const Color(0xFF245E9C));

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPlaying
              ? colors.primaryColor
              : filesNeedAttention
              ? generationColor
              : colors.borderColor,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: isDeleting || isPublicationBusy ? null : onOpen,
            contentPadding: EdgeInsets.all(AppSpacing.md),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: creationMethodColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: creationMethodColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                isPlaying
                    ? Icons.graphic_eq_rounded
                    : isRecording
                    ? Icons.mic_rounded
                    : Icons.edit_note_rounded,
                color: creationMethodColor,
                size: AppIconSizes.lg,
              ),
            ),
            title: Text(
              composition.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCreationMethodBadge(
                    isRecording: isRecording,
                    color: creationMethodColor,
                  ),
                  Gap(AppSpacing.xs),
                  Text(
                    '${composition.tempo} BPM - '
                    '${composition.keySignature}',
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.caption,
                    ),
                  ),
                  Gap(2),
                  Text(
                    formatEditedDate(editedDate),
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.caption,
                    ),
                  ),
                ],
              ),
            ),
            trailing: isDeleting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.primaryColor,
                    ),
                  )
                : PopupMenuButton<String>(
                    enabled: !isPublicationBusy,
                    color: colors.surfaceColor,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.secondaryTextColor,
                    ),
                    onSelected: (value) {
                      if (value == 'unpublish') {
                        onUnpublish();
                      }

                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) {
                      return [
                        if (hasUnpublishedChanges)
                          PopupMenuItem<String>(
                            value: 'unpublish',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.public_off_rounded,
                                  color: colors.primaryColor,
                                  size: AppIconSizes.sm,
                                ),
                                Gap(AppSpacing.sm),
                                Text(
                                  'Unpublish',
                                  style: TextStyle(color: colors.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: colors.primaryColor,
                                size: AppIconSizes.sm,
                              ),
                              Gap(AppSpacing.sm),
                              Text(
                                'Delete',
                                style: TextStyle(color: colors.primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
          ),
          if (filesNeedAttention) ...[
            Divider(height: 1, color: colors.borderColor),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              color: generationColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  if (generationIsRunning)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: generationColor,
                      ),
                    )
                  else
                    Icon(
                      filesAreOutOfDate
                          ? Icons.update_rounded
                          : Icons.warning_amber_rounded,
                      color: generationColor,
                      size: AppIconSizes.md,
                    ),
                  Gap(AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          generationIsRunning
                              ? 'Preparing your music files'
                              : filesAreOutOfDate
                              ? 'Music files need updating'
                              : 'Music files are not ready',
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Gap(2),
                        Text(
                          filesAreOutOfDate
                              ? 'Your changes are saved, but the available '
                                    'files contain an older version.'
                              : 'Your sheet music and playback files are not '
                                    'ready yet.',
                          style: TextStyle(
                            color: colors.secondaryTextColor,
                            fontSize: AppTextSizes.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!generationIsRunning) ...[
                    Gap(AppSpacing.sm),
                    TextButton(
                      onPressed: isDeleting ? null : onRetryGeneration,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ],
          Divider(height: 1, color: colors.borderColor),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed:
                          isDeleting ||
                              isPlaybackBusy ||
                              isPublicationBusy ||
                              isPublicationStatusLoading
                          ? null
                          : onPublicationAction,
                      icon: isPublicationBusy || isPublicationStatusLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: colors.primaryColor,
                              ),
                            )
                          : Icon(
                              hasUnpublishedChanges
                                  ? Icons.update_rounded
                                  : isPublished
                                  ? Icons.public_off_rounded
                                  : Icons.publish_rounded,
                              size: AppIconSizes.sm,
                            ),
                      label: Text(
                        isPublicationStatusLoading
                            ? 'Checking...'
                            : isPublicationBusy
                            ? activePublicationAction ==
                                      CompositionPublicationAction.unpublish
                                  ? 'Unpublishing...'
                                  : 'Publishing...'
                            : hasUnpublishedChanges
                            ? 'Publish Update'
                            : isPublished
                            ? 'Unpublish'
                            : 'Publish',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        disabledForegroundColor: colors.secondaryTextColor,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                ),
                Gap(AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed:
                          isDeleting || isPlaybackBusy || isPublicationBusy
                          ? null
                          : onPlay,
                      icon: isPlaybackBusy && isPlaying
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: colors.backgroundColor,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              size: AppIconSizes.md,
                            ),
                      label: Text(
                        isPlaybackBusy && isPlaying
                            ? 'Please wait'
                            : isPlaying
                            ? 'Stop'
                            : 'Play',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCreationMethodBadge({
    required bool isRecording,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecording ? Icons.mic_rounded : Icons.edit_note_rounded,
            size: 14,
            color: color,
          ),
          Gap(4),
          Text(
            isRecording ? 'Recording' : 'Manual',
            style: TextStyle(
              color: color,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String formatEditedDate(DateTime? date) {
    if (date == null) {
      return 'Not saved yet';
    }

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

    return 'Last edited ${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}
