import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Creates the permanent Firestore profile after Firebase verifies an email.
class RegistrationProfileService {
  RegistrationProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DocumentSnapshot<Map<String, dynamic>>> loadProfile(User user) {
    return _firestore.collection('users').doc(user.uid).get();
  }

  /// Creates the profile once without overwriting an existing account.
  Future<void> ensureProfile(User user, {String? fallbackUsername}) async {
    if (!user.emailVerified) {
      throw StateError('Email verification is required before profile setup.');
    }

    // Refresh the token so Firestore receives the current email_verified claim.
    await user.getIdTokenResult(true);

    final reference = _firestore.collection('users').doc(user.uid);
    final username = _usernameFor(user, fallbackUsername: fallbackUsername);

    await _firestore.runTransaction((transaction) async {
      final existingProfile = await transaction.get(reference);

      if (existingProfile.exists) {
        return;
      }

      transaction.set(reference, {
        'uid': user.uid,
        'username': username,
        'profileImageUrl': null,
        'email': user.email,
        'role': 'piano_player',
        'theme': 'light',
        'languageCode': 'en',
        'skillLevel': null,
        'practiceLevel': 1,
        'experiencePoints': 0,
        'preferredNotation': null,
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  String _usernameFor(User user, {String? fallbackUsername}) {
    final displayName = user.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final fallback = fallbackUsername?.trim();

    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    final email = user.email ?? '';
    final separatorIndex = email.indexOf('@');
    final emailName = separatorIndex > 0
        ? email.substring(0, separatorIndex)
        : '';

    return emailName.isNotEmpty ? emailName : 'SoundSight Player';
  }
}
