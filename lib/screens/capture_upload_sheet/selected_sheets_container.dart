import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_dialogs.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class SelectedSheetsContainer extends StatelessWidget {
  const SelectedSheetsContainer({
    super.key,
    required this.colors,
    required this.selectedSheets,
    required this.selectedPdfPageCount,
    required this.isSavingSheet,
    required this.onView,
    required this.onRemove,
  });

  final AppThemeColors colors;
  final List<PlatformFile> selectedSheets;
  final int? selectedPdfPageCount;
  final bool isSavingSheet;
  final ValueChanged<PlatformFile> onView;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    const uploadColor = Color(0xFF3B82F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Selected files',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primaryColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Text(
                selectedPdfPageCount == null
                    ? '${selectedSheets.length} / 20'
                    : '1 PDF',
                style: TextStyle(
                  color: colors.backgroundColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Gap(AppSpacing.xs),
        Text(
          'Tap to preview - Swipe right to remove',
          style: TextStyle(
            color: colors.secondaryTextColor,
            fontSize: AppTextSizes.caption,
          ),
        ),
        Gap(AppSpacing.sm),
        ...List.generate(selectedSheets.length, (index) {
          final file = selectedSheets[index];
          final isPdf = file.extension?.toLowerCase() == 'pdf';
          final fileSize = file.size >= 1024 * 1024
              ? '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB'
              : '${(file.size / 1024).toStringAsFixed(1)} KB';

          return Dismissible(
            key: ValueKey('${file.name}-${file.size}-$index'),
            direction: isSavingSheet
                ? DismissDirection.none
                : DismissDirection.startToEnd,
            background: Container(
              margin: EdgeInsets.only(bottom: AppSpacing.sm),
              padding: EdgeInsets.only(left: AppSpacing.md),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (_) => RemoveSelectedSheetDialog(
                      colors: colors,
                      fileName: file.name,
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) => onRemove(index),
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: colors.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: colors.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onView(file),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isPdf ? Colors.red : uploadColor)
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.image_rounded,
                            color: isPdf ? Colors.red : uploadColor,
                            size: 23,
                          ),
                        ),
                        Gap(AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.primaryColor,
                                  fontSize: AppTextSizes.label,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Gap(2),
                              Text(
                                isPdf && selectedPdfPageCount != null
                                    ? 'PDF - $fileSize - $selectedPdfPageCount pages'
                                    : 'Image - $fileSize',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.secondaryTextColor,
                                  fontSize: AppTextSizes.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap(AppSpacing.sm),
                        Icon(
                          Icons.open_in_full_rounded,
                          color: colors.secondaryTextColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
