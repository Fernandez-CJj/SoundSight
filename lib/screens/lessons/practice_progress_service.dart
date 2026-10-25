import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores the highest unlocked lesson stage on the signed-in user's profile.
class PracticeProgressService {
  static const int stageCompletionXp = 50;

  PracticeProgressService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _profile {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to save lesson progress.');
    return _firestore.collection('users').doc(user.uid);
  }

  Future<int> loadLevel() async {
    final snapshot = await _profile.get();
    if (!snapshot.exists) throw StateError('User profile not found.');
    return _levelFrom(snapshot.data());
  }

  Future<int> advanceAfterPass(int stageNumber) async {
    if (stageNumber < 1 || stageNumber > 16) {
      throw RangeError.range(stageNumber, 1, 16, 'stageNumber');
    }
    final profile = _profile;
    return _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(profile);
      if (!snapshot.exists) throw StateError('User profile not found.');
      final currentLevel = _levelFrom(snapshot.data());
      if (stageNumber < currentLevel) return currentLevel;
      if (stageNumber != currentLevel) {
        throw StateError('Complete the current stage first.');
      }
      final nextLevel = stageNumber + 1;
      final currentSkillLevel = snapshot.data()?['skillLevel'];
      final promotion = _promotionAfterPass(stageNumber, currentSkillLevel);
      final updates = <String, dynamic>{
        'practiceLevel': nextLevel,
        'experiencePoints': FieldValue.increment(stageCompletionXp),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (promotion != null) {
        updates['skillLevel'] = promotion;
      }
      transaction.update(profile, updates);
      return nextLevel;
    });
  }

  String? _promotionAfterPass(int stageNumber, dynamic skillLevel) {
    if (stageNumber == 16 && skillLevel != 'advanced') {
      return 'advanced';
    }
    if (stageNumber == 9 &&
        skillLevel != 'intermediate' &&
        skillLevel != 'advanced') {
      return 'intermediate';
    }
    return null;
  }

  int _levelFrom(Map<String, dynamic>? data) {
    final raw = data?['practiceLevel'];
    if (raw == null) return 1;
    if (raw is! int || raw < 1 || raw > 17) {
      throw const FormatException('Invalid practice level on user profile.');
    }
    return raw;
  }
}
