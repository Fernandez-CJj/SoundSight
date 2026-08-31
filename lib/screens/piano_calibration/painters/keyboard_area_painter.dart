import 'package:flutter/material.dart';

import '../models/keyboard_area_corner.dart';
import '../models/keyboard_area_corners.dart';
import '../models/piano_key_marker.dart';
import '../models/piano_key_region.dart';

/// Paints calibration geometry and practice guides over the camera preview.
///
/// Source-image coordinates are scaled to the current widget size so the same
/// painter can render live detection, editable outlines, labels, and hit line.
class KeyboardAreaPainter extends CustomPainter {
  KeyboardAreaPainter({
    required this.corners,
    required this.pianoKeyMarkers,
    required this.pianoKeyRegions,
    required this.showKeyboardArea,
    required this.showKeyOutlines,
    required this.showHitLine,
    required this.showMarkerCircles,
    required this.centerLabelsOnMarkers,
    required this.highlightedMarkerNames,
    required this.activeCorner,
  });
  final KeyboardAreaCorners corners;
  final List<PianoKeyMarker> pianoKeyMarkers;
  final List<PianoKeyRegion> pianoKeyRegions;
  final bool showKeyboardArea;
  final bool showKeyOutlines;
  final bool showHitLine;
  final bool showMarkerCircles;
  final bool centerLabelsOnMarkers;
  final Set<String> highlightedMarkerNames;
  final KeyboardAreaCorner? activeCorner;

  final double hitLineInsetFraction = 0.08;

  @override
  /// Draws enabled layers in back-to-front order for the current screen state.
  void paint(Canvas canvas, Size size) {
    double horizontalScale = size.width / corners.sourceImageWidth;

    double verticalScale = size.height / corners.sourceImageHeight;

    Offset displayedTopLeft = scalePoint(
      corners.topLeft,
      horizontalScale,
      verticalScale,
    );

    Offset displayedTopRight = scalePoint(
      corners.topRight,
      horizontalScale,
      verticalScale,
    );

    Offset displayedBottomRight = scalePoint(
      corners.bottomRight,
      horizontalScale,
      verticalScale,
    );

    Offset displayedBottomLeft = scalePoint(
      corners.bottomLeft,
      horizontalScale,
      verticalScale,
    );

    Path keyboardPath = Path();

    keyboardPath.moveTo(displayedTopLeft.dx, displayedTopLeft.dy);

    keyboardPath.lineTo(displayedTopRight.dx, displayedTopRight.dy);

    keyboardPath.lineTo(displayedBottomRight.dx, displayedBottomRight.dy);

    keyboardPath.lineTo(displayedBottomLeft.dx, displayedBottomLeft.dy);

    keyboardPath.close();

    Paint fillPaint = Paint();
    fillPaint.color = const Color(0x2632CD32);
    fillPaint.style = PaintingStyle.fill;

    Paint outlinePaint = Paint();
    outlinePaint.color = Colors.lightGreenAccent;
    outlinePaint.style = PaintingStyle.stroke;
    outlinePaint.strokeWidth = 3;

    if (showKeyboardArea) {
      canvas.drawPath(keyboardPath, fillPaint);
      canvas.drawPath(keyboardPath, outlinePaint);
    }

    if (showKeyOutlines) {
      drawPianoKeyRegions(
        canvas: canvas,
        horizontalScale: horizontalScale,
        verticalScale: verticalScale,
      );
    }

    if (showHitLine) {
      drawHitLine(
        canvas: canvas,
        displayedTopLeft: displayedTopLeft,
        displayedTopRight: displayedTopRight,
        displayedBottomRight: displayedBottomRight,
        displayedBottomLeft: displayedBottomLeft,
      );
    }

    if (showKeyboardArea) {
      drawCorner(canvas, displayedTopLeft, KeyboardAreaCorner.topLeft);
      drawCorner(canvas, displayedTopRight, KeyboardAreaCorner.topRight);
      drawCorner(canvas, displayedBottomRight, KeyboardAreaCorner.bottomRight);
      drawCorner(canvas, displayedBottomLeft, KeyboardAreaCorner.bottomLeft);
    }

    for (PianoKeyMarker marker in pianoKeyMarkers) {
      Offset displayedPosition = scalePoint(
        marker.position,
        horizontalScale,
        verticalScale,
      );

      drawPianoKeyMarker(
        canvas: canvas,
        position: displayedPosition,
        color: colorForPianoKeyMarker(marker),
        label: marker.noteName,
        labelColor: marker.isBlackKey ? Colors.white : Colors.black87,
        labelShadowColor: marker.isBlackKey ? Colors.black87 : Colors.white,
        radius: marker.isC ? 10 : 7,
        showCircle: showMarkerCircles,
        centerLabelOnPosition: centerLabelsOnMarkers,
        isHighlighted: highlightedMarkerNames.contains(marker.noteName),
      );
    }
  }

  /// Scales one source-image point into displayed preview coordinates.
  Offset scalePoint(
    Offset sourcePoint,
    double horizontalScale,
    double verticalScale,
  ) {
    return Offset(
      sourcePoint.dx * horizontalScale,
      sourcePoint.dy * verticalScale,
    );
  }

  /// Draws the cyan timing line slightly above the playable area's bottom edge.
  void drawHitLine({
    required Canvas canvas,
    required Offset displayedTopLeft,
    required Offset displayedTopRight,
    required Offset displayedBottomRight,
    required Offset displayedBottomLeft,
  }) {
    Offset leftHitPoint = Offset.lerp(
      displayedBottomLeft,
      displayedTopLeft,
      hitLineInsetFraction,
    )!;

    Offset rightHitPoint = Offset.lerp(
      displayedBottomRight,
      displayedTopRight,
      hitLineInsetFraction,
    )!;

    Paint hitLineGlowPaint = Paint()
      ..color = const Color(0x6680D8FF)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    Paint hitLinePaint = Paint()
      ..color = const Color(0xFF80D8FF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(leftHitPoint, rightHitPoint, hitLineGlowPaint);
    canvas.drawLine(leftHitPoint, rightHitPoint, hitLinePaint);
  }

  /// Draws white regions first and black regions second for natural overlap.
  void drawPianoKeyRegions({
    required Canvas canvas,
    required double horizontalScale,
    required double verticalScale,
  }) {
    for (PianoKeyRegion region in pianoKeyRegions) {
      if (region.isBlackKey) {
        continue;
      }

      drawPianoKeyRegion(
        canvas: canvas,
        region: region,
        horizontalScale: horizontalScale,
        verticalScale: verticalScale,
      );
    }

    for (PianoKeyRegion region in pianoKeyRegions) {
      if (!region.isBlackKey) {
        continue;
      }

      drawPianoKeyRegion(
        canvas: canvas,
        region: region,
        horizontalScale: horizontalScale,
        verticalScale: verticalScale,
      );
    }
  }

  /// Converts and strokes a single key's polygon with its key-type color.
  void drawPianoKeyRegion({
    required Canvas canvas,
    required PianoKeyRegion region,
    required double horizontalScale,
    required double verticalScale,
  }) {
    if (region.outlinePoints.length < 3) {
      return;
    }

    List<Offset> displayedPoints = [
      for (Offset sourcePoint in region.outlinePoints)
        scalePoint(sourcePoint, horizontalScale, verticalScale),
    ];

    Path regionPath = Path();
    regionPath.moveTo(displayedPoints.first.dx, displayedPoints.first.dy);

    for (int index = 1; index < displayedPoints.length; index++) {
      regionPath.lineTo(displayedPoints[index].dx, displayedPoints[index].dy);
    }

    regionPath.close();

    Paint regionFillPaint = Paint();
    regionFillPaint.color = region.isBlackKey
        ? const Color(0x1AFF4081)
        : const Color(0x12448AFF);
    regionFillPaint.style = PaintingStyle.fill;

    Paint regionOutlinePaint = Paint();
    regionOutlinePaint.color = region.isBlackKey
        ? const Color(0xE6FF4081)
        : const Color(0xCC448AFF);
    regionOutlinePaint.style = PaintingStyle.stroke;
    regionOutlinePaint.strokeWidth = region.isBlackKey ? 2 : 1.5;

    canvas.drawPath(regionPath, regionFillPaint);
    canvas.drawPath(regionPath, regionOutlinePaint);
  }

  /// Draws one draggable corner, emphasizing the actively moved corner.
  void drawCorner(Canvas canvas, Offset position, KeyboardAreaCorner corner) {
    bool isActive = activeCorner == corner;

    Paint cornerPaint = Paint();
    cornerPaint.color = isActive ? Colors.amber : Colors.white;
    cornerPaint.style = PaintingStyle.fill;

    Paint cornerOutlinePaint = Paint();
    cornerOutlinePaint.color = isActive
        ? Colors.white
        : Colors.lightGreenAccent;
    cornerOutlinePaint.style = PaintingStyle.stroke;
    cornerOutlinePaint.strokeWidth = 2;

    double radius = isActive ? 10 : 7;

    canvas.drawCircle(position, radius, cornerPaint);
    canvas.drawCircle(position, radius, cornerOutlinePaint);
  }

  /// Draws a key label and optional circle at its calibrated target position.
  ///
  /// Practice mode centers labels on the target while calibration mode places
  /// labels above colored circles for easier geometry review.
  void drawPianoKeyMarker({
    required Canvas canvas,
    required Offset position,
    required Color color,
    required String label,
    required Color labelColor,
    required Color labelShadowColor,
    required double radius,
    required bool showCircle,
    required bool centerLabelOnPosition,
    required bool isHighlighted,
  }) {
    if (showCircle) {
      Paint markerPaint = Paint();
      markerPaint.color = color;
      markerPaint.style = PaintingStyle.fill;

      Paint markerOutlinePaint = Paint();
      markerOutlinePaint.color = Colors.white;
      markerOutlinePaint.style = PaintingStyle.stroke;
      markerOutlinePaint.strokeWidth = 3;

      canvas.drawCircle(position, radius, markerPaint);
      canvas.drawCircle(position, radius, markerOutlinePaint);
    }

    TextPainter labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isHighlighted ? Colors.black87 : labelColor,
          fontSize: 12,
          fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
          shadows: isHighlighted
              ? const []
              : [Shadow(color: labelShadowColor, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    labelPainter.layout();

    double labelLeft = position.dx - (labelPainter.width / 2);
    double labelTop = centerLabelOnPosition
        ? position.dy - (labelPainter.height / 2)
        : position.dy - radius - labelPainter.height - 4;

    if (isHighlighted) {
      Rect highlightRect = Rect.fromLTWH(
        labelLeft - 6,
        labelTop - 4,
        labelPainter.width + 12,
        labelPainter.height + 8,
      );

      Paint highlightGlowPaint = Paint()
        ..color = const Color(0x6655FF55)
        ..style = PaintingStyle.fill;

      Paint highlightPaint = Paint()
        ..color = Colors.lightGreenAccent
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect.inflate(3), const Radius.circular(9)),
        highlightGlowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(7)),
        highlightPaint,
      );
    }

    labelPainter.paint(canvas, Offset(labelLeft, labelTop));
  }

  /// Selects calibration marker colors by key type and reference octave.
  Color colorForPianoKeyMarker(PianoKeyMarker marker) {
    if (marker.isBlackKey) {
      return Colors.pinkAccent;
    }

    if (!marker.isC) {
      return Colors.blueAccent;
    }

    if (marker.octaveNumber < 4) {
      return Colors.purpleAccent;
    }

    if (marker.octaveNumber > 4) {
      return Colors.cyanAccent;
    }

    return Colors.amber;
  }

  @override
  /// Repaints whenever geometry, visibility flags, drag state, or highlights change.
  bool shouldRepaint(KeyboardAreaPainter oldPainter) {
    bool cornersChanged = oldPainter.corners != corners;

    bool pianoKeyMarkersChanged = oldPainter.pianoKeyMarkers != pianoKeyMarkers;

    bool pianoKeyRegionsChanged = oldPainter.pianoKeyRegions != pianoKeyRegions;

    bool showKeyboardAreaChanged =
        oldPainter.showKeyboardArea != showKeyboardArea;

    bool showKeyOutlinesChanged = oldPainter.showKeyOutlines != showKeyOutlines;

    bool showHitLineChanged = oldPainter.showHitLine != showHitLine;

    bool showMarkerCirclesChanged =
        oldPainter.showMarkerCircles != showMarkerCircles;

    bool centerLabelsOnMarkersChanged =
        oldPainter.centerLabelsOnMarkers != centerLabelsOnMarkers;

    bool highlightedMarkerNamesChanged =
        oldPainter.highlightedMarkerNames.length !=
            highlightedMarkerNames.length ||
        !oldPainter.highlightedMarkerNames.every(
          highlightedMarkerNames.contains,
        );

    bool activeCornerChanged = oldPainter.activeCorner != activeCorner;

    return cornersChanged ||
        pianoKeyMarkersChanged ||
        pianoKeyRegionsChanged ||
        showKeyboardAreaChanged ||
        showKeyOutlinesChanged ||
        showHitLineChanged ||
        showMarkerCirclesChanged ||
        centerLabelsOnMarkersChanged ||
        highlightedMarkerNamesChanged ||
        activeCornerChanged;
  }
}
