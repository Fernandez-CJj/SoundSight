import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/normalized_piano_calibration.dart';
import '../models/piano_calibration_summary.dart';
import '../models/saved_piano_calibration.dart';

/// Reads and writes the signed-in user's piano calibrations in Firestore.
///
/// Documents live under `users/{uid}/pianoCalibrations/{calibrationId}` so
/// callers never need to pass or trust another user's identifier.
class PianoCalibrationFirestoreService {
  /// Watches lightweight calibration metadata ordered by most recent update.
  ///
  /// Geometry is intentionally not parsed here because list tiles only need a
  /// name and timestamps. Stream errors are surfaced to the list screen.
  Stream<List<PianoCalibrationSummary>> watchCalibrationSummaries() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Stream<List<PianoCalibrationSummary>>.error(
        StateError('The user must be signed in to view calibrations.'),
      );
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('pianoCalibrations')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((document) {
                Map<String, dynamic> data = document.data();
                Timestamp? createdAt = data['createdAt'] as Timestamp?;
                Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
                String? storedName = data['name'] as String?;
                String cleanedName = storedName?.trim() ?? '';

                return PianoCalibrationSummary(
                  documentId: document.id,
                  name: cleanedName.isEmpty
                      ? 'Unnamed calibration'
                      : cleanedName,
                  createdAt: createdAt?.toDate(),
                  updatedAt: updatedAt?.toDate(),
                );
              })
              .toList(growable: false);
        });
  }

  /// Loads and validates the full calibration stored in [documentId].
  ///
  /// Throws when the user is signed out, the document is missing, or its
  /// schema cannot be understood by this app version.
  Future<SavedPianoCalibration> loadCalibration({
    required String documentId,
  }) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw StateError(
        'The user must be signed in before loading a calibration.',
      );
    }

    String cleanedDocumentId = documentId.trim();

    if (cleanedDocumentId.isEmpty) {
      throw ArgumentError('The calibration document ID cannot be empty.');
    }

    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('pianoCalibrations')
        .doc(cleanedDocumentId)
        .get();

    if (!snapshot.exists) {
      throw StateError('The selected calibration no longer exists.');
    }

    Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      throw StateError('The selected calibration contains no data.');
    }

    dynamic schemaVersionValue = data['schemaVersion'];

    if (schemaVersionValue is! num || schemaVersionValue.toInt() != 1) {
      throw UnsupportedError('This calibration format is not supported.');
    }

    dynamic nameValue = data['name'];

    if (nameValue is! String || nameValue.trim().isEmpty) {
      throw FormatException(
        'The selected calibration does not have a valid name.',
      );
    }

    return SavedPianoCalibration(
      documentId: snapshot.id,
      name: nameValue.trim(),
      calibration: NormalizedPianoCalibration.fromJson(data),
    );
  }

  /// Creates a new calibration document or updates an existing one.
  ///
  /// Returns the document ID. Server timestamps ensure ordering does not rely
  /// on the phone's clock, while merge mode preserves the original creation
  /// timestamp during edits.
  Future<String> saveCalibration({
    required String calibrationName,
    required NormalizedPianoCalibration calibration,
    String? existingDocumentId,
  }) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw StateError(
        'The user must be signed in before saving a calibration.',
      );
    }

    String cleanedName = calibrationName.trim();

    if (cleanedName.isEmpty) {
      throw ArgumentError('The calibration name cannot be empty.');
    }

    CollectionReference<Map<String, dynamic>> calibrationCollection =
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('pianoCalibrations');

    DocumentReference<Map<String, dynamic>> calibrationDocument;

    if (existingDocumentId == null) {
      calibrationDocument = calibrationCollection.doc();
    } else {
      calibrationDocument = calibrationCollection.doc(existingDocumentId);
    }

    Map<String, dynamic> calibrationData = calibration.toJson();

    calibrationData['name'] = cleanedName;
    calibrationData['schemaVersion'] = 1;
    calibrationData['updatedAt'] = FieldValue.serverTimestamp();

    if (existingDocumentId == null) {
      calibrationData['createdAt'] = FieldValue.serverTimestamp();
    }

    await calibrationDocument.set(calibrationData, SetOptions(merge: true));

    return calibrationDocument.id;
  }
}
