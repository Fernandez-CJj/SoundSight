import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../constants/constant.dart';
import '../../../theme/app_colors.dart';

Future<void> showVerificationCompleteDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              decoration: BoxDecoration(
                color: AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.verified_outlined,
                size: AppIconSizes.sm,
                color: AppColors.lightSurface,
              ),
            ),
            const Gap(AppSpacing.sm),
            const Expanded(
              child: Text(
                'Email Verified',
                style: TextStyle(
                  color: AppColors.lightPrimary,
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your email has been verified and your account is ready. '
          'Please log in to continue.',
          style: TextStyle(
            color: AppColors.lightSecondaryText,
            fontSize: AppTextSizes.body,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              icon: const Icon(
                Icons.login_outlined,
                size: AppIconSizes.sm,
              ),
              label: const Text('Go to Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: AppColors.lightSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
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
