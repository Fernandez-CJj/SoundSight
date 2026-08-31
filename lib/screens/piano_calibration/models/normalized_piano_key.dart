import 'normalized_image_point.dart';

/// Resolution-independent identity and geometry for one calibrated piano key.
class NormalizedPianoKey {
  const NormalizedPianoKey({
    required this.noteLetter,
    required this.octaveNumber,
    required this.isBlackKey,
    required this.markerPosition,
    required this.outlinePoints,
  });

  /// Letter name, including `#` for black keys, such as `C` or `F#`.
  final String noteLetter;
  /// Scientific-pitch octave number used with [noteLetter].
  final int octaveNumber;
  /// Whether the key is a raised black key.
  final bool isBlackKey;

  /// Label/falling-note target point in normalized image coordinates.
  final NormalizedImagePoint markerPosition;

  /// Ordered normalized vertices forming the key's visual outline.
  final List<NormalizedImagePoint> outlinePoints;

  /// Reconstructs and validates one key from stored Firestore JSON.
  factory NormalizedPianoKey.fromJson(Map<String, dynamic> json) {
    dynamic noteLetterValue = json['noteLetter'];
    dynamic octaveNumberValue = json['octaveNumber'];
    dynamic isBlackKeyValue = json['isBlackKey'];
    dynamic markerPositionValue = json['markerPosition'];
    dynamic outlinePointsValue = json['outlinePoints'];

    if (noteLetterValue is! String ||
        noteLetterValue.trim().isEmpty ||
        octaveNumberValue is! num ||
        isBlackKeyValue is! bool ||
        markerPositionValue is! Map ||
        outlinePointsValue is! List) {
      throw FormatException('The saved piano key data is invalid.');
    }

    List<NormalizedImagePoint> restoredOutlinePoints = [];

    for (dynamic pointValue in outlinePointsValue) {
      if (pointValue is! Map) {
        throw FormatException('A piano key outline point is invalid.');
      }

      restoredOutlinePoints.add(
        NormalizedImagePoint.fromJson(Map<String, dynamic>.from(pointValue)),
      );
    }

    if (restoredOutlinePoints.length < 3) {
      throw FormatException(
        'A saved piano key outline must contain at least three points.',
      );
    }

    return NormalizedPianoKey(
      noteLetter: noteLetterValue.trim(),
      octaveNumber: octaveNumberValue.toInt(),
      isBlackKey: isBlackKeyValue,
      markerPosition: NormalizedImagePoint.fromJson(
        Map<String, dynamic>.from(markerPositionValue),
      ),
      outlinePoints: List<NormalizedImagePoint>.unmodifiable(
        restoredOutlinePoints,
      ),
    );
  }

  /// Human-readable note name, for example `C4` or `F#3`.
  String get noteName {
    return '$noteLetter$octaveNumber';
  }

  /// Serializes this key, marker, and outline into Firestore-compatible JSON.
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> outlinePointsJson = [];

    for (NormalizedImagePoint point in outlinePoints) {
      outlinePointsJson.add(point.toJson());
    }

    return {
      'noteLetter': noteLetter,
      'octaveNumber': octaveNumber,
      'isBlackKey': isBlackKey,
      'markerPosition': markerPosition.toJson(),
      'outlinePoints': outlinePointsJson,
    };
  }
}
