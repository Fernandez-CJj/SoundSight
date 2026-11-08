import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/auth/widgets/app_text_form_field.dart';

import '../../../constants/constant.dart';
import '../../../theme/app_colors.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isObscure,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isObscure;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;

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
            'Welcome back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextSizes.display,
              fontWeight: FontWeight.w400,
              color: AppColors.lightPrimary,
            ),
          ),
          const Gap(AppSpacing.xs),
          const Text(
            'Continue your piano learning journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextSizes.body,
              color: AppColors.lightSecondaryText,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Gap(AppSpacing.xl),
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

              if (value.length < 6) {
                return 'Password must be at least 6 characters';
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
          const Gap(AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(
                Icons.login_outlined,
                size: AppIconSizes.md,
              ),
              label: const Text('Login'),
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
                child: Divider(
                  color: AppColors.lightBorder,
                  thickness: 1,
                ),
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
                child: Divider(
                  color: AppColors.lightBorder,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: AppColors.lightSecondaryText,
                  fontSize: AppTextSizes.body,
                ),
              ),
              GestureDetector(
                onTap: onRegister,
                child: const Text(
                  'Register',
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
