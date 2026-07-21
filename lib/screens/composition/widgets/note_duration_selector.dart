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
  });

  final AppThemeColors colors;
  final double selectedDuration;
  final int beatsPerMeasure;
  final int beatUnit;
  final ValueChanged<double> onDurationSelected;
  final bool compact;
  final bool enabled;

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

    if (compact) {
      return Container(
        height: 60,
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                'Duration',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Gap(AppSpacing.xs),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Gap(AppSpacing.xs),
                itemBuilder: (context, index) {
                  final option = options[index];

                  return SizedBox(
                    width: 104,
                    child: _CompactDurationButton(
                      colors: colors,
                      option: option,
                      selected: _sameDuration(selectedDuration, option.beats),
                      enabled: enabled,
                      onTap: () {
                        onDurationSelected(option.beats);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
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
          Text(
            'Note Duration',
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.label,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Choose the length before tapping a piano key.',
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in options)
                SizedBox(
                  width: 142,
                  child: _DurationButton(
                    colors: colors,
                    option: option,
                    selected: _sameDuration(selectedDuration, option.beats),
                    enabled: enabled,
                    onTap: () {
                      onDurationSelected(option.beats);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _sameDuration(double first, double second) {
    return (first - second).abs() < 0.001;
  }
}

class _CompactDurationButton extends StatelessWidget {
  const _CompactDurationButton({
    required this.colors,
    required this.option,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final AppThemeColors colors;
  final _DurationOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.primaryColor : colors.backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 16,
                color: selected
                    ? colors.backgroundColor
                    : colors.primaryColor,
              ),
              const Gap(3),
              Flexible(
                child: Text(
                  option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? colors.backgroundColor
                        : colors.primaryColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  const _DurationButton({
    required this.colors,
    required this.option,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final AppThemeColors colors;
  final _DurationOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.backgroundColor,
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
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option.icon,
                      color: colors.primaryColor,
                      size: AppIconSizes.sm,
                    ),
                    const Gap(AppSpacing.xs),
                    Flexible(
                      child: Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.caption,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.xs),
                Text(
                  option.beatLabel,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ],
            ),
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
