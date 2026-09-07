import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../constants/constant.dart';
import '../../../theme/app_colors.dart';

void showAgreementRequiredDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
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
                Icons.description_outlined,
                size: AppIconSizes.sm,
                color: AppColors.lightSurface,
              ),
            ),
            const Gap(AppSpacing.sm),
            const Expanded(
              child: Text(
                'Agreement Required',
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
          'Please agree to the Terms and Privacy Policy before creating your account.',
          style: TextStyle(
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
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
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

Future<bool> showCreateAccountDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
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
                    Icons.person_add_alt_1,
                    size: AppIconSizes.sm,
                    color: AppColors.lightSurface,
                  ),
                ),
                const Gap(AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Create Account?',
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
              'Are you sure you want to create this account?',
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
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.lightPrimary,
                          side: const BorderSide(
                            color: AppColors.lightInputBorder,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightPrimary,
                          foregroundColor: AppColors.lightSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: const Text('Create'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<bool> showAccountCreatedDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
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
                    Icons.check_circle_outline,
                    size: AppIconSizes.sm,
                    color: AppColors.lightSurface,
                  ),
                ),
                const Gap(AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Check Your Email',
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
              'We sent a verification link to your email address. Open it to '
              'finish creating your SoundSight account.',
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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
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
      ) ??
      false;
}

Future<void> showRegisterErrorDialog(
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
                'Registration Problem',
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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

void showRegisterLoadingDialog(BuildContext context) {
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
                'Creating account',
                style: TextStyle(
                  color: AppColors.lightPrimary,
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(AppSpacing.xs),
              Text(
                'Please wait while we set up your account.',
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

Future<void> showTermsDialog(BuildContext context) async {
  await _showRegisterInformationDialog(
    context,
    title: 'Terms of Use',
    icon: Icons.description_outlined,
    content:
        'Using SoundSight\n'
        'Create your account using accurate information and keep your login '
        'details secure. You are responsible for activity performed through '
        'your account.\n\n'
        'Learning tools\n'
        'SoundSight provides piano-learning, assessment, practice, and music '
        'creation tools. Results and recommendations are educational guidance '
        'and should be used together with your own judgment.\n\n'
        'Your content\n'
        'Only upload sheet music, images, PDFs, compositions, or other content '
        'that you own or have permission to use.\n\n'
        'Responsible use\n'
        'Do not misuse the service, attempt to access another user’s account, '
        'or upload harmful or unlawful content.\n\n'
        'Account and service changes\n'
        'Access may be restricted when these terms are violated. SoundSight '
        'features may also be updated as the application develops.\n\n'
        'By creating an account, you agree to these Terms of Use.',
  );
}

Future<void> showPrivacyPolicyDialog(BuildContext context) async {
  await _showRegisterInformationDialog(
    context,
    title: 'Privacy Policy',
    icon: Icons.privacy_tip_outlined,
    content:
        'Information handled by SoundSight\n'
        'SoundSight uses your username and email address to create and secure '
        'your account. It may also store your assessment answers, skill level, '
        'learning progress, preferences, and content you choose to create or '
        'upload.\n\n'
        'How information is used\n'
        'This information is used to authenticate you, personalize your '
        'learning experience, save your progress, and provide the application’s '
        'features.\n\n'
        'Firebase services\n'
        'SoundSight uses Firebase Authentication, Cloud Firestore, and Firebase '
        'Storage to manage accounts, app information, and permitted uploads.\n\n'
        'Account protection\n'
        'Email verification and Firebase security rules are used to prevent '
        'unverified accounts from accessing protected app data.\n\n'
        'Your responsibility\n'
        'Do not include unnecessary personal or sensitive information in '
        'usernames, uploads, comments, or other content you provide.\n\n'
        'By creating an account, you acknowledge this Privacy Policy.',
  );
}

Future<void> _showRegisterInformationDialog(
  BuildContext context, {
  required String title,
  required IconData icon,
  required String content,
}) async {
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
                color: AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: AppIconSizes.sm,
                color: AppColors.lightSurface,
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.lightPrimary,
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(
              color: AppColors.lightSecondaryText,
              fontSize: AppTextSizes.label,
              height: 1.5,
            ),
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
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: AppColors.lightSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      );
    },
  );
}
