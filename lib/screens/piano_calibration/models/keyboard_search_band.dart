/// Vertical portion of a frame in which black keys should be searched for.
class KeyboardSearchBand {
  KeyboardSearchBand({required this.topFraction, required this.bottomFraction});

  /// Inclusive upper boundary expressed as a fraction of image height.
  final double topFraction;
  /// Inclusive lower boundary expressed as a fraction of image height.
  final double bottomFraction;
}
