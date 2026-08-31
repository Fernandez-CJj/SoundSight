import 'keyboard_area_corners.dart';
import 'piano_detection_guidance.dart';
import 'black_key_candidate.dart';
import 'calibration_frame.dart';

/// Complete output produced for one camera frame by the keyboard detector.
///
/// It combines diagnostic counts, user guidance, stable geometry, and the
/// grayscale frame needed by later boundary-refinement stages.
class PianoDetectionResult {
  PianoDetectionResult({
    required this.isStable,
    required this.candidateCount,
    required this.groupSizes,
    required this.completeGroupCount,
    required this.matchingFrameCount,
    required this.requiredMatchingFrames,
    required this.guidance,
    required this.keyboardAreaCorners,
    required this.blackKeyGroups,
    this.calibrationFrame,
  });

  /// Whether this frame completes the required stable-frame sequence.
  final bool isStable;
  /// Number of possible black keys found before pattern validation.
  final int candidateCount;
  /// Candidate counts of the accepted or best available 2/3-key groups.
  final List<int> groupSizes;
  /// Number of complete black-key groups in the current pattern.
  final int completeGroupCount;
  /// Consecutive frames matching the same keyboard geometry.
  final int matchingFrameCount;
  /// Consecutive matches required before calibration may continue.
  final int requiredMatchingFrames;
  /// Guidance message category appropriate for this frame.
  final PianoDetectionGuidance guidance;
  /// Estimated playable area when sufficient geometry is available.
  final KeyboardAreaCorners? keyboardAreaCorners;
  /// Accepted black-key groups used by subsequent note derivation.
  final List<List<BlackKeyCandidate>> blackKeyGroups;
  /// Grayscale snapshot retained only when useful for calibration.
  final CalibrationFrame? calibrationFrame;

  /// Number of complete octaves represented by alternating 2/3-key groups.
  int get completeOctaveCount {
    return completeGroupCount ~/ 2;
  }
}
