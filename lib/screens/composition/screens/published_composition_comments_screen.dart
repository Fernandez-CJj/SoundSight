import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/models/published_composition_comment.dart';
import 'package:soundsight/screens/composition/services/published_composition_social_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class PublishedCompositionCommentsScreen extends StatefulWidget {
  const PublishedCompositionCommentsScreen({
    super.key,
    required this.colors,
    required this.composition,
  });

  final AppThemeColors colors;
  final PublishedComposition composition;

  @override
  State<PublishedCompositionCommentsScreen> createState() =>
      _PublishedCompositionCommentsScreenState();
}

class _PublishedCompositionCommentsScreenState
    extends State<PublishedCompositionCommentsScreen> {
  final PublishedCompositionSocialService socialService =
      PublishedCompositionSocialService();
  final TextEditingController commentController = TextEditingController();

  late final String? userId;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Comments · V${widget.composition.currentVersion}',
          style: const TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PublishedCompositionComment>>(
              stream: socialService.getComments(
                widget.composition.id,
                widget.composition.currentVersion,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return buildMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Comments could not be loaded.',
                    message: 'Check your connection and try again.',
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return buildMessage(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No comments yet',
                    message: 'Be the first to share your thoughts.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return buildComment(comments[index]);
                  },
                );
              },
            ),
          ),
          buildCommentInput(),
        ],
      ),
    );
  }

  Widget buildComment(PublishedCompositionComment comment) {
    final colors = widget.colors;
    final canDelete = comment.userId == userId ||
        widget.composition.ownerId == userId;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.backgroundColor,
            foregroundImage: comment.profileImageUrl.isEmpty
                ? null
                : NetworkImage(comment.profileImageUrl),
            child: comment.profileImageUrl.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    color: colors.primaryColor,
                    size: AppIconSizes.sm,
                  )
                : null,
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      formatCommentDate(comment.createdAt),
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.xs),
                Text(
                  comment.text,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Delete comment',
              onPressed: () {
                confirmDeleteComment(comment);
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
                size: AppIconSizes.sm,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildCommentInput() {
    final colors = widget.colors;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          border: Border(
            top: BorderSide(color: colors.borderColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                enabled: !isSending,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: colors.primaryColor),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(color: colors.secondaryTextColor),
                  counterText: '',
                  filled: true,
                  fillColor: colors.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: colors.primaryColor),
                  ),
                ),
              ),
            ),
            const Gap(AppSpacing.sm),
            SizedBox(
              width: 50,
              height: 50,
              child: ElevatedButton(
                onPressed: isSending ? null : sendComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryColor,
                  foregroundColor: colors.backgroundColor,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.backgroundColor,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = widget.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.secondaryTextColor, size: AppIconSizes.xl),
            const Gap(AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.xs),
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
      ),
    );
  }

  Future<void> sendComment() async {
    final text = commentController.text.trim();

    if (text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await socialService.addComment(
        widget.composition.id,
        widget.composition.currentVersion,
        text,
      );

      commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (_) {
      showMessage('The comment could not be posted.');
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  Future<void> confirmDeleteComment(
    PublishedCompositionComment comment,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: widget.colors.surfaceColor,
          title: Text(
            'Delete comment?',
            style: TextStyle(color: widget.colors.primaryColor),
          ),
          content: Text(
            'This comment will be removed permanently.',
            style: TextStyle(color: widget.colors.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: widget.colors.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await socialService.deleteComment(
        widget.composition.id,
        widget.composition.currentVersion,
        comment.id,
      );
    } catch (_) {
      showMessage('The comment could not be deleted.');
    }
  }

  String formatCommentDate(DateTime? date) {
    if (date == null) return 'Just now';

    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';

    return '${date.month}/${date.day}/${date.year}';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
