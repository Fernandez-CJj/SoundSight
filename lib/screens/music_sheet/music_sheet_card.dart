import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class MusicSheetCard extends StatelessWidget {
  const MusicSheetCard({
    super.key,
    required this.colors,
    required this.title,
    required this.type,
    required this.pageCount,
    required this.dateText,
    required this.isDeleting,
    required this.onView,
    required this.onRename,
    required this.onDelete,
  });

  final AppThemeColors colors;
  final String title;
  final String type;
  final int pageCount;
  final String dateText;
  final bool isDeleting;
  final VoidCallback onView;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPdf = type == 'pdf';
    final typeColor = isPdf ? const Color(0xFFDC2626) : const Color(0xFF3B82F6);
    final pageLabel = pageCount == 1 ? 'page' : 'pages';

    return Material(
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDeleting ? null : onView,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.library_music_rounded,
                  color: typeColor,
                  size: 27,
                ),
              ),
              Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      '$pageCount $pageLabel - ${isPdf ? 'PDF' : 'Images'}',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                    if (dateText.isNotEmpty) ...[
                      Gap(2),
                      Text(
                        dateText,
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: AppTextSizes.caption,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Gap(AppSpacing.sm),
              if (isDeleting)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.primaryColor,
                  ),
                )
              else
                PopupMenuButton<String>(
                  color: colors.surfaceColor,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.secondaryTextColor,
                  ),
                  onSelected: (value) {
                    if (value == 'rename') {
                      onRename();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: colors.primaryColor,
                            size: 20,
                          ),
                          Gap(AppSpacing.sm),
                          Text(
                            'Rename',
                            style: TextStyle(color: colors.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: const Color(0xFFDC2626),
                            size: 20,
                          ),
                          Gap(AppSpacing.sm),
                          Text(
                            'Delete',
                            style: TextStyle(color: const Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
