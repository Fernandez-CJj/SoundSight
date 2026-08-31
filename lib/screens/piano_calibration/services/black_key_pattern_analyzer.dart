import '../models/black_key_candidate.dart';
import '../models/black_key_pattern_analysis.dart';

/// Recognizes the repeating two-black-key/three-black-key piano pattern.
///
/// Candidate dimensions are normalized around robust medians before gaps are
/// clustered, which rejects unrelated dark rectangles and incomplete patterns.
class BlackKeyPatternAnalyzer {
  final double minimumWidthScale = 0.50;
  final double maximumWidthScale = 1.80;
  final double minimumHeightScale = 0.55;
  final double maximumHeightScale = 1.60;
  final double bottomAlignmentTolerance = 0.45;
  final double maximumGapMultiplier = 2.80;
  final int gapClusteringIterations = 8;
  final double minimumLargeGapScale = 1.25;
  final double maximumLargeGapScale = 2.50;
  final int maximumIgnoredCandidatesPerSide = 3;
  final int minimumCompleteGroupsForTwoOctaves = 4;

  /// Filters [candidates], groups them by horizontal gaps, and validates octaves.
  ///
  /// The best complete sequence is returned only when enough alternating groups
  /// span a plausible portion of [imageWidth].
  BlackKeyPatternAnalysis analyzePattern(
    List<BlackKeyCandidate> candidates,
    int imageWidth,
  ) {
    if (candidates.length < 5) {
      return BlackKeyPatternAnalysis(
        acceptedGroups: null,
        largestCompleteGroupCount: 0,
      );
    }

    List<BlackKeyCandidate> similarCandidates = filterSimilarCandidates(
      candidates,
    );

    if (similarCandidates.length < 5) {
      return BlackKeyPatternAnalysis(
        acceptedGroups: null,
        largestCompleteGroupCount: 0,
      );
    }

    similarCandidates.sort((firstCandidate, secondCandidate) {
      return firstCandidate.left.compareTo(secondCandidate.left);
    });

    List<List<BlackKeyCandidate>>? bestGroups;
    int bestCompleteGroupCount = 0;
    int bestCandidateCount = 0;
    double? bestCenterDistance;
    int largestCompleteGroupCount = 0;

    int maximumLeftRemoval = maximumIgnoredCandidatesPerSide;

    if (similarCandidates.length - maximumLeftRemoval < 5) {
      maximumLeftRemoval = similarCandidates.length - 5;
    }

    for (
      int removedFromLeft = 0;
      removedFromLeft <= maximumLeftRemoval;
      removedFromLeft++
    ) {
      int maximumRightRemoval = maximumIgnoredCandidatesPerSide;

      int candidatesRemainingAfterLeftRemoval =
          similarCandidates.length - removedFromLeft;

      if (candidatesRemainingAfterLeftRemoval - maximumRightRemoval < 5) {
        maximumRightRemoval = candidatesRemainingAfterLeftRemoval - 5;
      }

      for (
        int removedFromRight = 0;
        removedFromRight <= maximumRightRemoval;
        removedFromRight++
      ) {
        int endIndex = similarCandidates.length - removedFromRight;

        List<BlackKeyCandidate> candidateSequence = similarCandidates.sublist(
          removedFromLeft,
          endIndex,
        );

        List<List<BlackKeyCandidate>>? groups = createGroups(candidateSequence);

        if (groups == null) {
          continue;
        }

        int foundCompleteGroupCount = countCompleteGroups(groups);

        if (foundCompleteGroupCount > largestCompleteGroupCount) {
          largestCompleteGroupCount = foundCompleteGroupCount;
        }

        List<List<BlackKeyCandidate>>? completeOctaveGroups =
            selectCompleteOctaveGroups(groups, imageWidth);

        if (completeOctaveGroups == null) {
          continue;
        }

        int completeGroupCount = countCompleteGroups(completeOctaveGroups);

        int candidateCount = countCandidates(completeOctaveGroups);

        double centerDistance = calculateGroupCenterDistance(
          completeOctaveGroups,
          imageWidth,
        );

        bool hasMoreCompleteGroups =
            completeGroupCount > bestCompleteGroupCount;

        bool hasSameGroupsAndMoreCandidates =
            completeGroupCount == bestCompleteGroupCount &&
            candidateCount > bestCandidateCount;

        bool hasSameResultSize =
            completeGroupCount == bestCompleteGroupCount &&
            candidateCount == bestCandidateCount;

        bool isCloserToFrameCenter =
            bestCenterDistance == null || centerDistance < bestCenterDistance;

        bool hasSameSizeAndIsMoreCentered =
            hasSameResultSize && isCloserToFrameCenter;

        if (hasMoreCompleteGroups ||
            hasSameGroupsAndMoreCandidates ||
            hasSameSizeAndIsMoreCentered) {
          bestGroups = completeOctaveGroups;
          bestCompleteGroupCount = completeGroupCount;
          bestCandidateCount = candidateCount;
          bestCenterDistance = centerDistance;
        }
      }
    }

    return BlackKeyPatternAnalysis(
      acceptedGroups: bestGroups,
      largestCompleteGroupCount: largestCompleteGroupCount,
    );
  }

  /// Splits ordered candidates wherever a statistically large gap is found.
  List<List<BlackKeyCandidate>>? createGroups(
    List<BlackKeyCandidate> candidates,
  ) {
    if (candidates.length < 5) {
      return null;
    }

    List<double> gaps = [];

    for (int index = 1; index < candidates.length; index++) {
      BlackKeyCandidate previousCandidate = candidates[index - 1];

      BlackKeyCandidate currentCandidate = candidates[index];

      double previousCenter =
          previousCandidate.left + (previousCandidate.width / 2);

      double currentCenter =
          currentCandidate.left + (currentCandidate.width / 2);

      gaps.add(currentCenter - previousCenter);
    }

    double normalGap = calculateMedian(gaps);

    for (double gap in gaps) {
      if (gap < normalGap * 0.50 || gap > normalGap * maximumGapMultiplier) {
        return null;
      }
    }

    double? largeGapBoundary = findLargeGapBoundary(gaps);

    if (largeGapBoundary == null) {
      return null;
    }

    List<List<BlackKeyCandidate>> groups = [];
    List<BlackKeyCandidate> currentGroup = [candidates.first];

    for (int index = 1; index < candidates.length; index++) {
      double gap = gaps[index - 1];

      if (gap > largeGapBoundary) {
        groups.add(currentGroup);
        currentGroup = [];
      }

      currentGroup.add(candidates[index]);
    }

    groups.add(currentGroup);

    if (!matchesPianoPattern(groups)) {
      return null;
    }

    return groups;
  }

  /// Selects the strongest consecutive run of complete alternating 2/3 groups.
  List<List<BlackKeyCandidate>>? selectCompleteOctaveGroups(
    List<List<BlackKeyCandidate>> groups,
    int imageWidth,
  ) {
    List<List<BlackKeyCandidate>> completeGroups = [];

    for (List<BlackKeyCandidate> group in groups) {
      if (group.length == 2 || group.length == 3) {
        completeGroups.add(group);
      }
    }

    if (completeGroups.length < minimumCompleteGroupsForTwoOctaves) {
      return null;
    }

    if (completeGroups.length.isEven) {
      return completeGroups;
    }

    List<List<BlackKeyCandidate>> groupsWithoutLast = completeGroups.sublist(
      0,
      completeGroups.length - 1,
    );

    List<List<BlackKeyCandidate>> groupsWithoutFirst = completeGroups.sublist(
      1,
    );

    double withoutLastCenterDistance = calculateGroupCenterDistance(
      groupsWithoutLast,
      imageWidth,
    );

    double withoutFirstCenterDistance = calculateGroupCenterDistance(
      groupsWithoutFirst,
      imageWidth,
    );

    if (withoutLastCenterDistance < withoutFirstCenterDistance) {
      return groupsWithoutLast;
    }

    if (withoutFirstCenterDistance < withoutLastCenterDistance) {
      return groupsWithoutFirst;
    }

    bool withoutLastBeginsWithGroupOfTwo = groupsWithoutLast.first.length == 2;

    if (withoutLastBeginsWithGroupOfTwo) {
      return groupsWithoutLast;
    }

    return groupsWithoutFirst;
  }

  /// Measures how much of the image width the accepted candidate run spans.
  double calculateGroupCenterDistance(
    List<List<BlackKeyCandidate>> groups,
    int imageWidth,
  ) {
    BlackKeyCandidate firstCandidate = groups.first.first;

    BlackKeyCandidate lastCandidate = groups.last.last;

    double leftEdge = firstCandidate.left.toDouble();

    double rightEdge = (lastCandidate.left + lastCandidate.width).toDouble();

    double groupCenter = (leftEdge + rightEdge) / 2;

    double frameCenter = imageWidth / 2;

    return (groupCenter - frameCenter).abs();
  }

  /// Counts groups containing exactly two or three candidates.
  int countCompleteGroups(List<List<BlackKeyCandidate>> groups) {
    int completeGroupCount = 0;

    for (List<BlackKeyCandidate> group in groups) {
      if (group.length == 2 || group.length == 3) {
        completeGroupCount++;
      }
    }

    return completeGroupCount;
  }

  /// Counts all black-key candidates across [groups].
  int countCandidates(List<List<BlackKeyCandidate>> groups) {
    int candidateCount = 0;

    for (List<BlackKeyCandidate> group in groups) {
      candidateCount += group.length;
    }

    return candidateCount;
  }

  /// Uses two-center clustering to separate within-group and between-group gaps.
  ///
  /// Returns a split threshold, or `null` when the two gap populations are not
  /// sufficiently distinct to support a piano pattern.
  double? findLargeGapBoundary(List<double> gaps) {
    if (gaps.length < 2) {
      return null;
    }

    double shortGapCenter = gaps.first;
    double longGapCenter = gaps.first;

    for (double gap in gaps) {
      if (gap < shortGapCenter) {
        shortGapCenter = gap;
      }

      if (gap > longGapCenter) {
        longGapCenter = gap;
      }
    }

    if (shortGapCenter == longGapCenter) {
      return null;
    }

    for (int iteration = 0; iteration < gapClusteringIterations; iteration++) {
      List<double> shortGaps = [];
      List<double> longGaps = [];

      for (double gap in gaps) {
        double distanceFromShortCenter = (gap - shortGapCenter).abs();

        double distanceFromLongCenter = (gap - longGapCenter).abs();

        if (distanceFromShortCenter <= distanceFromLongCenter) {
          shortGaps.add(gap);
        } else {
          longGaps.add(gap);
        }
      }

      if (shortGaps.isEmpty || longGaps.isEmpty) {
        return null;
      }

      shortGapCenter = calculateAverage(shortGaps);
      longGapCenter = calculateAverage(longGaps);
    }

    if (longGapCenter < shortGapCenter * minimumLargeGapScale) {
      return null;
    }

    if (longGapCenter > shortGapCenter * maximumLargeGapScale) {
      return null;
    }

    return (shortGapCenter + longGapCenter) / 2;
  }

  /// Keeps candidates close to median width, height, and bottom alignment.
  List<BlackKeyCandidate> filterSimilarCandidates(
    List<BlackKeyCandidate> candidates,
  ) {
    List<double> widths = [];
    List<double> heights = [];
    List<double> bottoms = [];

    for (BlackKeyCandidate candidate in candidates) {
      widths.add(candidate.width.toDouble());
      heights.add(candidate.height.toDouble());

      bottoms.add((candidate.top + candidate.height).toDouble());
    }

    double medianWidth = calculateMedian(widths);
    double medianHeight = calculateMedian(heights);
    double medianBottom = calculateMedian(bottoms);

    List<BlackKeyCandidate> similarCandidates = [];

    for (BlackKeyCandidate candidate in candidates) {
      if (candidate.width < medianWidth * minimumWidthScale ||
          candidate.width > medianWidth * maximumWidthScale) {
        continue;
      }

      if (candidate.height < medianHeight * minimumHeightScale ||
          candidate.height > medianHeight * maximumHeightScale) {
        continue;
      }

      double candidateBottom = (candidate.top + candidate.height).toDouble();

      double bottomDifference = (candidateBottom - medianBottom).abs();

      if (bottomDifference > medianHeight * bottomAlignmentTolerance) {
        continue;
      }

      similarCandidates.add(candidate);
    }

    return similarCandidates;
  }

  /// Verifies that complete groups alternate between sizes two and three.
  bool matchesPianoPattern(List<List<BlackKeyCandidate>> groups) {
    if (groups.length < 2) {
      return false;
    }

    bool containsGroupOfTwo = false;
    bool containsGroupOfThree = false;
    int? previousCompleteGroupSize;

    for (int index = 0; index < groups.length; index++) {
      int groupSize = groups[index].length;

      bool isEdgeGroup = index == 0 || index == groups.length - 1;

      if (groupSize == 1 && isEdgeGroup) {
        continue;
      }

      if (groupSize != 2 && groupSize != 3) {
        return false;
      }

      if (previousCompleteGroupSize == groupSize) {
        return false;
      }

      previousCompleteGroupSize = groupSize;

      if (groupSize == 2) {
        containsGroupOfTwo = true;
      }

      if (groupSize == 3) {
        containsGroupOfThree = true;
      }
    }

    return containsGroupOfTwo && containsGroupOfThree;
  }

  /// Returns the arithmetic mean of a non-empty list.
  double calculateAverage(List<double> values) {
    double total = 0;

    for (double value in values) {
      total += value;
    }

    return total / values.length;
  }

  /// Returns a robust median for candidate-size and gap calculations.
  double calculateMedian(List<double> values) {
    List<double> sortedValues = List<double>.from(values);
    sortedValues.sort();

    int middleIndex = sortedValues.length ~/ 2;

    if (sortedValues.length.isOdd) {
      return sortedValues[middleIndex];
    }

    double valueBeforeMiddle = sortedValues[middleIndex - 1];

    double valueAfterMiddle = sortedValues[middleIndex];

    return (valueBeforeMiddle + valueAfterMiddle) / 2;
  }
}
