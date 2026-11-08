
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/onboarding/widgets/feature_tour_tooltip.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_controller.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Shared appearance and explicit navigation for every feature tour target.
class FeatureShowcase extends StatelessWidget {
  const FeatureShowcase({
    super.key,
    required this.controller,
    required this.stepIndex,
    required this.title,
    required this.description,
    required this.colors,
    required this.child,
  });

  final FeatureTourController controller;
  final int stepIndex;
  final String title;
  final String description;
  final AppThemeColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {

    return Showcase.withWidget(
      key: controller.steps[stepIndex].targetKey,
      scope: controller.scope,
      disableBarrierInteraction: true,
      disableMovingAnimation: true,
      enableAutoScroll: false,
      // Consume target taps so touring cannot activate the real control.
      onTargetClick: () {},
      disposeOnTap: false,
      overlayColor: Colors.black,
      overlayOpacity: 0.72,
      targetBorderRadius: BorderRadius.circular(AppRadius.sm),
      toolTipMargin: 0,
      targetTooltipGap: 0,
      container: const SizedBox(width: 1, height: 1),
      floatingActionWidget: FloatingActionWidget(
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        child: FeatureTourTooltip(
          controller: controller,
          stepIndex: stepIndex,
          title: title,
          description: description,
          colors: colors,
        ),
      ),
      child: KeyedSubtree(
        key: controller.steps[stepIndex].anchorKey,
        child: child,
      ),
    );
  }
}
