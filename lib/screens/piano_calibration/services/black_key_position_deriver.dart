import 'dart:ui';

import '../models/black_key_candidate.dart';
import '../models/black_key_derivation_result.dart';
import '../models/black_key_geometry.dart';
import '../models/calibration_frame.dart';
import '../models/keyboard_area_corners.dart';
import '../models/piano_key_marker.dart';
import '../models/piano_key_region.dart';
import 'black_key_bottom_detector.dart';
import 'keyboard_perspective_mapper.dart';

/// Labels black-key candidates and derives marker/outlines for the overlay.
class BlackKeyPositionDeriver {
  final KeyboardPerspectiveMapper perspectiveMapper =
      KeyboardPerspectiveMapper();

  final BlackKeyBottomDetector bottomDetector = BlackKeyBottomDetector();

  final List<String> twoKeyNoteLetters = ['C\u266f', 'D\u266f'];

  final List<String> threeKeyNoteLetters = ['F\u266f', 'G\u266f', 'A\u266f'];

  /// Assigns sharp note names from 2/3 groups and derives visible geometry.
  ///
  /// Two-key groups are anchored to nearby labeled C keys. Three-key groups
  /// inherit the adjacent octave. Candidates without both surrounding white
  /// keys are excluded so partially visible edge keys are not mislabeled.
  BlackKeyDerivationResult deriveBlackKeys({
    required List<List<BlackKeyCandidate>> blackKeyGroups,
    required List<PianoKeyMarker> whiteKeyMarkers,
    required KeyboardAreaCorners keyboardAreaCorners,
    CalibrationFrame? calibrationFrame,
  }) {
    if (blackKeyGroups.isEmpty || whiteKeyMarkers.isEmpty) {
      return const BlackKeyDerivationResult(
        markers: <PianoKeyMarker>[],
        regions: <PianoKeyRegion>[],
      );
    }

    List<List<BlackKeyCandidate>> orderedGroups = orderGroups(blackKeyGroups);
    List<BlackKeyCandidate> orderedCandidates = [
      for (List<BlackKeyCandidate> group in orderedGroups) ...group,
    ];

    Map<int, int> octaveByTwoKeyGroup = assignOctavesToTwoKeyGroups(
      orderedGroups: orderedGroups,
      whiteKeyMarkers: whiteKeyMarkers,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    List<PianoKeyMarker> blackKeyMarkers = [];
    List<PianoKeyRegion> blackKeyRegions = [];

    for (int groupIndex = 0; groupIndex < orderedGroups.length; groupIndex++) {
      List<BlackKeyCandidate> group = orderedGroups[groupIndex];

      int? octaveNumber;
      List<String> noteLetters;

      if (group.length == 2) {
        octaveNumber = octaveByTwoKeyGroup[groupIndex];
        noteLetters = twoKeyNoteLetters;
      } else if (group.length == 3) {
        octaveNumber = octaveForThreeKeyGroup(
          groupIndex: groupIndex,
          orderedGroups: orderedGroups,
          octaveByTwoKeyGroup: octaveByTwoKeyGroup,
        );

        noteLetters = threeKeyNoteLetters;
      } else {
        continue;
      }

      if (octaveNumber == null) {
        continue;
      }

      for (int keyIndex = 0; keyIndex < group.length; keyIndex++) {
        String noteLetter = noteLetters[keyIndex];

        if (!surroundingWhiteKeysAreVisible(
          noteLetter: noteLetter,
          octaveNumber: octaveNumber,
          whiteKeyMarkers: whiteKeyMarkers,
        )) {
          continue;
        }

        BlackKeyCandidate candidate = group[keyIndex];
        int candidateIndex = orderedCandidates.indexOf(candidate);
        BlackKeyCandidate? previousCandidate = candidateIndex > 0
            ? orderedCandidates[candidateIndex - 1]
            : null;
        BlackKeyCandidate? nextCandidate =
            candidateIndex >= 0 && candidateIndex < orderedCandidates.length - 1
            ? orderedCandidates[candidateIndex + 1]
            : null;
        Offset fallbackPosition = candidateCenter(candidate);
        Offset position = fallbackPosition;
        BlackKeyGeometry? geometry;

        if (calibrationFrame != null) {
          geometry = bottomDetector.findGeometry(
            candidate: candidate,
            previousCandidate: previousCandidate,
            nextCandidate: nextCandidate,
            calibrationFrame: calibrationFrame,
            keyboardAreaCorners: keyboardAreaCorners,
          );

          position = geometry?.markerPosition ?? fallbackPosition;
        }

        if (!isInsideKeyboardArea(
          position: position,
          keyboardAreaCorners: keyboardAreaCorners,
        )) {
          continue;
        }

        blackKeyMarkers.add(
          PianoKeyMarker(
            noteLetter: noteLetter,
            octaveNumber: octaveNumber,
            position: position,
            isBlackKey: true,
          ),
        );

        if (geometry != null && geometry.outlinePoints.length == 4) {
          blackKeyRegions.add(
            PianoKeyRegion(
              noteLetter: noteLetter,
              octaveNumber: octaveNumber,
              isBlackKey: true,
              outlinePoints: geometry.outlinePoints,
            ),
          );
        }
      }
    }

    blackKeyMarkers.sort((first, second) {
      return first.position.dx.compareTo(second.position.dx);
    });

    return BlackKeyDerivationResult(
      markers: List<PianoKeyMarker>.unmodifiable(blackKeyMarkers),
      regions: List<PianoKeyRegion>.unmodifiable(blackKeyRegions),
    );
  }

  /// Returns non-empty groups and their candidates sorted from left to right.
  List<List<BlackKeyCandidate>> orderGroups(
    List<List<BlackKeyCandidate>> blackKeyGroups,
  ) {
    List<List<BlackKeyCandidate>> orderedGroups = [];

    for (List<BlackKeyCandidate> group in blackKeyGroups) {
      if (group.isEmpty) {
        continue;
      }

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

  /// Maps each two-key group to the octave of its closest derived white C.
  Map<int, int> assignOctavesToTwoKeyGroups({
    required List<List<BlackKeyCandidate>> orderedGroups,
    required List<PianoKeyMarker> whiteKeyMarkers,
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

      PianoKeyMarker? closestC = findClosestWhiteC(
        estimatedCFraction: estimatedCFraction,
        whiteKeyMarkers: whiteKeyMarkers,
        keyboardAreaCorners: keyboardAreaCorners,
      );

      if (closestC != null) {
        octaveByGroupIndex[groupIndex] = closestC.octaveNumber;
      }
    }

    return octaveByGroupIndex;
  }

  /// Finds the labeled C nearest an estimated C fraction from a black-key pair.
  PianoKeyMarker? findClosestWhiteC({
    required double estimatedCFraction,
    required List<PianoKeyMarker> whiteKeyMarkers,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    PianoKeyMarker? closestC;
    double? closestDistance;

    for (PianoKeyMarker marker in whiteKeyMarkers) {
      if (!marker.isC) {
        continue;
      }

      double markerFraction = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: marker.position,
            corners: keyboardAreaCorners,
          )
          .horizontalFraction;

      double distance = (markerFraction - estimatedCFraction).abs();

      if (closestDistance == null || distance < closestDistance) {
        closestC = marker;
        closestDistance = distance;
      }
    }

    return closestC;
  }

  /// Infers a three-key group's octave from a neighboring two-key group.
  int? octaveForThreeKeyGroup({
    required int groupIndex,
    required List<List<BlackKeyCandidate>> orderedGroups,
    required Map<int, int> octaveByTwoKeyGroup,
  }) {
    int previousIndex = groupIndex - 1;

    if (previousIndex >= 0 && orderedGroups[previousIndex].length == 2) {
      return octaveByTwoKeyGroup[previousIndex];
    }

    int nextIndex = groupIndex + 1;

    if (nextIndex < orderedGroups.length &&
        orderedGroups[nextIndex].length == 2) {
      int? nextOctave = octaveByTwoKeyGroup[nextIndex];

      if (nextOctave != null) {
        return nextOctave - 1;
      }
    }

    return null;
  }

  /// Ensures both natural keys surrounding a sharp have visible markers.
  bool surroundingWhiteKeysAreVisible({
    required String noteLetter,
    required int octaveNumber,
    required List<PianoKeyMarker> whiteKeyMarkers,
  }) {
    List<String>? surroundingLetters = surroundingWhiteLetters(noteLetter);

    if (surroundingLetters == null) {
      return false;
    }

    return findWhiteKey(
              noteLetter: surroundingLetters[0],
              octaveNumber: octaveNumber,
              whiteKeyMarkers: whiteKeyMarkers,
            ) !=
            null &&
        findWhiteKey(
              noteLetter: surroundingLetters[1],
              octaveNumber: octaveNumber,
              whiteKeyMarkers: whiteKeyMarkers,
            ) !=
            null;
  }

  /// Returns the natural-key letters immediately beside a supported sharp.
  List<String>? surroundingWhiteLetters(String noteLetter) {
    switch (noteLetter) {
      case 'C\u266f':
        return const ['C', 'D'];
      case 'D\u266f':
        return const ['D', 'E'];
      case 'F\u266f':
        return const ['F', 'G'];
      case 'G\u266f':
        return const ['G', 'A'];
      case 'A\u266f':
        return const ['A', 'B'];
      default:
        return null;
    }
  }

  /// Looks up one natural key by letter and octave.
  PianoKeyMarker? findWhiteKey({
    required String noteLetter,
    required int octaveNumber,
    required List<PianoKeyMarker> whiteKeyMarkers,
  }) {
    for (PianoKeyMarker marker in whiteKeyMarkers) {
      if (!marker.isBlackKey &&
          marker.noteLetter == noteLetter &&
          marker.octaveNumber == octaveNumber) {
        return marker;
      }
    }

    return null;
  }

  /// Tests whether a detected marker lies inside the playable quadrilateral.
  bool isInsideKeyboardArea({
    required Offset position,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    Path keyboardPath = Path();

    keyboardPath.moveTo(
      keyboardAreaCorners.topLeft.dx,
      keyboardAreaCorners.topLeft.dy,
    );

    keyboardPath.lineTo(
      keyboardAreaCorners.topRight.dx,
      keyboardAreaCorners.topRight.dy,
    );

    keyboardPath.lineTo(
      keyboardAreaCorners.bottomRight.dx,
      keyboardAreaCorners.bottomRight.dy,
    );

    keyboardPath.lineTo(
      keyboardAreaCorners.bottomLeft.dx,
      keyboardAreaCorners.bottomLeft.dy,
    );

    keyboardPath.close();

    return keyboardPath.contains(position);
  }

  /// Returns the center point of a candidate's contour bounds.
  Offset candidateCenter(BlackKeyCandidate candidate) {
    return Offset(
      candidate.left + (candidate.width / 2),
      candidate.top + (candidate.height / 2),
    );
  }

  /// Converts a candidate center into a perspective-corrected horizontal fraction.
  double horizontalFractionForCandidate(
    BlackKeyCandidate candidate,
    KeyboardAreaCorners keyboardAreaCorners,
  ) {
    return perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: candidateCenter(candidate),
          corners: keyboardAreaCorners,
        )
        .horizontalFraction;
  }
}
