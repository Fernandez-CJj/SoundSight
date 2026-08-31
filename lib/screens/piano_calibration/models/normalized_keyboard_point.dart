/// Position expressed within the keyboard quadrilateral rather than the image.
///
/// This representation is used by perspective mapping calculations.
class NormalizedKeyboardPoint {
  const NormalizedKeyboardPoint({
    required this.horizontalFraction,
    required this.verticalFraction,
  });

  /// Left-to-right fraction within the keyboard area.
  final double horizontalFraction;
  /// Top-to-bottom fraction within the keyboard area.
  final double verticalFraction;
}
