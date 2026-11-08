import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_controller.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// A screen-bounded guide in ShowcaseView's own top interaction layer.
/// Keeping the card beside the highlight in the same overlay avoids a second
/// entry whose paint position and pointer region can fall out of sync.
class FeatureTourTooltip extends StatelessWidget {
  const FeatureTourTooltip({
    super.key,
    required this.controller,
    required this.stepIndex,
    required this.title,
    required this.description,
    required this.colors,
  });

  final FeatureTourController controller;
  final int stepIndex;
  final String title;
  final String description;
  final AppThemeColors colors;

  Rect? _targetRect(BuildContext context) {
    final target = controller.steps[stepIndex]
        .anchorKey.currentContext?.findRenderObject();
    if (target is! RenderBox || !target.attached || !target.hasSize) return null;
    final overlayBox = Overlay.of(context, rootOverlay: true).context.findRenderObject();
    final origin = overlayBox is RenderBox
        ? overlayBox.localToGlobal(Offset.zero) : Offset.zero;
    return (target.localToGlobal(Offset.zero) - origin) & target.size;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (!controller.isActive || controller.isTransitioning ||
          controller.stepIndex != stepIndex) return const SizedBox.shrink();
      final media = MediaQuery.of(context);
      return LayoutBuilder(builder: (context, constraints) {
        const edge = 8.0;
        final left = math.max(media.viewPadding.left, media.viewInsets.left) + edge;
        final top = math.max(media.viewPadding.top, media.viewInsets.top) + edge;
        final right = math.max(left, constraints.maxWidth -
            math.max(media.viewPadding.right, media.viewInsets.right) - edge);
        final bottom = math.max(top, constraints.maxHeight -
            math.max(media.viewPadding.bottom, media.viewInsets.bottom) - edge);
        final safeRect = Rect.fromLTRB(left, top, right, bottom);
        if (safeRect.isEmpty) return const SizedBox.shrink();
        return CustomSingleChildLayout(
          delegate: _GuidePosition(
            target: _targetRect(context) ?? Rect.fromCenter(
              center: safeRect.center, width: 0, height: 0,
            ),
            safeRect: safeRect,
          ),
          child: _GuideCard(
            controller: controller,
            stepIndex: stepIndex,
            title: title,
            description: description,
            colors: colors,
            availableHeight: math.min(420.0, safeRect.height),
          ),
        );
      });
    },
  );
}

class _GuidePosition extends SingleChildLayoutDelegate {
  const _GuidePosition({required this.target, required this.safeRect});
  final Rect target;
  final Rect safeRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(
    maxWidth: math.min(360.0, safeRect.width),
    maxHeight: math.min(420.0, safeRect.height),
  );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = 12.0;
    final below = safeRect.bottom - target.bottom - gap;
    final above = target.top - safeRect.top - gap;
    var x = target.center.dx - childSize.width / 2;
    double y;
    if (below >= childSize.height) {
      y = target.bottom + gap;
    } else if (above >= childSize.height) {
      y = target.top - gap - childSize.height;
    } else if (safeRect.right - target.right - gap >= childSize.width) {
      x = target.right + gap;
      y = target.center.dy - childSize.height / 2;
    } else if (target.left - safeRect.left - gap >= childSize.width) {
      x = target.left - gap - childSize.width;
      y = target.center.dy - childSize.height / 2;
    } else {
      // Large highlights may leave no room beside them. Keep the guide visible.
      y = below >= above ? target.bottom + gap : target.top - gap - childSize.height;
    }
    return Offset(
      x.clamp(safeRect.left, math.max(safeRect.left, safeRect.right - childSize.width)).toDouble(),
      y.clamp(safeRect.top, math.max(safeRect.top, safeRect.bottom - childSize.height)).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_GuidePosition oldDelegate) =>
      target != oldDelegate.target || safeRect != oldDelegate.safeRect;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.controller, required this.stepIndex,
    required this.title, required this.description, required this.colors,
    required this.availableHeight});
  final FeatureTourController controller;
  final int stepIndex;
  final String title;
  final String description;
  final AppThemeColors colors;
  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = controller.isActive && !controller.isTransitioning;
    final last = !controller.hasNextStep(stepIndex) && !controller.hasContinuation;
    final hasBack = controller.hasPreviousStep(stepIndex) || controller.canReturnToPrevious;
    final actionHeight = math.min(48.0, availableHeight);
    final topGap = math.min(8.0, math.max(0.0, (availableHeight - actionHeight) / 2));
    final bottomGap = math.min(12.0, math.max(0.0, availableHeight - actionHeight - topGap));
    final buttonStyle = TextButton.styleFrom(
      minimumSize: const Size(88, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      foregroundColor: colors.primaryColor,
    );
    Widget label(String text) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1),
    );
    return SizedBox(
      width: 360,
      child: Material(
        color: colors.surfaceColor,
        elevation: 8,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                key: ValueKey('${controller.scope}/$stepIndex'),
                primary: false,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.visibleStepCount == null
                          ? l10n.featureTourStepNumber(controller.visibleStepNumber(stepIndex))
                          : l10n.featureTourStep(controller.visibleStepNumber(stepIndex), controller.visibleStepCount!),
                      style: TextStyle(color: colors.secondaryTextColor, fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(title, style: TextStyle(color: colors.primaryColor,
                      fontSize: AppTextSizes.body, fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(description, style: TextStyle(color: colors.primaryColor, height: 1.4)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, topGap, 12, bottomGap),
              child: SizedBox(
                height: actionHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: TextButton(
                    onPressed: enabled ? () => unawaited(controller.skip()) : null,
                    style: buttonStyle.copyWith(foregroundColor: WidgetStatePropertyAll(colors.secondaryTextColor)),
                    child: label(l10n.skip),
                  )),
                  if (hasBack) ...[
                    const SizedBox(width: 4),
                    Expanded(child: TextButton(
                      onPressed: enabled ? () => unawaited(controller.previous()) : null,
                      style: buttonStyle,
                      child: label(l10n.back),
                    )),
                  ],
                  const SizedBox(width: 4),
                  Expanded(child: FilledButton(
                    onPressed: enabled ? () => unawaited(controller.next()) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primaryColor,
                      foregroundColor: colors.backgroundColor,
                      minimumSize: const Size(88, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    child: label(last ? l10n.done : l10n.next),
                  )),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
