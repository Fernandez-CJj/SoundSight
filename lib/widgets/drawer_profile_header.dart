import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class DrawerProfileHeader extends StatelessWidget {
  const DrawerProfileHeader({
    super.key,
    required this.colors,
    required this.onTap,
  });

  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final username = data?['username'] as String?;
        final email = data?['email'] as String?;
        final profileImageUrl = data?['profileImageUrl'] as String?;
        final rawSkillLevel = data?['skillLevel'] as String? ?? '';
        final skillLevel = rawSkillLevel.isEmpty
            ? 'Not assessed'
            : '${rawSkillLevel[0].toUpperCase()}${rawSkillLevel.substring(1)}';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: profileImageUrl == null || profileImageUrl.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            color: colors.primaryColor,
                            size: 36,
                          )
                        : ClipOval(
                            child: Image.network(
                              profileImageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person_rounded,
                                  color: colors.primaryColor,
                                  size: 36,
                                );
                              },
                            ),
                          ),
                  ),
                  Gap(AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username?.isNotEmpty == true
                              ? username!
                              : 'Piano Player',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.body,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Gap(AppSpacing.xs),
                        Text(
                          email?.isNotEmpty == true
                              ? email!
                              : user.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.secondaryTextColor,
                            fontSize: AppTextSizes.caption,
                          ),
                        ),
                        Gap(AppSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceColor,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_outline_rounded,
                                color: colors.primaryColor,
                                size: 14,
                              ),
                              Gap(AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  skillLevel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
