import 'package:flutter/material.dart';

import '../models/keyboard_area_corner.dart';
import '../models/keyboard_area_corners.dart';
import '../models/piano_key_marker.dart';
import '../models/piano_key_region.dart';
import '../painters/keyboard_area_painter.dart';

/// Interactive overlay for reviewing and adjusting detected keyboard geometry.
///
/// It translates preview gestures back into source-image coordinates and uses
/// [KeyboardAreaPainter] for all visual layers.
class KeyboardAreaOverlay extends StatefulWidget {
  const KeyboardAreaOverlay({
    super.key,
    required this.corners,
    required this.pianoKeyMarkers,
    required this.pianoKeyRegions,
    required this.showKeyboardArea,
    required this.showKeyOutlines,
    required this.showHitLine,
    required this.showMarkerCircles,
    required this.centerLabelsOnMarkers,
    required this.highlightedMarkerNames,
    required this.adjustmentEnabled,
    required this.referenceSelectionEnabled,
    required this.onCornersChanged,
    required this.onReferenceSelected,
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
  final bool adjustmentEnabled;
  final bool referenceSelectionEnabled;
  final ValueChanged<KeyboardAreaCorners> onCornersChanged;
  final ValueChanged<Offset> onReferenceSelected;

  @override
  /// Creates the gesture and working-corner state for this overlay.
  State<KeyboardAreaOverlay> createState() {
    return KeyboardAreaOverlayState();
  }
}

/// Maintains temporary corner positions while the user drags the overlay.
class KeyboardAreaOverlayState extends State<KeyboardAreaOverlay> {
  final double cornerTouchRadius = 34;
  final double minimumAreaWidthFraction = 0.08;
  final double minimumAreaHeightFraction = 0.08;

  late KeyboardAreaCorners workingCorners;
  KeyboardAreaCorner? activeCorner;

  @override
  /// Initializes editable geometry from the detector or restored calibration.
  void initState() {
    super.initState();
    workingCorners = widget.corners;
  }

  @override
  /// Synchronizes working geometry and cancels dragging when inputs change.
  void didUpdateWidget(KeyboardAreaOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.corners != widget.corners) {
      workingCorners = widget.corners;
    }

    if (!widget.adjustmentEnabled) {
      activeCorner = null;
    }
  }

  @override
  /// Builds gesture handling around the custom-painted overlay.
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size previewSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.referenceSelectionEnabled
              ? (TapDownDetails details) {
                  selectReferenceKey(details.localPosition, previewSize);
                }
              : null,
          onPanStart: widget.adjustmentEnabled
              ? (DragStartDetails details) {
                  startCornerDrag(details.localPosition, previewSize);
                }
              : null,
          onPanUpdate: widget.adjustmentEnabled
              ? (DragUpdateDetails details) {
                  updateCornerDrag(details.delta, previewSize);
                }
              : null,
          onPanEnd: widget.adjustmentEnabled
              ? (DragEndDetails details) {
                  finishCornerDrag();
                }
              : null,
          onPanCancel: widget.adjustmentEnabled ? finishCornerDrag : null,
          child: CustomPaint(
            painter: KeyboardAreaPainter(
              corners: workingCorners,
              pianoKeyMarkers: widget.pianoKeyMarkers,
              pianoKeyRegions: widget.pianoKeyRegions,
              showKeyboardArea: widget.showKeyboardArea,
              showKeyOutlines: widget.showKeyOutlines,
              showHitLine: widget.showHitLine,
              showMarkerCircles: widget.showMarkerCircles,
              centerLabelsOnMarkers: widget.centerLabelsOnMarkers,
              highlightedMarkerNames: widget.highlightedMarkerNames,
              activeCorner: activeCorner,
            ),
          ),
        );
      },
    );
  }

  /// Selects the nearest corner when a drag begins inside its touch radius.
  void startCornerDrag(Offset displayedPosition, Size previewSize) {
    Map<KeyboardAreaCorner, Offset> displayedCorners = {
      KeyboardAreaCorner.topLeft: convertSourceToDisplay(
        workingCorners.topLeft,
        previewSize,
      ),
      KeyboardAreaCorner.topRight: convertSourceToDisplay(
        workingCorners.topRight,
        previewSize,
      ),
      KeyboardAreaCorner.bottomRight: convertSourceToDisplay(
        workingCorners.bottomRight,
        previewSize,
      ),
      KeyboardAreaCorner.bottomLeft: convertSourceToDisplay(
        workingCorners.bottomLeft,
        previewSize,
      ),
    };

    KeyboardAreaCorner? closestCorner;
    double? closestDistance;

    displayedCorners.forEach((corner, cornerPosition) {
      double distance = (displayedPosition - cornerPosition).distance;

      if (closestDistance == null || distance < closestDistance!) {
        closestCorner = corner;
        closestDistance = distance;
      }
    });

    if (closestDistance == null || closestDistance! > cornerTouchRadius) {
      return;
    }

    setState(() {
      activeCorner = closestCorner;
    });
  }

  /// Applies a drag delta while preserving minimum size and convex geometry.
  void updateCornerDrag(Offset displayedDelta, Size previewSize) {
    KeyboardAreaCorner? currentActiveCorner = activeCorner;

    if (currentActiveCorner == null ||
        previewSize.width <= 0 ||
        previewSize.height <= 0) {
      return;
    }

    Offset sourceDelta = Offset(
      displayedDelta.dx * workingCorners.sourceImageWidth / previewSize.width,
      displayedDelta.dy * workingCorners.sourceImageHeight / previewSize.height,
    );

    Offset currentPosition = positionForCorner(currentActiveCorner);
    Offset requestedPosition = currentPosition + sourceDelta;
    Offset constrainedPosition = constrainCornerPosition(
      currentActiveCorner,
      requestedPosition,
    );

    KeyboardAreaCorners updatedCorners = replaceCorner(
      currentActiveCorner,
      constrainedPosition,
    );

    if (!isConvexKeyboardArea(updatedCorners)) {
      return;
    }

    setState(() {
      workingCorners = updatedCorners;
    });

    widget.onCornersChanged(updatedCorners);
  }

  /// Rejects self-crossing or inverted quadrilaterals after a corner move.
  bool isConvexKeyboardArea(KeyboardAreaCorners corners) {
    List<Offset> points = [
      corners.topLeft,
      corners.topRight,
      corners.bottomRight,
      corners.bottomLeft,
    ];

    double? expectedCrossProductSign;

    for (int index = 0; index < points.length; index++) {
      Offset firstPoint = points[index];
      Offset secondPoint = points[(index + 1) % points.length];
      Offset thirdPoint = points[(index + 2) % points.length];

      Offset firstEdge = secondPoint - firstPoint;
      Offset secondEdge = thirdPoint - secondPoint;

      double crossProduct =
          (firstEdge.dx * secondEdge.dy) - (firstEdge.dy * secondEdge.dx);

      if (crossProduct.abs() < 0.001) {
        continue;
      }

      double crossProductSign = crossProduct.sign;

      if (expectedCrossProductSign == null) {
        expectedCrossProductSign = crossProductSign;
        continue;
      }

      if (crossProductSign != expectedCrossProductSign) {
        return false;
      }
    }

    return expectedCrossProductSign != null;
  }

  /// Clears the active-corner highlight when the gesture finishes.
  void finishCornerDrag() {
    if (activeCorner == null) {
      return;
    }

    setState(() {
      activeCorner = null;
    });
  }

  /// Returns the current source-image position for [corner].
  Offset positionForCorner(KeyboardAreaCorner corner) {
    switch (corner) {
      case KeyboardAreaCorner.topLeft:
        return workingCorners.topLeft;
      case KeyboardAreaCorner.topRight:
        return workingCorners.topRight;
      case KeyboardAreaCorner.bottomRight:
        return workingCorners.bottomRight;
      case KeyboardAreaCorner.bottomLeft:
        return workingCorners.bottomLeft;
    }
  }

  /// Clamps a requested corner so opposite edges retain a usable separation.
  Offset constrainCornerPosition(
    KeyboardAreaCorner corner,
    Offset requestedPosition,
  ) {
    double imageWidth = workingCorners.sourceImageWidth.toDouble();
    double imageHeight = workingCorners.sourceImageHeight.toDouble();
    double minimumWidth = imageWidth * minimumAreaWidthFraction;
    double minimumHeight = imageHeight * minimumAreaHeightFraction;

    double constrainedX = requestedPosition.dx.clamp(0, imageWidth).toDouble();
    double constrainedY = requestedPosition.dy.clamp(0, imageHeight).toDouble();

    switch (corner) {
      case KeyboardAreaCorner.topLeft:
        constrainedX = constrainedX
            .clamp(0, workingCorners.topRight.dx - minimumWidth)
            .toDouble();
        constrainedY = constrainedY
            .clamp(0, workingCorners.bottomLeft.dy - minimumHeight)
            .toDouble();
        break;
      case KeyboardAreaCorner.topRight:
        constrainedX = constrainedX
            .clamp(workingCorners.topLeft.dx + minimumWidth, imageWidth)
            .toDouble();
        constrainedY = constrainedY
            .clamp(0, workingCorners.bottomRight.dy - minimumHeight)
            .toDouble();
        break;
      case KeyboardAreaCorner.bottomRight:
        constrainedX = constrainedX
            .clamp(workingCorners.bottomLeft.dx + minimumWidth, imageWidth)
            .toDouble();
        constrainedY = constrainedY
            .clamp(workingCorners.topRight.dy + minimumHeight, imageHeight)
            .toDouble();
        break;
      case KeyboardAreaCorner.bottomLeft:
        constrainedX = constrainedX
            .clamp(0, workingCorners.bottomRight.dx - minimumWidth)
            .toDouble();
        constrainedY = constrainedY
            .clamp(workingCorners.topLeft.dy + minimumHeight, imageHeight)
            .toDouble();
        break;
    }

    return Offset(constrainedX, constrainedY);
  }

  /// Returns a new corner model with exactly one point replaced.
  KeyboardAreaCorners replaceCorner(
    KeyboardAreaCorner corner,
    Offset newPosition,
  ) {
    Offset topLeft = workingCorners.topLeft;
    Offset topRight = workingCorners.topRight;
    Offset bottomRight = workingCorners.bottomRight;
    Offset bottomLeft = workingCorners.bottomLeft;

    switch (corner) {
      case KeyboardAreaCorner.topLeft:
        topLeft = newPosition;
        break;
      case KeyboardAreaCorner.topRight:
        topRight = newPosition;
        break;
      case KeyboardAreaCorner.bottomRight:
        bottomRight = newPosition;
        break;
      case KeyboardAreaCorner.bottomLeft:
        bottomLeft = newPosition;
        break;
    }

    return KeyboardAreaCorners(
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft,
      sourceImageWidth: workingCorners.sourceImageWidth,
      sourceImageHeight: workingCorners.sourceImageHeight,
    );
  }

  /// Accepts a reference-key tap only when it lies inside the keyboard polygon.
  void selectReferenceKey(Offset displayedPosition, Size previewSize) {
    if (previewSize.width <= 0 || previewSize.height <= 0) {
      return;
    }

    Offset sourcePosition = convertDisplayToSource(
      displayedPosition,
      previewSize,
    );

    Path keyboardPath = Path();
    keyboardPath.moveTo(workingCorners.topLeft.dx, workingCorners.topLeft.dy);
    keyboardPath.lineTo(workingCorners.topRight.dx, workingCorners.topRight.dy);
    keyboardPath.lineTo(
      workingCorners.bottomRight.dx,
      workingCorners.bottomRight.dy,
    );
    keyboardPath.lineTo(
      workingCorners.bottomLeft.dx,
      workingCorners.bottomLeft.dy,
    );
    keyboardPath.close();

    if (!keyboardPath.contains(sourcePosition)) {
      return;
    }

    widget.onReferenceSelected(sourcePosition);
  }

  /// Scales a source-image point into local preview coordinates.
  Offset convertSourceToDisplay(Offset sourcePosition, Size previewSize) {
    return Offset(
      sourcePosition.dx * previewSize.width / workingCorners.sourceImageWidth,
      sourcePosition.dy * previewSize.height / workingCorners.sourceImageHeight,
    );
  }

  /// Scales a local preview tap back into source-image coordinates.
  Offset convertDisplayToSource(Offset displayedPosition, Size previewSize) {
    return Offset(
      displayedPosition.dx *
          workingCorners.sourceImageWidth /
          previewSize.width,
      displayedPosition.dy *
          workingCorners.sourceImageHeight /
          previewSize.height,
    );
  }
}
