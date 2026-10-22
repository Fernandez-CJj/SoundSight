import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class EditProfileHeader extends StatelessWidget {
  const EditProfileHeader({super.key, required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
        Gap(AppSpacing.md),
        Text(
          context.l10n.editProfile,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.screenTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(AppSpacing.xs),
        Text(
          context.l10n.updatePersonalInformation,
          style: TextStyle(
            color: colors.secondaryTextColor,
            fontSize: AppTextSizes.label,
          ),
        ),
      ],
    );
  }
}
