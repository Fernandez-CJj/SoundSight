import 'dart:async';

import 'package:soundsight/services/processing_announcements.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/screens/my_compositions_screen.dart';
import 'package:soundsight/screens/composition/screens/published_compositions_screen.dart';
import 'package:soundsight/screens/composition/screens/published_composition_viewer_screen.dart';
import 'package:soundsight/screens/composition/screens/saved_compositions_screen.dart';
import 'package:soundsight/screens/homescreen/widgets/community_compositions_section.dart';
import 'package:soundsight/screens/profile/widgets/player_progress_container.dart';
import 'package:soundsight/screens/homescreen/widgets/practice_container.dart';
import 'package:soundsight/screens/homescreen/widgets/quick_actions.dart';
import 'package:soundsight/screens/music_sheet/screens/music_sheet_screen.dart';
import 'package:soundsight/screens/music_library/screens/music_library_search_screen.dart';
import 'package:soundsight/screens/practice_result/screens/practice_results_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';
import 'package:soundsight/screens/onboarding/tours/home_drawer_tour.dart';
import 'package:soundsight/screens/onboarding/widgets/feature_showcase.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isDarkMode;
  late final HomeDrawerTour homeTour;

  String username = '';
  String skillLevel = '';
  int experiencePoints = 0;

  @override
  void initState() {
    super.initState();
    homeTour = HomeDrawerTour(context: () => context, isMounted: () => mounted);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ProcessingAnnouncements.navigationReady.value = true;
    });

    isDarkMode = widget.isDarkMode ?? false;

    unawaited(prepareHomeTutorial());
  }

  @override
  void dispose() {
    homeTour.dispose();
    super.dispose();
  }

  Future<void> prepareHomeTutorial() async {
    try {
      await loadHomeData();
    } catch (error) {
      debugPrint('Could not load the home profile: $error');
    }
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await homeTour.controller.start();
  }

  Widget guide(int index, String title, String description, Widget child) {
    return FeatureShowcase(
      controller: homeTour.controller,
      stepIndex: index,
      title: title,
      description: description,
      colors: AppThemeColors.fromDarkMode(isDarkMode),
      child: child,
    );
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

    return AnimatedBuilder(
      animation: homeTour.controller,
      builder: (context, _) => PopScope(
        canPop: !homeTour.controller.isActive,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && homeTour.controller.isActive) {
            unawaited(homeTour.controller.cancel());
          }
        },
        child: Scaffold(
      key: homeTour.scaffoldKey,
      drawerEnableOpenDragGesture: !homeTour.controller.isActive,
      onDrawerChanged: homeTour.onDrawerChanged,
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: guide(
          3,
          context.l10n.featureTourMenuTitle,
          context.l10n.featureTourMenuBody,
          IconButton(
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => homeTour.scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
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
          guide(
            0,
            context.l10n.searchMusic,
            context.l10n.featureTourSearchBody,
IconButton(
            tooltip: context.l10n.searchMusic,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MusicLibrarySearchScreen(isDarkMode: isDarkMode),
                ),
              );
            },
            icon: const Icon(Icons.search_rounded, size: 30),
          )
          ),
        ],
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.home,
        scrollController: homeTour.drawerScrollController,
        navigationGuideBuilder: (child) => guide(
          4,
          context.l10n.featureTourNavigationTitle,
          context.l10n.featureTourNavigationBody,
          child,
        ),
        preferencesGuideBuilder: (child) => guide(
          5,
          context.l10n.featureTourPreferencesTitle,
          context.l10n.featureTourPreferencesBody,
          child,
        ),
        onReplayTutorial: () => unawaited(homeTour.controller.start(replay: true)),
        replayGuideBuilder: (child) => guide(
          6,
          context.l10n.featureTourReplay,
          context.l10n.featureTourReplayBody,
          child,
        ),
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          controller: homeTour.homeScrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              context.l10n.homeGreeting(username),
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              context.l10n.homeEncouragement,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Gap(AppSpacing.md),
            PlayerProgressContainer(
              colors: colors,
              skillLevel: skillLevel,
              experiencePoints: experiencePoints,
            ),
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
              headingBuilder: (child) => guide(
                1,
                context.l10n.quickActions,
                context.l10n.featureTourQuickActionsBody,
                child,
              ),
              onMusicSheets: openMusicSheets,
              onUploadSheet: openAddSheet,
              onPracticeResults: openPracticeResults,
              onSavedSheets: openSavedSheets,
              onComposition: openCompositions,
              onPublishedCompositions: openPublishedCompositions,
            ),
            const Gap(AppSpacing.md),
            CommunityCompositionsSection(
              colors: colors,
              headingBuilder: (child) => guide(
                2,
                context.l10n.communityCompositions,
                context.l10n.featureTourCommunityBody,
                child,
              ),
              onSeeAll: openPublishedCompositions,
              onOpenComposition: (composition) {
                openPublishedComposition(colors, composition);
              },
            ),
          ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Future<void> loadHomeData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();
    final theme = userData?['theme'] ?? 'light';

    if (!mounted) return;

    setState(() {
      isDarkMode = theme == 'dark';
      username = userData?['username'] ?? '';
      skillLevel = userData?['skillLevel'] ?? '';
      experiencePoints = (userData?['experiencePoints'] as num?)?.toInt() ?? 0;
    });
  }

  void openMusicSheets() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MusicSheetScreen(isDarkMode: isDarkMode),
      ),
    );
  }

  Future<void> openAddSheet() async {
    final wasUploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CaptureUploadSheetScreen(isDarkMode: isDarkMode),
      ),
    );

    if (!mounted || wasUploaded != true) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MusicSheetScreen(isDarkMode: isDarkMode),
      ),
    );
  }

  void openPracticeResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeResultsScreen(isDarkMode: isDarkMode),
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

  void openSavedSheets() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedCompositionsScreen(isDarkMode: isDarkMode),
      ),
    );
  }

  void openPublishedCompositions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedCompositionsScreen(isDarkMode: isDarkMode),
      ),
    );
  }

  void openPublishedComposition(
    AppThemeColors colors,
    PublishedComposition composition,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedCompositionViewerScreen(
          colors: colors,
          composition: composition,
        ),
      ),
    );
  }
}
