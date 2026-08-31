import 'dart:ui';

import '../models/black_key_candidate.dart';
import '../models/keyboard_area_corners.dart';
import '../models/normalized_keyboard_point.dart';
import '../models/reference_key_marker.dart';
import 'keyboard_perspective_mapper.dart';

/// Expands the user-selected C4 into visible reference C markers by octave.
class ReferenceKeyDeriver {
  final KeyboardPerspectiveMapper perspectiveMapper =
      KeyboardPerspectiveMapper();

  /// Locates C positions from each two-black-key group and anchors them to C4.
  ///
  /// Applying the user's tap offset to all detected Cs corrects a systematic
  /// horizontal error without losing the measured perspective.
  List<ReferenceKeyMarker> deriveVisibleCs({
    required Offset selectedC4Position,
    required List<List<BlackKeyCandidate>> blackKeyGroups,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    List<double> detectedCFractions = [];
    List<double> whiteKeyFractions = [];

    for (List<BlackKeyCandidate> group in blackKeyGroups) {
      if (group.length != 2) {
        continue;
      }

      List<BlackKeyCandidate> orderedGroup = List<BlackKeyCandidate>.from(
        group,
      );

      orderedGroup.sort((first, second) {
        return first.left.compareTo(second.left);
      });

      NormalizedKeyboardPoint firstBlackKey = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: candidateCenter(orderedGroup[0]),
            corners: keyboardAreaCorners,
          );

      NormalizedKeyboardPoint secondBlackKey = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: candidateCenter(orderedGroup[1]),
            corners: keyboardAreaCorners,
          );

      double whiteKeyFraction =
          secondBlackKey.horizontalFraction - firstBlackKey.horizontalFraction;

      if (whiteKeyFraction <= 0) {
        continue;
      }

      double detectedCFraction =
          firstBlackKey.horizontalFraction - (whiteKeyFraction / 2);

      detectedCFractions.add(detectedCFraction);
      whiteKeyFractions.add(whiteKeyFraction);
    }

    NormalizedKeyboardPoint selectedC4 = perspectiveMapper.toNormalizedPosition(
      sourcePosition: selectedC4Position,
      corners: keyboardAreaCorners,
    );

    if (detectedCFractions.isEmpty) {
      return [
        ReferenceKeyMarker(octaveNumber: 4, position: selectedC4Position),
      ];
    }

    detectedCFractions.sort();

    List<double> visibleCFractions = addPossibleEdgeCs(
      detectedCFractions: detectedCFractions,
      whiteKeyFractions: whiteKeyFractions,
    );

    int selectedCIndex = findClosestCIndex(
      selectedC4.horizontalFraction,
      visibleCFractions,
    );

    double userTapOffset =
        selectedC4.horizontalFraction - visibleCFractions[selectedCIndex];

    List<ReferenceKeyMarker> markers = [];

    for (int index = 0; index < visibleCFractions.length; index++) {
      double adjustedFraction = visibleCFractions[index] + userTapOffset;

      if (adjustedFraction < 0 || adjustedFraction > 1) {
        continue;
      }

      int octaveNumber = 4 + (index - selectedCIndex);

      Offset sourcePosition;

      if (index == selectedCIndex) {
        sourcePosition = selectedC4Position;
      } else {
        sourcePosition = perspectiveMapper.toSourcePosition(
          normalizedPosition: NormalizedKeyboardPoint(
            horizontalFraction: adjustedFraction,
            verticalFraction: selectedC4.verticalFraction,
          ),
          corners: keyboardAreaCorners,
        );
      }

      markers.add(
        ReferenceKeyMarker(
          octaveNumber: octaveNumber,
          position: sourcePosition,
        ),
      );
    }

    return List<ReferenceKeyMarker>.unmodifiable(markers);
  }

  /// Extrapolates one possible C beyond each detected edge octave.
  List<double> addPossibleEdgeCs({
    required List<double> detectedCFractions,
    required List<double> whiteKeyFractions,
  }) {
    List<double> visibleCFractions = List<double>.from(detectedCFractions);

    double fallbackOctaveWidth = calculateMedian(whiteKeyFractions) * 7;

    double leftOctaveWidth = fallbackOctaveWidth;
    double rightOctaveWidth = fallbackOctaveWidth;

    if (detectedCFractions.length >= 2) {
      leftOctaveWidth = detectedCFractions[1] - detectedCFractions[0];

      int lastIndex = detectedCFractions.length - 1;

      rightOctaveWidth =
          detectedCFractions[lastIndex] - detectedCFractions[lastIndex - 1];
    }

    visibleCFractions.insert(0, detectedCFractions.first - leftOctaveWidth);

    visibleCFractions.add(detectedCFractions.last + rightOctaveWidth);

    return visibleCFractions;
  }

  /// Returns the center of a black-key candidate rectangle.
  Offset candidateCenter(BlackKeyCandidate candidate) {
    return Offset(
      candidate.left + (candidate.width / 2),
      candidate.top + (candidate.height / 2),
    );
  }

  /// Finds which detected C fraction is closest to the user's C4 tap.
  int findClosestCIndex(
    double selectedHorizontalFraction,
    List<double> detectedCFractions,
  ) {
    int closestIndex = 0;
    double closestDistance =
        (selectedHorizontalFraction - detectedCFractions.first).abs();

    for (int index = 1; index < detectedCFractions.length; index++) {
      double distance = (selectedHorizontalFraction - detectedCFractions[index])
          .abs();

      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = index;
      }
    }

    return closestIndex;
  }

  /// Returns the median value used for robust octave-width estimation.
  double calculateMedian(List<double> values) {
    List<double> sortedValues = List<double>.from(values);
    sortedValues.sort();

    int middleIndex = sortedValues.length ~/ 2;

    if (sortedValues.length.isOdd) {
      return sortedValues[middleIndex];
    }

    return (sortedValues[middleIndex - 1] + sortedValues[middleIndex]) / 2;
  }
}
