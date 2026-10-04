import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

enum RecordingCompletionAction {
  discard,
  generate,
}

class RecordingCompletionDialog extends StatelessWidget {
  const RecordingCompletionDialog({
    super.key,
    required this.colors,
    required this.compositionTitle,
    required this.durationText,
    required this.noteCount,
  });

  final AppThemeColors colors;
  final String compositionTitle;
  final String durationText;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colors.surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.borderColor),
              ),
              child: Icon(
                Icons.video_file_rounded,
                color: colors.primaryColor,
                size: AppIconSizes.md,
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Text(
                'Recording Complete',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate composition files from this recording or discard it '
              'and record again.',
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                height: 1.4,
              ),
            ),
            const Gap(AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.borderColor),
              ),
              child: Column(
                children: [
                  buildInformationRow(
                    label: 'Title',
                    value: compositionTitle,
                  ),
                  const Gap(AppSpacing.sm),
                  buildInformationRow(
                    label: 'Duration',
                    value: durationText,
                  ),
                  const Gap(AppSpacing.sm),
                  buildInformationRow(
                    label: 'Captured Notes',
                    value: '$noteCount',
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        RecordingCompletionAction.discard,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primaryColor,
                      side: BorderSide(color: colors.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        RecordingCompletionAction.generate,
                      );
                    },
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: AppIconSizes.sm,
                    ),
                    label: const Text('Generate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryColor,
                      foregroundColor: colors.backgroundColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInformationRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
        ),
        const Gap(AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
