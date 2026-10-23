import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CalibrationWalkthroughDialog extends StatefulWidget {
  const CalibrationWalkthroughDialog({
    super.key,
    required this.colors,
  });

  final AppThemeColors colors;

  @override
  State<CalibrationWalkthroughDialog> createState() =>
      _CalibrationWalkthroughDialogState();
}

class _CalibrationWalkthroughDialogState
    extends State<CalibrationWalkthroughDialog> {
  final PageController pageController = PageController();
  int currentPage = 0;

  static const int pageCount = 4;

  @override
  Widget build(BuildContext context) {
    AppThemeColors colors = widget.colors;
    List<_CalibrationGuidePage> pages = [
      _CalibrationGuidePage(
        imagePath: 'assets/calibration/guide_1.png',
        title: context.l10n.calibrationGuideMountTitle,
        description: context.l10n.calibrationGuideMountDescription,
      ),
      _CalibrationGuidePage(
        imagePath: 'assets/calibration/guide2.png',
        title: context.l10n.calibrationGuideDetectedGroupTitle,
        description: context.l10n.calibrationGuideDetectedGroupDescription,
        emphasis: context.l10n.calibrationGuideDetectedGroupEmphasis,
      ),
      _CalibrationGuidePage(
        imagePath: 'assets/calibration/guide_3.png',
        title: context.l10n.calibrationGuideAdjustCornersTitle,
        description: context.l10n.calibrationGuideAdjustCornersDescription,
        emphasis: context.l10n.calibrationGuideAdjustCornersEmphasis,
      ),
      _CalibrationGuidePage(
        imagePath: 'assets/calibration/guide_4.png',
        title: context.l10n.calibrationGuideMiddleCTitle,
        description: context.l10n.calibrationGuideMiddleCDescription,
      ),
    ];

    double availableHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
        child: SizedBox(
          width: 760,
          height: availableHeight,
          child: Column(
            children: [
              _buildHeader(colors),
              Divider(height: 1, color: colors.borderColor),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: pages.length,
                  onPageChanged: (int index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return _buildPage(colors, pages[index]);
                  },
                ),
              ),
              Divider(height: 1, color: colors.borderColor),
              _buildFooter(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: () => Navigator.of(context).pop(false),
            color: colors.primaryColor,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.l10n.calibrationGuideTitle,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: colors.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Text(
              context.l10n.skip,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    AppThemeColors colors,
    _CalibrationGuidePage page,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double imageHeight = (constraints.maxHeight * 0.58)
            .clamp(150.0, 340.0)
            .toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: imageHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.asset(
                      page.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              context.l10n.calibrationGuideImageUnavailable,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.secondaryTextColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                page.title,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                page.description,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.body,
                  height: 1.4,
                ),
              ),
              if (page.emphasis != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFFFB300),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          page.emphasis!,
                          softWrap: true,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.label,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(AppThemeColors colors) {
    bool isLastPage = currentPage == pageCount - 1;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(pageCount, (int index) {
              bool isActive = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primaryColor
                      : colors.borderColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${currentPage + 1} / $pageCount',
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: currentPage == 0 ? null : _showPreviousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                    disabledForegroundColor: colors.secondaryTextColor,
                    side: BorderSide(color: colors.borderColor),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    context.l10n.back,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLastPage
                      ? () => Navigator.of(context).pop(true)
                      : _showNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: colors.backgroundColor,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    isLastPage
                        ? context.l10n.startCalibration
                        : context.l10n.next,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPreviousPage() {
    pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showNextPage() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

class _CalibrationGuidePage {
  const _CalibrationGuidePage({
    required this.imagePath,
    required this.title,
    required this.description,
    this.emphasis,
  });

  final String imagePath;
  final String title;
  final String description;
  final String? emphasis;
}
