import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:soundsight/screens/composition/models/composition.dart';

enum CompositionPublicationAction { publish, publishUpdate, unpublish }

class CompositionPublication {
  const CompositionPublication({
    required this.compositionId,
    required this.currentVersion,
    this.sourceUpdatedAt,
    this.publishedAt,
  });

  final String compositionId;
  final int currentVersion;
  final DateTime? sourceUpdatedAt;
  final DateTime? publishedAt;

  factory CompositionPublication.fromMap(
    String compositionId,
    Map<String, dynamic> map,
  ) {
    final sourceUpdatedAtData = map['sourceUpdatedAt'];
    final publishedAtData = map['publishedAt'];

    return CompositionPublication(
      compositionId: compositionId,
      currentVersion: (map['currentVersion'] as num?)?.toInt() ?? 1,
      sourceUpdatedAt: sourceUpdatedAtData is Timestamp
          ? sourceUpdatedAtData.toDate()
          : null,
      publishedAt: publishedAtData is Timestamp
          ? publishedAtData.toDate()
          : null,
    );
  }

  bool hasUnpublishedChanges(Composition composition) {
    final compositionUpdatedAt = composition.updatedAt;
    final publishedSourceDate = sourceUpdatedAt ?? publishedAt;

    if (compositionUpdatedAt == null || publishedSourceDate == null) {
      return false;
    }

    return compositionUpdatedAt.isAfter(publishedSourceDate);
  }
}

class CompositionPublishService {
  static const String backendUrl = 'http://192.168.0.104:8000';

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Streams each public post together with the private edit timestamp that
  /// produced its current version.
  Stream<Map<String, CompositionPublication>> getCompositionPublications(
    String ownerId,
  ) {
    return firestore
        .collection('compositionPosts')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          return {
            for (final document in snapshot.docs)
              document.id: CompositionPublication.fromMap(
                document.id,
                document.data(),
              ),
          };
        });
  }

  /// Streams the public post for one composition, or null while it is not
  /// published.
  Stream<CompositionPublication?> watchCompositionPublication(
    String compositionId,
  ) {
    return firestore
        .collection('compositionPosts')
        .doc(compositionId)
        .snapshots()
        .map((document) {
          final data = document.data();

          if (!document.exists || data == null) {
            return null;
          }

          return CompositionPublication.fromMap(document.id, data);
        });
  }

  Future<String> publishComposition(Composition composition) async {
    final requestData = composition.toMap();

    requestData['id'] = composition.id;
    requestData['notes'] = composition.notes.map((note) {
      final noteData = note.toMap();

      noteData['id'] = note.id;
      noteData.remove('noteId');

      return noteData;
    }).toList();

    final response = await http
        .post(
          Uri.parse('$backendUrl/compositions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        )
        .timeout(const Duration(minutes: 2));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Publishing failed with status '
        '${response.statusCode}.',
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return responseData['postId'] as String? ?? composition.id;
  }

  Future<void> unpublishComposition({
    required String compositionId,
    required String ownerId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$backendUrl/compositions/$compositionId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'ownerId': ownerId}),
        )
        .timeout(const Duration(minutes: 1));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Unpublishing failed with status '
        '${response.statusCode}.',
      );
    }
  }
}
