import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/models/published_composition_comment.dart';

class PublishedCompositionSocialService {
  final FirebaseFirestore database = FirebaseFirestore.instance;

  Stream<int> getLikeCount(
    String postId,
    int versionNumber,
  ) {
    return getVersionReference(postId, versionNumber)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<bool> isLikedByCurrentUser(
    String postId,
    int versionNumber,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return getVersionReference(postId, versionNumber)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((document) => document.exists);
  }

  Future<void> toggleLike(
    String postId,
    int versionNumber,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('You must be signed in to like a composition.');
    }

    final likeReference = getVersionReference(
      postId,
      versionNumber,
    ).collection('likes').doc(user.uid);

    final likeDocument = await likeReference.get();

    if (likeDocument.exists) {
      await likeReference.delete();
      return;
    }

    await likeReference.set({
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> getCommentCount(
    String postId,
    int versionNumber,
  ) {
    return getVersionReference(postId, versionNumber)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<PublishedCompositionComment>> getComments(
    String postId,
    int versionNumber,
  ) {
    return getVersionReference(postId, versionNumber)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
          final comments = <PublishedCompositionComment>[];

          for (final document in snapshot.docs) {
            comments.add(
              PublishedCompositionComment.fromMap(
                document.id,
                document.data(),
              ),
            );
          }

          comments.sort((first, second) {
            final firstDate = first.createdAt;
            final secondDate = second.createdAt;

            if (firstDate == null && secondDate == null) return 0;
            if (firstDate == null) return 1;
            if (secondDate == null) return -1;
            return firstDate.compareTo(secondDate);
          });

          return comments;
        });
  }

  Future<void> addComment(
    String postId,
    int versionNumber,
    String text,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final trimmedText = text.trim();

    if (user == null) {
      throw Exception('You must be signed in to comment.');
    }

    if (trimmedText.isEmpty || trimmedText.length > 500) {
      throw Exception('The comment must contain 1 to 500 characters.');
    }

    final userDocument = await database
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDocument.data();
    final username = userData?['username'] as String?;
    final profileImageUrl = userData?['profileImageUrl'] as String?;

    await getVersionReference(postId, versionNumber)
        .collection('comments')
        .add({
          'userId': user.uid,
          'username': username?.trim().isNotEmpty == true
              ? username!.trim()
              : 'SoundSight Musician',
          'profileImageUrl': profileImageUrl ?? '',
          'text': trimmedText,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteComment(
    String postId,
    int versionNumber,
    String commentId,
  ) {
    return getVersionReference(postId, versionNumber)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Stream<bool> isSavedByCurrentUser(
    String postId,
    int versionNumber,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return database
        .collection('savedCompositionPosts')
        .doc(getSaveId(user.uid, postId, versionNumber))
        .snapshots()
        .map((document) => document.exists);
  }

  Future<void> toggleSave(
    String postId,
    int versionNumber,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('You must be signed in to save a composition.');
    }

    final saveReference = database
        .collection('savedCompositionPosts')
        .doc(getSaveId(user.uid, postId, versionNumber));

    final saveDocument = await saveReference.get();

    if (saveDocument.exists) {
      await saveReference.delete();
      return;
    }

    await saveReference.set({
      'userId': user.uid,
      'postId': postId,
      'versionNumber': versionNumber,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PublishedComposition>> getSavedCompositions(
    String userId,
  ) {
    return database
        .collection('savedCompositionPosts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final savedDocuments = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.docs,
          );

          savedDocuments.sort((first, second) {
            final firstDate = first.data()['savedAt'] as Timestamp?;
            final secondDate = second.data()['savedAt'] as Timestamp?;

            if (firstDate == null && secondDate == null) return 0;
            if (firstDate == null) return 1;
            if (secondDate == null) return -1;
            return secondDate.compareTo(firstDate);
          });

          final compositions = <PublishedComposition>[];

          for (final savedDocument in savedDocuments) {
            final savedData = savedDocument.data();
            final postId = savedData['postId'] as String? ?? '';
            final versionNumber =
                (savedData['versionNumber'] as num?)?.toInt() ?? 1;

            if (postId.isEmpty) continue;

            final versionDocument = await getVersionReference(
              postId,
              versionNumber,
            ).get();

            final versionData = versionDocument.data();

            if (!versionDocument.exists || versionData == null) continue;

            compositions.add(
              PublishedComposition.fromMap(
                postId,
                versionData,
              ),
            );
          }

          return compositions;
        });
  }

  DocumentReference<Map<String, dynamic>> getVersionReference(
    String postId,
    int versionNumber,
  ) {
    return database
        .collection('compositionPosts')
        .doc(postId)
        .collection('versions')
        .doc('$versionNumber');
  }

  String getSaveId(
    String userId,
    String postId,
    int versionNumber,
  ) {
    return '${userId}_${postId}_$versionNumber';
  }
}
