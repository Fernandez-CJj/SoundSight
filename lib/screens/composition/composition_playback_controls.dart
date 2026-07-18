import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionPlaybackControls extends StatelessWidget {
  const CompositionPlaybackControls({
    super.key,
    required this.colors,
    required this.isPlaying,
    required this.isPaused,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    this.compact = false,
    this.isPreparing = false,
  });

  final AppThemeColors colors;
  final bool isPlaying;
  final bool isPaused;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final bool compact;
  final bool isPreparing;

  @override
  Widget build(BuildContext context) {
    final status = isPreparing
        ? 'Loading'
        : isPaused
        ? 'Paused'
        : isPlaying
        ? 'Playing'
        : 'Ready';

    if (compact) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isPlaying
                    ? colors.primaryColor
                    : colors.secondaryTextColor,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(AppSpacing.xs),
            Flexible(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            _CompactPlaybackButton(
              colors: colors,
              icon: Icons.play_arrow_rounded,
              tooltip: isPaused ? 'Resume' : 'Play',
              enabled: !isPreparing && (!isPlaying || isPaused),
              onTap: onPlay,
              filled: true,
            ),
            const Gap(AppSpacing.xs),
            _CompactPlaybackButton(
              colors: colors,
              icon: Icons.pause_rounded,
              tooltip: 'Pause',
              enabled: isPlaying && !isPaused && !isPreparing,
              onTap: onPause,
            ),
            const Gap(AppSpacing.xs),
            _CompactPlaybackButton(
              colors: colors,
              icon: Icons.stop_rounded,
              tooltip: 'Stop',
              enabled: isPlaying || isPaused || isPreparing,
              onTap: onStop,
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
        children: [
          Row(
            children: [
              Text(
                'Playback',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? colors.primaryColor
                            : colors.secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      status,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PlaybackButton(
                  colors: colors,
                  icon: Icons.play_arrow_rounded,
                  label: isPaused ? 'Resume' : 'Play',
                  filled: true,
                  enabled: !isPreparing && (!isPlaying || isPaused),
                  onTap: onPlay,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: _PlaybackButton(
                  colors: colors,
                  icon: Icons.pause_rounded,
                  label: 'Pause',
                  enabled: isPlaying && !isPaused && !isPreparing,
                  onTap: onPause,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: _PlaybackButton(
                  colors: colors,
                  icon: Icons.stop_rounded,
                  label: 'Stop',
                  enabled: isPlaying || isPaused || isPreparing,
                  onTap: onStop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactPlaybackButton extends StatelessWidget {
  const _CompactPlaybackButton({
    required this.colors,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: filled ? colors.primaryColor : colors.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                icon,
                size: AppIconSizes.sm,
                color: filled
                    ? colors.backgroundColor
                    : colors.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackButton extends StatelessWidget {
  const _PlaybackButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = filled
        ? colors.backgroundColor
        : colors.primaryColor;

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: Material(
        color: filled ? colors.primaryColor : colors.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: filled ? colors.primaryColor : colors.borderColor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foregroundColor, size: AppIconSizes.md),
                const Gap(2),
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
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
