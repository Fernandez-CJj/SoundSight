import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class LayerNotesControls extends StatelessWidget {
  const LayerNotesControls({
    super.key,
    required this.colors,
    required this.isLayerMode,
    required this.measureIndex,
    required this.startBeat,
    required this.enabled,
    required this.onLayerModeChanged,
    this.compact = false,
  });

  final AppThemeColors colors;
  final bool isLayerMode;
  final int measureIndex;
  final double startBeat;
  final bool enabled;
  final ValueChanged<bool> onLayerModeChanged;
  final bool compact;

  String get positionLabel {
    final beat = startBeat + 1;
    final roundedBeat = beat.roundToDouble();
    final beatLabel = (beat - roundedBeat).abs() < 0.0001
        ? roundedBeat.toInt().toString()
        : beat
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
    return 'Measure ${measureIndex + 1} · Beat $beatLabel';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isLayerMode
              ? colors.primaryColor.withValues(alpha: 0.08)
              : colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isLayerMode ? colors.primaryColor : colors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.layers_rounded,
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
                    'Layer Notes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isLayerMode ? positionLabel : 'Independent notes',
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
            Transform.scale(
              scale: 0.78,
              child: Switch.adaptive(
                value: isLayerMode,
                activeThumbColor: colors.primaryColor,
                onChanged: enabled ? onLayerModeChanged : null,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isLayerMode
            ? colors.primaryColor.withValues(alpha: 0.08)
            : colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isLayerMode ? colors.primaryColor : colors.borderColor,
        ),
      ),
      child: Row(
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
              Icons.layers_rounded,
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
                  'Layer Notes',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  isLayerMode
                      ? '$positionLabel — add the next note here.'
                      : 'Add shorter notes while another note continues playing.',
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isLayerMode,
            activeThumbColor: colors.primaryColor,
            onChanged: enabled ? onLayerModeChanged : null,
          ),
        ],
      ),
    );
  }
}
