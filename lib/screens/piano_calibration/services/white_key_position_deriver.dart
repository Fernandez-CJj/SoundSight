import 'dart:ui';

import '../models/keyboard_area_corners.dart';
import '../models/black_key_candidate.dart';
import '../models/normalized_keyboard_point.dart';
import '../models/piano_key_marker.dart';
import '../models/reference_key_marker.dart';
import 'keyboard_perspective_mapper.dart';
import 'white_key_center_refiner.dart';

/// Assigns natural-note names and positions across the visible keyboard range.
class WhiteKeyPositionDeriver {
  final List<String> whiteKeyLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  final KeyboardPerspectiveMapper perspectiveMapper =
      KeyboardPerspectiveMapper();

  final WhiteKeyCenterRefiner whiteKeyCenterRefiner = WhiteKeyCenterRefiner();

  /// Interpolates C-to-C natural keys, extends visible edges, then refines them.
  ///
  /// The selected C4 and derived reference Cs determine octave numbering.
  List<PianoKeyMarker> deriveWhiteKeys({
    required List<ReferenceKeyMarker> referenceCMarkers,
    required List<List<BlackKeyCandidate>> blackKeyGroups,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    if (referenceCMarkers.isEmpty) {
      return const <PianoKeyMarker>[];
    }

    List<ReferenceKeyMarker> orderedCs = List<ReferenceKeyMarker>.from(
      referenceCMarkers,
    );

    orderedCs.sort((first, second) {
      return first.octaveNumber.compareTo(second.octaveNumber);
    });

    if (orderedCs.length == 1) {
      ReferenceKeyMarker onlyC = orderedCs.first;

      return [
        PianoKeyMarker(
          noteLetter: 'C',
          octaveNumber: onlyC.octaveNumber,
          position: onlyC.position,
        ),
      ];
    }

    List<PianoKeyMarker> whiteKeys = [];

    for (int cIndex = 0; cIndex < orderedCs.length - 1; cIndex++) {
      ReferenceKeyMarker leftC = orderedCs[cIndex];
      ReferenceKeyMarker rightC = orderedCs[cIndex + 1];

      if (rightC.octaveNumber != leftC.octaveNumber + 1) {
        continue;
      }

      NormalizedKeyboardPoint normalizedLeftC = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: leftC.position,
            corners: keyboardAreaCorners,
          );

      NormalizedKeyboardPoint normalizedRightC = perspectiveMapper
          .toNormalizedPosition(
            sourcePosition: rightC.position,
            corners: keyboardAreaCorners,
          );

      for (int keyIndex = 0; keyIndex < whiteKeyLetters.length; keyIndex++) {
        String noteLetter = whiteKeyLetters[keyIndex];

        Offset sourcePosition;

        if (keyIndex == 0) {
          sourcePosition = leftC.position;
        } else {
          double octaveFraction = keyIndex / whiteKeyLetters.length;

          double horizontalFraction = interpolate(
            normalizedLeftC.horizontalFraction,
            normalizedRightC.horizontalFraction,
            octaveFraction,
          );

          double verticalFraction = interpolate(
            normalizedLeftC.verticalFraction,
            normalizedRightC.verticalFraction,
            octaveFraction,
          );

          sourcePosition = perspectiveMapper.toSourcePosition(
            normalizedPosition: NormalizedKeyboardPoint(
              horizontalFraction: horizontalFraction,
              verticalFraction: verticalFraction,
            ),
            corners: keyboardAreaCorners,
          );
        }

        whiteKeys.add(
          PianoKeyMarker(
            noteLetter: noteLetter,
            octaveNumber: leftC.octaveNumber,
            position: sourcePosition,
          ),
        );
      }
    }

    ReferenceKeyMarker finalC = orderedCs.last;

    whiteKeys.add(
      PianoKeyMarker(
        noteLetter: 'C',
        octaveNumber: finalC.octaveNumber,
        position: finalC.position,
      ),
    );

    addVisibleKeysBeforeFirstC(
      whiteKeys: whiteKeys,
      firstC: orderedCs[0],
      secondC: orderedCs[1],
      keyboardAreaCorners: keyboardAreaCorners,
    );

    addVisibleKeysAfterLastC(
      whiteKeys: whiteKeys,
      previousC: orderedCs[orderedCs.length - 2],
      lastC: orderedCs.last,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    List<PianoKeyMarker> refinedWhiteKeys = whiteKeyCenterRefiner.refineCenters(
      fallbackMarkers: whiteKeys,
      referenceCMarkers: orderedCs,
      blackKeyGroups: blackKeyGroups,
      keyboardAreaCorners: keyboardAreaCorners,
    );

    return List<PianoKeyMarker>.unmodifiable(refinedWhiteKeys);
  }

  /// Extrapolates natural keys left of the first complete visible C.
  void addVisibleKeysBeforeFirstC({
    required List<PianoKeyMarker> whiteKeys,
    required ReferenceKeyMarker firstC,
    required ReferenceKeyMarker secondC,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    NormalizedKeyboardPoint normalizedFirstC = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: firstC.position,
          corners: keyboardAreaCorners,
        );

    NormalizedKeyboardPoint normalizedSecondC = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: secondC.position,
          corners: keyboardAreaCorners,
        );

    double horizontalStep =
        (normalizedSecondC.horizontalFraction -
            normalizedFirstC.horizontalFraction) /
        whiteKeyLetters.length;

    double verticalStep =
        (normalizedSecondC.verticalFraction -
            normalizedFirstC.verticalFraction) /
        whiteKeyLetters.length;

    if (horizontalStep <= 0) {
      return;
    }

    int noteIndex = 0;
    int octaveNumber = firstC.octaveNumber;

    for (int stepCount = 1; ; stepCount++) {
      noteIndex--;

      if (noteIndex < 0) {
        noteIndex = whiteKeyLetters.length - 1;
        octaveNumber--;
      }

      double horizontalFraction =
          normalizedFirstC.horizontalFraction - (horizontalStep * stepCount);

      double verticalFraction =
          normalizedFirstC.verticalFraction - (verticalStep * stepCount);

      if (!isInsideKeyboard(
        horizontalFraction: horizontalFraction,
        verticalFraction: verticalFraction,
      )) {
        break;
      }

      Offset sourcePosition = perspectiveMapper.toSourcePosition(
        normalizedPosition: NormalizedKeyboardPoint(
          horizontalFraction: horizontalFraction,
          verticalFraction: verticalFraction,
        ),
        corners: keyboardAreaCorners,
      );

      whiteKeys.insert(
        0,
        PianoKeyMarker(
          noteLetter: whiteKeyLetters[noteIndex],
          octaveNumber: octaveNumber,
          position: sourcePosition,
        ),
      );
    }
  }

  /// Extrapolates natural keys right of the last complete visible C.
  void addVisibleKeysAfterLastC({
    required List<PianoKeyMarker> whiteKeys,
    required ReferenceKeyMarker previousC,
    required ReferenceKeyMarker lastC,
    required KeyboardAreaCorners keyboardAreaCorners,
  }) {
    NormalizedKeyboardPoint normalizedPreviousC = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: previousC.position,
          corners: keyboardAreaCorners,
        );

    NormalizedKeyboardPoint normalizedLastC = perspectiveMapper
        .toNormalizedPosition(
          sourcePosition: lastC.position,
          corners: keyboardAreaCorners,
        );

    double horizontalStep =
        (normalizedLastC.horizontalFraction -
            normalizedPreviousC.horizontalFraction) /
        whiteKeyLetters.length;

    double verticalStep =
        (normalizedLastC.verticalFraction -
            normalizedPreviousC.verticalFraction) /
        whiteKeyLetters.length;

    if (horizontalStep <= 0) {
      return;
    }

    int noteIndex = 0;
    int octaveNumber = lastC.octaveNumber;

    for (int stepCount = 1; ; stepCount++) {
      noteIndex++;

      if (noteIndex >= whiteKeyLetters.length) {
        noteIndex = 0;
        octaveNumber++;
      }

      double horizontalFraction =
          normalizedLastC.horizontalFraction + (horizontalStep * stepCount);

      double verticalFraction =
          normalizedLastC.verticalFraction + (verticalStep * stepCount);

      if (!isInsideKeyboard(
        horizontalFraction: horizontalFraction,
        verticalFraction: verticalFraction,
      )) {
        break;
      }

      Offset sourcePosition = perspectiveMapper.toSourcePosition(
        normalizedPosition: NormalizedKeyboardPoint(
          horizontalFraction: horizontalFraction,
          verticalFraction: verticalFraction,
        ),
        corners: keyboardAreaCorners,
      );

      whiteKeys.add(
        PianoKeyMarker(
          noteLetter: whiteKeyLetters[noteIndex],
          octaveNumber: octaveNumber,
          position: sourcePosition,
        ),
      );
    }
  }

  /// Checks whether a normalized extrapolated point remains in the keyboard.
  bool isInsideKeyboard({
    required double horizontalFraction,
    required double verticalFraction,
  }) {
    return horizontalFraction >= 0 &&
        horizontalFraction <= 1 &&
        verticalFraction >= 0 &&
        verticalFraction <= 1;
  }

  /// Linearly interpolates one scalar between [start] and [end].
  double interpolate(double start, double end, double fraction) {
    return start + ((end - start) * fraction);
  }
}
