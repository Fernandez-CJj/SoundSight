/// A dark rectangular component that may represent a black piano key.
///
/// Coordinates are measured in pixels within the processed camera image.
class BlackKeyCandidate {
  BlackKeyCandidate({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.fillRatio,
  });

  /// Horizontal coordinate of the candidate's left edge.
  final int left;
  /// Vertical coordinate of the candidate's top edge.
  final int top;
  /// Width of the candidate's bounding rectangle in pixels.
  final int width;
  /// Height of the candidate's bounding rectangle in pixels.
  final int height;
  /// Proportion of the bounding rectangle occupied by dark pixels.
  final double fillRatio;
}
