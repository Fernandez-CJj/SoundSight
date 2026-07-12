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
    required this.profileImageUrl,
  });

  final AppThemeColors colors;
  final String username;
  final String email;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => showProfileImage(context),
              child: Material(
                elevation: 2,
                color: colors.surfaceColor,
                shape: CircleBorder(
                  side: BorderSide(color: colors.borderColor),
                ),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: profileImageUrl == null || profileImageUrl!.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: 58,
                          color: colors.primaryColor,
                        )
                      : ClipOval(
                          child: Image.network(
                            profileImageUrl!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person_rounded,
                                size: 58,
                                color: colors.primaryColor,
                              );
                            },
                          ),
                        ),
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

  Future<void> showProfileImage(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: colors.surfaceColor,
          insetPadding: EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profile Picture',
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.sectionTitle,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.primaryColor,
                      ),
                    ),
                  ],
                ),
                Gap(AppSpacing.sm),
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: profileImageUrl == null || profileImageUrl!.isEmpty
                        ? Container(
                            color: colors.backgroundColor,
                            child: Icon(
                              Icons.person_rounded,
                              size: 140,
                              color: colors.primaryColor,
                            ),
                          )
                        : InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image.network(
                              profileImageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colors.backgroundColor,
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 140,
                                    color: colors.primaryColor,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
