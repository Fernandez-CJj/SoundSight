import 'normalized_piano_calibration.dart';

/// Full named calibration loaded from a user's Firestore document.
class SavedPianoCalibration {
  const SavedPianoCalibration({
    required this.documentId,
    required this.name,
    required this.calibration,
  });

  /// Firestore document identifier used for later updates.
  final String documentId;
  /// User-provided calibration name.
  final String name;
  /// Validated normalized keyboard geometry stored by the document.
  final NormalizedPianoCalibration calibration;
}
