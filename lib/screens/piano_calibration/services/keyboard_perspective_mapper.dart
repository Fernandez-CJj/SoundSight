import 'dart:math' as math;
import 'dart:ui';

import '../models/keyboard_area_corners.dart';
import '../models/normalized_keyboard_point.dart';

/// Maps points between the skewed camera quadrilateral and keyboard fractions.
class KeyboardPerspectiveMapper {
  /// Bilinearly maps a normalized keyboard coordinate into source-image space.
  Offset toSourcePosition({
    required NormalizedKeyboardPoint normalizedPosition,
    required KeyboardAreaCorners corners,
  }) {
    double horizontalFraction = normalizedPosition.horizontalFraction;

    double verticalFraction = normalizedPosition.verticalFraction;

    Offset topPosition = Offset.lerp(
      corners.topLeft,
      corners.topRight,
      horizontalFraction,
    )!;

    Offset bottomPosition = Offset.lerp(
      corners.bottomLeft,
      corners.bottomRight,
      horizontalFraction,
    )!;

    return Offset.lerp(topPosition, bottomPosition, verticalFraction)!;
  }

  /// Estimates the normalized keyboard coordinate for a source-image point.
  ///
  /// An iterative inverse of the bilinear mapping corrects for trapezoidal
  /// perspective instead of assuming the playable area is axis-aligned.
  NormalizedKeyboardPoint toNormalizedPosition({
    required Offset sourcePosition,
    required KeyboardAreaCorners corners,
  }) {
    List<double> horizontalValues = [
      corners.topLeft.dx,
      corners.topRight.dx,
      corners.bottomRight.dx,
      corners.bottomLeft.dx,
    ];

    List<double> verticalValues = [
      corners.topLeft.dy,
      corners.topRight.dy,
      corners.bottomRight.dy,
      corners.bottomLeft.dy,
    ];

    double minimumX = horizontalValues.reduce(math.min);
    double maximumX = horizontalValues.reduce(math.max);
    double minimumY = verticalValues.reduce(math.min);
    double maximumY = verticalValues.reduce(math.max);

    // Start with a bounding-box estimate, then iteratively remove its error.
    double horizontalFraction =
        ((sourcePosition.dx - minimumX) / (maximumX - minimumX))
            .clamp(0.0, 1.0)
            .toDouble();

    double verticalFraction =
        ((sourcePosition.dy - minimumY) / (maximumY - minimumY))
            .clamp(0.0, 1.0)
            .toDouble();

    for (int iteration = 0; iteration < 10; iteration++) {
      NormalizedKeyboardPoint currentGuess = NormalizedKeyboardPoint(
        horizontalFraction: horizontalFraction,
        verticalFraction: verticalFraction,
      );

      Offset calculatedPosition = toSourcePosition(
        normalizedPosition: currentGuess,
        corners: corners,
      );

      Offset error = sourcePosition - calculatedPosition;

      if (error.distance < 0.01) {
        break;
      }

      Offset topDirection = corners.topRight - corners.topLeft;

      Offset bottomDirection = corners.bottomRight - corners.bottomLeft;

      Offset horizontalDirection = Offset.lerp(
        topDirection,
        bottomDirection,
        verticalFraction,
      )!;

      Offset leftDirection = corners.bottomLeft - corners.topLeft;

      Offset rightDirection = corners.bottomRight - corners.topRight;

      Offset verticalDirection = Offset.lerp(
        leftDirection,
        rightDirection,
        horizontalFraction,
      )!;

      double determinant =
          (horizontalDirection.dx * verticalDirection.dy) -
          (horizontalDirection.dy * verticalDirection.dx);

      if (determinant.abs() < 0.000001) {
        break;
      }

      double horizontalCorrection =
          ((error.dx * verticalDirection.dy) -
              (error.dy * verticalDirection.dx)) /
          determinant;

      double verticalCorrection =
          ((horizontalDirection.dx * error.dy) -
              (horizontalDirection.dy * error.dx)) /
          determinant;

      horizontalFraction = (horizontalFraction + horizontalCorrection)
          .clamp(0.0, 1.0)
          .toDouble();

      verticalFraction = (verticalFraction + verticalCorrection)
          .clamp(0.0, 1.0)
          .toDouble();
    }

    return NormalizedKeyboardPoint(
      horizontalFraction: horizontalFraction,
      verticalFraction: verticalFraction,
    );
  }
}
