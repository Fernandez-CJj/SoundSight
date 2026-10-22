import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class SaveCompositionConfirmationDialog extends StatelessWidget {
  const SaveCompositionConfirmationDialog({
    super.key,
    required this.colors,
    required this.isExistingComposition,
  });

  final AppThemeColors colors;
  final bool isExistingComposition;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      icon: Icon(Icons.save_outlined, color: colors.primaryColor),
      title: Text(
        isExistingComposition
            ? context.l10n.saveChangesQuestion
            : context.l10n.saveCompositionQuestion,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        isExistingComposition
            ? context.l10n.replaceSavedCompositionDescription
            : context.l10n.createCompositionFilesDescription,
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
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.save_outlined),
          label: Text(context.l10n.save),
          style: FilledButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}
