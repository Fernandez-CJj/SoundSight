import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/profile/account_container.dart';
import 'package:soundsight/screens/profile/assessment_container.dart';
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
  late bool isDarkMode;
  String username = '';
  String skillLevel = '';
  String email = '';
  int? assessmentScore;
  DateTime? assessmentDate;
  int level = 1;
  int experiencePoints = 0;
  int experienceToNextLevel = 100;
  @override
  void initState() {
    super.initState();
    isDarkMode = widget.colors.isDarkMode;
    loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);
    final assessmentColor = colors.primaryColor;
    final scoreColor = colors.primaryColor;
    final dateColor = colors.primaryColor;
    final iconBackgroundColor = colors.backgroundColor;
    final iconForegroundColor = colors.primaryColor;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final assessmentDateText = assessmentDate == null
        ? 'Not available'
        : '${months[assessmentDate!.month - 1]} ${assessmentDate!.year}';

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
          IconButton(onPressed: () {}, icon: Icon(Icons.edit, size: 30)),
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
            ProfileContainer(colors: colors, username: username, email: email),
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
              iconBackgroundColor: iconBackgroundColor,
              iconForegroundColor: iconForegroundColor,
              assessmentColor: assessmentColor,
              scoreColor: scoreColor,
              assessmentScore: assessmentScore,
              dateColor: dateColor,
              assessmentDateText: assessmentDateText,
            ),
            Gap(AppSpacing.md),
            AccountContainer(
              colors: colors,
              onEditProfile: () {},
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
      assessmentScore = (data?['assessmentScore'] as num?)?.toInt();
      assessmentDate = (data?['assessmentDate'] as Timestamp?)?.toDate();
      level = (data?['level'] as num?)?.toInt() ?? 1;
      experiencePoints = (data?['experiencePoints'] as num?)?.toInt() ?? 0;
      experienceToNextLevel =
          (data?['experienceToNextLevel'] as num?)?.toInt() ?? 100;
    });
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
}
