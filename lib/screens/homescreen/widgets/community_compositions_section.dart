import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/controllers/published_composition_playback_controller.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';
import 'package:soundsight/screens/composition/services/published_composition_social_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CommunityCompositionsSection extends StatefulWidget {
  const CommunityCompositionsSection({
    super.key,
    required this.colors,
    required this.onSeeAll,
    required this.onOpenComposition,
  });

  final AppThemeColors colors;
  final VoidCallback onSeeAll;
  final ValueChanged<PublishedComposition> onOpenComposition;

  @override
  State<CommunityCompositionsSection> createState() =>
      _CommunityCompositionsSectionState();
}

class _CommunityCompositionsSectionState
    extends State<CommunityCompositionsSection> {
  final PublishedCompositionService compositionService =
      PublishedCompositionService();
  final PublishedCompositionSocialService socialService =
      PublishedCompositionSocialService();
  final PublishedCompositionPlaybackController playbackController =
      PublishedCompositionPlaybackController();

  late final Stream<List<PublishedComposition>> compositionsStream;

  @override
  void initState() {
    super.initState();
    compositionsStream = compositionService.getRecentPublishedCompositions();
    playbackController.addListener(updatePlaybackState);
  }

  @override
  void dispose() {
    playbackController.removeListener(updatePlaybackState);
    playbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Compositions',
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Discover music shared by other users.',
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.caption,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: colors.primaryColor,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Gap(AppSpacing.xs),
                  Icon(Icons.arrow_forward_rounded, size: AppIconSizes.sm),
                ],
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        StreamBuilder<List<PublishedComposition>>(
          stream: compositionsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildLoadingState();
            }

            if (snapshot.hasError) {
              return buildMessageState(
                icon: Icons.cloud_off_outlined,
                message: 'Community compositions could not be loaded.',
              );
            }

            final compositions = snapshot.data ?? [];

            if (compositions.isEmpty) {
              return buildMessageState(
                icon: Icons.music_note_rounded,
                message: 'No community compositions have been shared yet.',
              );
            }

            return SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: compositions.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) {
                  return buildCompositionCard(compositions[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildCompositionCard(PublishedComposition composition) {
    final colors = widget.colors;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 420 ? screenWidth * 0.72 : 280.0;
    final isPlaying = playbackController.isPlaying(composition);
    final isLoading = playbackController.isBusy && isPlaying;

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: colors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            widget.onOpenComposition(composition);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.backgroundColor,
                      foregroundImage: composition.authorProfileImageUrl.isEmpty
                          ? null
                          : NetworkImage(composition.authorProfileImageUrl),
                      child: composition.authorProfileImageUrl.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              color: colors.primaryColor,
                              size: AppIconSizes.sm,
                            )
                          : null,
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: Text(
                        composition.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: AppTextSizes.caption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'V${composition.currentVersion}',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
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
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      color: colors.secondaryTextColor,
                      size: AppIconSizes.sm,
                    ),
                    const Gap(AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${composition.keySignature} · '
                        '${composition.tempo} BPM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: AppTextSizes.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    StreamBuilder<int>(
                      stream: socialService.getLikeCount(
                        composition.id,
                        composition.currentVersion,
                      ),
                      builder: (context, snapshot) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              color: colors.secondaryTextColor,
                              size: AppIconSizes.sm,
                            ),
                            const Gap(AppSpacing.xs),
                            Text(
                              '${snapshot.data ?? 0}',
                              style: TextStyle(
                                color: colors.secondaryTextColor,
                                fontSize: AppTextSizes.caption,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: playbackController.isBusy
                            ? null
                            : () {
                                playComposition(composition);
                              },
                        icon: isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.backgroundColor,
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: AppIconSizes.sm,
                              ),
                        label: Text(isPlaying ? 'Stop' : 'Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryColor,
                          foregroundColor: colors.backgroundColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoadingState() {
    return SizedBox(
      height: 140,
      child: Center(
        child: CircularProgressIndicator(
          color: widget.colors.primaryColor,
        ),
      ),
    );
  }

  Widget buildMessageState({
    required IconData icon,
    required String message,
  }) {
    final colors = widget.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.secondaryTextColor, size: AppIconSizes.lg),
          const Gap(AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.label,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> playComposition(
    PublishedComposition composition,
  ) async {
    final resultMessage = await playbackController.togglePlayback(
      composition,
      onPlaybackStarted: () {
        showMessage('Playing "${composition.title}".');
      },
    );

    if (!mounted || resultMessage == null) return;

    showMessage(resultMessage);
  }

  void updatePlaybackState() {
    if (mounted) {
      setState(() {});
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
