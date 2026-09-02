import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/screens/assessment_entry_screen.dart';
import 'package:soundsight/screens/assessment/services/assessment_attempt_service.dart';
import 'package:soundsight/screens/profile/account_container.dart';
import 'package:soundsight/screens/profile/assessment_container.dart';
import 'package:soundsight/screens/profile/edit_profile_sheet.dart';
import 'package:soundsight/screens/profile/logout_container.dart';
import 'package:soundsight/screens/profile/player_progress_container.dart';
import 'package:soundsight/screens/profile/preferences_container.dart';
import 'package:soundsight/screens/profile/profile_container.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

import '../../constants/constant.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.colors});

  final AppThemeColors colors;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Loads the user's permanent or resumable assessment state.
  final AssessmentAttemptService _assessmentService =
      AssessmentAttemptService();

  late bool isDarkMode;
  String username = '';
  String skillLevel = '';
  String email = '';
  String? profileImageUrl;
  int level = 1;
  int experiencePoints = 0;
  int experienceToNextLevel = 100;

  /// Null means the user has not started an assessment yet.
  AssessmentAttempt? assessmentAttempt;

  /// Controls the small status indicator in the Assessment profile section.
  bool isAssessmentLoading = true;

  /// Lets the same profile tile retry if its server request fails.
  bool assessmentLoadFailed = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.colors.isDarkMode;
    loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppTextSizes.sectionTitle,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => showEditProfileSheet(colors),
            icon: Icon(Icons.edit, size: 30),
          ),
        ],
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.profile,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            ProfileContainer(
              colors: colors,
              username: username,
              email: email,
              profileImageUrl: profileImageUrl,
            ),
            Gap(AppSpacing.md),
            PlayerProgressContainer(
              colors: colors,
              skillLevel: skillLevel,
              level: level,
              experiencePoints: experiencePoints,
              experienceToNextLevel: experienceToNextLevel,
            ),
            Gap(AppSpacing.md),
            AssessmentContainer(
              colors: colors,
              actionLabel: assessmentActionLabel,
              description: assessmentDescription,
              isLoading: isAssessmentLoading,
              onTap: openAssessment,
            ),
            Gap(AppSpacing.md),
            AccountContainer(
              colors: colors,
              onEditProfile: () => showEditProfileSheet(colors),
              onChangePassword: () {},
            ),
            Gap(AppSpacing.md),
            PreferencesContainer(
              colors: colors,
              isDarkMode: isDarkMode,
              onDarkModeChanged: updateTheme,
            ),
            Gap(AppSpacing.md),
            LogoutContainer(colors: colors),
            Gap(AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() {
        isAssessmentLoading = true;
        assessmentLoadFailed = false;
      });
    }

    AssessmentAttempt? loadedAttempt;
    var failedToLoadAssessment = false;

    try {
      // This server-backed load also permanently finalizes an expired attempt.
      loadedAttempt = await _assessmentService.loadCurrentAttempt();
    } catch (error) {
      failedToLoadAssessment = true;
    }

    // Load the profile after the assessment so a newly expired Beginner level
    // is immediately reflected in the same screen.
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();

    if (!mounted) return;

    setState(() {
      username = data?['username'] ?? '';
      skillLevel = data?['skillLevel'] ?? '';
      email = data?['email'] ?? '';
      profileImageUrl = data?['profileImageUrl'];
      level = (data?['level'] as num?)?.toInt() ?? 1;
      experiencePoints = (data?['experiencePoints'] as num?)?.toInt() ?? 0;
      experienceToNextLevel =
          (data?['experienceToNextLevel'] as num?)?.toInt() ?? 100;
      assessmentAttempt = loadedAttempt;
      isAssessmentLoading = false;
      assessmentLoadFailed = failedToLoadAssessment;
    });
  }

  /// Opens the assessment entry with its already loaded state.
  ///
  /// If loading previously failed, tapping the tile retries instead.
  Future<void> openAssessment() async {
    if (assessmentLoadFailed) {
      await loadUser();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentEntryScreen(
          initialAttempt: assessmentAttempt,
        ),
      ),
    );

    if (!mounted) return;

    // Refresh the displayed level if the assessment changed before returning.
    await loadUser();
  }

  /// Chooses the Profile action that matches the saved assessment state.
  String get assessmentActionLabel {
    if (assessmentLoadFailed) {
      return 'Retry Assessment Status';
    }

    if (isAssessmentLoading) {
      return 'Loading Assessment';
    }

    final status = assessmentAttempt?.effectiveStatus;

    if (status == null) {
      return 'Start Assessment';
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return 'Resume Assessment';
      case AssessmentAttemptStatus.completed:
        return 'View Assessment Results';
      case AssessmentAttemptStatus.expired:
        return 'Assessment Expired';
    }
  }

  /// Explains whether the assessment is available, active, or permanent.
  String get assessmentDescription {
    if (assessmentLoadFailed) {
      return 'Unable to load the assessment. Tap to try again.';
    }

    if (isAssessmentLoading) {
      return 'Checking your current assessment status.';
    }

    final status = assessmentAttempt?.effectiveStatus;

    if (status == null) {
      return 'Start whenever you are ready. The timer has not begun.';
    }

    switch (status) {
      case AssessmentAttemptStatus.inProgress:
        return 'Continue before the active 72-hour deadline.';
      case AssessmentAttemptStatus.completed:
        return 'Review your permanent level and section scores.';
      case AssessmentAttemptStatus.expired:
        return 'Beginner was assigned permanently. No retry is available.';
    }
  }

  Future<void> updateTheme(bool value) async {
    setState(() {
      isDarkMode = value;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'theme': value ? 'dark' : 'light',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> showEditProfileSheet(AppThemeColors colors) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: EditProfileSheet(
            colors: colors,
            username: username,
            email: email,
            profileImageUrl: profileImageUrl,
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      username = result['username'] ?? username;
      profileImageUrl = result['profileImageUrl'] ?? profileImageUrl;
    });
  }
}
