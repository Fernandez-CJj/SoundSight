import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class DeleteSelectedSheetsDialog extends StatelessWidget {
  const DeleteSelectedSheetsDialog({
    super.key,
    required this.colors,
    required this.fileCount,
  });

  final AppThemeColors colors;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.delete_sweep_outlined,
              color: Color(0xFFDC2626),
              size: 21,
            ),
          ),
          Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.deleteAllFilesQuestion,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        context.l10n.deleteSelectedFilesConfirmation(fileCount),
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            context.l10n.cancel,
            style: TextStyle(color: colors.secondaryTextColor),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(context.l10n.deleteAll),
        ),
      ],
    );
  }
}

class RemoveSelectedSheetDialog extends StatelessWidget {
  const RemoveSelectedSheetDialog({
    super.key,
    required this.colors,
    required this.fileName,
  });

  final AppThemeColors colors;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        context.l10n.removeFileQuestion,
        style: TextStyle(
          color: colors.primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        context.l10n.removeFileConfirmation(fileName),
        style: TextStyle(color: colors.secondaryTextColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            context.l10n.cancel,
            style: TextStyle(color: colors.secondaryTextColor),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            context.l10n.remove,
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class SheetTitleDialog extends StatefulWidget {
  const SheetTitleDialog({super.key, required this.colors});

  final AppThemeColors colors;

  @override
  State<SheetTitleDialog> createState() => _SheetTitleDialogState();
}

class _SheetTitleDialogState extends State<SheetTitleDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.library_music_outlined,
              color: colors.primaryColor,
              size: 21,
            ),
          ),
          Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.nameYourSheet,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: titleController,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: colors.primaryColor),
          decoration: InputDecoration(
            labelText: context.l10n.sheetTitle,
            labelStyle: TextStyle(color: colors.secondaryTextColor),
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
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.enterSheetTitle;
            }
            return null;
          },
          onFieldSubmitted: (_) => submitTitle(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.cancel,
            style: TextStyle(color: colors.secondaryTextColor),
          ),
        ),
        ElevatedButton(
          onPressed: submitTitle,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.backgroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            context.l10n.upload,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  void submitTitle() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, titleController.text.trim());
  }
}

class SheetSaveResultDialog extends StatelessWidget {
  const SheetSaveResultDialog({
    super.key,
    required this.colors,
    required this.isSuccessful,
    this.sheetTitle,
    this.isAudio = false,
  });

  final AppThemeColors colors;
  final bool isSuccessful;
  final String? sheetTitle;
  final bool isAudio;

  @override
  Widget build(BuildContext context) {
    final statusColor = isSuccessful
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSuccessful ? Icons.check_rounded : Icons.error_outline_rounded,
          color: statusColor,
          size: 32,
        ),
      ),
      title: Text(
        isSuccessful
            ? (isAudio ? context.l10n.audioSaved : context.l10n.sheetSaved)
            : context.l10n.unableToSave,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        isSuccessful
            ? (isAudio
                  ? context.l10n.audioSavedDescription
                  : context.l10n.sheetSavedDescription(sheetTitle ?? ''))
            : context.l10n.sheetSaveFailedDescription,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.label,
          height: 1.4,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: statusColor,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(180, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            isSuccessful ? context.l10n.done : context.l10n.backToSelection,
          ),
        ),
      ],
    );
  }
}
