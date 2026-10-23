import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../constants/constant.dart';
import '../../../theme/app_colors.dart';

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
  const errorColor = Color(0xFFDC2626);
  final messenger = ScaffoldMessenger.of(context);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: AppColors.lightSurface),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.lightSurface,
                fontSize: AppTextSizes.label,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? errorColor : AppColors.lightPrimary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );
}
