import 'package:cloud_firestore/cloud_firestore.dart';

class PublishedCompositionComment {
  const PublishedCompositionComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String username;
  final String profileImageUrl;
  final String text;
  final DateTime? createdAt;

  static PublishedCompositionComment fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final createdAtData = map['createdAt'];

    return PublishedCompositionComment(
      id: id,
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? 'SoundSight Musician',
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: createdAtData is Timestamp
          ? createdAtData.toDate()
          : null,
    );
  }
}
