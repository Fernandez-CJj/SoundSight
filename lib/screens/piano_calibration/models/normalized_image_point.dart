/// Resolution-independent point stored as horizontal and vertical fractions.
///
/// Normalized points make a calibration portable across preview sizes while
/// retaining the perspective captured by the original camera frame.
class NormalizedImagePoint {
  const NormalizedImagePoint({
    required this.horizontalFraction,
    required this.verticalFraction,
  });

  /// Horizontal position where `0` is the left and `1` is the right edge.
  final double horizontalFraction;
  /// Vertical position where `0` is the top and `1` is the bottom edge.
  final double verticalFraction;

  /// Deserializes a normalized point and rejects missing/non-numeric values.
  factory NormalizedImagePoint.fromJson(Map<String, dynamic> json) {
    dynamic horizontalValue = json['horizontalFraction'];
    dynamic verticalValue = json['verticalFraction'];

    if (horizontalValue is! num || verticalValue is! num) {
      throw const FormatException(
        'A normalized image point must contain numeric fractions.',
      );
    }

    return NormalizedImagePoint(
      horizontalFraction: horizontalValue.toDouble(),
      verticalFraction: verticalValue.toDouble(),
    );
  }

  /// Converts this point into the map stored in Firestore calibration data.
  Map<String, dynamic> toJson() {
    return {
      'horizontalFraction': horizontalFraction,
      'verticalFraction': verticalFraction,
    };
  }
}
