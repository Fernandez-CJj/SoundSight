import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class ChordModeControls extends StatelessWidget {
  const ChordModeControls({
    super.key,
    required this.colors,
    required this.isChordMode,
    required this.isBuildingChord,
    required this.chordNoteCount,
    required this.enabled,
    required this.onChordModeChanged,
    required this.onFinishChord,
    this.compact = false,
  });

  final AppThemeColors colors;
  final bool isChordMode;
  final bool isBuildingChord;
  final int chordNoteCount;
  final bool enabled;
  final ValueChanged<bool> onChordModeChanged;
  final VoidCallback onFinishChord;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isChordMode
              ? colors.primaryColor.withOpacity(0.08)
              : colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isChordMode ? colors.primaryColor : colors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.piano_rounded,
              size: AppIconSizes.sm,
              color: colors.primaryColor,
            ),
            const Gap(AppSpacing.xs),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chord Mode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isBuildingChord
                        ? '$chordNoteCount notes'
                        : 'Allow stacking',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isBuildingChord) ...[
              const Gap(AppSpacing.xs),
              _FinishButton(
                colors: colors,
                enabled: enabled,
                compact: true,
                onPressed: onFinishChord,
              ),
            ],
            Transform.scale(
              scale: 0.78,
              child: Switch.adaptive(
                value: isChordMode,
                activeColor: colors.primaryColor,
                onChanged: enabled ? onChordModeChanged : null,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isChordMode
            ? colors.primaryColor.withOpacity(0.08)
            : colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isChordMode ? colors.primaryColor : colors.borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Icon(
                  Icons.piano_rounded,
                  color: colors.primaryColor,
                  size: AppIconSizes.md,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chord Mode',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Allow multiple notes to start on the same beat.',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isChordMode,
                activeColor: colors.primaryColor,
                onChanged: enabled ? onChordModeChanged : null,
              ),
            ],
          ),
          if (isBuildingChord) ...[
            const Gap(AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$chordNoteCount ${chordNoteCount == 1 ? 'note' : 'notes'} combined',
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _FinishButton(
                  colors: colors,
                  enabled: enabled,
                  onPressed: onFinishChord,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FinishButton extends StatelessWidget {
  const _FinishButton({
    required this.colors,
    required this.enabled,
    required this.onPressed,
    this.compact = false,
  });

  final AppThemeColors colors;
  final bool enabled;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 30 : 38,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryColor,
          foregroundColor: colors.backgroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          ),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: Text(
          compact ? 'Done' : 'Finish Chord',
          style: TextStyle(
            fontSize: AppTextSizes.caption,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
