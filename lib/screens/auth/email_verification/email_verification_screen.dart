import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/auth/email_verification/email_verification_dialogs.dart';
import 'package:soundsight/screens/auth/login/login_screen.dart';
import 'package:soundsight/screens/auth/register/register_screen.dart';

import '../../../constants/constant.dart';
import '../../../theme/app_colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? resendCooldownTimer;
  int resendSecondsRemaining = 30;
  bool isSendingVerification = false;
  bool isCheckingVerification = false;
  bool isCancellingRegistration = false;

  @override
  void initState() {
    super.initState();
    beginResendCountdown();
  }

  @override
  void dispose() {
    resendCooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email ?? 'your email address';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_image.png'),
                opacity: 0.8,
                fit: BoxFit.cover,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const Gap(AppSpacing.xl),
                Center(
                  child: Image.asset(
                    'assets/images/logo_image_light.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const Gap(AppSpacing.sm),
                const Text(
                  'SoundSight',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextSizes.screenTitle,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightPrimary,
                  ),
                ),
                const Gap(AppSpacing.xs),
                const Text(
                  'See the music. Play with confidence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    color: AppColors.lightSecondaryText,
                  ),
                ),
                const Gap(AppSpacing.xl),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.lightBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.lightPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              color: AppColors.lightSurface,
                              size: AppIconSizes.lg,
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          const Text(
                            'Verify your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextSizes.display,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lightPrimary,
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          const Text(
                            'We sent a verification link to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextSizes.body,
                              color: AppColors.lightSecondaryText,
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.lightInputBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: AppIconSizes.sm,
                                  color: AppColors.lightSecondaryText,
                                ),
                                const Gap(AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    email,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.label,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          const Text(
                            'Open the email and tap the verification link. '
                            'Then return to SoundSight and check your status.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTextSizes.label,
                              color: AppColors.lightSecondaryText,
                              height: 1.5,
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: AppIconSizes.sm,
                                color: AppColors.lightSecondaryText,
                              ),
                              Gap(AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  'Check your Spam folder if it does not arrive.',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    color: AppColors.lightSecondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed:
                                  isCheckingVerification ||
                                      isSendingVerification ||
                                      isCancellingRegistration
                                  ? null
                                  : checkEmailVerification,
                              icon: isCheckingVerification
                                  ? const SizedBox(
                                      width: AppIconSizes.sm,
                                      height: AppIconSizes.sm,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.lightSurface,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.verified_outlined,
                                      size: AppIconSizes.md,
                                    ),
                              label: Text(
                                isCheckingVerification
                                    ? 'Checking Verification...'
                                    : 'Check Verification',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lightPrimary,
                                foregroundColor: AppColors.lightSurface,
                                disabledBackgroundColor:
                                    AppColors.lightSecondaryText,
                                disabledForegroundColor: AppColors.lightSurface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed:
                                  resendSecondsRemaining > 0 ||
                                      isSendingVerification ||
                                      isCheckingVerification ||
                                      isCancellingRegistration
                                  ? null
                                  : resendVerificationEmail,
                              icon: isSendingVerification
                                  ? const SizedBox(
                                      width: AppIconSizes.sm,
                                      height: AppIconSizes.sm,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.lightPrimary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_outlined,
                                      size: AppIconSizes.sm,
                                    ),
                              label: Text(
                                isSendingVerification
                                    ? 'Sending Verification Email...'
                                    : resendSecondsRemaining > 0
                                    ? 'Resend in ${resendSecondsRemaining}s'
                                    : 'Resend Verification Email',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.lightPrimary,
                                side: const BorderSide(
                                  color: AppColors.lightInputBorder,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          TextButton(
                            onPressed:
                                isCheckingVerification ||
                                    isSendingVerification ||
                                    isCancellingRegistration
                                ? null
                                : handleBack,
                            child: Text(
                              isCancellingRegistration
                                  ? 'Cancelling Registration...'
                                  : 'Cancel Registration',
                              style: const TextStyle(
                                fontSize: AppTextSizes.label,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> checkEmailVerification() async {
    if (isCheckingVerification ||
        isSendingVerification ||
        isCancellingRegistration) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
        (route) => false,
      );
      return;
    }

    setState(() {
      isCheckingVerification = true;
    });

    try {
      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (refreshedUser?.emailVerified == true) {
        await refreshedUser!.getIdTokenResult(true);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(refreshedUser.uid)
            .set({
              'uid': refreshedUser.uid,
              'username': widget.username,
              'profileImageUrl': null,
              'email': refreshedUser.email,
              'role': 'piano_player',
              'theme': 'light',
              'skillLevel': null,
              'preferredNotation': null,
              'accountStatus': 'active',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (!mounted) return;

        await showVerificationCompleteDialog(context);

        if (!mounted) return;

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        showVerificationMessage(
          context,
          'Your email is not verified yet. Open the newest verification email, '
          'tap its link, then try again.',
          icon: Icons.info_outline,
        );
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message;

      if (e.code == 'network-request-failed' || e.code == 'unavailable') {
        message =
            "We couldn't check your email yet. Check your internet connection "
            'and try again.';
      } else if (e.code == 'too-many-requests') {
        message =
            'Too many attempts were made. Please wait a while and try again.';
      } else if (e.code == 'user-token-expired' ||
          e.code == 'user-disabled' ||
          e.code == 'user-not-found') {
        message =
            'This registration session is no longer available. Please register '
            'again.';
      } else if (e.code == 'permission-denied') {
        message =
            "We couldn't finish setting up your account. Please try again.";
      } else {
        message =
            "We couldn't check your email verification. Please try again.";
      }

      showVerificationMessage(
        context,
        message,
        isError: true,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (resendSecondsRemaining > 0 ||
        isSendingVerification ||
        isCheckingVerification ||
        isCancellingRegistration) {
      return;
    }

    setState(() {
      isSendingVerification = true;
    });

    try {
      await user.sendEmailVerification();

      if (!mounted) return;

      showVerificationMessage(
        context,
        'A new verification email has been sent.',
        icon: Icons.mark_email_read_outlined,
      );

      startResendCooldown();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isSendingVerification = false;
      });

      String message;

      if (e.code == 'network-request-failed') {
        message =
            "We couldn't send another email. Check your internet connection "
            'and try again.';
      } else if (e.code == 'too-many-requests') {
        message =
            'Too many verification emails were requested. Please wait a while '
            'and try again.';
      } else if (e.code == 'user-token-expired' ||
          e.code == 'user-disabled' ||
          e.code == 'user-not-found') {
        message =
            'This registration session is no longer available. Please register '
            'again.';
      } else {
        message =
            "We couldn't send another verification email. Please try again "
            'later.';
      }

      showVerificationMessage(
        context,
        message,
        isError: true,
        icon: Icons.error_outline,
      );

      return;
    }
  }

  void startResendCooldown() {
    resendCooldownTimer?.cancel();

    setState(() {
      isSendingVerification = false;
      resendSecondsRemaining = 30;
    });

    beginResendCountdown();
  }

  void beginResendCountdown() {
    resendCooldownTimer?.cancel();

    resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          resendSecondsRemaining = 0;
        });
      } else {
        setState(() {
          resendSecondsRemaining--;
        });
      }
    });
  }

  Future<void> handleBack() async {
    if (isCancellingRegistration ||
        isCheckingVerification ||
        isSendingVerification) {
      return;
    }

    setState(() {
      isCancellingRegistration = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null) {
        final email = user.email;

        if (email != null) {
          final credential = EmailAuthProvider.credential(
            email: email,
            password: widget.password,
          );

          await user.reauthenticateWithCredential(credential);
        }

        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      if (e.code == 'network-request-failed') {
        message =
            "We couldn't cancel registration. Check your internet connection "
            'and try again.';
      } else if (e.code == 'too-many-requests') {
        message =
            'Too many attempts were made. Please wait a while and try again.';
      } else {
        message =
            "We couldn't cancel registration right now. Please try again.";
      }

      showVerificationMessage(
        context,
        message,
        isError: true,
        icon: Icons.error_outline,
      );

      setState(() {
        isCancellingRegistration = false;
      });
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
      (route) => false,
    );
  }
}
