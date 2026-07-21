import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/published_composition_social_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class PublishedCompositionCard extends StatefulWidget {
  const PublishedCompositionCard({
    super.key,
    required this.colors,
    required this.composition,
    required this.canUnpublish,
    required this.isUnpublishing,
    required this.isPlaying,
    required this.isPlaybackBusy,
    required this.onOpen,
    required this.onPlay,
    required this.onComments,
    required this.onUnpublish,
  });

  final AppThemeColors colors;
  final PublishedComposition composition;
  final bool canUnpublish;
  final bool isUnpublishing;
  final bool isPlaying;
  final bool isPlaybackBusy;
  final VoidCallback onOpen;
  final VoidCallback onPlay;
  final VoidCallback onComments;
  final VoidCallback onUnpublish;

  @override
  State<PublishedCompositionCard> createState() =>
      _PublishedCompositionCardState();
}

class _PublishedCompositionCardState
    extends State<PublishedCompositionCard> {
  final PublishedCompositionSocialService socialService =
      PublishedCompositionSocialService();

  static const Color dangerColor = Color(0xFFDC2626);

  bool isUpdatingLike = false;
  bool isUpdatingSave = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final composition = widget.composition;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: composition.authorProfileImageUrl.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        color: colors.primaryColor,
                        size: AppIconSizes.lg,
                      )
                    : Image.network(
                        composition.authorProfileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Icon(
                            Icons.person_rounded,
                            color: colors.primaryColor,
                            size: AppIconSizes.lg,
                          );
                        },
                      ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      composition.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'By ${composition.authorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      formatPublishedDate(composition.publishedAt),
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              buildInformationChip(
                icon: Icons.history_rounded,
                text: 'Version ${composition.currentVersion}',
              ),
              buildInformationChip(
                icon: Icons.music_note_rounded,
                text: composition.keySignature,
              ),
              buildInformationChip(
                icon: Icons.speed_rounded,
                text: '${composition.tempo} BPM',
              ),
              buildInformationChip(
                icon: Icons.grid_view_rounded,
                text: '${composition.measureCount} measures',
              ),
              buildInformationChip(
                icon: Icons.notes_rounded,
                text: '${composition.noteCount} notes',
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          buildSocialActions(),
          const Gap(AppSpacing.md),
          buildMainActions(),
        ],
      ),
    );
  }

  Widget buildSocialActions() {
    final composition = widget.composition;

    return Row(
      children: [
        Expanded(
          child: StreamBuilder<bool>(
            stream: socialService.isLikedByCurrentUser(
              composition.id,
              composition.currentVersion,
            ),
            builder: (context, likedSnapshot) {
              final isLiked = likedSnapshot.data ?? false;

              return StreamBuilder<int>(
                stream: socialService.getLikeCount(
                  composition.id,
                  composition.currentVersion,
                ),
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
        const Gap(AppSpacing.sm),
        Expanded(
          child: StreamBuilder<int>(
            stream: socialService.getCommentCount(
              composition.id,
              composition.currentVersion,
            ),
            builder: (context, snapshot) {
              return buildSocialButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${snapshot.data ?? 0}',
                onTap: widget.onComments,
              );
            },
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: StreamBuilder<bool>(
            stream: socialService.isSavedByCurrentUser(
              composition.id,
              composition.currentVersion,
            ),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;

              return buildSocialButton(
                icon: isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: isSaved ? 'Saved' : 'Save',
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
    final disabled = widget.isUnpublishing || loading;

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
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected
              ? colors.backgroundColor
              : colors.primaryColor,
          backgroundColor: selected
              ? colors.primaryColor
              : colors.surfaceColor,
          side: BorderSide(color: colors.borderColor),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }

  Widget buildMainActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: buildPlayButton(),
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 46,
                child: buildViewButton(),
              ),
            ),
          ],
        ),
        if (widget.canUnpublish) ...[
          const Gap(AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: widget.isUnpublishing || widget.isPlaybackBusy
                  ? null
                  : widget.onUnpublish,
              style: OutlinedButton.styleFrom(
                foregroundColor: dangerColor,
                side: BorderSide(
                  color: widget.isUnpublishing
                      ? widget.colors.borderColor
                      : dangerColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: widget.isUnpublishing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: dangerColor,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.public_off_rounded,
                          size: AppIconSizes.sm,
                        ),
                        Gap(AppSpacing.xs),
                        Text(
                          'Unpublish',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildPlayButton() {
    final showLoading = widget.isPlaybackBusy && widget.isPlaying;

    return OutlinedButton.icon(
      onPressed: widget.isUnpublishing || widget.isPlaybackBusy
          ? null
          : widget.onPlay,
      icon: showLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.colors.primaryColor,
              ),
            )
          : Icon(
              widget.isPlaying
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
              size: AppIconSizes.sm,
            ),
      label: Text(
        widget.isPlaying ? 'Stop' : 'Play',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.colors.primaryColor,
        side: BorderSide(color: widget.colors.borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  Widget buildViewButton() {
    return ElevatedButton.icon(
      onPressed: widget.isUnpublishing ? null : widget.onOpen,
      icon: const Icon(
        Icons.picture_as_pdf_outlined,
        size: AppIconSizes.sm,
      ),
      label: const Text(
        'View Sheet',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.colors.primaryColor,
        foregroundColor: widget.colors.backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  Widget buildInformationChip({
    required IconData icon,
    required String text,
  }) {
    final colors = widget.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: colors.secondaryTextColor,
            size: AppIconSizes.sm,
          ),
          const Gap(AppSpacing.xs),
          Text(
            text,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> toggleLike() async {
    if (isUpdatingLike || widget.isUnpublishing) return;

    setState(() {
      isUpdatingLike = true;
    });

    try {
      await socialService.toggleLike(
        widget.composition.id,
        widget.composition.currentVersion,
      );
    } catch (_) {
      showMessage('The like could not be updated.');
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingLike = false;
        });
      }
    }
  }

  Future<void> toggleSave() async {
    if (isUpdatingSave || widget.isUnpublishing) return;

    setState(() {
      isUpdatingSave = true;
    });

    try {
      await socialService.toggleSave(
        widget.composition.id,
        widget.composition.currentVersion,
      );
    } catch (_) {
      showMessage('The saved composition could not be updated.');
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
    final actionText = isSaved ? 'Remove' : 'Save';

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
                  isSaved ? 'Remove saved sheet?' : 'Save this sheet?',
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
                ? 'Remove "${widget.composition.title}" version '
                    '${widget.composition.currentVersion} from Saved Sheets?'
                : 'Save "${widget.composition.title}" version '
                    '${widget.composition.currentVersion} so you can find it '
                    'later in Saved Sheets?',
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
                      child: const Text('Cancel'),
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

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String formatPublishedDate(DateTime? date) {
    if (date == null) {
      return 'Recently published';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return 'Published ${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}
