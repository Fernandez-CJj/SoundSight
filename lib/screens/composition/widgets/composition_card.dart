import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionCard extends StatelessWidget {
  const CompositionCard({
    super.key,
    required this.colors,
    required this.composition,
    required this.isDeleting,
    required this.isPlaying,
    required this.isPlaybackBusy,
    required this.onOpen,
    required this.onEdit,
    required this.onPlay,
    required this.onDelete,
  });

  final AppThemeColors colors;
  final Composition composition;
  final bool isDeleting;
  final bool isPlaying;
  final bool isPlaybackBusy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final editedDate = composition.updatedAt ?? composition.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPlaying ? colors.primaryColor : colors.borderColor,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: isDeleting ? null : onOpen,
            contentPadding: EdgeInsets.all(AppSpacing.md),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.borderColor),
              ),
              child: Icon(
                isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.music_note_rounded,
                color: colors.primaryColor,
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
                    color: colors.surfaceColor,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.secondaryTextColor,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) {
                      return [
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
          Divider(height: 1, color: colors.borderColor),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: isDeleting ? null : onEdit,
                      icon: Icon(Icons.edit_outlined, size: AppIconSizes.sm),
                      label: Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
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
                      onPressed: isDeleting || isPlaybackBusy ? null : onPlay,
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
