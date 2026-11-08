import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart';
import 'package:soundsight/screens/music_sheet/dialogs/music_sheet_dialogs.dart';
import 'package:soundsight/screens/music_sheet/services/music_sheet_delete_service.dart';
import 'package:soundsight/screens/music_sheet/screens/music_sheet_viewer_screen.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_card.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';
import 'package:soundsight/widgets/processing_job_card.dart';
import 'package:soundsight/screens/onboarding/tours/music_sheets_tour.dart';
import 'package:soundsight/screens/onboarding/tours/feature_tour_step_counts.dart';
import 'package:soundsight/screens/onboarding/widgets/feature_showcase.dart';

class MusicSheetScreen extends StatefulWidget {
  const MusicSheetScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<MusicSheetScreen> createState() => _MusicSheetScreenState();
}

class _MusicSheetScreenState extends State<MusicSheetScreen> {
  late bool isDarkMode;
  late final String? userId;
  late final MusicSheetsTour sheetTour;
  bool _tourReady = false;
  bool _hasSheets = false;
  bool _hasProcessingStatus = false;
  bool _tutorialScheduled = false;
  QueryDocumentSnapshot<Map<String, dynamic>>? _tutorialSheet;
  Stream<QuerySnapshot<Map<String, dynamic>>>? musicSheetsStream;
  final Set<String> deletingSheetIds = {};
  final MusicSheetDeleteService deleteService = MusicSheetDeleteService();

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;
    sheetTour = MusicSheetsTour(
      context: () => context,
      isMounted: () => mounted,
      isReady: () => _tourReady && deletingSheetIds.isEmpty,
      hasSheets: () => _hasSheets,
      hasProcessingStatus: () => _hasProcessingStatus,
      openSheet: openTutorialSheet,
      sheetStepCount: () {
        final data = _tutorialSheet?.data();
        if (data == null) return 0;
        return FeatureTourStepCounts.musicSheetViewer(
          type: data['type'] as String? ?? 'images',
          files: getFiles(data),
          data: data,
        );
      },
    );

    if (userId != null) {
      musicSheetsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('musicSheets')
          .snapshots();
    }

    loadTheme();
  }

  @override
  void dispose() {
    sheetTour.dispose();
    super.dispose();
  }

  void scheduleTutorial() {
    if (_tutorialScheduled || userId == null) return;
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_tourReady) {
        _tutorialScheduled = false;
        return;
      }
      unawaited(sheetTour.controller.start());
    });
  }

  Widget guide(int index, String title, String description, Widget child) {
    return FeatureShowcase(
      controller: sheetTour.controller,
      stepIndex: index,
      title: title,
      description: description,
      colors: AppThemeColors.fromDarkMode(isDarkMode),
      child: child,
    );
  }

  Widget libraryGuide(Widget child) => guide(
    1,
    context.l10n.yourLibrary,
    _hasSheets ? context.l10n.featureTourSheetsLibraryBody :
        context.l10n.featureTourSheetsEmptyBody,
    child,
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    return AnimatedBuilder(
      animation: sheetTour.controller,
      builder: (context, _) => PopScope(
      canPop: !sheetTour.controller.isActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && sheetTour.controller.isActive) {
          unawaited(sheetTour.controller.cancel());
        }
      },
      child: Scaffold(
      key: sheetTour.scaffoldKey,
      drawerEnableOpenDragGesture: !sheetTour.controller.isActive,
      onDrawerChanged: sheetTour.onDrawerChanged,
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.musicSheets,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppTextSizes.sectionTitle,
          ),
        ),
        actions: [
          guide(
            0, context.l10n.addMusicSheet,
            context.l10n.featureTourSheetsAddBody,
          IconButton(
            tooltip: context.l10n.addSheetTooltip,
            onPressed: sheetTour.controller.isActive ? null : openAddSheetScreen,
            icon: Icon(Icons.add_rounded, size: 29),
          ),
          ),
        ],
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.musicSheets,
        scrollController: sheetTour.drawerScrollController,
        onReplayTutorial: userId == null ? null :
            () => unawaited(sheetTour.controller.start(replay: true)),
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: AbsorbPointer(
        absorbing: sheetTour.controller.isActive,
        child: musicSheetsStream == null
          ? buildSignedOutState(colors)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: musicSheetsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  _tourReady = false;
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  _tourReady = false;
                  return buildErrorState(colors);
                }

                final sheets =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snapshot.data?.docs ?? [],
                    );
                sheets.sort(sortSheetsByDate);
                _hasSheets = sheets.isNotEmpty;
                _tutorialSheet = sheets.isEmpty ? null : sheets.first;
                _hasProcessingStatus = _hasSheets && ProcessingJobCard.isVisible(
                  sheets.first.data()['lastJobStatus'] as String?,
                );
                _tourReady = true;
                scheduleTutorial();

                if (sheets.isEmpty) {
                  return buildEmptyState(colors);
                }

                return buildMusicSheetList(colors, sheets);
              },
            ),
      ),
    ),
    ),
    );
  }

  Widget buildMusicSheetList(
    AppThemeColors colors,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sheets,
  ) {
    return ListView.separated(
      controller: sheetTour.scrollController,
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: sheets.length + 1,
      separatorBuilder: (_, index) {
        return Gap(index == 0 ? AppSpacing.md : AppSpacing.sm);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return libraryGuide(Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.yourLibrary,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.screenTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      context.l10n.libraryDescription,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.label,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  '${sheets.length}',
                  style: TextStyle(
                    color: colors.backgroundColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ));
        }

        final sheet = sheets[index - 1];
        final data = sheet.data();
        final title = data['title'] as String? ?? context.l10n.untitledSheet;
        final type = data['type'] as String? ?? 'images';
        final pageCount = (data['pageCount'] as num?)?.toInt() ?? 0;

        return MusicSheetCard(
          colors: colors,
          dismissKey: sheet.id,
          title: title,
          type: type,
          pageCount: pageCount,
          durationMs: (data['durationMs'] as num?)?.toInt() ?? 0,
          jobId: data['activeJobId'] as String?,
          jobStatus: data['lastJobStatus'] as String?,
          dateText: formatDate(data['createdAt'] as Timestamp?),
          isDeleting: deletingSheetIds.contains(sheet.id),
          onView: () => openMusicSheet(colors, sheet.id, title, type, data),
          onRename: () => renameMusicSheet(colors, sheet, title),
          onDelete: () => deleteMusicSheet(colors, sheet, title, data),
          infoGuideBuilder: index == 1 ? (child) => guide(
            3, context.l10n.featureTourSheetsOpenTitle,
            context.l10n.featureTourSheetsOpenBody, child,
          ) : null,
          processingGuideBuilder: index == 1 ? (child) => guide(
            2, context.l10n.featureTourSheetsStatusTitle,
            context.l10n.featureTourSheetsStatusBody, child,
          ) : null,
        );
      },
    );
  }

  Widget buildEmptyState(AppThemeColors colors) {
    return Center(
      child: SingleChildScrollView(
        controller: sheetTour.scrollController,
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_music_outlined,
                color: const Color(0xFF3B82F6),
                size: 40,
              ),
            ),
            Gap(AppSpacing.lg),
            libraryGuide(Text(
              context.l10n.noMusicSheets,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            )),
            Gap(AppSpacing.sm),
            Text(
              context.l10n.noMusicSheetsDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                height: 1.45,
              ),
            ),
            Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: openAddSheetScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: colors.backgroundColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(context.l10n.addMusicSheet),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorState(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: colors.secondaryTextColor,
              size: 48,
            ),
            Gap(AppSpacing.md),
            Text(
              context.l10n.musicSheetsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(AppSpacing.xs),
            Text(
              context.l10n.musicSheetsLoadErrorHelp,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSignedOutState(AppThemeColors colors) {
    return Center(
      child: Text(
        context.l10n.signInForMusicSheets,
        style: TextStyle(color: colors.secondaryTextColor),
      ),
    );
  }

  Future<void> loadTheme() async {
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final theme = userDoc.data()?['theme'] ?? 'light';

    if (!mounted) return;

    setState(() {
      isDarkMode = theme == 'dark';
    });
  }

  void openAddSheetScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaptureUploadSheetScreen(isDarkMode: isDarkMode),
      ),
    );
  }

  Future<Object?> openMusicSheet(
    AppThemeColors colors,
    String sheetId,
    String title,
    String type,
    Map<String, dynamic> data,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MusicSheetViewerScreen(
          colors: colors,
          sheetId: sheetId,
          ownerId: data['ownerId'] as String? ?? userId ?? '',
          title: title,
          type: type,
          files: getFiles(data),
        ),
      ),
    );
  }

  Future<Object?> openTutorialSheet() async {
    final sheet = _tutorialSheet;
    if (sheet == null || !mounted) return null;
    final data = sheet.data();
    return openMusicSheet(
      AppThemeColors.fromDarkMode(isDarkMode),
      sheet.id,
      data['title'] as String? ?? context.l10n.untitledSheet,
      data['type'] as String? ?? 'images',
      data,
    );
  }

  Future<void> renameMusicSheet(
    AppThemeColors colors,
    QueryDocumentSnapshot<Map<String, dynamic>> sheet,
    String currentTitle,
  ) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) =>
          RenameMusicSheetDialog(colors: colors, currentTitle: currentTitle),
    );

    if (newTitle == null || newTitle == currentTitle || !mounted) {
      return;
    }

    try {
      await sheet.reference.update({
        'title': newTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      showMessage(
        context.l10n.musicSheetRenamed,
        type: AppSnackBarType.success,
      );
    } catch (_) {
      showMessage(
        context.l10n.musicSheetRenameFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> deleteMusicSheet(
    AppThemeColors colors,
    QueryDocumentSnapshot<Map<String, dynamic>> sheet,
    String title,
    Map<String, dynamic> data,
  ) async {
    if (data['transcriptionStatus'] == 'processing') {
      showMessage(
        context.l10n.audioWaitBeforeDelete,
        type: AppSnackBarType.warning,
      );
      return;
    }
    if (data['omrStatus'] == 'processing') {
      showMessage(
        context.l10n.waitForTranslationBeforeDelete,
        type: AppSnackBarType.warning,
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteMusicSheetDialog(colors: colors, title: title),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      deletingSheetIds.add(sheet.id);
    });

    try {
      final latestSheet = await sheet.reference.get();
      if (!mounted) return;
      if (latestSheet.data()?['transcriptionStatus'] == 'processing') {
        showMessage(
          context.l10n.audioWaitBeforeDelete,
          type: AppSnackBarType.warning,
        );
        return;
      }
      await deleteService.deleteMusicSheet(
        sheetReference: sheet.reference,
        sheetData: data,
      );
      showMessage(
        context.l10n.musicSheetDeleted(title),
        type: AppSnackBarType.success,
      );
    } catch (_) {
      showMessage(
        context.l10n.musicSheetDeleteFailed,
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          deletingSheetIds.remove(sheet.id);
        });
      }
    }
  }

  List<Map<String, dynamic>> getFiles(Map<String, dynamic> data) {
    final files = data['files'];
    if (files is! List) return [];

    return files.whereType<Map>().map((file) {
      return Map<String, dynamic>.from(file);
    }).toList();
  }

  int sortSheetsByDate(
    QueryDocumentSnapshot<Map<String, dynamic>> first,
    QueryDocumentSnapshot<Map<String, dynamic>> second,
  ) {
    final firstDate = first.data()['createdAt'] as Timestamp?;
    final secondDate = second.data()['createdAt'] as Timestamp?;

    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    return secondDate.compareTo(firstDate);
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final localizedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(date);
    return context.l10n.addedDate(localizedDate);
  }

  void showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showLatestSnackBar(
      appSnackBar(
        colors: AppThemeColors.fromDarkMode(isDarkMode),
        message: message,
        type: type,
      ),
    );
  }
}

