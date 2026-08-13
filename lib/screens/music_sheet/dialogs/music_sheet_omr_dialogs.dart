import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/music_sheet/models/omr_conversion_result.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class RecognizeMusicSheetDialog extends StatelessWidget {
  const RecognizeMusicSheetDialog({
    super.key,
    required this.colors,
    required this.title,
    required this.isReconversion,
  });

  final AppThemeColors colors;
  final String title;
  final bool isReconversion;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        isReconversion
            ? 'Translate this sheet again?'
            : 'Translate music sheet?',
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        isReconversion
            ? 'SoundSight will create a new translation for "$title" and '
                  'replace its current MusicXML and audio preview.'
            : 'SoundSight will translate "$title" into playable music. '
                  'This may take a few minutes.',
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
          height: 1.4,
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                    side: BorderSide(color: colors.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
            Gap(AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: colors.backgroundColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    isReconversion ? 'Continue' : 'Translate',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MusicSheetOmrLoadingDialog extends StatelessWidget {
  const MusicSheetOmrLoadingDialog({
    super.key,
    required this.colors,
  });

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colors.surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: colors.primaryColor,
                  strokeWidth: 3,
                ),
              ),
              Gap(AppSpacing.lg),
              Text(
                'Translating music sheet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gap(AppSpacing.xs),
              Text(
                'Audiveris is reading the notes. Please wait and keep '
                'the app open.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.label,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MusicSheetOmrSuccessDialog extends StatelessWidget {
  const MusicSheetOmrSuccessDialog({
    super.key,
    required this.colors,
    required this.result,
  });

  final AppThemeColors colors;
  final OmrConversionResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF16A34A),
          size: AppIconSizes.lg,
        ),
      ),
      title: Text(
        'Translation complete',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'SoundSight recognized ${result.noteCount} notes across '
        '${result.partCount} ${result.partCount == 1 ? 'part' : 'parts'}.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
          height: 1.4,
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: colors.backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class MusicSheetOmrErrorDialog extends StatelessWidget {
  const MusicSheetOmrErrorDialog({
    super.key,
    required this.colors,
    required this.message,
  });

  final AppThemeColors colors;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFDC2626),
          size: AppIconSizes.lg,
        ),
      ),
      title: Text(
        'Translation failed',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
          height: 1.4,
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: colors.backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }
}
