import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class EditProfileAvatar extends StatelessWidget {
  const EditProfileAvatar({
    super.key,
    required this.colors,
    required this.selectedImage,
    required this.profileImageUrl,
    required this.onTap,
  });

  final AppThemeColors colors;
  final File? selectedImage;
  final String? profileImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasProfileImage =
        profileImageUrl != null && profileImageUrl!.isNotEmpty;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: colors.backgroundColor,
              backgroundImage: selectedImage != null
                  ? FileImage(selectedImage!)
                  : hasProfileImage
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: selectedImage == null && !hasProfileImage
                  ? Icon(
                      Icons.person_rounded,
                      size: 58,
                      color: colors.primaryColor,
                    )
                  : null,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: colors.primaryColor,
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 17,
                  color: colors.backgroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
