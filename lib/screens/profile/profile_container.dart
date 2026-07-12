import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class ProfileContainer extends StatelessWidget {
  const ProfileContainer({
    super.key,
    required this.colors,
    required this.username,
    required this.email,
  });

  final AppThemeColors colors;
  final String username;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              elevation: 2,
              color: colors.surfaceColor,
              shape: CircleBorder(side: BorderSide(color: colors.borderColor)),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Icon(
                  Icons.person_rounded,
                  size: 58,
                  color: colors.primaryColor,
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                elevation: 2,
                color: colors.primaryColor,
                shape: CircleBorder(
                  side: BorderSide(color: colors.backgroundColor, width: 3),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.piano,
                    size: 17,
                    color: colors.backgroundColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        Gap(AppSpacing.md),
        Text(
          username,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.screenTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(AppSpacing.xs),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.secondaryTextColor,
            fontSize: AppTextSizes.label,
          ),
        ),
        Gap(AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colors.borderColor),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 16,
                  color: colors.primaryColor,
                ),
                Gap(AppSpacing.xs),
                Text(
                  'Piano Player',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
