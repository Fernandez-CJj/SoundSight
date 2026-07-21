import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionHistoryControls extends StatelessWidget {
  const CompositionHistoryControls({
    super.key,
    required this.colors,
    required this.canUndo,
    required this.canRedo,
    required this.canCopy,
    required this.canPaste,
    required this.canSelectAll,
    required this.canToggleTie,
    required this.isTieActive,
    required this.canDeleteSelection,
    required this.canDeleteChord,
    required this.onUndo,
    required this.onRedo,
    required this.onCopy,
    required this.onPaste,
    required this.onSelectAll,
    required this.onToggleTie,
    required this.onDeleteSelection,
    required this.onDeleteChord,
    this.enabled = true,
    this.compact = false,
  });

  final AppThemeColors colors;
  final bool canUndo;
  final bool canRedo;
  final bool canCopy;
  final bool canPaste;
  final bool canSelectAll;
  final bool canToggleTie;
  final bool isTieActive;
  final bool canDeleteSelection;
  final bool canDeleteChord;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onSelectAll;
  final VoidCallback onToggleTie;
  final VoidCallback onDeleteSelection;
  final VoidCallback onDeleteChord;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _HistoryAction(
        label: 'Undo',
        icon: Icons.undo_rounded,
        available: canUndo,
        onPressed: onUndo,
      ),
      _HistoryAction(
        label: 'Redo',
        icon: Icons.redo_rounded,
        available: canRedo,
        onPressed: onRedo,
      ),
      _HistoryAction(
        label: 'Copy',
        icon: Icons.content_copy_rounded,
        available: canCopy,
        onPressed: onCopy,
      ),
      _HistoryAction(
        label: 'Paste',
        icon: Icons.content_paste_rounded,
        available: canPaste,
        onPressed: onPaste,
      ),
      _HistoryAction(
        label: 'Select All',
        icon: Icons.select_all_rounded,
        available: canSelectAll,
        onPressed: onSelectAll,
      ),
      _HistoryAction(
        label: isTieActive ? 'Remove Tie' : 'Tie to Next',
        icon: isTieActive
            ? Icons.link_off_rounded
            : Icons.link_rounded,
        available: canToggleTie,
        onPressed: onToggleTie,
      ),
      _HistoryAction(
        label: 'Delete Selection',
        icon: Icons.delete_outline_rounded,
        available: canDeleteSelection,
        onPressed: onDeleteSelection,
        destructive: true,
      ),
      _HistoryAction(
        label: 'Delete Whole Chord',
        icon: Icons.layers_clear_rounded,
        available: canDeleteChord,
        onPressed: onDeleteChord,
        destructive: true,
      ),
    ];

    if (compact) {
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.borderColor),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const Gap(2),
                _CompactHistoryButton(
                  colors: colors,
                  action: actions[index],
                  enabled: enabled,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDarkMode ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: colors.primaryColor,
                size: AppIconSizes.md,
              ),
              const Gap(AppSpacing.xs),
              Text(
                'History and editing',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = constraints.maxWidth >= 620
                  ? (constraints.maxWidth - (AppSpacing.sm * 3)) / 4
                  : constraints.maxWidth >= 360
                  ? (constraints.maxWidth - AppSpacing.sm) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: buttonWidth,
                      child: _LabeledHistoryButton(
                        colors: colors,
                        action: action,
                        enabled: enabled,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompactHistoryButton extends StatelessWidget {
  const _CompactHistoryButton({
    required this.colors,
    required this.action,
    required this.enabled,
  });

  final AppThemeColors colors;
  final _HistoryAction action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && action.available;
    final activeColor = action.destructive
        ? _destructiveColor(colors)
        : colors.primaryColor;

    return Tooltip(
      message: action.label,
      child: IconButton(
        onPressed: canPress ? action.onPressed : null,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        color: activeColor,
        disabledColor: colors.secondaryTextColor.withOpacity(0.4),
        iconSize: AppIconSizes.sm,
        icon: Icon(action.icon),
      ),
    );
  }
}

class _LabeledHistoryButton extends StatelessWidget {
  const _LabeledHistoryButton({
    required this.colors,
    required this.action,
    required this.enabled,
  });

  final AppThemeColors colors;
  final _HistoryAction action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && action.available;
    final activeColor = action.destructive
        ? _destructiveColor(colors)
        : colors.primaryColor;

    return OutlinedButton.icon(
      onPressed: canPress ? action.onPressed : null,
      icon: Icon(action.icon, size: AppIconSizes.sm),
      label: Text(
        action.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        foregroundColor: activeColor,
        disabledForegroundColor: colors.secondaryTextColor.withOpacity(0.4),
        side: BorderSide(
          color: canPress ? activeColor : colors.borderColor,
        ),
        textStyle: const TextStyle(
          fontSize: AppTextSizes.caption,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class _HistoryAction {
  const _HistoryAction({
    required this.label,
    required this.icon,
    required this.available,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final bool available;
  final VoidCallback onPressed;
  final bool destructive;
}

Color _destructiveColor(AppThemeColors colors) {
  return colors.isDarkMode
      ? const Color(0xFFF87171)
      : const Color(0xFFDC2626);
}
