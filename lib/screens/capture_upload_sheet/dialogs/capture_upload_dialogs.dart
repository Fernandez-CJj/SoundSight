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

class SheetSavingDialog extends StatefulWidget {
  const SheetSavingDialog({
    super.key,
    required this.colors,
    required this.progress,
  });

  final AppThemeColors colors;
  final double? progress;

  @override
  State<SheetSavingDialog> createState() => _SheetSavingDialogState();
}

class _SheetSavingDialogState extends State<SheetSavingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animationController.stop();
      animationController.value = 0;
    } else if (!animationController.isAnimating) {
      animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final value = widget.progress?.clamp(0.0, 1.0).toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label = value == null
        ? context.l10n.preparingAudio
        : context.l10n.savingProgress((value * 100).round());
    final isWaiting = value == null || value == 0 || value == 1;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colors.surfaceColor,
        surfaceTintColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.borderColor),
        ),
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 140,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      final motion = Curves.easeInOut.transform(
                        animationController.value,
                      );
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: 0.94 + motion * 0.06,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primaryColor.withValues(
                                  alpha: 0.05 + motion * 0.03,
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, 3 - motion * 6),
                            child: Transform.rotate(
                              angle: -0.04 + motion * 0.08,
                              child: child,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 24 + motion * 5,
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 22,
                              color: colors.primaryColor.withValues(alpha: 0.4),
                            ),
                          ),
                          Positioned(
                            right: 5,
                            bottom: 22 + motion * 7,
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 18,
                              color: colors.primaryColor.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      );
                    },
                    child: Container(
                      width: 62,
                      height: 76,
                      decoration: BoxDecoration(
                        color: colors.surfaceColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colors.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primaryColor.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.library_music_outlined,
                        color: colors.primaryColor,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              Gap(AppSpacing.sm),
              AnimatedSwitcher(
                duration: Duration(milliseconds: reduceMotion ? 0 : 200),
                child: Text(
                  value == null
                      ? context.l10n.preparingAudio
                      : context.l10n.savingEllipsis,
                  key: ValueKey(value == null),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Gap(AppSpacing.xs),
              Text(
                context.l10n.pleaseWait,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  height: 1.5,
                ),
              ),
              Gap(AppSpacing.lg),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value ?? 0),
                duration: Duration(milliseconds: reduceMotion ? 0 : 300),
                curve: Curves.easeOut,
                builder: (context, animatedValue, _) {
                  return LinearProgressIndicator(
                    value: isWaiting && !reduceMotion ? null : animatedValue,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: colors.primaryColor,
                    backgroundColor: colors.borderColor,
                    semanticsLabel: label,
                  );
                },
              ),
              if (value != null) ...[
                Gap(AppSpacing.sm),
                ExcludeSemantics(
                  child: Text(
                    '${(value * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
