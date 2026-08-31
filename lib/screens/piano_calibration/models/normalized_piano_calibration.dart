import 'normalized_image_point.dart';
import 'normalized_piano_key.dart';

/// Complete, resolution-independent piano calibration saved for a user.
///
/// It stores the playable-area corners and every visible key so the mapping
/// can be restored against a new camera-preview size without redetection.
class NormalizedPianoCalibration {
  const NormalizedPianoCalibration({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.sourceImageAspectRatio,
    required this.pianoKeys,
  });

  /// Normalized upper-left playable-area corner.
  final NormalizedImagePoint topLeft;
  /// Normalized upper-right playable-area corner.
  final NormalizedImagePoint topRight;
  /// Normalized lower-right playable-area corner.
  final NormalizedImagePoint bottomRight;
  /// Normalized lower-left playable-area corner.
  final NormalizedImagePoint bottomLeft;

  /// Width divided by height of the frame used during calibration.
  final double sourceImageAspectRatio;

  /// All labeled white and black keys visible in the calibrated area.
  final List<NormalizedPianoKey> pianoKeys;

  /// Reconstructs a calibration from Firestore JSON and validates its shape.
  ///
  /// A [FormatException] is thrown when required geometry or keys are absent.
  factory NormalizedPianoCalibration.fromJson(Map<String, dynamic> json) {
    dynamic sourceAspectRatioValue = json['sourceImageAspectRatio'];
    dynamic pianoKeysValue = json['pianoKeys'];

    if (sourceAspectRatioValue is! num ||
        sourceAspectRatioValue <= 0 ||
        pianoKeysValue is! List) {
      throw FormatException('The saved piano calibration data is invalid.');
    }

    // Keep point parsing in one place so each corner has identical validation.
    NormalizedImagePoint readPoint(String fieldName) {
      dynamic pointValue = json[fieldName];

      if (pointValue is! Map) {
        throw FormatException('The saved calibration is missing $fieldName.');
      }

      return NormalizedImagePoint.fromJson(
        Map<String, dynamic>.from(pointValue),
      );
    }

    List<NormalizedPianoKey> restoredPianoKeys = [];

    for (dynamic pianoKeyValue in pianoKeysValue) {
      if (pianoKeyValue is! Map) {
        throw FormatException('A saved piano key is invalid.');
      }

      restoredPianoKeys.add(
        NormalizedPianoKey.fromJson(Map<String, dynamic>.from(pianoKeyValue)),
      );
    }

    if (restoredPianoKeys.isEmpty) {
      throw FormatException(
        'The saved calibration does not contain any piano keys.',
      );
    }

    return NormalizedPianoCalibration(
      topLeft: readPoint('topLeft'),
      topRight: readPoint('topRight'),
      bottomRight: readPoint('bottomRight'),
      bottomLeft: readPoint('bottomLeft'),
      sourceImageAspectRatio: sourceAspectRatioValue.toDouble(),
      pianoKeys: List<NormalizedPianoKey>.unmodifiable(restoredPianoKeys),
    );
  }

  /// Serializes this calibration into Firestore-compatible primitive values.
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> pianoKeysJson = [];

    for (NormalizedPianoKey pianoKey in pianoKeys) {
      pianoKeysJson.add(pianoKey.toJson());
    }

    return {
      'sourceImageAspectRatio': sourceImageAspectRatio,
      'topLeft': topLeft.toJson(),
      'topRight': topRight.toJson(),
      'bottomRight': bottomRight.toJson(),
      'bottomLeft': bottomLeft.toJson(),
      'pianoKeys': pianoKeysJson,
    };
  }
}
