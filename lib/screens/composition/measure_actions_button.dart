import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

enum MeasureAction {
  addAfter,
  insertBefore,
  duplicate,
  moveLeft,
  moveRight,
  delete,
}

class MeasureActionsButton extends StatelessWidget {
  const MeasureActionsButton({
    super.key,
    required this.colors,
    required this.enabled,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.canDelete,
    required this.onSelected,
    this.compact = false,
  });

  final AppThemeColors colors;
  final bool enabled;
  final bool canMoveLeft;
  final bool canMoveRight;
  final bool canDelete;
  final ValueChanged<MeasureAction> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MeasureAction>(
      tooltip: 'Measure actions',
      enabled: enabled,
      color: colors.surfaceColor,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          buildItem(
            action: MeasureAction.addAfter,
            icon: Icons.add_rounded,
            label: 'Add measure after',
          ),
          buildItem(
            action: MeasureAction.insertBefore,
            icon: Icons.vertical_align_top_rounded,
            label: 'Insert measure before',
          ),
          buildItem(
            action: MeasureAction.duplicate,
            icon: Icons.copy_rounded,
            label: 'Duplicate measure',
          ),
          buildItem(
            action: MeasureAction.moveLeft,
            icon: Icons.arrow_back_rounded,
            label: 'Move measure left',
            enabled: canMoveLeft,
          ),
          buildItem(
            action: MeasureAction.moveRight,
            icon: Icons.arrow_forward_rounded,
            label: 'Move measure right',
            enabled: canMoveRight,
          ),
          const PopupMenuDivider(),
          buildItem(
            action: MeasureAction.delete,
            icon: Icons.delete_outline_rounded,
            label: 'Delete measure',
            enabled: canDelete,
            destructive: true,
          ),
        ];
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: Container(
          height: compact ? 44 : 50,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_music_outlined,
                color: colors.primaryColor,
                size: AppIconSizes.sm,
              ),
              if (!compact) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Measure',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              Icon(
                Icons.arrow_drop_down_rounded,
                color: colors.secondaryTextColor,
                size: AppIconSizes.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<MeasureAction> buildItem({
    required MeasureAction action,
    required IconData icon,
    required String label,
    bool enabled = true,
    bool destructive = false,
  }) {
    final foreground = destructive ? Colors.red : colors.primaryColor;

    return PopupMenuItem<MeasureAction>(
      value: action,
      enabled: enabled,
      child: Row(
        children: [
          Icon(
            icon,
            size: AppIconSizes.sm,
            color: enabled ? foreground : colors.secondaryTextColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: enabled ? foreground : colors.secondaryTextColor,
              fontSize: AppTextSizes.label,
            ),
          ),
        ],
      ),
    );
  }
}
