import 'black_key_candidate.dart';

/// Result of validating dark-key candidates against piano 2/3-key groups.
class BlackKeyPatternAnalysis {
  BlackKeyPatternAnalysis({
    required this.acceptedGroups,
    required this.largestCompleteGroupCount,
  });

  /// Groups accepted as a continuous piano pattern, or `null` when invalid.
  final List<List<BlackKeyCandidate>>? acceptedGroups;
  /// Largest number of complete 2/3 groups seen during analysis.
  final int largestCompleteGroupCount;
}
