import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class PublishCompositionDialog extends StatelessWidget {
  const PublishCompositionDialog({
    super.key,
    required this.colors,
    required this.composition,
  });

  final AppThemeColors colors;
  final Composition composition;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
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
              Icons.publish_rounded,
              color: colors.primaryColor,
              size: AppIconSizes.md,
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              'Publish Composition',
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
            'Publish "${composition.title}"?',
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            'A PDF music sheet will be created and shared with other '
            'SoundSight users.',
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
                  label: 'Key',
                  value: composition.keySignature,
                ),
                const Gap(AppSpacing.sm),
                buildInformationRow(
                  label: 'Tempo',
                  value: '${composition.tempo} BPM',
                ),
                const Gap(AppSpacing.sm),
                buildInformationRow(
                  label: 'Time Signature',
                  value:
                      '${composition.beatsPerMeasure}/${composition.beatUnit}',
                ),
                const Gap(AppSpacing.sm),
                buildInformationRow(
                  label: 'Measures',
                  value: '${composition.measureCount}',
                ),
                const Gap(AppSpacing.sm),
                buildInformationRow(
                  label: 'Notes',
                  value: '${composition.notes.length}',
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, true);
          },
          icon: const Icon(
            Icons.publish_rounded,
            size: AppIconSizes.sm,
          ),
          label: const Text('Publish'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.backgroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ],
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
        Text(
          value,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.caption,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
