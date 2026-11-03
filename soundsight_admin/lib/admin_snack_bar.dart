import 'package:flutter/material.dart';

import 'admin_theme.dart';

extension AdminSnackBarMessenger on ScaffoldMessengerState {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLatestSnackBar(
    SnackBar snackBar,
  ) {
    clearSnackBars();
    removeCurrentSnackBar();
    return showSnackBar(snackBar);
  }
}

/// Matches the Android app's snackbar layout using the admin color model.
SnackBar adminSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final colors = AdminPalette.of(context);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.horizontal,
    backgroundColor: colors.surface,
    elevation: 0,
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colors.border),
    ),
    duration: const Duration(seconds: 5),
    showCloseIcon: false,
    content: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 22,
            color: colors.foreground,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
