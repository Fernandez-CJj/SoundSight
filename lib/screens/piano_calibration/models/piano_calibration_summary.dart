/// Lightweight Firestore record displayed in the saved-calibration list.
///
/// Full key geometry is deliberately omitted until the user opens an entry.
class PianoCalibrationSummary {
  const PianoCalibrationSummary({
    required this.documentId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore document identifier used to load the full calibration.
  final String documentId;
  /// User-provided display name.
  final String name;
  /// Server creation time, or `null` while an unresolved timestamp is pending.
  final DateTime? createdAt;
  /// Most recent server update time.
  final DateTime? updatedAt;
}
