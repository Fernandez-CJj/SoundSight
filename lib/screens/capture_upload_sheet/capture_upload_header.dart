import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CaptureUploadHeader extends StatelessWidget {
  const CaptureUploadHeader({
    super.key,
    required this.colors,
    required this.isPickingFiles,
    required this.isSavingSheet,
    required this.isUploadLocked,
    required this.isCaptureLocked,
    required this.onUpload,
    required this.onCapture,
  });

  final AppThemeColors colors;
  final bool isPickingFiles;
  final bool isSavingSheet;
  final bool isUploadLocked;
  final bool isCaptureLocked;
  final VoidCallback onUpload;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your sheet music',
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.screenTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(AppSpacing.xs),
        Text(
          'Upload one PDF or capture clear photos of a printed sheet.',
          style: TextStyle(
            color: colors.secondaryTextColor,
            fontSize: AppTextSizes.label,
            height: 1.45,
          ),
        ),
        Gap(AppSpacing.md),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    color: colors.secondaryTextColor,
                    size: 16,
                  ),
                  Gap(AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Choose one method per sheet',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(AppSpacing.xs),
              Padding(
                padding: EdgeInsets.only(left: AppSpacing.lg),
                child: Text(
                  '1 PDF (20 MB, 20 pages) or up to 20 captured images (5 MB each). They cannot be combined.',
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(AppSpacing.lg),
        SizedBox(
          height: 174,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SheetActionCard(
                  colors: colors,
                  color: const Color(0xFF3B82F6),
                  icon: Icons.upload_file_rounded,
                  title: isPickingFiles ? 'Opening PDF...' : 'Upload PDF',
                  description: 'Choose 1 PDF, up to 20 MB and 20 pages.',
                  isLoading: isPickingFiles,
                  isLocked: isUploadLocked,
                  onTap: isPickingFiles || isSavingSheet ? null : onUpload,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: _SheetActionCard(
                  colors: colors,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.camera_alt_rounded,
                  title: 'Capture Pages',
                  description: 'Capture up to 20 images, 5 MB each.',
                  isLocked: isCaptureLocked,
                  onTap: isPickingFiles || isSavingSheet ? null : onCapture,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetActionCard extends StatelessWidget {
  const _SheetActionCard({
    required this.colors,
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isLoading = false,
    this.isLocked = false,
  });

  final AppThemeColors colors;
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final actionColor = isLocked ? colors.secondaryTextColor : color;

    return Material(
      color: isLocked
          ? colors.secondaryTextColor.withValues(alpha: 0.06)
          : colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: actionColor,
                            ),
                          )
                        : Icon(icon, color: actionColor, size: 27),
                  ),
                  Icon(
                    isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.north_east_rounded,
                    color: colors.secondaryTextColor,
                    size: 18,
                  ),
                ],
              ),
              Gap(AppSpacing.md),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gap(AppSpacing.xs),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
