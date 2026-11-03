import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// A consistent destructive cue for every swipe-to-delete or remove action.
class DeleteSwipeBackground extends StatelessWidget {
  const DeleteSwipeBackground({
    super.key,
    required this.colors,
    this.label,
    this.radius = AppRadius.md,
    this.margin = EdgeInsets.zero,
  });

  final AppThemeColors colors;
  final String? label;
  final double radius;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: colors.destructiveColor,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_outline_rounded, color: colors.onDestructiveColor),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label ?? context.l10n.delete,
          style: TextStyle(
            color: colors.onDestructiveColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
