import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:soundsight/constants/backend_config.dart';

import 'package:soundsight/screens/composition/models/composition.dart';

enum CompositionPublicationAction { publish, publishUpdate, unpublish }

class CompositionPublicationException implements Exception {
  const CompositionPublicationException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

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
  static const String backendUrl = BackendConfig.baseUrl;

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
    final uri = Uri.parse('$backendUrl/compositions/${composition.id}/publish');
    final response = await sendAuthenticatedRequest(
      (idToken) => http
          .post(uri, headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(minutes: 2)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CompositionPublicationException(
        statusCode: response.statusCode,
        message: readErrorMessage(
          response,
          'Publishing failed with status ${response.statusCode}.',
        ),
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return responseData['postId'] as String? ?? composition.id;
  }

  Future<void> unpublishComposition({required String compositionId}) async {
    final uri = Uri.parse('$backendUrl/compositions/$compositionId/publish');
    final response = await sendAuthenticatedRequest(
      (idToken) => http
          .delete(uri, headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(minutes: 1)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CompositionPublicationException(
        statusCode: response.statusCode,
        message: readErrorMessage(
          response,
          'Unpublishing failed with status ${response.statusCode}.',
        ),
      );
    }
  }

  Future<http.Response> sendAuthenticatedRequest(
    Future<http.Response> Function(String idToken) request,
  ) async {
    var response = await request(await requireIdToken());
    if (response.statusCode != 401) return response;

    await FirebaseAuth.instance.currentUser?.reload();
    response = await request(await requireIdToken());
    return response;
  }

  String readErrorMessage(http.Response response, String fallback) {
    try {
      final responseData = jsonDecode(response.body);
      if (responseData is Map<String, dynamic>) {
        final detail = responseData['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } on FormatException {
      return fallback;
    }

    return fallback;
  }

  Future<String> requireIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before changing a publication.');
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Your sign-in session could not be verified.');
    }

    return idToken;
  }
}
