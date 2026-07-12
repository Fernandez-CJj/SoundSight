import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soundsight/screens/profile/edit_profile_actions.dart';
import 'package:soundsight/screens/profile/edit_profile_avatar.dart';
import 'package:soundsight/screens/profile/edit_profile_dialogs.dart';
import 'package:soundsight/screens/profile/edit_profile_field.dart';
import 'package:soundsight/screens/profile/edit_profile_header.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import '../../constants/constant.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
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
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late String editedUsername;
  File? selectedProfileImage;

  @override
  void initState() {
    super.initState();
    editedUsername = widget.username;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: widget.colors.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditProfileHeader(colors: widget.colors),
              Gap(AppSpacing.lg),
              EditProfileAvatar(
                colors: widget.colors,
                selectedImage: selectedProfileImage,
                profileImageUrl: widget.profileImageUrl,
                onTap: pickProfileImage,
              ),
              Gap(AppSpacing.lg),
              EditProfileField(
                colors: widget.colors,
                label: 'Username',
                initialValue: widget.username,
                prefixIcon: Icons.person_outline_rounded,
                onChanged: (value) => editedUsername = value,
              ),
              Gap(AppSpacing.md),
              EditProfileField(
                colors: widget.colors,
                label: 'Email',
                initialValue: widget.email,
                prefixIcon: Icons.email_outlined,
                suffixIcon: Icons.lock_outline_rounded,
                helperText: 'Email cannot be changed',
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              Gap(AppSpacing.lg),
              EditProfileActions(
                colors: widget.colors,
                onCancel: () => Navigator.pop(context),
                onSave: saveProfileChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveProfileChanges() async {
    final newUsername = editedUsername.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username cannot be empty.')),
      );
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => ProfileSaveDialog(colors: widget.colors),
    );

    if (!mounted || shouldSave != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProfileSavingDialog(
        colors: widget.colors,
        uploadingImage: selectedProfileImage != null,
      ),
    );

    try {
      final savedProfileImageUrl = await uploadProfileImage(user.uid);
      final updates = <String, dynamic>{
        'username': newUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (selectedProfileImage != null) {
        updates['profileImageUrl'] = savedProfileImageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      if (!mounted) return;

      Navigator.of(context).pop();
      Navigator.pop(context, {
        'username': newUsername,
        'profileImageUrl': savedProfileImageUrl,
      });
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save profile changes. Please try again.',
          ),
        ),
      );
    }
  }

  Future<String?> uploadProfileImage(String userId) async {
    if (selectedProfileImage == null) return widget.profileImageUrl;

    final imageReference = FirebaseStorage.instance
        .ref()
        .child('profilePictures')
        .child(userId)
        .child('profile.jpg');

    await imageReference.putFile(selectedProfileImage!);

    final downloadUrl = await imageReference.getDownloadURL();
    return '$downloadUrl&v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> pickProfileImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );

    if (image == null) return;

    const maxFileSize = 5 * 1024 * 1024;
    final fileSize = await image.length();

    if (fileSize > maxFileSize) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture must be smaller than 5 MB.'),
        ),
      );
      return;
    }

    setState(() {
      selectedProfileImage = File(image.path);
    });
  }
}
