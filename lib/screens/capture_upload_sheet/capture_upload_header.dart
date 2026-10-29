import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CaptureUploadHeader extends StatelessWidget {
  const CaptureUploadHeader({
    super.key,
    required this.colors,
    required this.isPickingFiles,
    required this.isPickingAudio,
    required this.isSavingSheet,
    required this.isUploadLocked,
    required this.isCaptureLocked,
    required this.isAudioLocked,
    required this.onUpload,
    required this.onCapture,
    required this.onAudio,
  });

  final AppThemeColors colors;
  final bool isPickingFiles;
  final bool isPickingAudio;
  final bool isSavingSheet;
  final bool isUploadLocked;
  final bool isCaptureLocked;
  final bool isAudioLocked;
  final VoidCallback onUpload;
  final VoidCallback onCapture;
  final VoidCallback onAudio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.addYourSheetMusic,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.screenTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(AppSpacing.xs),
        Text(
          context.l10n.addSheetDescription,
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
                      context.l10n.chooseOneMethod,
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
                  context.l10n.sheetMethodLimits,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ),
              Gap(AppSpacing.sm),
              Divider(height: 1, color: colors.borderColor),
              Gap(AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.volume_off_outlined,
                    color: colors.secondaryTextColor,
                    size: 16,
                  ),
                  Gap(AppSpacing.xs),
                  Expanded(
                    child: Text(
                      context.l10n.recordingNoiseReminder,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ),
                ],
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
                  title: isPickingFiles && !isPickingAudio
                      ? context.l10n.openingPdf
                      : context.l10n.uploadPdf,
                  description: context.l10n.uploadPdfDescription,
                  isLoading: isPickingFiles && !isPickingAudio,
                  isLocked: isUploadLocked,
                  onTap: isPickingFiles || isSavingSheet || isUploadLocked
                      ? null
                      : onUpload,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: _SheetActionCard(
                  colors: colors,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.camera_alt_rounded,
                  title: context.l10n.capturePages,
                  description: context.l10n.capturePagesDescription,
                  isLocked: isCaptureLocked,
                  onTap: isPickingFiles || isSavingSheet || isCaptureLocked
                      ? null
                      : onCapture,
                ),
              ),
            ],
          ),
        ),
        Gap(AppSpacing.sm),
        SizedBox(
          height: 174,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SheetActionCard(
                  colors: colors,
                  color: colors.synthesiaResultColor,
                  icon: Icons.audio_file_rounded,
                  title: context.l10n.uploadAudio,
                  description: context.l10n.uploadAudioDescription,
                  isLoading: isPickingAudio,
                  isLocked: isAudioLocked,
                  onTap: isPickingFiles || isSavingSheet || isAudioLocked
                      ? null
                      : onAudio,
                ),
              ),
              Gap(AppSpacing.sm),
              Expanded(
                child: _SheetActionCard(
                  colors: colors,
                  color: colors.synthesiaResultColor,
                  icon: Icons.video_file_rounded,
                  title: context.l10n.uploadVideo,
                  description: context.l10n.uploadVideoComingSoon,
                  isLocked: true,
                  onTap: null,
                ),
              ),
            ],
          ),
        ),
        Gap(AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.swipe_right_rounded,
              color: colors.secondaryTextColor,
              size: 16,
            ),
            Gap(AppSpacing.xs),
            Expanded(
              child: Text(
                context.l10n.swipeToSwitchMethod,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
            ),
          ],
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
