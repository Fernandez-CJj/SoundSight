import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class SelectedSheetPreviewDialog extends StatelessWidget {
  const SelectedSheetPreviewDialog({
    super.key,
    required this.colors,
    required this.file,
  });

  final AppThemeColors colors;
  final PlatformFile file;

  @override
  Widget build(BuildContext context) {
    final isPdf = file.extension?.toLowerCase() == 'pdf';
    final previewHeight = MediaQuery.sizeOf(context).height * 0.65;

    return Dialog(
      backgroundColor: colors.surfaceColor,
      insetPadding: EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.primaryColor,
                  ),
                ),
              ],
            ),
            Gap(AppSpacing.md),
            if (isPdf && file.bytes != null)
              SizedBox(
                height: previewHeight,
                width: double.infinity,
                child: PdfViewer.data(file.bytes!, sourceName: file.name),
              )
            else if (file.bytes != null)
              SizedBox(
                height: previewHeight,
                width: double.infinity,
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.memory(file.bytes!, fit: BoxFit.contain),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Preview is not available.',
                  style: TextStyle(color: colors.secondaryTextColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
