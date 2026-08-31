import 'dart:ui';

import '../models/black_key_candidate.dart';
import '../models/keyboard_area_corners.dart';
import '../models/normalized_keyboard_point.dart';
import '../models/piano_key_marker.dart';
import '../models/reference_key_marker.dart';
import 'keyboard_perspective_mapper.dart';

/// Refines natural-key centers from the observed black-key pattern.
///
/// Black keys define most boundaries between neighboring natural notes. Missing
/// E/F and B/C boundaries are interpolated, then all centers are aligned back
/// to the user-selected C4 reference.
class WhiteKeyCenterRefiner {
  final List<String> whiteKeyLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  final KeyboardPerspectiveMapper perspectiveMapper =
      KeyboardPerspectiveMapper();

  /// Replaces fallback centers with pattern-derived centers when validation passes.
  ///
  /// Any ambiguous octave assignment, non-increasing result, or excessive C4
  /// correction returns [fallbackMarkers] unchanged.
  List<PianoKeyMarker> refineCenters({
    required List<PianoKeyMarker> fallbackMarkers,
    required List<ReferenceKeyMarker> referenceCMarkers,
    required List<List<BlackKeyCandidate>> blackKeyGroups,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    if (fallbackMarkers.isEmpty ||
        referenceCMarkers.isEmpty ||
        blackKeyGroups.isEmpty) {
      return fallbackMarkers;
    }

    ReferenceKeyMarker? selectedC4 = findC4(referenceCMarkers);

    if (selectedC4 == null) {
      return fallbackMarkers;
    }

    List<List<BlackKeyCandidate>> orderedGroups = orderGroups(blackKeyGroups);

    Map<int, int> octaveByGroupIndex = assignOctavesToTwoKeyGroups(
      orderedGroups: orderedGroups,
      referenceCMarkers: referenceCMarkers,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    if (octaveByGroupIndex.isEmpty) {
      return fallbackMarkers;
    }

    Map<int, double> boundaryFractions = {};
    Map<int, double> estimatedCFractions = {};
    Set<int> detectedOctaves = {};

    for (int groupIndex = 0; groupIndex < orderedGroups.length; groupIndex++) {
      List<BlackKeyCandidate> group = orderedGroups[groupIndex];

      if (group.length == 2) {
        int? octaveNumber = octaveByGroupIndex[groupIndex];

        if (octaveNumber == null) {
          continue;
        }

        double cSharpFraction = horizontalFractionForCandidate(
          group[0],
          keyboardAreaCorners,
        );

        double dSharpFraction = horizontalFractionForCandidate(
          group[1],
          keyboardAreaCorners,
        );

        if (dSharpFraction <= cSharpFraction) {
          continue;
        }

        detectedOctaves.add(octaveNumber);

        boundaryFractions[whiteKeyNumber('C', octaveNumber)] = cSharpFraction;

        boundaryFractions[whiteKeyNumber('D', octaveNumber)] = dSharpFraction;

        estimatedCFractions[octaveNumber] =
            cSharpFraction - ((dSharpFraction - cSharpFraction) / 2);

        continue;
      }

      if (group.length != 3) {
        continue;
      }

      int? octaveNumber = octaveForThreeKeyGroup(
        groupIndex: groupIndex,
        orderedGroups: orderedGroups,
        octaveByGroupIndex: octaveByGroupIndex,
      );

      if (octaveNumber == null) {
        continue;
      }

      double fSharpFraction = horizontalFractionForCandidate(
        group[0],
        keyboardAreaCorners,
      );

      double gSharpFraction = horizontalFractionForCandidate(
        group[1],
        keyboardAreaCorners,
      );

      double aSharpFraction = horizontalFractionForCandidate(
        group[2],
        keyboardAreaCorners,
      );

      if (gSharpFraction <= fSharpFraction ||
          aSharpFraction <= gSharpFraction) {
        continue;
      }

      detectedOctaves.add(octaveNumber);

      boundaryFractions[whiteKeyNumber('F', octaveNumber)] = fSharpFraction;

      boundaryFractions[whiteKeyNumber('G', octaveNumber)] = gSharpFraction;

      boundaryFractions[whiteKeyNumber('A', octaveNumber)] = aSharpFraction;
    }

    addMissingNaturalBoundaries(
      boundaryFractions: boundaryFractions,
      detectedOctaves: detectedOctaves,
    );

    Map<int, double> centerFractions = calculateDetectedCenters(
      boundaryFractions,
    );

    if (centerFractions.length < 4) {
      return fallbackMarkers;
    }

    double? alignmentOffset = calculateAlignmentOffset(
      centerFractions: centerFractions,
      estimatedCFractions: estimatedCFractions,
      referenceCMarkers: referenceCMarkers,
      selectedC4: selectedC4,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    if (alignmentOffset == null) {
      return fallbackMarkers;
    }

    Map<int, double> alignedCenterFractions = {};

    centerFractions.forEach((keyNumber, centerFraction) {
      alignedCenterFractions[keyNumber] = centerFraction + alignmentOffset;
    });

    if (!centersIncreaseFromLeftToRight(alignedCenterFractions)) {
      return fallbackMarkers;
    }

    double typicalWhiteKeyStep = calculateTypicalWhiteKeyStep(
      alignedCenterFractions,
    );

    if (typicalWhiteKeyStep <= 0) {
      return fallbackMarkers;
    }

    return refineFallbackMarkers(
      fallbackMarkers: fallbackMarkers,
      centerFractions: alignedCenterFractions,
      selectedC4: selectedC4,
      keyboardAreaCorners: keyboardAreaCorners,
      typicalWhiteKeyStep: typicalWhiteKeyStep,
    );
  }

  /// Finds the user-anchored C4 reference marker.
  ReferenceKeyMarker? findC4(List<ReferenceKeyMarker> referenceCMarkers) {
    for (ReferenceKeyMarker marker in referenceCMarkers) {
      if (marker.octaveNumber == 4) {
        return marker;
      }
    }

    return null;
  }

  /// Copies and sorts every black-key group and then orders the groups globally.
  List<List<BlackKeyCandidate>> orderGroups(
    List<List<BlackKeyCandidate>> blackKeyGroups,
  ) {
    List<List<BlackKeyCandidate>> orderedGroups = [];

    for (List<BlackKeyCandidate> group in blackKeyGroups) {
      List<BlackKeyCandidate> orderedGroup = List<BlackKeyCandidate>.from(
        group,
      );

      orderedGroup.sort((first, second) {
        return first.left.compareTo(second.left);
      });

      orderedGroups.add(orderedGroup);
    }

    orderedGroups.sort((first, second) {
      return first.first.left.compareTo(second.first.left);
    });

    return orderedGroups;
  }

  /// Anchors each C#/D# group to its closest visible reference C octave.
  Map<int, int> assignOctavesToTwoKeyGroups({
    required List<List<BlackKeyCandidate>> orderedGroups,
    required List<ReferenceKeyMarker> referenceCMarkers,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    Map<int, int> octaveByGroupIndex = {};

    for (int groupIndex = 0; groupIndex < orderedGroups.length; groupIndex++) {
      List<BlackKeyCandidate> group = orderedGroups[groupIndex];

      if (group.length != 2) {
        continue;
      }

      double firstFraction = horizontalFractionForCandidate(
        group[0],
        keyboardAreaCorners,
      );

      double secondFraction = horizontalFractionForCandidate(
        group[1],
        keyboardAreaCorners,
      );

      if (secondFraction <= firstFraction) {
        continue;
      }

      double estimatedCFraction =
          firstFraction - ((secondFraction - firstFraction) / 2);

      ReferenceKeyMarker? closestReference = findClosestReferenceC(
        estimatedCFraction: estimatedCFraction,
        referenceCMarkers: referenceCMarkers,
        keyboardAreaCorners: keyboardAreaCorners,
      );

      if (closestReference != null) {
        octaveByGroupIndex[groupIndex] = closestReference.octaveNumber;
      }
    }

    return octaveByGroupIndex;
  }

  /// Finds the reference C closest to an estimated C-key fraction.
  ReferenceKeyMarker? findClosestReferenceC({
    required double estimatedCFraction,
    required List<ReferenceKeyMarker> referenceCMarkers,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    ReferenceKeyMarker? closestReference;
    double? closestDistance;

    for (ReferenceKeyMarker marker in referenceCMarkers) {
      double markerFraction = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: marker.position,
            corners: keyboardAreaCorners,
          )
          .horizontalFraction;

      double distance = (markerFraction - estimatedCFraction).abs();

      if (closestDistance == null || distance < closestDistance) {
        closestReference = marker;
        closestDistance = distance;
      }
    }

    return closestReference;
  }

  /// Gets an F#/G#/A# group's octave from its adjacent C#/D# group.
  int? octaveForThreeKeyGroup({
    required int groupIndex,
    required List<List<BlackKeyCandidate>> orderedGroups,
    required Map<int, int> octaveByGroupIndex,
  }) {
    int previousIndex = groupIndex - 1;

    if (previousIndex >= 0 && orderedGroups[previousIndex].length == 2) {
      return octaveByGroupIndex[previousIndex];
    }

    int nextIndex = groupIndex + 1;

    if (nextIndex < orderedGroups.length &&
        orderedGroups[nextIndex].length == 2) {
      int? nextOctave = octaveByGroupIndex[nextIndex];

      if (nextOctave != null) {
        return nextOctave - 1;
      }
    }

    return null;
  }

  /// Interpolates the E/F and B/C boundaries that have no black key between them.
  void addMissingNaturalBoundaries({
    required Map<int, double> boundaryFractions,
    required Set<int> detectedOctaves,
  }) {
    for (int octaveNumber in detectedOctaves) {
      int afterD = whiteKeyNumber('D', octaveNumber);
      int afterE = whiteKeyNumber('E', octaveNumber);
      int afterF = whiteKeyNumber('F', octaveNumber);

      double? dSharpFraction = boundaryFractions[afterD];
      double? fSharpFraction = boundaryFractions[afterF];

      if (dSharpFraction != null && fSharpFraction != null) {
        boundaryFractions[afterE] = (dSharpFraction + fSharpFraction) / 2;
      }

      int afterA = whiteKeyNumber('A', octaveNumber);
      int afterB = whiteKeyNumber('B', octaveNumber);
      int nextC = whiteKeyNumber('C', octaveNumber + 1);

      double? aSharpFraction = boundaryFractions[afterA];
      double? nextCSharpFraction = boundaryFractions[nextC];

      if (aSharpFraction != null && nextCSharpFraction != null) {
        boundaryFractions[afterB] = (aSharpFraction + nextCSharpFraction) / 2;
      }
    }
  }

  /// Calculates natural-key centers from neighboring boundary fractions.
  Map<int, double> calculateDetectedCenters(
    Map<int, double> boundaryFractions,
  ) {
    Map<int, double> centerFractions = {};

    for (int rightBoundaryKey in boundaryFractions.keys) {
      int leftBoundaryKey = rightBoundaryKey - 1;

      double? leftBoundary = boundaryFractions[leftBoundaryKey];
      double? rightBoundary = boundaryFractions[rightBoundaryKey];

      if (leftBoundary == null || rightBoundary == null) {
        continue;
      }

      if (rightBoundary <= leftBoundary) {
        continue;
      }

      centerFractions[rightBoundaryKey] = (leftBoundary + rightBoundary) / 2;
    }

    return centerFractions;
  }

  /// Computes a shared horizontal correction that keeps detected C4 on its anchor.
  double? calculateAlignmentOffset({
    required Map<int, double> centerFractions,
    required Map<int, double> estimatedCFractions,
    required List<ReferenceKeyMarker> referenceCMarkers,
    required ReferenceKeyMarker selectedC4,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    double selectedC4Fraction = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: selectedC4.position,
          corners: keyboardAreaCorners,
        )
        .horizontalFraction;

    double? detectedC4Center = centerFractions[whiteKeyNumber('C', 4)];

    if (detectedC4Center != null) {
      return selectedC4Fraction - detectedC4Center;
    }

    double? estimatedC4Center = estimatedCFractions[4];

    if (estimatedC4Center != null) {
      return selectedC4Fraction - estimatedC4Center;
    }

    ReferenceKeyMarker? nearestUsableReference;
    double? nearestOctaveDistance;

    for (ReferenceKeyMarker marker in referenceCMarkers) {
      if (!estimatedCFractions.containsKey(marker.octaveNumber)) {
        continue;
      }

      double octaveDistance = (marker.octaveNumber - 4).abs().toDouble();

      if (nearestOctaveDistance == null ||
          octaveDistance < nearestOctaveDistance) {
        nearestUsableReference = marker;
        nearestOctaveDistance = octaveDistance;
      }
    }

    if (nearestUsableReference == null) {
      return null;
    }

    double referenceFraction = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: nearestUsableReference.position,
          corners: keyboardAreaCorners,
        )
        .horizontalFraction;

    double estimatedFraction =
        estimatedCFractions[nearestUsableReference.octaveNumber]!;

    return referenceFraction - estimatedFraction;
  }

  /// Validates that chromatically ordered natural keys move left to right.
  bool centersIncreaseFromLeftToRight(Map<int, double> centerFractions) {
    List<int> orderedKeyNumbers = centerFractions.keys.toList();
    orderedKeyNumbers.sort();

    double? previousFraction;

    for (int keyNumber in orderedKeyNumbers) {
      double currentFraction = centerFractions[keyNumber]!;

      if (previousFraction != null && currentFraction <= previousFraction) {
        return false;
      }

      previousFraction = currentFraction;
    }

    return true;
  }

  /// Returns the median per-key spacing, accounting for gaps in detected keys.
  double calculateTypicalWhiteKeyStep(Map<int, double> centerFractions) {
    List<int> orderedKeyNumbers = centerFractions.keys.toList();
    orderedKeyNumbers.sort();

    List<double> steps = [];

    for (int index = 1; index < orderedKeyNumbers.length; index++) {
      int previousKey = orderedKeyNumbers[index - 1];
      int currentKey = orderedKeyNumbers[index];

      int keyCount = currentKey - previousKey;

      if (keyCount <= 0) {
        continue;
      }

      double distance =
          centerFractions[currentKey]! - centerFractions[previousKey]!;

      if (distance > 0) {
        steps.add(distance / keyCount);
      }
    }

    if (steps.isEmpty) {
      return 0;
    }

    steps.sort();

    int middleIndex = steps.length ~/ 2;

    if (steps.length.isOdd) {
      return steps[middleIndex];
    }

    return (steps[middleIndex - 1] + steps[middleIndex]) / 2;
  }

  /// Applies detected/interpolated centers while limiting movement from fallback.
  List<PianoKeyMarker> refineFallbackMarkers({
    required List<PianoKeyMarker> fallbackMarkers,
    required Map<int, double> centerFractions,
    required ReferenceKeyMarker selectedC4,
    required KeyboardAreaCorners keyboardAreaCorners,
    required double typicalWhiteKeyStep,
  }) {
    List<PianoKeyMarker> refinedMarkers = [];
    double maximumAdjustment = typicalWhiteKeyStep * 0.75;

    for (PianoKeyMarker marker in fallbackMarkers) {
      if (marker.noteLetter == 'C' && marker.octaveNumber == 4) {
        refinedMarkers.add(
          PianoKeyMarker(
            noteLetter: marker.noteLetter,
            octaveNumber: marker.octaveNumber,
            position: selectedC4.position,
          ),
        );

        continue;
      }

      int keyNumber = whiteKeyNumber(marker.noteLetter, marker.octaveNumber);

      double? refinedFraction = interpolateCenterFraction(
        keyNumber: keyNumber,
        centerFractions: centerFractions,
      );

      if (refinedFraction == null) {
        refinedMarkers.add(marker);
        continue;
      }

      NormalizedKeyboardPoint fallbackPosition = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: marker.position,
            corners: keyboardAreaCorners,
          );

      double adjustment =
          (refinedFraction - fallbackPosition.horizontalFraction).abs();

      if (adjustment > maximumAdjustment) {
        refinedMarkers.add(marker);
        continue;
      }

      double safeHorizontalFraction = refinedFraction
          .clamp(0.0, 1.0)
          .toDouble();

      Offset refinedPosition = perspectiveMapper.toSourcePosition(
        normalizedPosition: NormalizedKeyboardPoint(
          horizontalFraction: safeHorizontalFraction,
          verticalFraction: fallbackPosition.verticalFraction,
        ),
        corners: keyboardAreaCorners,
      );

      refinedMarkers.add(
        PianoKeyMarker(
          noteLetter: marker.noteLetter,
          octaveNumber: marker.octaveNumber,
          position: refinedPosition,
        ),
      );
    }

    return refinedMarkers;
  }

  /// Finds, interpolates, or edge-extrapolates a center for [keyNumber].
  double? interpolateCenterFraction({
    required int keyNumber,
    required Map<int, double> centerFractions,
  }) {
    double? exactCenter = centerFractions[keyNumber];

    if (exactCenter != null) {
      return exactCenter;
    }

    List<int> orderedKeys = centerFractions.keys.toList();
    orderedKeys.sort();

    int? lowerKey;
    int? upperKey;

    for (int knownKey in orderedKeys) {
      if (knownKey < keyNumber) {
        lowerKey = knownKey;
        continue;
      }

      if (knownKey > keyNumber) {
        upperKey = knownKey;
        break;
      }
    }

    if (lowerKey != null && upperKey != null) {
      return interpolateBetweenKnownCenters(
        keyNumber: keyNumber,
        firstKey: lowerKey,
        secondKey: upperKey,
        centerFractions: centerFractions,
      );
    }

    if (lowerKey == null && orderedKeys.length >= 2) {
      return interpolateBetweenKnownCenters(
        keyNumber: keyNumber,
        firstKey: orderedKeys[0],
        secondKey: orderedKeys[1],
        centerFractions: centerFractions,
      );
    }

    if (upperKey == null && orderedKeys.length >= 2) {
      int lastIndex = orderedKeys.length - 1;

      return interpolateBetweenKnownCenters(
        keyNumber: keyNumber,
        firstKey: orderedKeys[lastIndex - 1],
        secondKey: orderedKeys[lastIndex],
        centerFractions: centerFractions,
      );
    }

    return null;
  }

  /// Linearly interpolates a center between two known numbered natural keys.
  double interpolateBetweenKnownCenters({
    required int keyNumber,
    required int firstKey,
    required int secondKey,
    required Map<int, double> centerFractions,
  }) {
    double firstCenter = centerFractions[firstKey]!;
    double secondCenter = centerFractions[secondKey]!;

    double keyFraction = (keyNumber - firstKey) / (secondKey - firstKey);

    return firstCenter + ((secondCenter - firstCenter) * keyFraction);
  }

  /// Converts a natural note and octave into a continuous sortable key number.
  int whiteKeyNumber(String noteLetter, int octaveNumber) {
    int letterIndex = whiteKeyLetters.indexOf(noteLetter);

    return (octaveNumber * whiteKeyLetters.length) + letterIndex;
  }

  /// Returns a black candidate's perspective-corrected horizontal fraction.
  double horizontalFractionForCandidate(
    BlackKeyCandidate candidate,
    KeyboardAreaCorners keyboardAreaCorners,
  ) {
    Offset center = Offset(
      candidate.left + (candidate.width / 2),
      candidate.top + (candidate.height / 2),
    );

    return perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: center,
          corners: keyboardAreaCorners,
        )
        .horizontalFraction;
  }
}
