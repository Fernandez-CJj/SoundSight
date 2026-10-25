import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Shows the nine currently supported achievements from saved user progress.
class AchievementsContainer extends StatefulWidget {
  const AchievementsContainer({
    super.key,
    required this.colors,
    required this.userId,
    required this.assessmentCompleted,
  });

  final AppThemeColors colors;
  final String? userId;
  final bool? assessmentCompleted;

  @override
  State<AchievementsContainer> createState() => _AchievementsContainerState();
}

class _AchievementsContainerState extends State<AchievementsContainer> {
  late Future<({bool sheet, bool composition})> _existingItems;

  @override
  void initState() {
    super.initState();
    _existingItems = _checkExistingItems();
  }

  @override
  void didUpdateWidget(covariant AchievementsContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _existingItems = _checkExistingItems();
    }
  }

  // Older accounts can already have sheets or compositions without the new
  // permanent flags. Recognize them and record the flags for future visits.
  Future<({bool sheet, bool composition})> _checkExistingItems() async {
    final userId = widget.userId;
    if (userId == null) return (sheet: false, composition: false);

    final profile = FirebaseFirestore.instance.collection('users').doc(userId);
    Map<String, dynamic>? savedFlags;
    try {
      savedFlags = (await profile.get()).data();
    } catch (_) {
      // The collection checks below can still find older achievements.
    }

    Future<bool> check(
      String collection,
      String flag,
      String backfillFlag,
    ) async {
      if (savedFlags?[flag] == true) return true;
      try {
        final existing = await profile.collection(collection).limit(1).get();
        if (existing.docs.isEmpty) return false;
        try {
          await profile.set({
            flag: true,
            backfillFlag: true,
          }, SetOptions(merge: true));
        } catch (_) {
          // The existing item still counts during this visit.
        }
        return true;
      } catch (_) {
        return false;
      }
    }

    final results = await Future.wait([
      check('musicSheets', 'hasUploadedMusicSheet', 'sheetBadgeBackfilled'),
      check(
        'compositions',
        'hasCreatedComposition',
        'compositionBadgeBackfilled',
      ),
    ]);
    return (sheet: results[0], composition: results[1]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final userId = widget.userId;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, profileSnapshot) {
        return FutureBuilder<({bool sheet, bool composition})>(
          future: _existingItems,
          builder: (context, existingSnapshot) {
            final profile = profileSnapshot.data?.data();
            final practiceLevel = profile?['practiceLevel'] is int
                ? profile!['practiceLevel'] as int
                : profileSnapshot.hasData
                ? 1
                : null;
            final existing = existingSnapshot.data;
            final sheetEarned =
                profile?['hasUploadedMusicSheet'] == true ||
                existing?.sheet == true;
            final compositionEarned =
                profile?['hasCreatedComposition'] == true ||
                existing?.composition == true;
            final sheetKnown =
                profile?['hasUploadedMusicSheet'] == true ||
                existingSnapshot.connectionState == ConnectionState.done;
            final compositionKnown =
                profile?['hasCreatedComposition'] == true ||
                existingSnapshot.connectionState == ConnectionState.done;
            final badges = <_Badge>[
              _Badge(
                context.l10n.badgeFirstMeasure,
                context.l10n.badgeFirstMeasureDescription,
                'first_measure.png',
                widget.assessmentCompleted,
              ),
              _Badge(
                context.l10n.badgeSheetCollector,
                context.l10n.badgeSheetCollectorDescription,
                'sheet_collector.png',
                sheetKnown ? sheetEarned : null,
              ),
              _Badge(
                context.l10n.badgeFirstComposer,
                context.l10n.badgeFirstComposerDescription,
                'first_composer.png',
                compositionKnown ? compositionEarned : null,
              ),
              _Badge(
                context.l10n.badgeMiddleC,
                context.l10n.badgeMiddleCDescription,
                'middle_c.png',
                practiceLevel == null ? null : practiceLevel > 3,
              ),
              _Badge(
                context.l10n.badgeFirstMelody,
                context.l10n.badgeFirstMelodyDescription,
                'first_melody.png',
                practiceLevel == null ? null : practiceLevel > 6,
              ),
              _Badge(
                context.l10n.badgeGrowingMusician,
                context.l10n.badgeGrowingMusicianDescription,
                'growing_musician.png',
                practiceLevel == null ? null : practiceLevel > 9,
              ),
              _Badge(
                context.l10n.badgeChordBuilder,
                context.l10n.badgeChordBuilderDescription,
                'chord_builder.png',
                practiceLevel == null ? null : practiceLevel > 12,
              ),
              _Badge(
                context.l10n.badgeMusicNavigator,
                context.l10n.badgeMusicNavigatorDescription,
                'music_navigator.png',
                practiceLevel == null ? null : practiceLevel > 15,
              ),
              _Badge(
                context.l10n.badgeSoundSightMaster,
                context.l10n.badgeSoundSightMasterDescription,
                'soundsight_master.png',
                practiceLevel == null ? null : practiceLevel > 16,
              ),
            ];
            final earned = badges.where((badge) => badge.earned == true).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.achievements,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$earned / ${badges.length}',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: badges.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth >= 480 ? 4 : 3,
                        mainAxisExtent: 136,
                        crossAxisSpacing: AppSpacing.xs,
                        mainAxisSpacing: AppSpacing.xs,
                      ),
                      itemBuilder: (context, index) =>
                          _BadgeTile(badge: badges[index], colors: colors),
                    ),
                  ),
                ),
                const Gap(AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _AchievementDetailsScreen(
                          colors: colors,
                          badges: badges,
                        ),
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    label: Text(context.l10n.viewAchievementDetails),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Badge {
  const _Badge(this.title, this.description, this.filename, this.earned);

  final String title;
  final String description;
  final String filename;
  final bool? earned;
}

class _AchievementDetailsScreen extends StatelessWidget {
  const _AchievementDetailsScreen({required this.colors, required this.badges});

  final AppThemeColors colors;
  final List<_Badge> badges;

  @override
  Widget build(BuildContext context) {
    final earned = badges.where((badge) => badge.earned == true).length;
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        title: Text(context.l10n.achievementDetails),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: badges.length + 1,
        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              context.l10n.achievementProgress(earned, badges.length),
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w600,
              ),
            );
          }
          final badge = badges[index - 1];
          final unlocked = badge.earned == true;
          final status = badge.earned == null
              ? context.l10n.badgeChecking
              : unlocked
              ? context.l10n.badgeUnlocked
              : context.l10n.badgeLocked;
          return Semantics(
            label: '${badge.title}. $status. ${badge.description}',
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: unlocked ? 1 : .42,
                    child: Image.asset(
                      'assets/badge/${badge.filename}',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.title,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.body,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(AppSpacing.xs),
                        Text(
                          status,
                          style: TextStyle(
                            color: unlocked
                                ? colors.completedStageColor
                                : colors.secondaryTextColor,
                            fontSize: AppTextSizes.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        Text(
                          badge.description,
                          style: TextStyle(
                            color: colors.secondaryTextColor,
                            fontSize: AppTextSizes.label,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.colors});

  final _Badge badge;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned == true;
    final status = badge.earned == null
        ? context.l10n.badgeChecking
        : earned
        ? context.l10n.badgeUnlocked
        : context.l10n.badgeLocked;
    return Semantics(
      label: '${badge.title}, $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: earned ? 1 : .42,
              child: Image.asset(
                'assets/badge/${badge.filename}',
                width: 68,
                height: 68,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            const Gap(3),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: earned
                    ? colors.completedStageColor
                    : colors.secondaryTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
