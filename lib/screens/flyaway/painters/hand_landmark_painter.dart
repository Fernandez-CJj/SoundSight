import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hand_detection/hand_detection.dart';

/// Draws the detected hand landmarks over the full-screen camera preview.
/// The painter applies the same BoxFit.cover scaling used by the preview so
/// that detector coordinates appear in the correct screen positions.
class HandLandmarkPainter extends CustomPainter {
  const HandLandmarkPainter({required this.hands, required this.imageSize});

  /// Hands detected in the current camera frame.
  final List<Hand> hands;

  /// Size of the rotated and resized image analyzed by the detector.
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawing cannot be calculated from an empty detector image.
    if (imageSize.isEmpty) {
      return;
    }

    // Calculate how much the detector image must grow in both directions.
    final horizontalScale = size.width / imageSize.width;
    final verticalScale = size.height / imageSize.height;

    // BoxFit.cover uses the larger scale so the image fills the screen.
    final scale = math.max(horizontalScale, verticalScale);

    final displayedWidth = imageSize.width * scale;
    final displayedHeight = imageSize.height * scale;

    // Center the scaled image. A negative offset represents cropped content.
    final horizontalOffset = (size.width - displayedWidth) / 2;
    final verticalOffset = (size.height - displayedHeight) / 2;

    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      final hand = hands[handIndex];

      final Color pointColor;

      // Give each detected hand a different landmark color.
      if (handIndex == 0) {
        pointColor = Colors.cyanAccent;
      } else {
        pointColor = Colors.orangeAccent;
      }

      final pointPaint = Paint();
      pointPaint.color = pointColor;
      pointPaint.style = PaintingStyle.fill;

      for (final landmark in hand.landmarks) {
        // Convert the detector coordinate into a displayed-screen coordinate.
        final scaledX = landmark.x * scale;
        final scaledY = landmark.y * scale;

        final screenX = scaledX + horizontalOffset;
        final screenY = scaledY + verticalOffset;

        final screenPoint = Offset(screenX, screenY);

        canvas.drawCircle(screenPoint, 5, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter oldDelegate) {
    // Repaint when the detected hands or detector image size changes.
    return oldDelegate.hands != hands || oldDelegate.imageSize != imageSize;
  }
}
