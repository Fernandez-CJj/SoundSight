import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class AccountContainer extends StatelessWidget {
  const AccountContainer({
    super.key,
    required this.colors,
    required this.onEditProfile,
    required this.onChangePassword,
  });

  final AppThemeColors colors;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.person_outline_rounded,
                  color: colors.primaryColor,
                ),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.secondaryTextColor,
                ),
                onTap: onEditProfile,
              ),
              Divider(height: 1, indent: 56, color: colors.borderColor),
              ListTile(
                leading: Icon(
                  Icons.lock_outline_rounded,
                  color: colors.primaryColor,
                ),
                title: Text(
                  'Change Password',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.secondaryTextColor,
                ),
                onTap: onChangePassword,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
