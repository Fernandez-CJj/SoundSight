import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class RecordingGenerationOverlay extends StatelessWidget {
  const RecordingGenerationOverlay({
    super.key,
    required this.colors,
  });

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ModalBarrier(
            dismissible: false,
            color: Colors.black54,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: colors.primaryColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Generating composition files...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Please keep this screen open.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
