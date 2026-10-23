import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class UnsavedCompositionDialog extends StatelessWidget {
  const UnsavedCompositionDialog({super.key, required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      icon: Icon(Icons.warning_amber_rounded, color: colors.primaryColor),
      title: Text(
        context.l10n.discardUnsavedChanges,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.primaryColor),
      ),
      content: Text(
        context.l10n.discardUnsavedChangesDescription,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.secondaryTextColor),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primaryColor,
            side: BorderSide(color: colors.borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(context.l10n.keepEditing),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(context.l10n.discard),
        ),
      ],
    );
  }
}
