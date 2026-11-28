import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/help_center/models/help_feature.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class HelpGuideScreenshot extends StatelessWidget {
  const HelpGuideScreenshot({
    super.key,
    required this.step,
    required this.colors,
    required this.icon,
  });

  final HelpGuideStep step;
  final AppThemeColors colors;
  final IconData icon;

  Future<void> _openFullScreen(BuildContext context) => showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: colors.backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(color: colors.primaryColor, fontSize: AppTextSizes.body, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: context.l10n.helpCenterClose,
                    onPressed: () => Navigator.of(context).pop(),
                    color: colors.primaryColor,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(child: _image(context)),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: colors.backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: colors.borderColor),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _image(context),
        if (step.imageFor(colors.isDarkMode) != null)
          PositionedDirectional(
            end: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Material(
              color: colors.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: colors.borderColor),
              ),
              child: IconButton(
                tooltip: context.l10n.helpCenterEnlargeScreenshot,
                onPressed: () => _openFullScreen(context),
                color: colors.primaryColor,
                icon: const Icon(Icons.fullscreen_rounded, size: AppIconSizes.md),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _image(BuildContext context) {
    final l10n = context.l10n;
    final asset = step.imageFor(colors.isDarkMode);
    if (asset == null) return _placeholder(l10n.helpCenterScreenshotPending);
    // The captured colors preserve music notation, key colors, and camera
    // images. The surrounding viewer always uses the active app palette.
    return InteractiveViewer(
      key: ValueKey(asset),
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: Image.asset(
          asset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          semanticLabel: l10n.helpCenterScreenshotLabel(step.title),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
              wasSynchronouslyLoaded || frame != null
              ? child
              : Center(child: CircularProgressIndicator(color: colors.primaryColor)),
          errorBuilder: (_, _, _) => _placeholder(l10n.helpCenterScreenshotUnavailable),
        ),
      ),
    );
  }

  Widget _placeholder(String message) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.xl, color: colors.secondaryTextColor),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center,
            style: TextStyle(color: colors.secondaryTextColor, fontSize: AppTextSizes.label)),
        ],
      ),
    ),
  );
}
