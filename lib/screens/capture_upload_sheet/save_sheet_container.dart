import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class SaveSheetContainer extends StatelessWidget {
  const SaveSheetContainer({
    super.key,
    required this.colors,
    required this.isSavingSheet,
    required this.uploadProgress,
    required this.onSave,
  });

  final AppThemeColors colors;
  final bool isSavingSheet;
  final double uploadProgress;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          border: Border(top: BorderSide(color: colors.borderColor)),
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isSavingSheet ? null : onSave,
            icon: isSavingSheet
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: uploadProgress == 0 ? null : uploadProgress,
                      strokeWidth: 2.5,
                      color: colors.backgroundColor,
                    ),
                  )
                : Icon(Icons.cloud_upload_outlined, size: 21),
            label: Text(
              isSavingSheet
                  ? 'Saving ${(uploadProgress * 100).round()}%'
                  : 'Save Sheet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: colors.backgroundColor,
              disabledBackgroundColor: colors.primaryColor,
              disabledForegroundColor: colors.backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
