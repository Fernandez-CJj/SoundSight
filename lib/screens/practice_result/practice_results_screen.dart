import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/players/sight_reading/practice_result_models.dart';
import 'package:soundsight/screens/players/sight_reading/practice_result_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

import 'practice_result_detail_screen.dart';

enum _ResultDateFilter { allTime, today, last7Days, last30Days }

enum _ResultAccuracyFilter { all, excellent, good, needsPractice }

enum _ResultSourceFilter { all, musicSheet, lesson, composition, challenge }

enum _ResultSort { newest, oldest, highestAccuracy, lowestAccuracy }

class PracticeResultsScreen extends StatefulWidget {
  const PracticeResultsScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<PracticeResultsScreen> createState() => _PracticeResultsScreenState();
}

class _PracticeResultsScreenState extends State<PracticeResultsScreen> {
  final PracticeResultService resultService = PracticeResultService();
  final Set<String> deletingResultIds = <String>{};
  final TextEditingController searchController = TextEditingController();
  late bool isDarkMode;
  late final String? userId;
  bool deletingAllResults = false;
  bool deletingResultInProgress = false;
  PracticeResultType? selectedPracticeType;
  _ResultDateFilter selectedDateFilter = _ResultDateFilter.allTime;
  _ResultAccuracyFilter selectedAccuracyFilter = _ResultAccuracyFilter.all;
  _ResultSourceFilter selectedSourceFilter = _ResultSourceFilter.all;
  _ResultSort selectedSort = _ResultSort.newest;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    userId = FirebaseAuth.instance.currentUser?.uid;
    loadTheme();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        title: Text(
          context.l10n.practiceResultsTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (deletingAllResults)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: context.l10n.practiceResultsDeleteAllTooltip,
              onPressed:
                  userId == null ||
                      deletingResultInProgress ||
                      deletingAllResults
                  ? null
                  : () {
                      deleteAllPracticeResults(colors);
                    },
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Color(0xFFDC2626),
              ),
            ),
          const Gap(AppSpacing.xs),
        ],
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
              title: context.l10n.practiceResultsSignIn,
              message: context.l10n.practiceResultsSignInDescription,
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
                    title: context.l10n.practiceResultsLoadFailed,
                    message: context.l10n.practiceResultsCheckConnection,
                  );
                }

                final availableResults = (snapshot.data ?? const [])
                    .where(
                      (result) =>
                          result.id == null ||
                          !deletingResultIds.contains(result.id),
                    )
                    .toList(growable: false);

                if (availableResults.isEmpty) {
                  return buildMessageState(
                    colors,
                    icon: Icons.insights_outlined,
                    title: context.l10n.practiceResultsEmpty,
                    message: context.l10n.practiceResultsEmptyDescription,
                  );
                }

                final filteredResults = filterAndSortResults(
                  availableResults,
                );

                return Column(
                  children: [
                    buildResultsFilters(colors, availableResults),
                    Expanded(
                      child: filteredResults.isEmpty
                          ? buildNoMatchingResults(colors)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              itemCount: filteredResults.length,
                              separatorBuilder: (_, _) =>
                                  const Gap(AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final result = filteredResults[index];
                                final resultId = result.id;

                                return Dismissible(
                                  key: ValueKey(
                                    resultId ??
                                        '${result.pieceTitle}-${result.completedAt}-$index',
                                  ),
                                  direction:
                                      resultId == null ||
                                          deletingAllResults ||
                                          deletingResultInProgress
                                      ? DismissDirection.none
                                      : DismissDirection.startToEnd,
                                  confirmDismiss: (_) => confirmDeleteResult(
                                    colors,
                                    result,
                                  ),
                                  onDismissed: (_) {
                                    dismissResult(result);
                                  },
                                  background: buildDeleteBackground(colors),
                                  child: buildResultCard(colors, result),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget buildResultsFilters(
    AppThemeColors colors,
    List<PracticeResultSummary> availableResults,
  ) {
    final hasArResults = availableResults.any(
      (result) => result.practiceType == PracticeResultType.arPerformance,
    );
    final typeOptions = <PracticeResultType?>[
      null,
      PracticeResultType.sightReading,
      PracticeResultType.synthesia,
      if (hasArResults) PracticeResultType.arPerformance,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border(bottom: BorderSide(color: colors.borderColor)),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.trim();
              });
            },
            textInputAction: TextInputAction.search,
            style: TextStyle(color: colors.primaryColor),
            decoration: InputDecoration(
              hintText: context.l10n.practiceResultsSearchHint,
              hintStyle: TextStyle(color: colors.secondaryTextColor),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.secondaryTextColor,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l10n.practiceResultsClearSearch,
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.surfaceColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(
                  color: colors.primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: typeOptions.map((type) {
                      final selected = selectedPracticeType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          selected: selected,
                          showCheckmark: false,
                          label: Text(
                            type == null
                                ? context.l10n.practiceResultsAll
                                : practiceTypeLabel(type),
                          ),
                          onSelected: (_) {
                            setState(() {
                              selectedPracticeType = type;
                            });
                          },
                          selectedColor: colors.primaryColor,
                          backgroundColor: colors.surfaceColor,
                          side: BorderSide(color: colors.borderColor),
                          labelStyle: TextStyle(
                            color: selected
                                ? colors.backgroundColor
                                : colors.primaryColor,
                            fontSize: AppTextSizes.caption,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
              const Gap(AppSpacing.sm),
              OutlinedButton(
                onPressed: () => showResultFilters(colors),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primaryColor,
                  side: BorderSide(color: colors.borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded, size: 18),
                    const Gap(AppSpacing.xs),
                    Text(context.l10n.practiceResultsFilters),
                    if (activeAdvancedFilterCount > 0) ...[
                      const Gap(AppSpacing.xs),
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeAdvancedFilterCount',
                          style: TextStyle(
                            color: colors.backgroundColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PracticeResultSummary> filterAndSortResults(
    List<PracticeResultSummary> results,
  ) {
    final normalizedSearch = searchQuery.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliestDate = switch (selectedDateFilter) {
      _ResultDateFilter.allTime => null,
      _ResultDateFilter.today => today,
      _ResultDateFilter.last7Days => today.subtract(const Duration(days: 6)),
      _ResultDateFilter.last30Days => today.subtract(const Duration(days: 29)),
    };

    final filtered = results.where((result) {
      if (normalizedSearch.isNotEmpty &&
          !result.pieceTitle.toLowerCase().contains(normalizedSearch)) {
        return false;
      }
      if (selectedPracticeType != null &&
          result.practiceType != selectedPracticeType) {
        return false;
      }
      if (earliestDate != null) {
        final completedAt = result.completedAt?.toLocal();
        if (completedAt == null || completedAt.isBefore(earliestDate)) {
          return false;
        }
      }
      if (!_matchesAccuracy(result.timingAccuracyPercentage)) {
        return false;
      }
      if (!_matchesSource(result.source)) {
        return false;
      }
      return true;
    }).toList();

    final undatedValue = DateTime(9999, 12, 31);
    DateTime resultDate(PracticeResultSummary result) {
      return result.completedAt?.toLocal() ?? undatedValue;
    }

    filtered.sort((first, second) {
      final comparison = switch (selectedSort) {
        _ResultSort.newest => resultDate(second).compareTo(resultDate(first)),
        _ResultSort.oldest => resultDate(first).compareTo(resultDate(second)),
        _ResultSort.highestAccuracy => second.timingAccuracyPercentage.compareTo(
          first.timingAccuracyPercentage,
        ),
        _ResultSort.lowestAccuracy => first.timingAccuracyPercentage.compareTo(
          second.timingAccuracyPercentage,
        ),
      };
      if (comparison != 0) return comparison;
      return resultDate(second).compareTo(resultDate(first));
    });

    return filtered;
  }

  bool _matchesAccuracy(int accuracy) {
    return switch (selectedAccuracyFilter) {
      _ResultAccuracyFilter.all => true,
      _ResultAccuracyFilter.excellent => accuracy >= 90,
      _ResultAccuracyFilter.good => accuracy >= 75 && accuracy < 90,
      _ResultAccuracyFilter.needsPractice => accuracy < 75,
    };
  }

  bool _matchesSource(String source) {
    return switch (selectedSourceFilter) {
      _ResultSourceFilter.all => true,
      _ResultSourceFilter.musicSheet => source == 'musicSheet',
      _ResultSourceFilter.lesson => source == 'lesson',
      _ResultSourceFilter.composition => source == 'composition',
      _ResultSourceFilter.challenge => source == 'challenge',
    };
  }

  int get activeAdvancedFilterCount {
    var count = 0;
    if (selectedDateFilter != _ResultDateFilter.allTime) count++;
    if (selectedAccuracyFilter != _ResultAccuracyFilter.all) count++;
    if (selectedSourceFilter != _ResultSourceFilter.all) count++;
    if (selectedSort != _ResultSort.newest) count++;
    return count;
  }

  bool get hasActiveResultsFilter {
    return searchQuery.isNotEmpty ||
        selectedPracticeType != null ||
        activeAdvancedFilterCount > 0;
  }

  Widget buildNoMatchingResults(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: AppIconSizes.xl,
              color: colors.secondaryTextColor,
            ),
            const Gap(AppSpacing.md),
            Text(
              context.l10n.practiceResultsNoMatches,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              context.l10n.practiceResultsNoMatchesDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryTextColor),
            ),
            if (hasActiveResultsFilter) ...[
              const Gap(AppSpacing.md),
              OutlinedButton.icon(
                onPressed: clearResultsFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primaryColor,
                  side: BorderSide(color: colors.borderColor),
                ),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(context.l10n.practiceResultsClearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void clearResultsFilters() {
    searchController.clear();
    setState(() {
      searchQuery = '';
      selectedPracticeType = null;
      selectedDateFilter = _ResultDateFilter.allTime;
      selectedAccuracyFilter = _ResultAccuracyFilter.all;
      selectedSourceFilter = _ResultSourceFilter.all;
      selectedSort = _ResultSort.newest;
    });
  }

  Future<void> showResultFilters(AppThemeColors colors) async {
    var pendingDateFilter = selectedDateFilter;
    var pendingAccuracyFilter = selectedAccuracyFilter;
    var pendingSourceFilter = selectedSourceFilter;
    var pendingSort = selectedSort;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, refreshSheet) {
            return FractionallySizedBox(
              heightFactor: 0.86,
              child: Material(
                color: colors.surfaceColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.practiceResultsFilterAndSort,
                                style: TextStyle(
                                  color: colors.primaryColor,
                                  fontSize: AppTextSizes.sectionTitle,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                clearResultsFilters();
                              },
                              child: Text(
                                context.l10n.practiceResultsClearAll,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              tooltip: context.l10n.practiceResultsCloseFilters,
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: colors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: colors.borderColor),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildFilterChoiceSection<_ResultDateFilter>(
                                colors: colors,
                                title: context.l10n.practiceResultsDate,
                                options: _ResultDateFilter.values,
                                selectedValue: pendingDateFilter,
                                labelFor: dateFilterLabel,
                                onChanged: (value) {
                                  refreshSheet(() {
                                    pendingDateFilter = value;
                                  });
                                },
                              ),
                              const Gap(AppSpacing.lg),
                              buildFilterChoiceSection<
                                _ResultAccuracyFilter
                              >(
                                colors: colors,
                                title: context.l10n.practiceResultsAccuracy,
                                options: _ResultAccuracyFilter.values,
                                selectedValue: pendingAccuracyFilter,
                                labelFor: accuracyFilterLabel,
                                onChanged: (value) {
                                  refreshSheet(() {
                                    pendingAccuracyFilter = value;
                                  });
                                },
                              ),
                              const Gap(AppSpacing.lg),
                              buildFilterChoiceSection<_ResultSourceFilter>(
                                colors: colors,
                                title: context.l10n.practiceResultsSource,
                                options: _ResultSourceFilter.values,
                                selectedValue: pendingSourceFilter,
                                labelFor: sourceFilterLabel,
                                onChanged: (value) {
                                  refreshSheet(() {
                                    pendingSourceFilter = value;
                                  });
                                },
                              ),
                              const Gap(AppSpacing.lg),
                              buildFilterChoiceSection<_ResultSort>(
                                colors: colors,
                                title: context.l10n.practiceResultsSortBy,
                                options: _ResultSort.values,
                                selectedValue: pendingSort,
                                labelFor: sortLabel,
                                onChanged: (value) {
                                  refreshSheet(() {
                                    pendingSort = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.surfaceColor,
                          border: Border(
                            top: BorderSide(color: colors.borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  refreshSheet(() {
                                    pendingDateFilter =
                                        _ResultDateFilter.allTime;
                                    pendingAccuracyFilter =
                                        _ResultAccuracyFilter.all;
                                    pendingSourceFilter =
                                        _ResultSourceFilter.all;
                                    pendingSort = _ResultSort.newest;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.primaryColor,
                                  side: BorderSide(color: colors.borderColor),
                                ),
                                child: Text(
                                  context.l10n.practiceResultsReset,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const Gap(AppSpacing.sm),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDateFilter = pendingDateFilter;
                                    selectedAccuracyFilter =
                                        pendingAccuracyFilter;
                                    selectedSourceFilter = pendingSourceFilter;
                                    selectedSort = pendingSort;
                                  });
                                  Navigator.of(sheetContext).pop();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primaryColor,
                                  foregroundColor: colors.backgroundColor,
                                ),
                                child: Text(
                                  context.l10n.practiceResultsApplyFilters,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildFilterChoiceSection<T>({
    required AppThemeColors colors,
    required String title,
    required List<T> options,
    required T selectedValue,
    required String Function(T value) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.body,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Gap(AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((option) {
            final selected = option == selectedValue;
            return ChoiceChip(
              selected: selected,
              showCheckmark: false,
              label: Text(labelFor(option)),
              onSelected: (_) => onChanged(option),
              selectedColor: colors.primaryColor,
              backgroundColor: colors.backgroundColor,
              side: BorderSide(color: colors.borderColor),
              labelStyle: TextStyle(
                color: selected
                    ? colors.backgroundColor
                    : colors.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  String dateFilterLabel(_ResultDateFilter filter) {
    return switch (filter) {
      _ResultDateFilter.allTime => context.l10n.practiceResultsAllTime,
      _ResultDateFilter.today => context.l10n.practiceResultsToday,
      _ResultDateFilter.last7Days => context.l10n.practiceResultsLast7Days,
      _ResultDateFilter.last30Days => context.l10n.practiceResultsLast30Days,
    };
  }

  String accuracyFilterLabel(_ResultAccuracyFilter filter) {
    return switch (filter) {
      _ResultAccuracyFilter.all => context.l10n.practiceResultsAllScores,
      _ResultAccuracyFilter.excellent => '90–100%',
      _ResultAccuracyFilter.good => '75–89%',
      _ResultAccuracyFilter.needsPractice => context.l10n.practiceResultsBelow75,
    };
  }

  String sourceFilterLabel(_ResultSourceFilter filter) {
    return switch (filter) {
      _ResultSourceFilter.all => context.l10n.practiceResultsAllSources,
      _ResultSourceFilter.musicSheet => context.l10n.practiceResultsMusicSheet,
      _ResultSourceFilter.lesson => context.l10n.practiceResultsLesson,
      _ResultSourceFilter.composition =>
        context.l10n.practiceResultsComposition,
      _ResultSourceFilter.challenge => context.l10n.practiceResultsChallenge,
    };
  }

  String sortLabel(_ResultSort sort) {
    return switch (sort) {
      _ResultSort.newest => context.l10n.practiceResultsNewestFirst,
      _ResultSort.oldest => context.l10n.practiceResultsOldestFirst,
      _ResultSort.highestAccuracy =>
        context.l10n.practiceResultsHighestAccuracy,
      _ResultSort.lowestAccuracy =>
        context.l10n.practiceResultsLowestAccuracy,
    };
  }

  Widget buildResultCard(AppThemeColors colors, PracticeResultSummary result) {
    final weakClef = result.weakestClef;
    final accentColor = resultTypeColor(colors, result.practiceType);
    final typeIcon = resultTypeIcon(result.practiceType);
    final suggestion = localizedResultSuggestion(result);

    return Material(
      color: Color.alphaBlend(
        accentColor.withValues(alpha: 0.06),
        colors.surfaceColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  '${result.timingAccuracyPercentage}%',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    resultTypeLabel(
                      accentColor: accentColor,
                      icon: typeIcon,
                      label: practiceTypeLabel(result.practiceType),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      result.pieceTitle,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.l10n.practiceResultsCardMetadata(
                        sourceLabel(result.source),
                        formatDate(result.completedAt),
                        result.scoreText,
                      ),
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
                          context.l10n.practiceResultsWrongNotesCount(
                            result.wrongCount,
                          ),
                        ),
                        resultChip(
                          colors,
                          Icons.timer_off_outlined,
                          context.l10n.practiceResultsNotPlayedCount(
                            result.missedCount,
                          ),
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

  Widget resultTypeLabel({
    required Color accentColor,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const Gap(AppSpacing.xs),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: accentColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color resultTypeColor(
    AppThemeColors colors,
    PracticeResultType practiceType,
  ) {
    return switch (practiceType) {
      PracticeResultType.sightReading => colors.sightReadingResultColor,
      PracticeResultType.synthesia => colors.synthesiaResultColor,
      PracticeResultType.arPerformance => colors.arPerformanceResultColor,
    };
  }

  IconData resultTypeIcon(PracticeResultType practiceType) {
    return switch (practiceType) {
      PracticeResultType.sightReading => Icons.menu_book_rounded,
      PracticeResultType.synthesia => Icons.piano_rounded,
      PracticeResultType.arPerformance => Icons.view_in_ar_rounded,
    };
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
              textAlign: TextAlign.center,
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

  Widget buildDeleteBackground(AppThemeColors colors) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
          const Gap(AppSpacing.xs),
          Text(
            context.l10n.delete,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> confirmDeleteResult(
    AppThemeColors colors,
    PracticeResultSummary result,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: colors.surfaceColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: Text(
                context.l10n.practiceResultsDeleteQuestion,
                style: TextStyle(color: colors.primaryColor),
              ),
              content: Text(
                context.l10n.practiceResultsDeleteDescription(
                  result.pieceTitle,
                ),
                style: TextStyle(color: colors.secondaryTextColor),
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                    side: BorderSide(color: colors.borderColor),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(context.l10n.delete),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> dismissResult(PracticeResultSummary result) async {
    final resultId = result.id;

    if (resultId == null) {
      return;
    }

    setState(() {
      deletingResultIds.add(resultId);
      deletingResultInProgress = true;
    });

    try {
      await resultService.deleteResult(resultId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        deletingResultIds.remove(resultId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.practiceResultsDeleteFailed),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          deletingResultInProgress = false;
        });
      }
    }
  }

  Future<void> deleteAllPracticeResults(AppThemeColors colors) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            context.l10n.practiceResultsDeleteAllQuestion,
            style: TextStyle(color: colors.primaryColor),
          ),
          content: Text(
            context.l10n.practiceResultsDeleteAllDescription,
            style: TextStyle(color: colors.secondaryTextColor),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.practiceResultsDeleteAll),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      deletingAllResults = true;
    });

    try {
      await resultService.deleteAllResults();

      if (!mounted) {
        return;
      }

      setState(() {
        deletingResultIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.practiceResultsDeleteAllSuccess)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.practiceResultsDeleteAllFailed),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          deletingAllResults = false;
        });
      }
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
    return switch (source) {
      'lesson' => context.l10n.practiceResultsLesson,
      'composition' => context.l10n.practiceResultsComposition,
      'challenge' => context.l10n.practiceResultsChallenge,
      _ => context.l10n.practiceResultsMusicSheet,
    };
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return context.l10n.practiceResultsJustNow;
    }

    final local = date.toLocal();
    return DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(local);
  }

  String clefPracticeLabel(String clef) {
    switch (clef.toLowerCase()) {
      case 'treble':
        return context.l10n.practiceResultsPracticeHigherNotes;
      case 'bass':
        return context.l10n.practiceResultsPracticeLowerNotes;
      default:
        return context.l10n.practiceResultsPracticeClef(clef.toLowerCase());
    }
  }

  String practiceTypeLabel(PracticeResultType practiceType) {
    return switch (practiceType) {
      PracticeResultType.sightReading =>
        context.l10n.practiceResultsSightReading,
      PracticeResultType.synthesia => context.l10n.practiceResultsSynthesia,
      PracticeResultType.arPerformance =>
        context.l10n.practiceResultsArPerformance,
    };
  }

  String localizedResultSuggestion(PracticeResultSummary result) {
    final difficultNotes = result.noteBreakdown
        .where((item) => item.errorCount > 0)
        .toList()
      ..sort((first, second) => second.errorCount.compareTo(first.errorCount));
    final difficultNote = difficultNotes.isEmpty
        ? null
        : midiNoteName(difficultNotes.first.midiNote);

    if (result.practiceType == PracticeResultType.sightReading) {
      if (result.errorEventCount == 0 &&
          result.wrongCount == 0 &&
          result.missedCount == 0) {
        return context.l10n.sightReadingSuggestionPerfect;
      }
      if (result.timingAccuracyPercentage >= 90) {
        return context.l10n.sightReadingSuggestionAlmostPerfect;
      }
      if (difficultNote != null) {
        return context.l10n.sightReadingSuggestionDifficultNote(difficultNote);
      }
      if (result.missedCount > 0) {
        return context.l10n.sightReadingSuggestionMissedNotes;
      }
      return context.l10n.sightReadingSuggestionGeneralPractice;
    }

    if (result.errorEventCount == 0 &&
        result.wrongCount == 0 &&
        result.missedCount == 0) {
      return context.l10n.synthesiaSuggestionPerfect;
    }
    if (result.timingAccuracyPercentage >= 90) {
      return context.l10n.synthesiaSuggestionAlmostPerfect;
    }
    if (difficultNote != null) {
      return context.l10n.synthesiaSuggestionDifficultNote(difficultNote);
    }
    if (result.missedCount > 0) {
      return context.l10n.synthesiaSuggestionMissedNotes;
    }
    if (result.wrongCount > 0) {
      return context.l10n.synthesiaSuggestionWrongNotes;
    }
    return context.l10n.practiceResultsGeneralSuggestion;
  }

  String midiNoteName(int midiNote) {
    const noteNames = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final octave = (midiNote ~/ 12) - 1;
    return '${noteNames[midiNote % 12]}$octave';
  }
}
