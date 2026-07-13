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
    required this.onUpload,
    required this.onCapture,
  });

  final AppThemeColors colors;
  final bool isPickingFiles;
  final bool isSavingSheet;
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
          'Upload an existing file or capture a clear photo of a printed sheet.',
          style: TextStyle(
            color: colors.secondaryTextColor,
            fontSize: AppTextSizes.label,
            height: 1.45,
          ),
        ),
        Gap(AppSpacing.md),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
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
                      'Up to 20 images or 1 PDF',
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
                  'Images: 5 MB each  -  PDF: 20 MB, 20 pages',
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
                  title: isPickingFiles ? 'Opening files...' : 'Upload',
                  description: 'Choose files from your device.',
                  isLoading: isPickingFiles,
                  onTap: isPickingFiles || isSavingSheet ? null : onUpload,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: _SheetActionCard(
                  colors: colors,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.camera_alt_rounded,
                  title: 'Capture',
                  description: 'Take a photo with your camera.',
                  onTap: isSavingSheet ? null : onCapture,
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
  });

  final AppThemeColors colors;
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceColor,
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
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: color,
                            ),
                          )
                        : Icon(icon, color: color, size: 27),
                  ),
                  Icon(
                    Icons.north_east_rounded,
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
