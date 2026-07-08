import 'package:flutter/material.dart';
import 'package:soundsight/theme/app_colors.dart';

import '../../../constants/constant.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: AppColors.lightPrimary,
      style: const TextStyle(
        fontSize: AppTextSizes.body,
        color: AppColors.lightPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintText: label,
        hintStyle: const TextStyle(
          fontSize: AppTextSizes.body,
          color: AppColors.lightSecondaryText,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: AppIconSizes.md,
          color: AppColors.lightSecondaryText,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: AppSpacing.xxl + AppSpacing.md,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : IconTheme(
                data: const IconThemeData(
                  size: AppIconSizes.md,
                  color: AppColors.lightSecondaryText,
                ),
                child: suffixIcon!,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: AppSpacing.xxl + AppSpacing.md,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.lightInputBorder,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.lightInputBorder,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.lightPrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
