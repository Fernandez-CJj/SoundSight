import 'dart:ui';

/// Camera-space marker and outline geometry for one detected black key.
class BlackKeyGeometry {
  const BlackKeyGeometry({
    required this.markerPosition,
    required this.outlinePoints,
  });

  /// Point near the key's lower edge where its label is displayed.
  final Offset markerPosition;
  /// Ordered vertices describing the visible black-key polygon.
  final List<Offset> outlinePoints;
}
