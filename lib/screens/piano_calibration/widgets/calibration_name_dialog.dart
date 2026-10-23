import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Dialog that validates and returns a user-friendly calibration name.
class CalibrationNameDialog extends StatefulWidget {
  const CalibrationNameDialog({
    super.key,
    required this.colors,
    this.initialName,
  });

  final AppThemeColors colors;

  /// Existing name shown when an already saved calibration is edited.
  final String? initialName;

  @override
  /// Creates text-entry state owned for the dialog's lifetime.
  State<CalibrationNameDialog> createState() {
    return CalibrationNameDialogState();
  }
}

/// Owns the name controller and inline validation message.
class CalibrationNameDialogState extends State<CalibrationNameDialog> {
  late final TextEditingController nameController;

  String? nameError;

  @override
  /// Seeds the field with the existing name when one was supplied.
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  /// Builds the name field and cancel/save actions.
  Widget build(BuildContext context) {
    AppThemeColors colors = widget.colors;

    return AlertDialog(
      scrollable: true,
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderColor),
        ),
        child: Icon(
          Icons.drive_file_rename_outline_rounded,
          color: colors.primaryColor,
          size: AppIconSizes.lg,
        ),
      ),
      title: Text(
        context.l10n.namePianoSetup,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: colors.primaryColor),
          cursorColor: colors.primaryColor,
          decoration: InputDecoration(
            labelText: context.l10n.pianoSetupName,
            hintText: context.l10n.pianoSetupNameHint,
            errorText: nameError,
            labelStyle: TextStyle(color: colors.secondaryTextColor),
            hintStyle: TextStyle(color: colors.secondaryTextColor),
            counterStyle: TextStyle(color: colors.secondaryTextColor),
            errorStyle: TextStyle(color: colors.primaryColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: colors.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: colors.primaryColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: colors.primaryColor),
            ),
          ),
          onChanged: (String value) {
            if (nameError == null) {
              return;
            }

            setState(() {
              nameError = null;
            });
          },
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                    side: BorderSide(color: colors.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    context.l10n.cancel,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: ElevatedButton(
                  onPressed: saveName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: colors.backgroundColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    context.l10n.save,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Trims and validates the name before returning it to the caller.
  void saveName() {
    String calibrationName = nameController.text.trim();

    if (calibrationName.isEmpty) {
      setState(() {
        nameError = context.l10n.enterPianoSetupName;
      });

      return;
    }

    Navigator.of(context).pop(calibrationName);
  }

  @override
  /// Releases the text controller when the dialog is removed.
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
