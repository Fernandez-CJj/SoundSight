import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.colors,
    required this.onMusicSheets,
    required this.onUploadSheet,
    required this.onCaptureSheet,
    required this.onComposition,
  });

  final AppThemeColors colors;
  final VoidCallback onMusicSheets;
  final VoidCallback onUploadSheet;
  final VoidCallback onCaptureSheet;
  final VoidCallback onComposition;

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      _QuickAction(
        'Music Sheets',
        Icons.queue_music,
        const Color(0xFF3B82F6),
        onMusicSheets,
      ),
      _QuickAction(
        'Upload Sheet',
        Icons.upload,
        const Color(0xFF22C55E),
        onUploadSheet,
      ),
      _QuickAction(
        'Capture Sheet',
        Icons.camera_alt_outlined,
        const Color(0xFFF59E0B),
        onCaptureSheet,
      ),
      const _QuickAction(
        'Saved Sheets',
        Icons.folder_open,
        Color(0xFF8B5CF6),
        null,
      ),
      _QuickAction(
        'Composition',
        Icons.edit_outlined,
        const Color(0xFFEC4899),
        onComposition,
      ),
      const _QuickAction(
        'Practice Results',
        Icons.bar_chart,
        Color(0xFF06B6D4),
        null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 520 ? 4 : 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final action = quickActions[index];

                return Material(
                  color: colors.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    side: BorderSide(color: colors.borderColor),
                  ),
                  child: InkWell(
                    onTap: action.onTap,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: action.color.withOpacity(0.14),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 24,
                          ),
                        ),
                        const Gap(AppSpacing.xs),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.color, this.onTap);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}
