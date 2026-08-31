import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'camera_image_converter.dart';
import 'keyboard_image_preprocessor.dart';
import '../models/black_key_candidate.dart';
import 'black_key_candidate_finder.dart';
import 'black_key_pattern_analyzer.dart';
import 'piano_detection_stabilizer.dart';
import '../models/piano_detection_result.dart';
import '../models/piano_detection_guidance.dart';
import '../models/black_key_pattern_analysis.dart';
import '../models/keyboard_search_band.dart';
import 'keyboard_search_band_masker.dart';
import 'keyboard_area_estimator.dart';
import '../models/keyboard_area_corners.dart';
import '../models/calibration_frame.dart';

/// Coordinates the real-time computer-vision piano detection pipeline.
///
/// Each frame is converted, thresholded, searched in several vertical bands,
/// validated as repeating 2/3 black-key groups, and stabilized over time.
class PianoKeyboardDetector {
  final int minimumCandidateCountForClearanceGuidance = 9;

  final CameraImageConverter cameraImageConverter = CameraImageConverter();

  final KeyboardImagePreprocessor keyboardImagePreprocessor =
      KeyboardImagePreprocessor();

  final BlackKeyCandidateFinder blackKeyCandidateFinder =
      BlackKeyCandidateFinder();

  final BlackKeyPatternAnalyzer blackKeyPatternAnalyzer =
      BlackKeyPatternAnalyzer();

  final PianoDetectionStabilizer pianoDetectionStabilizer =
      PianoDetectionStabilizer();

  final KeyboardSearchBandMasker keyboardSearchBandMasker =
      KeyboardSearchBandMasker();

  final KeyboardAreaEstimator keyboardAreaEstimator = KeyboardAreaEstimator();

  final List<KeyboardSearchBand> keyboardSearchBands = [
    KeyboardSearchBand(topFraction: 0.15, bottomFraction: 0.45),
    KeyboardSearchBand(topFraction: 0.25, bottomFraction: 0.55),
    KeyboardSearchBand(topFraction: 0.35, bottomFraction: 0.65),
    KeyboardSearchBand(topFraction: 0.45, bottomFraction: 0.75),
    KeyboardSearchBand(topFraction: 0.55, bottomFraction: 0.85),
  ];

  int? preferredSearchBandIndex;

  /// Processes one camera frame and returns geometry plus user guidance.
  ///
  /// OpenCV matrices created during processing are disposed before returning.
  /// Once the same pattern is stable, the result also includes playable-area
  /// corners and a grayscale snapshot for detailed seam detection.
  PianoDetectionResult process(CameraImage cameraImage) {
    cv.Mat grayscaleImage = cameraImageConverter.convertToGrayscale(
      cameraImage,
    );

    try {
      cv.Mat completeDarkRegionMask = keyboardImagePreprocessor
          .createDarkRegionMask(grayscaleImage);

      try {
        int highestCandidateCount = 0;

        int highestCompleteGroupCount = 0;

        List<BlackKeyCandidate>? selectedCandidates;

        List<List<BlackKeyCandidate>>? selectedGroups;

        int? selectedSearchBandIndex;

        // Try the last successful band first to reduce work on steady frames.
        List<int> searchBandIndexes = [];

        int? preferredIndex = preferredSearchBandIndex;

        if (preferredIndex != null) {
          searchBandIndexes.add(preferredIndex);
        }

        for (int index = 0; index < keyboardSearchBands.length; index++) {
          if (index != preferredIndex) {
            searchBandIndexes.add(index);
          }
        }

        for (int searchBandIndex in searchBandIndexes) {
          KeyboardSearchBand searchBand = keyboardSearchBands[searchBandIndex];

          cv.Mat bandMask = keyboardSearchBandMasker.createBandMask(
            completeDarkRegionMask,
            searchBand,
          );

          try {
            List<BlackKeyCandidate> candidates = blackKeyCandidateFinder
                .findCandidates(bandMask);

            if (candidates.length > highestCandidateCount) {
              highestCandidateCount = candidates.length;
            }

            BlackKeyPatternAnalysis patternAnalysis = blackKeyPatternAnalyzer
                .analyzePattern(candidates, bandMask.cols);

            if (patternAnalysis.largestCompleteGroupCount >
                highestCompleteGroupCount) {
              highestCompleteGroupCount =
                  patternAnalysis.largestCompleteGroupCount;
            }

            List<List<BlackKeyCandidate>>? groups =
                patternAnalysis.acceptedGroups;

            if (groups == null) {
              continue;
            }

            if (searchBandIndex == preferredIndex) {
              selectedCandidates = candidates;
              selectedGroups = groups;
              selectedSearchBandIndex = searchBandIndex;
              break;
            }

            if (selectedCandidates == null ||
                candidates.length > selectedCandidates.length) {
              selectedCandidates = candidates;
              selectedGroups = groups;
              selectedSearchBandIndex = searchBandIndex;
            }
          } finally {
            bandMask.dispose();
          }
        }

        if (selectedCandidates == null || selectedGroups == null) {
          pianoDetectionStabilizer.registerMiss();

          if (pianoDetectionStabilizer.matchingFrameCount == 0) {
            preferredSearchBandIndex = null;
          }

          PianoDetectionGuidance guidance =
              PianoDetectionGuidance.pointCameraAtKeyboard;

          if (highestCompleteGroupCount > 0) {
            guidance = PianoDetectionGuidance.moveFartherBack;

            if (highestCandidateCount >=
                minimumCandidateCountForClearanceGuidance) {
              guidance = PianoDetectionGuidance.keepKeyboardClear;
            }
          }

          return PianoDetectionResult(
            isStable: false,
            candidateCount: highestCandidateCount,
            groupSizes: [],
            completeGroupCount: highestCompleteGroupCount,
            matchingFrameCount: pianoDetectionStabilizer.matchingFrameCount,
            requiredMatchingFrames:
                pianoDetectionStabilizer.requiredMatchingFrames,
            guidance: guidance,
            keyboardAreaCorners: null,
            blackKeyGroups: const <List<BlackKeyCandidate>>[],
          );
        }

        preferredSearchBandIndex = selectedSearchBandIndex;

        bool isStable = pianoDetectionStabilizer.registerDetection(
          selectedGroups,
          completeDarkRegionMask.cols,
        );

        KeyboardAreaCorners? keyboardAreaCorners;

        if (isStable) {
          keyboardAreaCorners = keyboardAreaEstimator.estimate(
            groups: selectedGroups,
            imageWidth: completeDarkRegionMask.cols,
            imageHeight: completeDarkRegionMask.rows,
          );
        }

        CalibrationFrame? calibrationFrame;

        if (isStable) {
          calibrationFrame = CalibrationFrame(
            width: grayscaleImage.cols,
            height: grayscaleImage.rows,
            grayscaleBytes: Uint8List.fromList(grayscaleImage.data),
          );
        }

        List<int> groupSizes = [];

        for (List<BlackKeyCandidate> group in selectedGroups) {
          groupSizes.add(group.length);
        }

        PianoDetectionGuidance guidance =
            PianoDetectionGuidance.holdPhoneSteady;

        if (isStable) {
          guidance = PianoDetectionGuidance.pianoDetected;
        }

        return PianoDetectionResult(
          isStable: isStable,
          candidateCount: selectedCandidates.length,
          groupSizes: groupSizes,
          completeGroupCount: selectedGroups.length,
          matchingFrameCount: pianoDetectionStabilizer.matchingFrameCount,
          requiredMatchingFrames:
              pianoDetectionStabilizer.requiredMatchingFrames,
          guidance: guidance,
          keyboardAreaCorners: keyboardAreaCorners,
          blackKeyGroups: selectedGroups,
          calibrationFrame: calibrationFrame,
        );
      } finally {
        completeDarkRegionMask.dispose();
      }
    } finally {
      grayscaleImage.dispose();
    }
  }

  /// Clears stability and preferred-band state before a fresh detection run.
  void reset() {
    pianoDetectionStabilizer.reset();
    preferredSearchBandIndex = null;
  }
}
