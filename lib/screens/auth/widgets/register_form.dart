import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/auth/widgets/app_text_form_field.dart';

import '../../../constants/constant.dart';
import '../../../theme/app_colors.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isChecked,
    required this.isObscure,
    required this.onAgreementChanged,
    required this.onTermsPressed,
    required this.onPrivacyPolicyPressed,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isChecked;
  final bool isObscure;
  final ValueChanged<bool?> onAgreementChanged;
  final VoidCallback onTermsPressed;
  final VoidCallback onPrivacyPolicyPressed;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        children: [
          const Gap(AppSpacing.xxl),
          Center(
            child: Image.asset(
              'assets/images/logo_image_light.png',
              width: 92,
              height: 92,
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
          const Text(
            'Create your account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextSizes.display,
              fontWeight: FontWeight.w400,
              color: AppColors.lightPrimary,
            ),
          ),
          const Gap(AppSpacing.xs),
          const Text(
            'Start your piano learning journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextSizes.body,
              color: AppColors.lightSecondaryText,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Gap(AppSpacing.lg),
          AppTextFormField(
            controller: usernameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
            label: 'Username',
            prefixIcon: Icons.person_outline,
          ),
          const Gap(AppSpacing.md),
          AppTextFormField(
            controller: emailController,
            label: 'Email Address',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }

              if (!EmailValidator.validate(value.trim())) {
                return 'Enter a valid email address';
              }

              return null;
            },
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const Gap(AppSpacing.md),
          AppTextFormField(
            controller: passwordController,
            label: 'Password',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }

              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }

              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'Password must contain at least one capital letter';
              }

              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'Password must contain at least one number';
              }

              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return 'Password must contain at least one special character';
              }

              return null;
            },
            prefixIcon: Icons.lock_outlined,
            obscureText: isObscure,
            suffixIcon: IconButton(
              onPressed: onTogglePasswordVisibility,
              icon: Icon(
                isObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppIconSizes.sm,
                  color: AppColors.lightSecondaryText,
                ),
                Gap(AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Use at least 8 characters with a capital letter, number, and special character.',
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      color: AppColors.lightSecondaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.md),
          AppTextFormField(
            controller: confirmPasswordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }

              if (value != passwordController.text) {
                return 'Passwords do not match';
              }

              return null;
            },
            label: 'Confirm Password',
            prefixIcon: Icons.lock_outlined,
            obscureText: isObscure,
            suffixIcon: IconButton(
              onPressed: onTogglePasswordVisibility,
              icon: Icon(
                isObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: isChecked,
                activeColor: AppColors.lightPrimary,
                checkColor: AppColors.lightSurface,
                onChanged: onAgreementChanged,
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'I agree to the ',
                      style: TextStyle(
                        fontSize: AppTextSizes.body,
                        color: AppColors.lightSecondaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: onTermsPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.lightPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: AppTextSizes.body,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Terms'),
                    ),
                    const Text(
                      'and ',
                      style: TextStyle(
                        fontSize: AppTextSizes.body,
                        color: AppColors.lightSecondaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: onPrivacyPolicyPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.lightPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: AppTextSizes.body,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.person_add_alt_1, size: AppIconSizes.md),
              label: const Text('Create Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: AppColors.lightSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                textStyle: const TextStyle(
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: Divider(color: AppColors.lightBorder, thickness: 1),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'or',
                  style: TextStyle(
                    fontSize: AppTextSizes.label,
                    color: AppColors.lightSecondaryText,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppColors.lightBorder, thickness: 1),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(
                  color: AppColors.lightSecondaryText,
                  fontSize: AppTextSizes.body,
                ),
              ),
              GestureDetector(
                onTap: onLogin,
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightPrimary,
                    fontSize: AppTextSizes.body,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
        ],
      ),
    );
  }
}
