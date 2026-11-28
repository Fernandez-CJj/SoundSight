import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/help_center/models/help_feature.dart';
import 'package:soundsight/screens/help_center/widgets/help_guide_screenshot.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class HelpGuideDialog extends StatefulWidget {
  const HelpGuideDialog({
    super.key,
    required this.feature,
    required this.colors,
  });

  final HelpFeature feature;
  final AppThemeColors colors;

  @override
  State<HelpGuideDialog> createState() => _HelpGuideDialogState();
}

class _HelpGuideDialogState extends State<HelpGuideDialog> {
  final ScrollController _scrollController = ScrollController();
  int _stepIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    if (index < 0 || index >= widget.feature.steps.length) return;
    setState(() => _stepIndex = index);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final l10n = context.l10n;
    final step = widget.feature.steps[_stepIndex];
    final lastStep = _stepIndex == widget.feature.steps.length - 1;
    return Dialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: colors.surfaceColor,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.feature.title,
                        style: TextStyle(color: colors.primaryColor, fontSize: AppTextSizes.sectionTitle, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      tooltip: l10n.helpCenterClose,
                      onPressed: () => Navigator.of(context).pop(),
                      color: colors.secondaryTextColor,
                      icon: const Icon(Icons.close_rounded, size: AppIconSizes.md),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.helpCenterStepCount(_stepIndex + 1, widget.feature.steps.length),
                    style: TextStyle(color: colors.secondaryTextColor, fontSize: AppTextSizes.label),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(
                value: (_stepIndex + 1) / widget.feature.steps.length,
                color: colors.primaryColor,
                backgroundColor: colors.borderColor,
                minHeight: AppSpacing.xs,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenshot = HelpGuideScreenshot(
                        key: ValueKey('$_stepIndex-${step.imageAsset}'),
                        step: step,
                        colors: colors,
                        icon: widget.feature.icon,
                      );
                      final instructions = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(step.title,
                              style: TextStyle(color: colors.primaryColor, fontSize: AppTextSizes.sectionTitle, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(step.description,
                            style: TextStyle(color: colors.secondaryTextColor, fontSize: AppTextSizes.body, height: 1.5)),
                        ],
                      );
                      if (constraints.maxWidth >= 680 ||
                          MediaQuery.orientationOf(context) == Orientation.landscape) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: screenshot),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(flex: 2, child: SingleChildScrollView(
                              controller: _scrollController,
                              child: instructions,
                            )),
                          ],
                        );
                      }
                      return SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: math.max(AppSpacing.xxl * 4, constraints.maxHeight * 0.85),
                              child: screenshot,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            instructions,
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Divider(height: 1, color: colors.borderColor),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _stepIndex == 0 ? null : () => _goToStep(_stepIndex - 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryColor,
                            disabledForegroundColor: colors.secondaryTextColor,
                            side: BorderSide(color: colors.borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          child: Text(l10n.helpCenterPrevious),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: lastStep ? () => Navigator.of(context).pop() : () => _goToStep(_stepIndex + 1),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primaryColor,
                            foregroundColor: colors.backgroundColor,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          child: Text(lastStep ? l10n.helpCenterDone : l10n.helpCenterNext),
                        ),
                      ),
                    ],
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
