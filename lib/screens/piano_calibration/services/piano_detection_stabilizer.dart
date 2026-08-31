import '../models/black_key_candidate.dart';

/// Prevents one noisy camera frame from being accepted as a calibration.
///
/// A keyboard is stable only after similar black-key candidates appear across
/// several consecutive frames within position and width tolerances.
class PianoDetectionStabilizer {
  final int requiredMatchingFrames = 5;
  final int minimumMatchingCandidates = 5;
  final double minimumMatchingCandidateFraction = 0.60;
  final double horizontalMovementTolerance = 0.02;
  final double widthChangeTolerance = 0.60;

  List<BlackKeyCandidate>? previousCandidates;
  int matchingFrameCount = 0;

  /// Registers a valid grouped detection and returns whether it is now stable.
  bool registerDetection(List<List<BlackKeyCandidate>> groups, int imageWidth) {
    List<BlackKeyCandidate> currentCandidates = [];

    for (List<BlackKeyCandidate> group in groups) {
      currentCandidates.addAll(group);
    }

    bool matchesPreviousDetection = detectionsMatch(
      currentCandidates,
      imageWidth,
    );

    if (matchesPreviousDetection) {
      if (matchingFrameCount < requiredMatchingFrames) {
        matchingFrameCount++;
      }
    } else {
      matchingFrameCount = 1;
    }

    previousCandidates = List<BlackKeyCandidate>.from(currentCandidates);

    return matchingFrameCount >= requiredMatchingFrames;
  }

  /// Compares current candidates to the previous frame without reusing matches.
  bool detectionsMatch(
    List<BlackKeyCandidate> currentCandidates,
    int imageWidth,
  ) {
    List<BlackKeyCandidate>? oldCandidates = previousCandidates;

    if (oldCandidates == null) {
      return false;
    }

    double horizontalTolerance = imageWidth * horizontalMovementTolerance;

    Set<int> matchedOldCandidateIndexes = {};
    int matchingCandidateCount = 0;

    for (BlackKeyCandidate currentCandidate in currentCandidates) {
      int? closestOldCandidateIndex;
      double? closestHorizontalDifference;

      for (int oldIndex = 0; oldIndex < oldCandidates.length; oldIndex++) {
        if (matchedOldCandidateIndexes.contains(oldIndex)) {
          continue;
        }

        BlackKeyCandidate oldCandidate = oldCandidates[oldIndex];

        double currentCenterX =
            currentCandidate.left + (currentCandidate.width / 2);

        double oldCenterX = oldCandidate.left + (oldCandidate.width / 2);

        double horizontalDifference = (currentCenterX - oldCenterX).abs();

        if (horizontalDifference > horizontalTolerance) {
          continue;
        }

        double largerWidth = currentCandidate.width.toDouble();

        if (oldCandidate.width > largerWidth) {
          largerWidth = oldCandidate.width.toDouble();
        }

        double widthTolerance = largerWidth * widthChangeTolerance;

        if ((currentCandidate.width - oldCandidate.width).abs() >
            widthTolerance) {
          continue;
        }

        if (closestHorizontalDifference == null ||
            horizontalDifference < closestHorizontalDifference) {
          closestHorizontalDifference = horizontalDifference;
          closestOldCandidateIndex = oldIndex;
        }
      }

      if (closestOldCandidateIndex != null) {
        matchedOldCandidateIndexes.add(closestOldCandidateIndex);
        matchingCandidateCount++;
      }
    }

    int comparableCandidateCount = currentCandidates.length;

    if (oldCandidates.length < comparableCandidateCount) {
      comparableCandidateCount = oldCandidates.length;
    }

    int requiredCandidateMatches =
        (comparableCandidateCount * minimumMatchingCandidateFraction).ceil();

    if (requiredCandidateMatches < minimumMatchingCandidates) {
      requiredCandidateMatches = minimumMatchingCandidates;
    }

    return matchingCandidateCount >= requiredCandidateMatches;
  }

  /// Weakens the current stability streak when no valid pattern is found.
  void registerMiss() {
    if (matchingFrameCount > 0) {
      matchingFrameCount--;
    }

    if (matchingFrameCount == 0) {
      previousCandidates = null;
    }
  }

  /// Clears all remembered geometry and stability progress.
  void reset() {
    previousCandidates = null;
    matchingFrameCount = 0;
  }
}
