import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class MusicSheetOmrStatusCard extends StatelessWidget {
  const MusicSheetOmrStatusCard({
    super.key,
    required this.colors,
    required this.status,
    required this.partCount,
    required this.noteCount,
    required this.isConverting,
    required this.onRecognize,
  });

  final AppThemeColors colors;
  final String status;
  final int partCount;
  final int noteCount;
  final bool isConverting;
  final VoidCallback onRecognize;

  @override
  Widget build(BuildContext context) {
    final isProcessing = status == 'processing' || isConverting;
    final isCompleted = status == 'completed';
    final isFailed = status == 'failed';
    final accentColor = isCompleted
        ? const Color(0xFF16A34A)
        : isFailed
        ? const Color(0xFFDC2626)
        : colors.primaryColor;
    final icon = isCompleted
        ? Icons.check_rounded
        : isFailed
        ? Icons.refresh_rounded
        : Icons.document_scanner_outlined;
    final title = isCompleted
        ? 'Translation ready'
        : isFailed
        ? 'Translation failed'
        : isProcessing
        ? 'Translating music sheet'
        : 'Translate music sheet';
    final subtitle = isCompleted
        ? '$noteCount notes • $partCount ${partCount == 1 ? 'part' : 'parts'}'
        : isFailed
        ? 'The sheet could not be translated. You can try again.'
        : isProcessing
        ? 'Audiveris is recognizing the notes.'
        : 'Create MusicXML and an audio preview.';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: isProcessing
                ? Padding(
                    padding: EdgeInsets.all(AppSpacing.sm + 2),
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(
                    icon,
                    color: accentColor,
                    size: AppIconSizes.md,
                  ),
          ),
          Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ],
            ),
          ),
          if (!isProcessing) ...[
            Gap(AppSpacing.sm),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: onRecognize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? colors.backgroundColor
                      : colors.primaryColor,
                  foregroundColor: isCompleted
                      ? colors.primaryColor
                      : colors.backgroundColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  side: isCompleted
                      ? BorderSide(color: colors.borderColor)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  isCompleted
                      ? 'Reconvert'
                      : isFailed
                      ? 'Retry'
                      : 'Translate',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
