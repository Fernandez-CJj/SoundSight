import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class EditProfileField extends StatelessWidget {
  const EditProfileField({
    super.key,
    required this.colors,
    required this.label,
    required this.initialValue,
    required this.prefixIcon,
    this.onChanged,
    this.readOnly = false,
    this.keyboardType,
    this.suffixIcon,
    this.helperText,
  });

  final AppThemeColors colors;
  final String label;
  final String initialValue;
  final IconData prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(AppSpacing.sm),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: TextStyle(color: colors.primaryColor),
          decoration: InputDecoration(
            prefixIcon: Icon(
              prefixIcon,
              color: colors.secondaryTextColor,
            ),
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: colors.secondaryTextColor),
            helperText: helperText,
            helperStyle: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
            filled: true,
            fillColor: colors.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
