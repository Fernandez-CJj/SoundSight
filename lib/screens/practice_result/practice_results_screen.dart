import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/players/sight_reading/practice_result_models.dart';
import 'package:soundsight/screens/players/sight_reading/practice_result_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

import 'practice_result_detail_screen.dart';

class PracticeResultsScreen extends StatefulWidget {
  const PracticeResultsScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<PracticeResultsScreen> createState() => _PracticeResultsScreenState();
}

class _PracticeResultsScreenState extends State<PracticeResultsScreen> {
  final PracticeResultService resultService = PracticeResultService();
  late bool isDarkMode;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;
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
        centerTitle: true,
        title: const Text(
          'Practice Results',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.practiceResults,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: userId == null
          ? buildMessageState(
              colors,
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to view practice results',
              message: 'Completed Performance attempts will appear here.',
            )
          : StreamBuilder<List<PracticeResultSummary>>(
              stream: resultService.watchResults(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return buildMessageState(
                    colors,
                    icon: Icons.error_outline_rounded,
                    title: 'Results could not be loaded',
                    message: 'Check your connection and try again.',
                  );
                }

                final results = snapshot.data ?? const [];

                if (results.isEmpty) {
                  return buildMessageState(
                    colors,
                    icon: Icons.insights_outlined,
                    title: 'No practice results yet',
                    message:
                        'Complete a score in Performance Mode to create your first result.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return buildResultCard(colors, results[index]);
                  },
                );
              },
            ),
    );
  }

  Widget buildResultCard(AppThemeColors colors, PracticeResultSummary result) {
    final weakClef = result.weakestClef;
    final suggestion = result.suggestions.isEmpty
        ? 'Practise the difficult parts slowly, then play the piece again.'
        : result.suggestions.first;

    return Material(
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PracticeResultDetailScreen(result: result, colors: colors),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Text(
                  '${result.timingAccuracyPercentage}%',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.pieceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primaryColor,
                              fontSize: AppTextSizes.body,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          color: colors.surfaceColor,
                          iconColor: colors.secondaryTextColor,
                          onSelected: (value) {
                            if (value == 'delete') {
                              confirmDelete(colors, result);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFDC2626),
                                  ),
                                  Gap(AppSpacing.sm),
                                  Text('Delete result'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${sourceLabel(result.source)} · ${formatDate(result.completedAt)} '
                      '· Score ${result.scoreText}',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        resultChip(
                          colors,
                          Icons.close_rounded,
                          '${result.wrongCount} wrong notes',
                        ),
                        resultChip(
                          colors,
                          Icons.timer_off_outlined,
                          '${result.missedCount} not played',
                        ),
                        if (weakClef != null)
                          resultChip(
                            colors,
                            Icons.music_note_rounded,
                            clefPracticeLabel(weakClef.clef),
                          ),
                      ],
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      suggestion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.caption,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget resultChip(AppThemeColors colors, IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.secondaryTextColor),
          const Gap(AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageState(
    AppThemeColors colors, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSizes.xl, color: colors.secondaryTextColor),
            const Gap(AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmDelete(
    AppThemeColors colors,
    PracticeResultSummary result,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          title: Text(
            'Delete practice result?',
            style: TextStyle(color: colors.primaryColor),
          ),
          content: Text(
            'This removes the result for “${result.pieceTitle}” and its detailed error log.',
            style: TextStyle(color: colors.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || result.id == null) {
      return;
    }

    try {
      await resultService.deleteResult(result.id!);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The practice result could not be deleted.'),
        ),
      );
    }
  }

  Future<void> loadTheme() async {
    if (userId == null) {
      return;
    }

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final theme = userDocument.data()?['theme'] ?? 'light';

    if (!mounted) {
      return;
    }

    setState(() {
      isDarkMode = theme == 'dark';
    });
  }

  String sourceLabel(String source) {
    return source == 'composition' ? 'Composition' : 'Music Sheet';
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Just now';
    }

    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  String clefPracticeLabel(String clef) {
    switch (clef.toLowerCase()) {
      case 'treble':
        return 'Practise higher notes';
      case 'bass':
        return 'Practise lower notes';
      default:
        return 'Practise the ${clef.toLowerCase()} clef';
    }
  }
}
