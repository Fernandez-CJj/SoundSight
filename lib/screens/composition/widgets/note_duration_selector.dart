import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class NoteDurationSelector extends StatelessWidget {
  const NoteDurationSelector({
    super.key,
    required this.colors,
    required this.selectedDuration,
    required this.beatsPerMeasure,
    required this.beatUnit,
    required this.onDurationSelected,
    this.compact = false,
    this.enabled = true,
    this.helperText,
    this.showAutomatic = false,
    this.automaticSelected = false,
    this.onAutomaticSelected,
  });

  final AppThemeColors colors;
  final double selectedDuration;
  final int beatsPerMeasure;
  final int beatUnit;
  final ValueChanged<double> onDurationSelected;
  final bool compact;
  final bool enabled;
  final String? helperText;
  final bool showAutomatic;
  final bool automaticSelected;
  final VoidCallback? onAutomaticSelected;

  @override
  Widget build(BuildContext context) {
    final allOptions = beatUnit == 8
        ? const [
            _DurationOption('Whole', 8, Icons.circle_outlined),
            _DurationOption('Dotted Half', 6, Icons.more_horiz_rounded),
            _DurationOption('Half', 4, Icons.music_note_outlined),
            _DurationOption('Dotted Quarter', 3, Icons.more_horiz_rounded),
            _DurationOption('Quarter', 2, Icons.music_note_rounded),
            _DurationOption('Dotted Eighth', 1.5, Icons.more_horiz_rounded),
            _DurationOption('Eighth', 1, Icons.queue_music_rounded),
            _DurationOption('Triplet', 2 / 3, Icons.looks_3_outlined),
            _DurationOption('Sixteenth', 0.5, Icons.double_arrow_rounded),
          ]
        : const [
            _DurationOption('Whole', 4, Icons.circle_outlined),
            _DurationOption('Dotted Half', 3, Icons.more_horiz_rounded),
            _DurationOption('Half', 2, Icons.music_note_outlined),
            _DurationOption('Dotted Quarter', 1.5, Icons.more_horiz_rounded),
            _DurationOption('Quarter', 1, Icons.music_note_rounded),
            _DurationOption('Dotted Eighth', 0.75, Icons.more_horiz_rounded),
            _DurationOption('Triplet', 2 / 3, Icons.looks_3_outlined),
            _DurationOption('Eighth', 0.5, Icons.queue_music_rounded),
            _DurationOption('Sixteenth', 0.25, Icons.double_arrow_rounded),
          ];

    final options = allOptions.where((option) {
      return option.beats <= beatsPerMeasure;
    }).toList();

    final selectedOption = options.firstWhere(
      (option) => _sameDuration(selectedDuration, option.beats),
      orElse: () => options.first,
    );

    return Tooltip(
      message: helperText ?? 'Choose the length before tapping a piano key.',
      child: Material(
        color: colors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            compact ? AppRadius.md : AppRadius.lg,
          ),
          side: BorderSide(color: colors.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => _showDurationDialog(context, options) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: SizedBox(
              height: compact ? 60 : 78,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? AppSpacing.sm : AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 38 : 44,
                      height: compact ? 38 : 44,
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        automaticSelected
                            ? Icons.auto_mode_rounded
                            : selectedOption.icon,
                        color: colors.primaryColor,
                        size: compact ? 20 : AppIconSizes.md,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration',
                            style: TextStyle(
                              color: colors.secondaryTextColor,
                              fontSize: AppTextSizes.caption,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            automaticSelected
                                ? 'Automatic'
                                : selectedOption.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primaryColor,
                              fontSize: AppTextSizes.label,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.secondaryTextColor,
                      size: AppIconSizes.md,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDurationDialog(
    BuildContext context,
    List<_DurationOption> options,
  ) async {
    final screenSize = MediaQuery.sizeOf(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final columnCount = screenSize.width >= 800
            ? 4
            : screenSize.width >= 520
            ? 3
            : 2;
        final optionCount = options.length + (showAutomatic ? 1 : 0);
        final rowCount = (optionCount / columnCount).ceil();
        final desiredGridHeight = rowCount * 78.0 + (rowCount - 1) * 8.0;
        final maximumGridHeight = screenSize.height * 0.56;
        final gridHeight = desiredGridHeight < maximumGridHeight
            ? desiredGridHeight
            : maximumGridHeight;

        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            0,
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: colors.primaryColor,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Note Duration',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      showAutomatic
                          ? 'Choose a fixed length or let your key hold set it.'
                          : 'Choose how long the next note will be.',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.secondaryTextColor,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          content: SizedBox(
            width: 620,
            height: gridHeight,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: optionCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 78,
              ),
              itemBuilder: (context, index) {
                if (showAutomatic && index == 0) {
                  return _DurationDialogOption(
                    colors: colors,
                    icon: Icons.auto_mode_rounded,
                    title: 'Automatic',
                    subtitle: 'Use key hold time',
                    selected: automaticSelected,
                    enabled: onAutomaticSelected != null,
                    onTap: () {
                      onAutomaticSelected?.call();
                      Navigator.of(dialogContext).pop();
                    },
                  );
                }

                final optionIndex = showAutomatic ? index - 1 : index;
                final option = options[optionIndex];
                return _DurationDialogOption(
                  colors: colors,
                  icon: option.icon,
                  title: option.name,
                  subtitle: option.beatLabel,
                  selected:
                      !automaticSelected &&
                      _sameDuration(selectedDuration, option.beats),
                  enabled: true,
                  onTap: () {
                    onDurationSelected(option.beats);
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  bool _sameDuration(double first, double second) {
    return (first - second).abs() < 0.001;
  }
}

class _DurationDialogOption extends StatelessWidget {
  const _DurationDialogOption({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? colors.primaryColor.withValues(alpha: 0.12)
          : colors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? colors.primaryColor : colors.borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primaryColor, size: AppIconSizes.sm),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primaryColor,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationOption {
  const _DurationOption(this.name, this.beats, this.icon);

  final String name;
  final double beats;
  final IconData icon;

  String get beatLabel {
    if (beats == 1) return '1 beat';
    if (beats == 2 || beats == 3 || beats == 4 || beats == 6 || beats == 8) {
      return '${beats.toInt()} beats';
    }
    if ((beats - (2 / 3)).abs() < 0.001) return '2/3 beat';
    return '${beats.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} beats';
  }
}
