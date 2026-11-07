import 'package:flutter/material.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/published_composition_social_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class PublishedCompositionSocialActions extends StatefulWidget {
  const PublishedCompositionSocialActions({
    super.key,
    this.compact = false,
    this.disabled = false,
    required this.colors,
    required this.composition,
    required this.onComments,
  });

  final AppThemeColors colors;
  final bool compact;
  final bool disabled;
  final PublishedComposition composition;
  final VoidCallback onComments;

  @override
  State<PublishedCompositionSocialActions> createState() =>
      _PublishedCompositionSocialActionsState();
}

class _PublishedCompositionSocialActionsState
    extends State<PublishedCompositionSocialActions> {
  final PublishedCompositionSocialService socialService =
      PublishedCompositionSocialService();
  static const Color dangerColor = Color(0xFFDC2626);
  bool isUpdatingLike = false;
  bool isUpdatingSave = false;
  late final Stream<bool> likedStream;
  late final Stream<int> likeCountStream;
  late final Stream<int> commentCountStream;
  late final Stream<bool> savedStream;

  @override
  void initState() {
    super.initState();
    final composition = widget.composition;
    likedStream = socialService.isLikedByCurrentUser(
      composition.id,
      composition.currentVersion,
    );
    likeCountStream = socialService.getLikeCount(
      composition.id,
      composition.currentVersion,
    );
    commentCountStream = socialService.getCommentCount(
      composition.id,
      composition.currentVersion,
    );
    savedStream = socialService.isSavedByCurrentUser(
      composition.id,
      composition.currentVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<bool>(
            stream: likedStream,
            builder: (context, likedSnapshot) {
              final isLiked = likedSnapshot.data ?? false;

              return StreamBuilder<int>(
                stream: likeCountStream,
                builder: (context, countSnapshot) {
                  final likeCount = countSnapshot.data ?? 0;

                  return buildSocialButton(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '$likeCount',
                    selected: isLiked,
                    loading: isUpdatingLike,
                    onTap: toggleLike,
                  );
                },
              );
            },
          ),
        ),
        Gap(widget.compact ? AppSpacing.xs : AppSpacing.sm),
        Expanded(
          child: StreamBuilder<int>(
            stream: commentCountStream,
            builder: (context, snapshot) {
              return buildSocialButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${snapshot.data ?? 0}',
                onTap: widget.onComments,
              );
            },
          ),
        ),
        Gap(widget.compact ? AppSpacing.xs : AppSpacing.sm),
        Expanded(
          child: StreamBuilder<bool>(
            stream: savedStream,
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;

              return buildSocialButton(
                icon: isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: isSaved ? context.l10n.saved : context.l10n.save,
                selected: isSaved,
                loading: isUpdatingSave,
                onTap: () {
                  confirmToggleSave(isSaved);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    bool loading = false,
  }) {
    final colors = widget.colors;
    final disabled = widget.disabled || loading;

    if (widget.compact) {
      return Tooltip(
        message: label,
        child: SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: disabled ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: selected ? colors.backgroundColor : colors.primaryColor,
              backgroundColor: selected ? colors.primaryColor : colors.surfaceColor,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              side: BorderSide(color: colors.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primaryColor,
                    ),
                  )
                else
                  Icon(icon, size: AppIconSizes.sm),
                const Gap(2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : onTap,
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primaryColor,
                ),
              )
            : Icon(icon, size: AppIconSizes.sm),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected
              ? colors.backgroundColor
              : colors.primaryColor,
          backgroundColor: selected ? colors.primaryColor : colors.surfaceColor,
          side: BorderSide(color: colors.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }

  Future<void> toggleLike() async {
    if (widget.disabled || isUpdatingLike) return;

    setState(() {
      isUpdatingLike = true;
    });

    try {
      await socialService.toggleLike(
        widget.composition.id,
        widget.composition.currentVersion,
      );
    } catch (_) {
      if (mounted) showMessage(context.l10n.likeUpdateFailed);
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingLike = false;
        });
      }
    }
  }

  Future<void> toggleSave() async {
    if (widget.disabled || isUpdatingSave) return;

    setState(() {
      isUpdatingSave = true;
    });

    try {
      await socialService.toggleSave(
        widget.composition.id,
        widget.composition.currentVersion,
      );
    } catch (_) {
      if (mounted) showMessage(context.l10n.savedCompositionUpdateFailed);
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingSave = false;
        });
      }
    }
  }

  Future<void> confirmToggleSave(bool isSaved) async {
    final colors = widget.colors;
    final actionText = isSaved ? context.l10n.remove : context.l10n.save;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: colors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Icon(
                  isSaved
                      ? Icons.bookmark_remove_outlined
                      : Icons.bookmark_add_outlined,
                  color: colors.primaryColor,
                  size: AppIconSizes.sm,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  isSaved
                      ? context.l10n.removeSavedSheetQuestion
                      : context.l10n.saveSheetQuestion,
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
            isSaved
                ? context.l10n.removeSavedSheetDescription(
                    widget.composition.title,
                    widget.composition.currentVersion,
                  )
                : context.l10n.saveSheetDescription(
                    widget.composition.title,
                    widget.composition.currentVersion,
                  ),
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.body,
              height: 1.4,
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
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSaved
                            ? dangerColor
                            : colors.primaryColor,
                        foregroundColor: isSaved
                            ? Colors.white
                            : colors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        actionText,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldContinue == true && mounted) {
      await toggleSave();
    }
  }

  void showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.error,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      .showLatestSnackBar(
        appSnackBar(colors: widget.colors, message: message, type: type),
      );
  }

}
