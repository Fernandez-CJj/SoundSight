import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionPerformanceControls extends StatelessWidget {
  const CompositionPerformanceControls({
    super.key,
    required this.colors,
    required this.volume,
    required this.velocity,
    required this.playFromCursor,
    required this.isLoopEnabled,
    required this.isSustainEnabled,
    required this.isMetronomeEnabled,
    required this.onVolumeChanged,
    required this.onVelocityChanged,
    required this.onPlayFromCursorChanged,
    required this.onLoopChanged,
    required this.onSustainChanged,
    required this.onMetronomeChanged,
    this.enabled = true,
    this.compact = false,
  });

  final AppThemeColors colors;
  final double volume;
  final double velocity;
  final bool playFromCursor;
  final bool isLoopEnabled;
  final bool isSustainEnabled;
  final bool isMetronomeEnabled;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onVelocityChanged;
  final ValueChanged<bool> onPlayFromCursorChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onSustainChanged;
  final ValueChanged<bool> onMetronomeChanged;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final hasActiveOption =
          playFromCursor ||
          isLoopEnabled ||
          isSustainEnabled ||
          isMetronomeEnabled;

      return Tooltip(
        message: 'Performance settings',
        child: Material(
          color: colors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: colors.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => showSettings(context) : null,
            child: SizedBox.square(
              dimension: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: enabled
                        ? colors.primaryColor
                        : colors.secondaryTextColor,
                    size: AppIconSizes.md,
                  ),
                  if (hasActiveOption)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.surfaceColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _PerformancePanel(
      colors: colors,
      volume: _unitValue(volume),
      velocity: _unitValue(velocity),
      playFromCursor: playFromCursor,
      isLoopEnabled: isLoopEnabled,
      isSustainEnabled: isSustainEnabled,
      isMetronomeEnabled: isMetronomeEnabled,
      enabled: enabled,
      onVolumeChanged: onVolumeChanged,
      onVelocityChanged: onVelocityChanged,
      onPlayFromCursorChanged: onPlayFromCursorChanged,
      onLoopChanged: onLoopChanged,
      onSustainChanged: onSustainChanged,
      onMetronomeChanged: onMetronomeChanged,
    );
  }

  Future<void> showSettings(BuildContext context) async {
    var currentVolume = _unitValue(volume);
    var currentVelocity = _unitValue(velocity);
    var currentPlayFromCursor = playFromCursor;
    var currentLoop = isLoopEnabled;
    var currentSustain = isSustainEnabled;
    var currentMetronome = isMetronomeEnabled;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
                ),
                child: _PerformancePanel(
                  colors: colors,
                  volume: currentVolume,
                  velocity: currentVelocity,
                  playFromCursor: currentPlayFromCursor,
                  isLoopEnabled: currentLoop,
                  isSustainEnabled: currentSustain,
                  isMetronomeEnabled: currentMetronome,
                  enabled: enabled,
                  showCloseButton: true,
                  onClose: () {
                    Navigator.of(sheetContext).pop();
                  },
                  onVolumeChanged: (value) {
                    setSheetState(() {
                      currentVolume = value;
                    });
                    onVolumeChanged(value);
                  },
                  onVelocityChanged: (value) {
                    setSheetState(() {
                      currentVelocity = value;
                    });
                    onVelocityChanged(value);
                  },
                  onPlayFromCursorChanged: (value) {
                    setSheetState(() {
                      currentPlayFromCursor = value;
                    });
                    onPlayFromCursorChanged(value);
                  },
                  onLoopChanged: (value) {
                    setSheetState(() {
                      currentLoop = value;
                    });
                    onLoopChanged(value);
                  },
                  onSustainChanged: (value) {
                    setSheetState(() {
                      currentSustain = value;
                    });
                    onSustainChanged(value);
                  },
                  onMetronomeChanged: (value) {
                    setSheetState(() {
                      currentMetronome = value;
                    });
                    onMetronomeChanged(value);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _unitValue(double value) {
    return value.clamp(0.0, 1.0).toDouble();
  }
}

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel({
    required this.colors,
    required this.volume,
    required this.velocity,
    required this.playFromCursor,
    required this.isLoopEnabled,
    required this.isSustainEnabled,
    required this.isMetronomeEnabled,
    required this.enabled,
    required this.onVolumeChanged,
    required this.onVelocityChanged,
    required this.onPlayFromCursorChanged,
    required this.onLoopChanged,
    required this.onSustainChanged,
    required this.onMetronomeChanged,
    this.showCloseButton = false,
    this.onClose,
  });

  final AppThemeColors colors;
  final double volume;
  final double velocity;
  final bool playFromCursor;
  final bool isLoopEnabled;
  final bool isSustainEnabled;
  final bool isMetronomeEnabled;
  final bool enabled;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onVelocityChanged;
  final ValueChanged<bool> onPlayFromCursorChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onSustainChanged;
  final ValueChanged<bool> onMetronomeChanged;
  final bool showCloseButton;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDarkMode ? 0.24 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
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
                      'Performance',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Adjust playback and how new notes sound.',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              if (showCloseButton)
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.primaryColor,
                  ),
                ),
            ],
          ),
          const Gap(AppSpacing.sm),
          _PerformanceSlider(
            colors: colors,
            icon: Icons.volume_up_rounded,
            label: 'Volume',
            value: volume,
            enabled: enabled,
            onChanged: onVolumeChanged,
          ),
          _PerformanceSlider(
            colors: colors,
            icon: Icons.bolt_rounded,
            label: 'Note velocity',
            value: velocity,
            enabled: enabled,
            onChanged: onVelocityChanged,
          ),
          const Gap(AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final wideLayout = constraints.maxWidth >= 620;
              final itemWidth = wideLayout
                  ? (constraints.maxWidth - (AppSpacing.sm * 3)) / 4
                  : constraints.maxWidth;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _PerformanceToggle(
                      colors: colors,
                      icon: Icons.play_circle_outline_rounded,
                      label: 'From cursor',
                      value: playFromCursor,
                      enabled: enabled && !isLoopEnabled,
                      onChanged: onPlayFromCursorChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _PerformanceToggle(
                      colors: colors,
                      icon: Icons.repeat_rounded,
                      label: 'Loop measure',
                      value: isLoopEnabled,
                      enabled: enabled,
                      onChanged: onLoopChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _PerformanceToggle(
                      colors: colors,
                      icon: Icons.piano_rounded,
                      label: 'Sustain',
                      value: isSustainEnabled,
                      enabled: enabled,
                      onChanged: onSustainChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _PerformanceToggle(
                      colors: colors,
                      icon: Icons.timer_outlined,
                      label: 'Metronome',
                      value: isMetronomeEnabled,
                      enabled: enabled,
                      onChanged: onMetronomeChanged,
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

class _PerformanceSlider extends StatelessWidget {
  const _PerformanceSlider({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colors.primaryColor, size: AppIconSizes.sm),
        const Gap(AppSpacing.xs),
        SizedBox(
          width: 86,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 20,
            activeColor: colors.primaryColor,
            inactiveColor: colors.borderColor,
            onChanged: enabled ? onChanged : null,
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PerformanceToggle extends StatelessWidget {
  const _PerformanceToggle({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        color: value
            ? colors.primaryColor.withOpacity(0.08)
            : colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: value ? colors.primaryColor : colors.borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primaryColor, size: AppIconSizes.sm),
          const Gap(AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch.adaptive(
              value: value,
              activeColor: colors.primaryColor,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
