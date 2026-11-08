import 'package:cloud_firestore/cloud_firestore.dart';

/// One boolean per feature, shared by all devices signed in to this account.
class FeatureTourProgressService {
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _reference(String userId) =>
      _database.collection('users').doc(userId).collection('onboarding').doc('features');

  Future<bool> hasSeen(String userId, String featureId) async {
    // Read the server so another device's completion is respected.
    // If the read fails, the controller defers the automatic tour.
    final snapshot = await _reference(userId).get(
      const GetOptions(source: Source.server),
    );
    return snapshot.data()?[featureId] == true;
  }

  Future<void> markSeen(String userId, String featureId) async {
    // Merge preserves flags belonging to other feature tours.
    await _reference(userId).set({featureId: true}, SetOptions(merge: true));
  }
}
