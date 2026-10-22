import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'practice_result_models.dart';

class PracticeResultService {
  PracticeResultService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CollectionReference<Map<String, dynamic>> _resultsReference(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('practice_results');
  }

  Stream<List<PracticeResultSummary>> watchResults() {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      return Stream.value(const []);
    }

    return _resultsReference(
      user.uid,
    ).orderBy('completedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(PracticeResultSummary.fromDocument)
          .where((result) => result.storageStatus == 'complete')
          .toList(growable: false);
    });
  }

  Stream<List<PracticeResultErrorEvent>> watchErrorEvents(String resultId) {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      return Stream.value(const []);
    }

    return _resultsReference(user.uid)
        .doc(resultId)
        .collection('error_events')
        .orderBy('positionIndex')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((document) {
                return PracticeResultErrorEvent.fromMap(document.data());
              })
              .toList(growable: false);
        });
  }

  Future<String> savePerformanceResult(
    SightReadingPerformanceReport report,
  ) async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('The user must be signed in to save practice results.');
    }

    final resultReference = _resultsReference(user.uid).doc();
    final savingSummary = PracticeResultSummary(
      id: resultReference.id,
      practiceType: report.summary.practiceType,
      ownerId: user.uid,
      scoreDocumentPath: report.summary.scoreDocumentPath,
      source: report.summary.source,
      pieceTitle: report.summary.pieceTitle,
      completedAt: null,
      targetDurationMs: report.summary.targetDurationMs,
      elapsedDurationMs: report.summary.elapsedDurationMs,
      correctCount: report.summary.correctCount,
      wrongCount: report.summary.wrongCount,
      missedCount: report.summary.missedCount,
      totalCount: report.summary.totalCount,
      timingAccuracyPercentage: report.summary.timingAccuracyPercentage,
      noteBreakdown: report.summary.noteBreakdown,
      clefBreakdown: report.summary.clefBreakdown,
      suggestions: report.suggestions,
      errorEventCount: report.errorEvents.length,
      storageStatus: 'saving',
    );

    try {
      await resultReference.set(
        savingSummary.toMap(completedAtValue: FieldValue.serverTimestamp()),
      );

      const batchSize = 400;

      for (
        var startIndex = 0;
        startIndex < report.errorEvents.length;
        startIndex += batchSize
      ) {
        final batch = firestore.batch();
        final endIndex = (startIndex + batchSize < report.errorEvents.length)
            ? startIndex + batchSize
            : report.errorEvents.length;

        for (var index = startIndex; index < endIndex; index++) {
          final event = report.errorEvents[index];
          final eventReference = resultReference
              .collection('error_events')
              .doc(event.positionIndex.toString());
          batch.set(eventReference, event.toMap());
        }

        await batch.commit();
      }

      await resultReference.update({'storageStatus': 'complete'});
      return resultReference.id;
    } catch (_) {
      await _deleteResultReference(resultReference, ignoreFailures: true);
      rethrow;
    }
  }

  Future<void> deleteResult(String resultId) async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      throw StateError(
        'The user must be signed in to delete practice results.',
      );
    }

    await _deleteResultReference(_resultsReference(user.uid).doc(resultId));
  }

  Future<void> deleteAllResults() async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      throw StateError(
        'The user must be signed in to delete practice results.',
      );
    }

    final resultsReference = _resultsReference(user.uid);

    while (true) {
      final results = await resultsReference.limit(50).get();

      if (results.docs.isEmpty) {
        return;
      }

      for (final result in results.docs) {
        await _deleteResultReference(result.reference);
      }
    }
  }

  Future<void> _deleteResultReference(
    DocumentReference<Map<String, dynamic>> resultReference, {
    bool ignoreFailures = false,
  }) async {
    try {
      while (true) {
        final events = await resultReference
            .collection('error_events')
            .limit(400)
            .get();

        if (events.docs.isEmpty) {
          break;
        }

        final batch = firestore.batch();

        for (final event in events.docs) {
          batch.delete(event.reference);
        }

        await batch.commit();
      }

      await resultReference.delete();
    } catch (_) {
      if (!ignoreFailures) {
        rethrow;
      }
    }
  }
}
