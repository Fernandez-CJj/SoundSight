import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

enum AppSnackBarType { info, success, warning, error }

extension AppSnackBarMessenger on ScaffoldMessengerState {
  /// Replace the visible message and discard older queued snackbars.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLatestSnackBar(
    SnackBar snackBar,
  ) {
    clearSnackBars();
    removeCurrentSnackBar();
    return showSnackBar(snackBar);
  }
}

/// All transient app messages use the same layout and the user's palette.
SnackBar appSnackBar({
  required AppThemeColors colors,
  required String message,
  String? detail,
  AppSnackBarType type = AppSnackBarType.info,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 5),
}) {
  assert((actionLabel == null) == (onAction == null));
  final succeeded = type == AppSnackBarType.success;
  final statusIcon =
      icon ??
      switch (type) {
        AppSnackBarType.info => Icons.info_outline_rounded,
        AppSnackBarType.success => Icons.check_circle_outline_rounded,
        AppSnackBarType.warning => Icons.warning_amber_rounded,
        AppSnackBarType.error => Icons.error_outline_rounded,
      };

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.horizontal,
    backgroundColor: colors.surfaceColor,
    elevation: 0,
    margin: const EdgeInsets.all(AppSpacing.md),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: colors.borderColor),
    ),
    duration: duration,
    showCloseIcon: false,
    content: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: succeeded
                ? colors.completedStageSurfaceColor
                : colors.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            statusIcon,
            size: 22,
            color: succeeded ? colors.completedStageColor : colors.primaryColor,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
    action: actionLabel == null || onAction == null
        ? null
        : SnackBarAction(
            label: actionLabel,
            backgroundColor: colors.primaryColor,
            textColor: colors.surfaceColor,
            disabledBackgroundColor: colors.borderColor,
            disabledTextColor: colors.secondaryTextColor,
            onPressed: onAction,
          ),
  );
}
