import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CaptureTipsContainer extends StatelessWidget {
  const CaptureTipsContainer({super.key, required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    const tipColor = Color(0xFFF59E0B);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: tipColor,
                  size: 23,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.captureTips,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(2),
                    Text(
                      context.l10n.captureTipsDescription,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(AppSpacing.md),
          Divider(height: 1, color: colors.borderColor),
          Gap(AppSpacing.md),
          _CaptureTip(
            colors: colors,
            icon: Icons.wb_sunny_outlined,
            text: context.l10n.captureTipLighting,
          ),
          Gap(AppSpacing.md),
          _CaptureTip(
            colors: colors,
            icon: Icons.table_bar_outlined,
            text: context.l10n.captureTipFlat,
          ),
          Gap(AppSpacing.md),
          _CaptureTip(
            colors: colors,
            icon: Icons.center_focus_strong_outlined,
            text: context.l10n.captureTipVisible,
          ),
        ],
      ),
    );
  }
}

class _CaptureTip extends StatelessWidget {
  const _CaptureTip({
    required this.colors,
    required this.icon,
    required this.text,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colors.secondaryTextColor, size: 18),
        Gap(AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
        ),
      ],
    );
  }
}
