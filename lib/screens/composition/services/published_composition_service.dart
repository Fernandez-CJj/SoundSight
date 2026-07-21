import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';

class PublishedCompositionService {
  static const int maximumPdfSize = 20 * 1024 * 1024;

  Stream<List<PublishedComposition>> getRecentPublishedCompositions({
    int limit = 3,
  }) {
    return FirebaseFirestore.instance
        .collection('compositionPosts')
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final compositions = <PublishedComposition>[];

          for (final document in snapshot.docs) {
            compositions.add(
              PublishedComposition.fromMap(
                document.id,
                document.data(),
              ),
            );
          }

          return compositions;
        });
  }

  Stream<List<PublishedComposition>> getPublishedCompositions() {
    return FirebaseFirestore.instance
        .collection('compositionPosts')
        .snapshots()
        .map((snapshot) {
          final compositions = <PublishedComposition>[];

          for (final document in snapshot.docs) {
            final composition = PublishedComposition.fromMap(
              document.id,
              document.data(),
            );

            compositions.add(composition);
          }

          compositions.sort((first, second) {
            final firstDate = first.publishedAt;
            final secondDate = second.publishedAt;

            if (firstDate == null && secondDate == null) {
              return 0;
            }

            if (firstDate == null) {
              return 1;
            }

            if (secondDate == null) {
              return -1;
            }

            return secondDate.compareTo(firstDate);
          });

          return compositions;
        });
  }

  Future<Uint8List?> loadPdf(String storagePath) {
    if (storagePath.isEmpty) {
      return Future.value(null);
    }

    return FirebaseStorage.instance
        .ref(storagePath)
        .getData(maximumPdfSize);
  }

  Future<Composition?> loadPlayableComposition(
    PublishedComposition publishedComposition,
  ) async {
    final versionDocument = await FirebaseFirestore.instance
        .collection('compositionPosts')
        .doc(publishedComposition.id)
        .collection('versions')
        .doc('${publishedComposition.currentVersion}')
        .get();

    final versionData = versionDocument.data();
    final notesData = versionData?['notes'];

    if (!versionDocument.exists ||
        versionData == null ||
        notesData is! List ||
        notesData.isEmpty) {
      return null;
    }

    return Composition.fromMap(
      publishedComposition.compositionId,
      versionData,
    );
  }
}
