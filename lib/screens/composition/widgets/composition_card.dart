import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionCard extends StatelessWidget {
  const CompositionCard({
    super.key,
    required this.colors,
    required this.composition,
    required this.isDeleting,
    required this.isGeneratingFiles,
    required this.onOpen,
    required this.onRetryGeneration,
    required this.onDelete,
  });

  final AppThemeColors colors;
  final Composition composition;
  final bool isDeleting;
  final bool isGeneratingFiles;
  final VoidCallback onOpen;
  final VoidCallback onRetryGeneration;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final editedDate = composition.updatedAt ?? composition.createdAt;
    final isRecording =
        composition.creationMethod == Composition.recordingCreationMethod;
    final filesNeedAttention = !composition.generatedFilesAreCurrent;
    final filesAreOutOfDate = composition.generatedFilesAreOutOfDate;
    final generationIsRunning =
        isGeneratingFiles ||
        composition.generationStatus == Composition.generatingStatus;
    final generationColor = generationIsRunning
        ? colors.primaryColor
        : filesAreOutOfDate
        ? const Color(0xFFF59E0B)
        : const Color(0xFFDC2626);
    final creationMethodColor = isRecording
        ? (colors.isDarkMode
              ? const Color(0xFFFF8A80)
              : const Color(0xFFB3261E))
        : (colors.isDarkMode
              ? const Color(0xFF8AB4F8)
              : const Color(0xFF245E9C));

    return Dismissible(
      key: ValueKey(composition.id),
      direction: isDeleting
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: Container(
        padding: EdgeInsets.only(left: AppSpacing.lg),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: filesNeedAttention
                ? generationColor
                : colors.borderColor,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              onTap: isDeleting ? null : onOpen,
              contentPadding: EdgeInsets.all(AppSpacing.md),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: creationMethodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: creationMethodColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  isRecording
                      ? Icons.mic_rounded
                      : Icons.edit_note_rounded,
                  color: creationMethodColor,
                  size: AppIconSizes.lg,
                ),
              ),
              title: Text(
                composition.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildCreationMethodBadge(
                      context: context,
                      isRecording: isRecording,
                      color: creationMethodColor,
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      '${composition.tempo} BPM - '
                      '${composition.keySignature}',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                    Gap(2),
                    Text(
                      formatEditedDate(context, editedDate),
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: isDeleting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colors.primaryColor,
                      ),
                    )
                  : null,
            ),
            if (filesNeedAttention) ...[
              Divider(height: 1, color: colors.borderColor),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.md),
                color: generationColor.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    if (generationIsRunning)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: generationColor,
                        ),
                      )
                    else
                      Icon(
                        filesAreOutOfDate
                            ? Icons.update_rounded
                            : Icons.warning_amber_rounded,
                        color: generationColor,
                        size: AppIconSizes.md,
                      ),
                    Gap(AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            generationIsRunning
                                ? context.l10n.preparingMusicFiles
                                : filesAreOutOfDate
                                ? context.l10n.musicFilesNeedUpdating
                                : context.l10n.musicFilesNotReady,
                            style: TextStyle(
                              color: colors.primaryColor,
                              fontSize: AppTextSizes.label,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Gap(2),
                          Text(
                            filesAreOutOfDate
                                ? context.l10n.musicFilesOutOfDateDescription
                                : context.l10n.musicFilesNotReadyDescription,
                            style: TextStyle(
                              color: colors.secondaryTextColor,
                              fontSize: AppTextSizes.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!generationIsRunning) ...[
                      Gap(AppSpacing.sm),
                      TextButton(
                        onPressed: isDeleting ? null : onRetryGeneration,
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            Divider(height: 1, color: colors.borderColor),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isDeleting ? null : onOpen,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: AppIconSizes.sm,
                  ),
                  label: Text(context.l10n.view),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: colors.backgroundColor,
                    disabledBackgroundColor: colors.borderColor,
                    disabledForegroundColor: colors.secondaryTextColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCreationMethodBadge({
    required BuildContext context,
    required bool isRecording,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecording ? Icons.mic_rounded : Icons.edit_note_rounded,
            size: 14,
            color: color,
          ),
          Gap(4),
          Text(
            isRecording ? context.l10n.recording : context.l10n.manual,
            style: TextStyle(
              color: color,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String formatEditedDate(BuildContext context, DateTime? date) {
    if (date == null) {
      return context.l10n.notSavedYet;
    }

    final localizedDate = MaterialLocalizations.of(context).formatMediumDate(
      date,
    );
    return context.l10n.lastEdited(localizedDate);
  }
}
