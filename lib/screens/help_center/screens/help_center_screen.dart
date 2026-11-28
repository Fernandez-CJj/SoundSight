import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/help_center/data/help_features.dart';
import 'package:soundsight/screens/help_center/dialogs/help_guide_dialog.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/help_center/models/help_feature.dart';
import 'package:soundsight/screens/help_center/localization/help_category_localization.dart';
import 'package:soundsight/screens/help_center/widgets/help_center_theme.dart';
import 'package:soundsight/screens/help_center/widgets/help_feature_tile.dart';
import 'package:soundsight/screens/help_center/widgets/help_contact_section.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  HelpCategory _selectedCategory = HelpCategory.all;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]));
    super.dispose();
  }

  Future<void> _openGuide(HelpFeature feature, AppThemeColors colors) async {
    await showDialog<void>(
      context: context,
      barrierColor: colors.isDarkMode
          ? colors.backgroundColor.withValues(alpha: 0.85)
          : colors.primaryColor.withValues(alpha: 0.35),
      builder: (context) => Theme(
        data: helpCenterTheme(context, colors),
        child: HelpGuideDialog(feature: feature, colors: colors),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(widget.isDarkMode);
    final l10n = context.l10n;
    final features = buildHelpFeatures(l10n).where((feature) =>
      _selectedCategory == HelpCategory.all || feature.category == _selectedCategory,
    ).toList();

    return Theme(
      data: helpCenterTheme(context, colors),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          backgroundColor: colors.backgroundColor,
          foregroundColor: colors.primaryColor,
          surfaceTintColor: colors.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            l10n.helpCenterTitle,
            style: TextStyle(color: colors.primaryColor, fontSize: AppTextSizes.sectionTitle, fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            labelColor: colors.primaryColor,
            unselectedLabelColor: colors.secondaryTextColor,
            indicatorColor: colors.primaryColor,
            dividerColor: colors.borderColor,
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            labelStyle: const TextStyle(fontSize: AppTextSizes.label, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: l10n.helpCenterGuidesTab),
              Tab(text: l10n.helpCenterContactTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                key: const PageStorageKey('help-center-guides'),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.helpCenterHeading,
                              style: TextStyle(color: colors.primaryColor, fontSize: AppTextSizes.display, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.helpCenterIntroduction,
                            style: TextStyle(color: colors.secondaryTextColor, fontSize: AppTextSizes.label, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          for (final category in HelpCategory.values)
                            Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: ChoiceChip(
                                label: Text(category.label(l10n)),
                                selected: category == _selectedCategory,
                                onSelected: (_) {
                                  setState(() => _selectedCategory = category);
                                },
                                showCheckmark: false,
                                backgroundColor: colors.surfaceColor,
                                selectedColor: colors.primaryColor,
                                surfaceTintColor: colors.surfaceColor,
                                labelStyle: TextStyle(
                                  color: category == _selectedCategory ? colors.backgroundColor : colors.primaryColor,
                                  fontSize: AppTextSizes.label,
                                  fontWeight: category == _selectedCategory ? FontWeight.w600 : FontWeight.w400,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                                side: BorderSide(color: category == _selectedCategory ? colors.primaryColor : colors.borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.helpCenterBrowse,
                              style: TextStyle(color: colors.primaryColor, fontSize: AppTextSizes.body, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.helpCenterGuideCount(features.length), style: TextStyle(color: colors.secondaryTextColor, fontSize: AppTextSizes.caption)),
                        ],
                      ),
                    ),
                  ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index.isOdd) return const SizedBox(height: AppSpacing.sm);
                            final feature = features[index ~/ 2];
                            return HelpFeatureTile(
                              key: ValueKey(feature.id),
                              feature: feature,
                              colors: colors,
                              onTap: () => _openGuide(feature, colors),
                            );
                          },
                          childCount: features.isEmpty ? 0 : features.length * 2 - 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
            ),
            HelpContactSection(colors: colors),
          ],
        ),
        ),
      ),
    );
  }
}
