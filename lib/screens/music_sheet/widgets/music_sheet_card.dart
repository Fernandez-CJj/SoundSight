import 'package:soundsight/widgets/processing_job_card.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/widgets/delete_swipe_background.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class MusicSheetCard extends StatelessWidget {
  const MusicSheetCard({
    super.key,
    required this.colors,
    required this.dismissKey,
    required this.title,
    required this.type,
    required this.pageCount,
    this.durationMs = 0,
    this.jobId,
    this.jobStatus,
    required this.dateText,
    required this.isDeleting,
    required this.onView,
    required this.onRename,
    required this.onDelete,
  });

  final String? jobId;
  final String? jobStatus;
  final AppThemeColors colors;
  final String dismissKey;
  final String title;
  final String type;
  final int pageCount;
  final int durationMs;
  final String dateText;
  final bool isDeleting;
  final VoidCallback onView;
  final VoidCallback onRename;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final isPdf = type == 'pdf';
    final isAudio = type == 'audio';
    final typeColor = isAudio
        ? colors.synthesiaResultColor
        : isPdf
        ? colors.sightReadingResultColor
        : colors.arPerformanceResultColor;
    final duration = Duration(milliseconds: durationMs);
    final audioDuration =
        '${duration.inMinutes}:'
        '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(dismissKey),
      direction: isDeleting || jobId != null
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: DeleteSwipeBackground(colors: colors),
      child: Material(
        color: colors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDeleting ? null : onView,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isAudio
                            ? Icons.audio_file_rounded
                            : isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.library_music_rounded,
                        color: typeColor,
                        size: 25,
                      ),
                    ),
                    const Gap(AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primaryColor,
                              fontSize: AppTextSizes.body,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(AppSpacing.xs),
                          Text(
                            isAudio
                                ? '${context.l10n.audioFileType} \u00b7 $audioDuration'
                                : '${context.l10n.pageCount(pageCount)} \u00b7 ${isPdf ? context.l10n.pdf : context.l10n.images}',
                            style: TextStyle(
                              color: colors.secondaryTextColor,
                              fontSize: AppTextSizes.caption,
                            ),
                          ),
                          if (dateText.isNotEmpty) ...[
                            const Gap(AppSpacing.xs),
                            Text(
                              dateText,
                              style: TextStyle(
                                color: colors.secondaryTextColor,
                                fontSize: AppTextSizes.caption,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isDeleting)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.primaryColor,
                        ),
                      )
                    else
                      PopupMenuButton<String>(
                        color: colors.surfaceColor,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: colors.secondaryTextColor,
                        ),
                        onSelected: (value) {
                          if (value == 'rename') onRename();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            enabled: jobId == null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: colors.primaryColor,
                                  size: 20,
                                ),
                                const Gap(AppSpacing.sm),
                                Text(
                                  context.l10n.rename,
                                  style: TextStyle(color: colors.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (ProcessingJobCard.isVisible(jobStatus)) ...[
                  const Gap(AppSpacing.sm + AppSpacing.xs),
                  ProcessingJobCard(
                    colors: colors,
                    status: jobStatus,
                    jobId: jobId,
                    embedded: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
