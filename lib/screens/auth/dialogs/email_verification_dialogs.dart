import 'package:flutter/material.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';

Future<void> showCancellationRequiresLoginDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
          'For your security, sign in again before cancelling this '
          'registration. After signing in, return to verification and choose '
          'Cancel Registration.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Go to Login'),
          ),
        ],
      );
    },
  );
}

void showVerificationMessage(
  BuildContext context,
  String message, {
  bool isError = false,
  IconData icon = Icons.info_outline,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showLatestSnackBar(
    appSnackBar(
      colors: AppThemeColors.fromDarkMode(false),
      message: message,
      type: isError ? AppSnackBarType.error : AppSnackBarType.info,
      icon: isError ? Icons.error_outline_rounded : icon,
    ),
  );
}
