import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SightReadingCompletionResult {
  const SightReadingCompletionResult({
    required this.newlyCompleted,
    required this.xpAwarded,
  });

  final bool newlyCompleted;
  final int xpAwarded;
}

class SightReadingProgressService {
  static const int perfectPerformanceXp = 20;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<SightReadingCompletionResult> recordPerfectCompletion({
    required String challengeItemId,
    required int correctCount,
    required int wrongCount,
    required int missedCount,
    required int totalCount,
  }) async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('The user must be signed in.');
    }

    final isPerfect =
        totalCount > 0 &&
        correctCount == totalCount &&
        wrongCount == 0 &&
        missedCount == 0;

    if (!isPerfect) {
      throw StateError('Only a perfect performance can be completed.');
    }

    final userReference = firestore.collection('users').doc(user.uid);

    final progressReference = userReference
        .collection('challenge_progress')
        .doc(challengeItemId);

    return firestore.runTransaction((transaction) async {
      final progressSnapshot = await transaction.get(progressReference);
      final progressData = progressSnapshot.data();

      final alreadyCompleted = progressData?['completed'] == true;

      if (alreadyCompleted) {
        return const SightReadingCompletionResult(
          newlyCompleted: false,
          xpAwarded: 0,
        );
      }

      transaction.set(progressReference, {
        'challengeItemId': challengeItemId,
        'completed': true,
        'mode': 'performance',
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'missedCount': missedCount,
        'totalCount': totalCount,
        'xpAwarded': perfectPerformanceXp,
        'completedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(userReference, {
        'experiencePoints': FieldValue.increment(perfectPerformanceXp),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const SightReadingCompletionResult(
        newlyCompleted: true,
        xpAwarded: perfectPerformanceXp,
      );
    });
  }
}
