import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
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
    final fileLabel = fileCount == 1 ? 'file' : 'files';

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
              'Delete all files?',
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
        'This will remove all $fileCount selected $fileLabel.',
        style: TextStyle(
          color: colors.secondaryTextColor,
          fontSize: AppTextSizes.body,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
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
          child: const Text('Delete All'),
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
        'Remove file?',
        style: TextStyle(
          color: colors.primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Do you want to remove $fileName?',
        style: TextStyle(color: colors.secondaryTextColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: colors.secondaryTextColor),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Remove',
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
  const SheetTitleDialog({
    super.key,
    required this.colors,
    required this.initialTitle,
  });

  final AppThemeColors colors;
  final String initialTitle;

  @override
  State<SheetTitleDialog> createState() => _SheetTitleDialogState();
}

class _SheetTitleDialogState extends State<SheetTitleDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
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
              'Name your sheet',
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
            labelText: 'Sheet title',
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
              return 'Enter a title for this sheet.';
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
            'Cancel',
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
          child: const Text(
            'Upload',
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
  });

  final AppThemeColors colors;
  final bool isSuccessful;
  final String? sheetTitle;

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
          isSuccessful
              ? Icons.check_rounded
              : Icons.error_outline_rounded,
          color: statusColor,
          size: 32,
        ),
      ),
      title: Text(
        isSuccessful ? 'Sheet saved' : 'Unable to save',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.sectionTitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        isSuccessful
            ? '"$sheetTitle" was uploaded and saved successfully.'
            : 'The sheet could not be saved. Check your connection and try again.',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(isSuccessful ? 'Done' : 'Back to selection'),
        ),
      ],
    );
  }
}
