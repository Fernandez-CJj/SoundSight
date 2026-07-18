import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_sheet_screen.dart';
import 'package:soundsight/screens/composition/my_compositions_screen.dart';
import 'package:soundsight/screens/homescreen/level_card.dart';
import 'package:soundsight/screens/homescreen/practice_container.dart';
import 'package:soundsight/screens/homescreen/quick_actions.dart';
import 'package:soundsight/screens/music_sheet/music_sheet_screen.dart';
import 'package:soundsight/screens/profile/profile_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isDarkMode;

  String username = '';
  String skillLevel = '';

  @override
  void initState() {
    super.initState();

    isDarkMode = widget.isDarkMode ?? false;

    loadTheme();
    loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    final practiceImage = isDarkMode
        ? 'assets/images/black_container.png'
        : 'assets/images/white_container.png';

    final practiceTextColor = isDarkMode ? Colors.white : Colors.black;
    final practiceButtonColor = isDarkMode ? Colors.white : Colors.black;
    final practiceButtonTextColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 25,
              width: 25,
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage(colors.logoPath)),
              ),
            ),
            const Gap(AppSpacing.xs),
            const Text(
              'SoundSight',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppTextSizes.sectionTitle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(colors: colors),
                ),
              );
            },
            icon: const Icon(Icons.person, size: 30),
          ),
        ],
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.home,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            Text(
              'Good Morning, $username',
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              'Keep practicing, Great music starts with you.',
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Gap(AppSpacing.md),
            TopCard(colors: colors, skillLevel: skillLevel),
            const Gap(AppSpacing.md),
            PracticeContainer(
              practiceImage: practiceImage,
              practiceTextColor: practiceTextColor,
              practiceButtonColor: practiceButtonColor,
              practiceButtonTextColor: practiceButtonTextColor,
              borderColor: colors.borderColor,
            ),
            const Gap(AppSpacing.md),
            QuickActions(
              colors: colors,
              onMusicSheets: openMusicSheets,
              onUploadSheet: () {
                openAddSheet(SheetInputAction.upload);
              },
              onCaptureSheet: () {
                openAddSheet(SheetInputAction.capture);
              },
              onComposition: openCompositions,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadTheme() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final theme = userDoc.data()?['theme'] ?? 'light';

    if (!mounted) return;

    setState(() {
      isDarkMode = theme == 'dark';
    });
  }

  Future<void> loadUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      username = userDoc.data()?['username'] ?? '';
      skillLevel = userDoc.data()?['skillLevel'] ?? '';
    });
  }

  void openMusicSheets() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MusicSheetScreen(isDarkMode: isDarkMode),
      ),
    );
  }

  void openAddSheet(SheetInputAction initialAction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaptureUploadSheetScreen(
          isDarkMode: isDarkMode,
          initialAction: initialAction,
        ),
      ),
    );
  }

  void openCompositions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyCompositionsScreen(isDarkMode: isDarkMode),
      ),
    );
  }
}
