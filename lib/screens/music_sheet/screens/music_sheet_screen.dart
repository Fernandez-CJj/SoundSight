import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_sheet_screen.dart';
import 'package:soundsight/screens/music_sheet/dialogs/music_sheet_dialogs.dart';
import 'package:soundsight/screens/music_sheet/services/music_sheet_delete_service.dart';
import 'package:soundsight/screens/music_sheet/screens/music_sheet_viewer_screen.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_card.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

class MusicSheetScreen extends StatefulWidget {
  const MusicSheetScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<MusicSheetScreen> createState() => _MusicSheetScreenState();
}

class _MusicSheetScreenState extends State<MusicSheetScreen> {
  late bool isDarkMode;
  late final String? userId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? musicSheetsStream;
  final Set<String> deletingSheetIds = {};
  final MusicSheetDeleteService deleteService = MusicSheetDeleteService();

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      musicSheetsStream = FirebaseFirestore.instance
          .collection('musicSheets')
          .where('ownerId', isEqualTo: userId)
          .snapshots();
    }

    loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    return Scaffold(
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
          'Music Sheets',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppTextSizes.sectionTitle,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add sheet',
            onPressed: () => openAddSheetScreen(),
            icon: Icon(Icons.add_rounded, size: 29),
          ),
        ],
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.musicSheets,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: musicSheetsStream == null
          ? buildSignedOutState(colors)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: musicSheetsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return buildErrorState(colors);
                }

                final sheets =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snapshot.data?.docs ?? [],
                    );
                sheets.sort(sortSheetsByDate);

                if (sheets.isEmpty) {
                  return buildEmptyState(colors);
                }

                return buildMusicSheetList(colors, sheets);
              },
            ),
    );
  }

  Widget buildMusicSheetList(
    AppThemeColors colors,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sheets,
  ) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: sheets.length + 1,
      separatorBuilder: (_, index) {
        return Gap(index == 0 ? AppSpacing.md : AppSpacing.sm);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your library',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.screenTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      'Open and manage your uploaded music sheets.',
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
          );
        }

        final sheet = sheets[index - 1];
        final data = sheet.data();
        final title = data['title'] as String? ?? 'Untitled Sheet';
        final type = data['type'] as String? ?? 'images';
        final pageCount = (data['pageCount'] as num?)?.toInt() ?? 0;

        return MusicSheetCard(
          colors: colors,
          title: title,
          type: type,
          pageCount: pageCount,
          dateText: formatDate(data['createdAt'] as Timestamp?),
          isDeleting: deletingSheetIds.contains(sheet.id),
          onView: () => openMusicSheet(colors, sheet.id, title, type, data),
          onRename: () => renameMusicSheet(colors, sheet, title),
          onDelete: () => deleteMusicSheet(colors, sheet, title, data),
        );
      },
    );
  }

  Widget buildEmptyState(AppThemeColors colors) {
    return Center(
      child: SingleChildScrollView(
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
            Text(
              'No music sheets yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            Gap(AppSpacing.sm),
            Text(
              'Upload images or a PDF to start building your music-sheet library.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                height: 1.45,
              ),
            ),
            Gap(AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: openAddSheetScreen,
              icon: Icon(Icons.add_rounded),
              label: Text('Add Music Sheet'),
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
              'Your music sheets could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(AppSpacing.xs),
            Text(
              'Check your connection and Firebase permissions.',
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
        'Sign in to view your music sheets.',
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

  void openMusicSheet(
    AppThemeColors colors,
    String sheetId,
    String title,
    String type,
    Map<String, dynamic> data,
  ) {
    Navigator.of(context).push(
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

      showMessage('Music sheet renamed.');
    } catch (_) {
      showMessage('The music sheet could not be renamed.');
    }
  }

  Future<void> deleteMusicSheet(
    AppThemeColors colors,
    QueryDocumentSnapshot<Map<String, dynamic>> sheet,
    String title,
    Map<String, dynamic> data,
  ) async {
    if (data['omrStatus'] == 'processing') {
      showMessage(
        'Wait for the music-sheet translation to finish before deleting it.',
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
      await deleteService.deleteMusicSheet(
        sheetReference: sheet.reference,
        sheetData: data,
      );
      showMessage('"$title" was deleted.');
    } catch (_) {
      showMessage('The music sheet could not be deleted.');
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
    final date = timestamp.toDate();
    return 'Added ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
