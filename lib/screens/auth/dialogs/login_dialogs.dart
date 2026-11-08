import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../constants/constant.dart';
import '../../../theme/app_colors.dart';

void showLoginLoadingDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.lightSurface,
          surfaceTintColor: AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.lightPrimary,
                ),
              ),
              Gap(AppSpacing.md),
              Text(
                'Logging in',
                style: TextStyle(
                  color: AppColors.lightPrimary,
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(AppSpacing.xs),
              Text(
                'Please wait while we open your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.lightSecondaryText,
                  fontSize: AppTextSizes.body,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showLoginErrorDialog(
  BuildContext context,
  String message,
) async {
  const errorColor = Color(0xFFDC2626);

  await showDialog<void>(
    context: context,
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
                color: errorColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.error_outline,
                size: AppIconSizes.sm,
                color: AppColors.lightSurface,
              ),
            ),
            const Gap(AppSpacing.sm),
            const Expanded(
              child: Text(
                "Couldn't Log In",
                style: TextStyle(
                  color: AppColors.lightPrimary,
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.lightSecondaryText,
            fontSize: AppTextSizes.body,
            height: 1.4,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: AppColors.lightSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: const Text('Okay'),
            ),
          ),
        ],
      );
    },
  );
}
