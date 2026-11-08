import 'package:soundsight/screens/onboarding/widgets/screen_feature_tour.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/widgets/published_composition_social_actions.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class PublishedCompositionCard extends StatefulWidget {
  const PublishedCompositionCard({
    super.key,
    this.compact = false,
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
  final bool compact;
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

class _PublishedCompositionCardState extends State<PublishedCompositionCard> {
  static const Color dangerColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final composition = widget.composition;

    return Material(
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.isUnpublishing ? null : widget.onOpen,
        child: Padding(
          padding: EdgeInsets.all(widget.compact ? AppSpacing.sm : AppSpacing.md),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FeatureTourTarget(id: 'card_info', child: buildAuthorAvatar()),
          const Gap(AppSpacing.sm),
          Text(
            composition.title,
            textAlign: TextAlign.center,
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
            context.l10n.publishedBy(composition.authorName),
            textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
            ),
          ),
          const Gap(AppSpacing.sm),
          FeatureTourTarget(id: 'social', child: PublishedCompositionSocialActions(
            key: ValueKey('${composition.id}/${composition.currentVersion}'),
            colors: colors,
            composition: composition,
            compact: widget.compact,
            disabled: widget.isUnpublishing,
            onComments: widget.onComments,
          )),
          const Gap(AppSpacing.sm),
          buildMainActions(),
        ],
          ),
        ),
      ),
    );
  }

  Widget buildAuthorAvatar() {
    final colors = widget.colors;
    final imageUrl = widget.composition.authorProfileImageUrl;
    final size = widget.compact ? 36.0 : 54.0;
    final placeholder = Icon(
      Icons.person_rounded,
      color: colors.primaryColor,
      size: widget.compact ? AppIconSizes.md : AppIconSizes.lg,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }

  Widget buildMainActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: buildPlayButton(),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.public_off_rounded, size: AppIconSizes.sm),
                        Gap(AppSpacing.xs),
                        Flexible(
                          child: Text(
                            context.l10n.unpublish,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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

    return FeatureTourTarget(id: 'play', child: ElevatedButton.icon(
      onPressed: widget.isUnpublishing || widget.isPlaybackBusy
          ? null
          : widget.onPlay,
      icon: showLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              widget.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: AppIconSizes.sm,
            ),
      label: Text(
        widget.isPlaying ? context.l10n.stop : context.l10n.play,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ));
  }

  String formatPublishedDate(DateTime? date) {
    if (date == null) {
      return context.l10n.recentlyPublished;
    }

    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(date);
    return context.l10n.publishedOn(formattedDate);
  }
}
