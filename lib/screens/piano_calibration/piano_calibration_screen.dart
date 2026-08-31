import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../midi/services/midi_input_service.dart';
import 'services/piano_keyboard_detector.dart';
import 'models/piano_detection_result.dart';
import 'models/piano_detection_guidance.dart';
import 'models/keyboard_area_corners.dart';
import 'models/piano_key_marker.dart';
import 'models/piano_calibration_stage.dart';
import 'models/reference_key_marker.dart';
import 'widgets/keyboard_area_overlay.dart';
import 'models/black_key_candidate.dart';
import 'services/reference_key_deriver.dart';
import 'services/white_key_position_deriver.dart';
import 'services/white_key_boundary_detector.dart';
import 'models/calibration_frame.dart';
import 'models/white_key_boundary_detection_result.dart';
import 'services/black_key_position_deriver.dart';
import 'models/piano_key_region.dart';
import 'services/piano_key_region_deriver.dart';
import 'models/black_key_derivation_result.dart';
import 'models/normalized_piano_calibration.dart';
import 'services/piano_calibration_normalizer.dart';
import 'services/piano_calibration_firestore_service.dart';
import 'widgets/calibration_name_dialog.dart';
import 'models/restored_piano_calibration.dart';
import 'models/saved_piano_calibration.dart';
import 'services/piano_calibration_restorer.dart';
import '../practice/screens/challenges/ar/models/ar_score_timeline.dart';
import '../practice/screens/challenges/ar/services/ar_practice_performance_tracker.dart';
import '../practice/screens/challenges/ar/utils/midi_note_utils.dart';
import '../practice/screens/challenges/ar/widgets/ar_falling_notes_overlay.dart';

/// Camera-based piano calibration and AR practice screen.
///
/// With no [savedCalibration], the screen detects, labels, and saves a new
/// mapping. With a saved calibration and [scoreTimeline], it first allows the
/// user to review/recalibrate the mapping and then starts AR practice.
class PianoCalibrationScreen extends StatefulWidget {
  const PianoCalibrationScreen({
    super.key,
    this.savedCalibration,
    this.scoreTimeline,
  });

  /// Existing mapping to restore instead of running initial detection.
  final SavedPianoCalibration? savedCalibration;

  /// Timed notes rendered after the user chooses to use a saved mapping.
  final ArScoreTimeline? scoreTimeline;

  @override
  /// Creates the camera, calibration workflow, MIDI, and playback state.
  State<PianoCalibrationScreen> createState() {
    return PianoCalibrationScreenState();
  }
}

/// Coordinates the complete calibration lifecycle and AR practice session.
class PianoCalibrationScreenState extends State<PianoCalibrationScreen>
    with SingleTickerProviderStateMixin {
  // Live-camera and stable-detection state.
  CameraController? cameraController;
  String? cameraError;
  bool isProcessingCameraImage = false;
  bool isPianoDetected = false;
  PianoDetectionGuidance detectionGuidance =
      PianoDetectionGuidance.pointCameraAtKeyboard;
  String detectionDetails = 'Candidates: 0 | Pattern: not found';
  DateTime? lastCameraImageTime;
  KeyboardAreaCorners? keyboardAreaCorners;
  final Duration cameraImageInterval = const Duration(milliseconds: 225);

  final PianoKeyboardDetector pianoKeyboardDetector = PianoKeyboardDetector();

  // Calibration-stage geometry and note-label state.
  PianoCalibrationStage calibrationStage =
      PianoCalibrationStage.detectingKeyboard;

  Offset? referenceKeyPosition;

  List<ReferenceKeyMarker> referenceKeyMarkers = [];

  List<PianoKeyMarker> pianoKeyMarkers = [];

  List<PianoKeyRegion> pianoKeyRegions = [];

  List<List<BlackKeyCandidate>> detectedBlackKeyGroups = [];

  CalibrationFrame? calibrationFrame;

  String? whiteKeyAlignmentDetails;

  final ReferenceKeyDeriver referenceKeyDeriver = ReferenceKeyDeriver();

  final WhiteKeyPositionDeriver whiteKeyPositionDeriver =
      WhiteKeyPositionDeriver();

  final WhiteKeyBoundaryDetector whiteKeyBoundaryDetector =
      WhiteKeyBoundaryDetector();

  final BlackKeyPositionDeriver blackKeyPositionDeriver =
      BlackKeyPositionDeriver();

  final PianoCalibrationNormalizer pianoCalibrationNormalizer =
      PianoCalibrationNormalizer();

  final PianoCalibrationFirestoreService calibrationFirestoreService =
      PianoCalibrationFirestoreService();

  final PianoKeyRegionDeriver pianoKeyRegionDeriver = PianoKeyRegionDeriver();

  // Persistence and saved-calibration restoration state.
  NormalizedPianoCalibration? normalizedCalibration;

  bool isSavingCalibration = false;

  String? calibrationSaveError;

  String? savedCalibrationId;

  String? savedCalibrationName;

  final PianoCalibrationRestorer pianoCalibrationRestorer =
      PianoCalibrationRestorer();

  // MIDI, falling-note playback, Wait Mode, and attempt-scoring state.
  bool isRestoringSavedCalibration = false;
  bool loadedFromSavedCalibration = false;
  bool isPracticeMode = false;
  AnimationController? fallingNotesAnimationController;

  final MidiInputService midiInputService = MidiInputService();
  StreamSubscription<Set<int>>? activeMidiNotesSubscription;
  StreamSubscription<int>? midiNoteOnSubscription;
  Set<int> activeMidiNotes = <int>{};
  String midiConnectionStatus = 'Not connected';
  bool isConnectingMidi = false;
  bool isMidiConnected = false;
  bool hasPracticePlaybackStarted = false;
  bool isPracticePlaybackPaused = false;
  bool isPracticePlaybackComplete = false;
  bool performanceModeEnabled = true;
  final ArPracticePerformanceTracker practicePerformanceTracker =
      ArPracticePerformanceTracker();
  int waitModeTargetGroupIndex = 0;
  bool isWaitingForCorrectNotes = false;
  bool isCompletionDialogShowing = false;
  final Set<int> waitModePressedNotes = <int>{};
  final Map<int, DateTime> waitModeNotePressedAt = <int, DateTime>{};

  final Duration fallingNoteApproachDuration = const Duration(seconds: 4);

  @override
  /// Starts MIDI listeners, locks landscape orientation, and opens the camera.
  void initState() {
    super.initState();
    listenToMidiInput();
    SavedPianoCalibration? initialSavedCalibration = widget.savedCalibration;

    if (initialSavedCalibration != null) {
      normalizedCalibration = initialSavedCalibration.calibration;
      savedCalibrationId = initialSavedCalibration.documentId;
      savedCalibrationName = initialSavedCalibration.name;
      isRestoringSavedCalibration = true;
      detectionDetails = 'Loading saved key mapping...';
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    initializeCamera();
  }

  @override
  /// Layers the camera, calibration/practice overlays, controls, and back button.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: buildCameraContent()),
          if (!isPracticeMode) buildDetectionStatus(),
          if (!isPracticeMode) buildCalibrationControls(),
          if (isPracticeMode) buildPracticeControls(),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  tooltip: 'Back',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the top status card for detection, restoration, and mapping review.
  Widget buildDetectionStatus() {
    String statusText = 'Searching for piano...';
    String guidanceText = 'Point the camera at the piano keyboard';
    IconData statusIcon = Icons.search;
    Color statusColor = Colors.black54;

    switch (detectionGuidance) {
      case PianoDetectionGuidance.pointCameraAtKeyboard:
        break;
      case PianoDetectionGuidance.moveFartherBack:
        statusText = 'Move farther back';
        guidanceText = 'Show at least two complete octaves';
        statusIcon = Icons.zoom_out_map;
        statusColor = Colors.orange.shade800;
        break;
      case PianoDetectionGuidance.keepKeyboardClear:
        statusText = 'Keep the keyboard clear';
        guidanceText = 'Move hands or objects away during calibration';
        statusIcon = Icons.visibility;
        statusColor = Colors.amber.shade800;
        break;
      case PianoDetectionGuidance.holdPhoneSteady:
        statusText = 'Hold the phone steady';
        guidanceText = 'Keep the keyboard still while detection confirms';
        statusIcon = Icons.center_focus_strong;
        statusColor = Colors.blueGrey.shade700;
        break;
      case PianoDetectionGuidance.pianoDetected:
        statusText = 'Piano detected';
        guidanceText = 'The visible keyboard area is ready';
        statusIcon = Icons.check_circle;
        statusColor = Colors.green.shade700;
        break;
    }

    if (calibrationStage == PianoCalibrationStage.adjustingKeyboardArea) {
      statusText = 'Adjust keyboard area';
      guidanceText = 'Drag the white corners, then confirm the area';
      statusIcon = Icons.open_with;
      statusColor = Colors.teal.shade700;
    }

    if (calibrationStage == PianoCalibrationStage.selectingReferenceKey) {
      if (referenceKeyPosition == null) {
        statusText = 'Select a reference key';
        guidanceText = 'Tap Middle C (C4) on the real keyboard';
        statusIcon = Icons.music_note;
        statusColor = Colors.indigo.shade700;
      } else if (referenceKeyMarkers.length > 1) {
        List<PianoKeyMarker> visibleWhiteKeyMarkers = [];
        int visibleBlackKeyCount = 0;

        for (PianoKeyMarker marker in pianoKeyMarkers) {
          if (marker.isBlackKey) {
            visibleBlackKeyCount++;
          } else {
            visibleWhiteKeyMarkers.add(marker);
          }
        }

        String firstNote = visibleWhiteKeyMarkers.first.noteName;
        String lastNote = visibleWhiteKeyMarkers.last.noteName;

        statusText = 'Piano keys ready';
        guidanceText =
            '${visibleWhiteKeyMarkers.length} white keys mapped from '
            '$firstNote through $lastNote'
            '\n$visibleBlackKeyCount black keys mapped';

        if (whiteKeyAlignmentDetails != null) {
          guidanceText = '$guidanceText\n$whiteKeyAlignmentDetails';
        }

        if (pianoKeyRegions.isNotEmpty) {
          guidanceText =
              '$guidanceText\n${pianoKeyRegions.length} key outlines generated';
        }

        statusIcon = Icons.check_circle;
        statusColor = Colors.indigo.shade700;
      } else {
        statusText = 'C4 selected';
        guidanceText = 'No other C positions fit inside the keyboard area';
        statusIcon = Icons.warning_amber;
        statusColor = Colors.orange.shade800;
      }
    }

    if (calibrationStage == PianoCalibrationStage.mappingConfirmed) {
      NormalizedPianoCalibration? currentCalibration = normalizedCalibration;

      statusText = loadedFromSavedCalibration
          ? 'Calibration loaded'
          : 'Calibration saved';
      statusIcon = Icons.cloud_done;
      statusColor = Colors.green.shade700;

      if (currentCalibration == null) {
        guidanceText = 'The normalized calibration is unavailable';
      } else {
        String calibrationName = savedCalibrationName ?? 'Calibration';

        String actionText = loadedFromSavedCalibration ? 'restored' : 'saved';

        guidanceText =
            '"$calibrationName" $actionText with '
            '${currentCalibration.pianoKeys.length} piano keys';
      }
    }

    if (isSavingCalibration) {
      statusText = 'Saving calibration...';
      guidanceText = 'Keep this screen open while SoundSight saves the mapping';
      statusIcon = Icons.cloud_upload;
      statusColor = Colors.blue.shade700;
    }

    if (calibrationSaveError != null &&
        calibrationStage == PianoCalibrationStage.selectingReferenceKey) {
      statusText = 'Calibration not saved';
      guidanceText = calibrationSaveError!;
      statusIcon = Icons.cloud_off;
      statusColor = Colors.red.shade700;
    }

    if (isRestoringSavedCalibration) {
      statusText = 'Loading calibration...';
      guidanceText = 'Restoring the saved keyboard mapping';
      statusIcon = Icons.cloud_download;
      statusColor = Colors.blue.shade700;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  guidanceText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  detectionDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds camera loading/error states and the active visual overlay stack.
  Widget buildCameraContent() {
    CameraController? currentCameraController = cameraController;

    if (cameraError != null) {
      return Center(
        child: Text(
          cameraError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (currentCameraController == null ||
        !currentCameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    KeyboardAreaCorners? currentKeyboardAreaCorners = keyboardAreaCorners;

    Widget? keyboardOverlay;

    Set<String> highlightedMarkerNames = <String>{};

    if (isPracticeMode && activeMidiNotes.isNotEmpty) {
      for (PianoKeyMarker marker in pianoKeyMarkers) {
        int? midiNote = MidiNoteUtils.fromPianoKeyMarker(marker);

        if (midiNote != null && activeMidiNotes.contains(midiNote)) {
          highlightedMarkerNames.add(marker.noteName);
        }
      }
    }

    if (currentKeyboardAreaCorners != null) {
      KeyboardAreaCorners detectedCorners = currentKeyboardAreaCorners;

      keyboardOverlay = KeyboardAreaOverlay(
        corners: detectedCorners,
        pianoKeyMarkers: pianoKeyMarkers,
        pianoKeyRegions: pianoKeyRegions,
        showKeyboardArea:
            calibrationStage != PianoCalibrationStage.mappingConfirmed,
        showKeyOutlines: !isPracticeMode,
        showHitLine:
            isPracticeMode &&
            calibrationStage == PianoCalibrationStage.mappingConfirmed,
        showMarkerCircles: !isPracticeMode,
        centerLabelsOnMarkers: isPracticeMode,
        highlightedMarkerNames: highlightedMarkerNames,
        adjustmentEnabled:
            calibrationStage == PianoCalibrationStage.adjustingKeyboardArea,
        referenceSelectionEnabled:
            calibrationStage == PianoCalibrationStage.selectingReferenceKey &&
            !isSavingCalibration,
        onCornersChanged: updateKeyboardAreaCorners,
        onReferenceSelected: selectReferenceKey,
      );
    }

    AnimationController? currentAnimationController =
        fallingNotesAnimationController;

    ArScoreTimeline? currentTimeline = widget.scoreTimeline;

    return CameraPreview(
      currentCameraController,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isPracticeMode &&
              hasPracticePlaybackStarted &&
              currentAnimationController != null &&
              currentTimeline != null &&
              currentKeyboardAreaCorners != null)
            ArFallingNotesOverlay(
              corners: currentKeyboardAreaCorners,
              pianoKeyMarkers: pianoKeyMarkers,
              timeline: currentTimeline,
              animation: currentAnimationController,
              approachDuration: fallingNoteApproachDuration,
              noteResultsByStartMicroseconds:
                  practicePerformanceTracker.noteResultsByStartMicroseconds,
            ),
          if (keyboardOverlay != null) keyboardOverlay,
        ],
      ),
    );
  }

  /// Builds MIDI/start controls and the compact in-playback control row.
  ///
  /// Immediate correctness feedback is placed below the control row so it does
  /// not overlap the Wait/Performance toggle on narrow landscape screens.
  Widget buildPracticeControls() {
    AnimationController? currentAnimationController =
        fallingNotesAnimationController;

    bool canStart =
        isMidiConnected &&
        currentAnimationController != null &&
        !hasPracticePlaybackStarted;

    return Stack(
      children: [
        if (!hasPracticePlaybackStarted)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMidiConnected &&
                          midiConnectionStatus != 'Not connected') ...[
                        Text(
                          midiConnectionStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!isMidiConnected)
                        OutlinedButton.icon(
                          onPressed: isConnectingMidi ? null : connectToMidi,
                          icon: isConnectingMidi
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.usb),
                          label: Text(
                            isConnectingMidi
                                ? 'Connecting...'
                                : 'Connect MIDI',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            minimumSize: const Size(150, 42),
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: canStart ? startPracticePlayback : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(120, 42),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (hasPracticePlaybackStarted &&
            practicePerformanceTracker.feedbackText != 'Ready')
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 68),
                child: buildPracticeFeedback(),
              ),
            ),
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      unawaited(togglePracticePlaybackMode());
                    },
                    icon: Icon(
                      performanceModeEnabled
                          ? Icons.timer
                          : Icons.hourglass_empty,
                    ),
                    tooltip: performanceModeEnabled
                        ? 'Switch to Wait Mode'
                        : 'Switch to Performance Mode',
                    style: practiceIconButtonStyle(),
                  ),
                  const SizedBox(width: 8),
                  buildPracticeProgressIndicator(
                    currentAnimationController,
                  ),
                  if (hasPracticePlaybackStarted &&
                      !isPracticePlaybackComplete) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: togglePracticePlaybackPause,
                      icon: Icon(
                        isPracticePlaybackPaused
                            ? Icons.play_arrow
                            : Icons.pause,
                      ),
                      tooltip: isPracticePlaybackPaused ? 'Resume' : 'Pause',
                      style: practiceIconButtonStyle(),
                    ),
                  ],
                  if (hasPracticePlaybackStarted) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: restartPracticePlayback,
                      icon: const Icon(Icons.replay),
                      tooltip: 'Restart',
                      style: practiceIconButtonStyle(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the color-coded message for the most recent evaluated input.
  Widget buildPracticeFeedback() {
    Color feedbackColor;
    IconData feedbackIcon;

    switch (practicePerformanceTracker.feedbackKind) {
      case ArPracticeFeedbackKind.correct:
        feedbackColor = Colors.green;
        feedbackIcon = Icons.check;
        break;
      case ArPracticeFeedbackKind.warning:
        feedbackColor = Colors.orange;
        feedbackIcon = Icons.priority_high;
        break;
      case ArPracticeFeedbackKind.incorrect:
        feedbackColor = Colors.red;
        feedbackIcon = Icons.close;
        break;
      case ArPracticeFeedbackKind.neutral:
        feedbackColor = Colors.blueGrey;
        feedbackIcon = Icons.music_note;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: feedbackColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feedbackIcon, color: feedbackColor, size: 18),
          const SizedBox(width: 6),
          Text(
            practicePerformanceTracker.feedbackText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the shared translucent style used by practice icon buttons.
  ButtonStyle practiceIconButtonStyle() {
    return IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black.withValues(alpha: 0.72),
      side: const BorderSide(color: Colors.white38),
    );
  }

  /// Builds an animated percentage bar from evaluated score groups.
  Widget buildPracticeProgressIndicator(AnimationController? controller) {
    Widget buildProgressBar(double progress) {
      double safeProgress = progress.clamp(0.0, 1.0).toDouble();
      int percentage = (safeProgress * 100).round();

      return SizedBox(
        width: 180,
        height: 32,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black.withValues(alpha: 0.72)),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: safeProgress,
                  heightFactor: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF66BB6A)],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null) {
      return buildProgressBar(0);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return buildProgressBar(calculatePracticeProgress());
      },
    );
  }

  /// Returns completed note groups as a normalized `0` to `1` fraction.
  double calculatePracticeProgress() {
    if (!hasPracticePlaybackStarted) {
      return 0;
    }

    if (practicePerformanceTracker.totalGroupCount == 0) {
      return 0;
    }

    return practicePerformanceTracker.evaluatedGroupCount /
        practicePerformanceTracker.totalGroupCount;
  }

  /// Formats technical candidate/group/stability details for calibration review.
  String buildDetectionDetails(PianoDetectionResult detectionResult) {
    if (detectionResult.groupSizes.isEmpty) {
      bool hasPartialOctaves =
          detectionResult.guidance == PianoDetectionGuidance.moveFartherBack ||
          detectionResult.guidance == PianoDetectionGuidance.keepKeyboardClear;

      if (hasPartialOctaves) {
        return 'Candidates: ${detectionResult.candidateCount}'
            ' | Complete octaves: ${detectionResult.completeOctaveCount}/2';
      }

      return 'Candidates: ${detectionResult.candidateCount}'
          ' | Pattern: not found';
    }

    String groupText = detectionResult.groupSizes.join('-');

    return 'Octaves: ${detectionResult.completeOctaveCount}'
        ' | Candidates: ${detectionResult.candidateCount}'
        ' | Groups: $groupText'
        ' | Stable: ${detectionResult.matchingFrameCount}'
        '/${detectionResult.requiredMatchingFrames}';
  }

  /// Throttles and processes live frames until a stable keyboard is detected.
  ///
  /// When a saved calibration is pending, the first frame supplies only the
  /// current source dimensions needed to restore normalized coordinates.
  void processCameraImage(CameraImage cameraImage) {
    if (isRestoringSavedCalibration) {
      restoreSavedCalibration(cameraImage);
      return;
    }

    if (calibrationStage != PianoCalibrationStage.detectingKeyboard) {
      return;
    }

    if (isProcessingCameraImage) {
      return;
    }

    DateTime currentTime = DateTime.now();

    if (lastCameraImageTime != null) {
      Duration timeSinceLastImage = currentTime.difference(
        lastCameraImageTime!,
      );

      if (timeSinceLastImage < cameraImageInterval) {
        return;
      }
    }

    lastCameraImageTime = currentTime;
    isProcessingCameraImage = true;

    try {
      PianoDetectionResult detectionResult = pianoKeyboardDetector.process(
        cameraImage,
      );

      KeyboardAreaCorners? newKeyboardAreaCorners =
          detectionResult.keyboardAreaCorners;

      String newDetectionDetails = buildDetectionDetails(detectionResult);

      if (!mounted) {
        return;
      }

      bool statusChanged = detectionResult.isStable != isPianoDetected;

      bool detailsChanged = newDetectionDetails != detectionDetails;

      bool guidanceChanged = detectionResult.guidance != detectionGuidance;

      bool cornerAvailabilityChanged = false;

      if (newKeyboardAreaCorners == null && keyboardAreaCorners != null) {
        cornerAvailabilityChanged = true;
      }

      if (newKeyboardAreaCorners != null && keyboardAreaCorners == null) {
        cornerAvailabilityChanged = true;
      }

      if (!statusChanged &&
          !detailsChanged &&
          !guidanceChanged &&
          !cornerAvailabilityChanged) {
        return;
      }

      setState(() {
        isPianoDetected = detectionResult.isStable;
        detectionGuidance = detectionResult.guidance;
        detectionDetails = newDetectionDetails;

        if (newKeyboardAreaCorners == null) {
          keyboardAreaCorners = null;
          referenceKeyPosition = null;
          referenceKeyMarkers = [];
          pianoKeyMarkers = [];
          pianoKeyRegions = [];
          detectedBlackKeyGroups = [];
          calibrationFrame = null;
          whiteKeyAlignmentDetails = null;
          calibrationStage = PianoCalibrationStage.detectingKeyboard;
        } else {
          keyboardAreaCorners ??= newKeyboardAreaCorners;

          detectedBlackKeyGroups = detectionResult.blackKeyGroups
              .map((group) => List<BlackKeyCandidate>.unmodifiable(group))
              .toList(growable: false);

          calibrationFrame = detectionResult.calibrationFrame;

          referenceKeyMarkers = [];
          pianoKeyMarkers = [];
          pianoKeyRegions = [];
          whiteKeyAlignmentDetails = null;

          calibrationStage = PianoCalibrationStage.adjustingKeyboardArea;
        }
      });
    } catch (error) {
      debugPrint('Camera frame processing failed: $error');

      if (mounted) {
        setState(() {
          isPianoDetected = false;
          keyboardAreaCorners = null;
          referenceKeyPosition = null;
          referenceKeyMarkers = [];
          pianoKeyMarkers = [];
          pianoKeyRegions = [];
          detectedBlackKeyGroups = [];
          calibrationFrame = null;
          whiteKeyAlignmentDetails = null;
          calibrationStage = PianoCalibrationStage.detectingKeyboard;
          detectionGuidance = PianoDetectionGuidance.pointCameraAtKeyboard;
          detectionDetails = 'Processing error';
        });
      }
    } finally {
      isProcessingCameraImage = false;
    }
  }

  /// Converts the supplied saved calibration into current-frame pixel geometry.
  ///
  /// C4 is restored as the editing anchor when present; otherwise the first
  /// visible key provides a safe fallback reference position.
  void restoreSavedCalibration(CameraImage cameraImage) {
    SavedPianoCalibration? savedCalibration = widget.savedCalibration;

    if (!isRestoringSavedCalibration || savedCalibration == null) {
      return;
    }

    isRestoringSavedCalibration = false;

    try {
      RestoredPianoCalibration restoredCalibration = pianoCalibrationRestorer
          .restore(
            calibration: savedCalibration.calibration,
            sourceImageWidth: cameraImage.width,
            sourceImageHeight: cameraImage.height,
          );

      Offset? restoredReferencePosition;

      for (PianoKeyMarker marker in restoredCalibration.pianoKeyMarkers) {
        if (marker.noteLetter == 'C' &&
            marker.octaveNumber == 4 &&
            !marker.isBlackKey) {
          restoredReferencePosition = marker.position;
          break;
        }
      }

      restoredReferencePosition ??=
          restoredCalibration.pianoKeyMarkers.first.position;

      if (!mounted) {
        return;
      }

      setState(() {
        keyboardAreaCorners = restoredCalibration.keyboardAreaCorners;
        pianoKeyMarkers = restoredCalibration.pianoKeyMarkers;
        pianoKeyRegions = restoredCalibration.pianoKeyRegions;
        referenceKeyMarkers = restoredCalibration.referenceKeyMarkers;
        referenceKeyPosition = restoredReferencePosition;

        normalizedCalibration = savedCalibration.calibration;
        savedCalibrationId = savedCalibration.documentId;
        savedCalibrationName = savedCalibration.name;

        detectedBlackKeyGroups = [];
        calibrationFrame = null;
        whiteKeyAlignmentDetails = 'Loaded from Firebase';

        isPianoDetected = true;
        loadedFromSavedCalibration = true;
        detectionGuidance = PianoDetectionGuidance.pianoDetected;
        detectionDetails =
            '${pianoKeyMarkers.length} keys restored from Firebase';
        calibrationStage = PianoCalibrationStage.mappingConfirmed;
      });
    } catch (error) {
      debugPrint('Calibration restoration failed: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        normalizedCalibration = null;
        loadedFromSavedCalibration = false;
        detectionDetails = 'Saved calibration could not be restored';
        calibrationStage = PianoCalibrationStage.detectingKeyboard;
      });
    }
  }

  /// Opens the rear camera and starts the calibration image stream.
  ///
  /// Camera exceptions are converted into an on-screen error instead of leaving
  /// a partially initialized controller attached to the widget.
  Future<void> initializeCamera() async {
    CameraController? newCameraController;

    try {
      List<CameraDescription> cameras = await availableCameras();
      CameraDescription? rearCamera;

      for (CameraDescription camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      if (rearCamera == null) {
        if (mounted) {
          setState(() {
            cameraError = 'No rear camera is available on this device.';
          });
        }

        return;
      }

      newCameraController = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await newCameraController.initialize();

      if (!mounted) {
        await newCameraController.dispose();
        return;
      }

      await newCameraController.startImageStream(processCameraImage);

      if (!mounted) {
        await newCameraController.dispose();
        return;
      }

      setState(() {
        cameraController = newCameraController;
      });
    } on CameraException catch (error) {
      await newCameraController?.dispose();

      if (mounted) {
        setState(() {
          cameraError = error.description ?? 'The camera could not be opened.';
        });
      }
    }
  }

  /// Builds stage-specific actions for area adjustment, mapping, and completion.
  Widget buildCalibrationControls() {
    if (calibrationStage == PianoCalibrationStage.selectingReferenceKey) {
      bool mappingIsReady =
          referenceKeyPosition != null && pianoKeyRegions.isNotEmpty;

      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: isSavingCalibration
                      ? null
                      : adjustKeyboardAreaAgain,
                  icon: const Icon(Icons.open_with),
                  label: const Text('Adjust area'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
                if (mappingIsReady) ...[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: isSavingCalibration ? null : confirmMapping,
                    icon: Icon(
                      isSavingCalibration ? Icons.cloud_upload : Icons.check,
                    ),
                    label: Text(
                      isSavingCalibration ? 'Saving...' : 'Confirm mapping',
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (calibrationStage == PianoCalibrationStage.mappingConfirmed) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: isSavingCalibration ? null : editConfirmedMapping,
                  icon: Icon(
                    loadedFromSavedCalibration ? Icons.refresh : Icons.edit,
                  ),
                  label: Text(
                    loadedFromSavedCalibration ? 'Recalibrate' : 'Edit mapping',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: finishCalibration,
                  icon: const Icon(Icons.check),
                  label: Text(loadedFromSavedCalibration ? 'Use' : 'Done'),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (calibrationStage != PianoCalibrationStage.adjustingKeyboardArea) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: detectKeyboardAgain,
                icon: const Icon(Icons.refresh),
                label: const Text('Detect again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black54,
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: confirmKeyboardArea,
                icon: const Icon(Icons.check),
                label: const Text('Confirm area'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Accepts drag-adjusted corners while the playable area is editable.
  void updateKeyboardAreaCorners(KeyboardAreaCorners updatedCorners) {
    if (calibrationStage != PianoCalibrationStage.adjustingKeyboardArea) {
      return;
    }

    setState(() {
      keyboardAreaCorners = updatedCorners;
    });
  }

  /// Locks the quadrilateral and advances to the user C4-selection stage.
  void confirmKeyboardArea() {
    if (keyboardAreaCorners == null ||
        calibrationStage != PianoCalibrationStage.adjustingKeyboardArea) {
      return;
    }

    setState(() {
      referenceKeyPosition = null;
      referenceKeyMarkers = [];
      pianoKeyMarkers = [];
      pianoKeyRegions = [];
      whiteKeyAlignmentDetails = null;
      calibrationStage = PianoCalibrationStage.selectingReferenceKey;
    });
  }

  /// Returns from reference-key selection to corner adjustment.
  void adjustKeyboardAreaAgain() {
    if (keyboardAreaCorners == null ||
        calibrationStage != PianoCalibrationStage.selectingReferenceKey) {
      return;
    }

    setState(() {
      referenceKeyPosition = null;
      referenceKeyMarkers = [];
      pianoKeyMarkers = [];
      pianoKeyRegions = [];
      whiteKeyAlignmentDetails = null;
      calibrationStage = PianoCalibrationStage.adjustingKeyboardArea;
    });
  }

  /// Names, normalizes, and saves the completed key mapping to Firestore.
  ///
  /// Saving is allowed only when every marker has an outline, ensuring restored
  /// calibrations contain all geometry required by falling notes.
  Future<void> confirmMapping() async {
    if (isSavingCalibration) {
      return;
    }

    KeyboardAreaCorners? currentKeyboardAreaCorners = keyboardAreaCorners;

    if (calibrationStage != PianoCalibrationStage.selectingReferenceKey ||
        currentKeyboardAreaCorners == null ||
        referenceKeyPosition == null ||
        pianoKeyMarkers.isEmpty ||
        pianoKeyRegions.isEmpty ||
        pianoKeyMarkers.length != pianoKeyRegions.length) {
      return;
    }

    String? calibrationName = await askForCalibrationName();

    if (calibrationName == null || !mounted) {
      return;
    }

    setState(() {
      isSavingCalibration = true;
      calibrationSaveError = null;
    });

    try {
      NormalizedPianoCalibration newNormalizedCalibration =
          pianoCalibrationNormalizer.normalize(
            keyboardAreaCorners: currentKeyboardAreaCorners,
            pianoKeyMarkers: pianoKeyMarkers,
            pianoKeyRegions: pianoKeyRegions,
          );

      String documentId = await calibrationFirestoreService.saveCalibration(
        calibrationName: calibrationName,
        calibration: newNormalizedCalibration,
        existingDocumentId: savedCalibrationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        normalizedCalibration = newNormalizedCalibration;
        savedCalibrationId = documentId;
        savedCalibrationName = calibrationName;
        isSavingCalibration = false;
        loadedFromSavedCalibration = false;
        calibrationSaveError = null;
        calibrationStage = PianoCalibrationStage.mappingConfirmed;
      });
    } catch (error) {
      debugPrint('Calibration saving failed: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        normalizedCalibration = null;
        isSavingCalibration = false;
        calibrationSaveError =
            'Could not save the calibration. Check your connection and try again.';
      });
    }
  }

  /// Opens the validated naming dialog and returns `null` when cancelled.
  Future<String?> askForCalibrationName() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CalibrationNameDialog(initialName: savedCalibrationName);
      },
    );
  }

  /// Subscribes to held-note and note-on MIDI streams for AR evaluation.
  ///
  /// Performance Mode evaluates each attack against elapsed score time. Wait
  /// Mode also watches the complete held-note set so chords can be confirmed.
  void listenToMidiInput() {
    activeMidiNotesSubscription = midiInputService.activeNotesStream.listen((
      Set<int> notes,
    ) {
      if (!mounted || !isPracticeMode) {
        return;
      }

      setState(() {
        activeMidiNotes = Set<int>.from(notes);
      });

      tryCompleteWaitModeTarget(notes);
    });

    midiNoteOnSubscription = midiInputService.noteOnStream.listen((
      int midiNote,
    ) {
      if (!mounted || !isPracticeMode) {
        return;
      }

      if (!hasPracticePlaybackStarted ||
          isPracticePlaybackPaused ||
          isPracticePlaybackComplete) {
        return;
      }

      if (performanceModeEnabled) {
        bool feedbackChanged = practicePerformanceTracker
            .recordPerformanceNoteOn(
              midiNote,
              currentPracticeScoreElapsedMilliseconds(),
            );

        if (feedbackChanged) {
          setState(() {});
        }

        return;
      }

      if (isWaitingForCorrectNotes) {
        bool feedbackChanged = practicePerformanceTracker
            .recordWaitModeNoteOn(waitModeTargetGroupIndex, midiNote);

        waitModePressedNotes.add(midiNote);
        waitModeNotePressedAt[midiNote] = DateTime.now();

        if (feedbackChanged) {
          setState(() {});
        }

        tryCompleteWaitModeTarget(activeMidiNotes);
      }
    });
  }

  /// Discovers and connects the first available MIDI device.
  ///
  /// UI state is updated for searching/failure, and a success dialog confirms
  /// the connected device without leaving a large status card during playback.
  Future<void> connectToMidi() async {
    if (isConnectingMidi) {
      return;
    }

    setState(() {
      isConnectingMidi = true;
      midiConnectionStatus = 'Searching...';
    });

    try {
      final devices = await midiInputService.getDevices();

      if (!mounted) {
        return;
      }

      if (devices.isEmpty) {
        setState(() {
          isConnectingMidi = false;
          isMidiConnected = false;
          midiConnectionStatus = 'No device detected';
        });

        return;
      }

      final device = devices.first;

      setState(() {
        midiConnectionStatus = 'Connecting...';
      });

      await midiInputService.connectToDevice(device);

      if (!mounted) {
        return;
      }

      setState(() {
        isConnectingMidi = false;
        isMidiConnected = true;
        midiConnectionStatus = 'Connected: ${device.name}';
        activeMidiNotes = <int>{};
      });

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
            title: const Text('MIDI connected'),
            content: Text('${device.name} is ready to use.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      debugPrint('AR MIDI connection failed: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        isConnectingMidi = false;
        isMidiConnected = false;
        midiConnectionStatus = 'Connection failed';
      });
    }
  }

  /// Resets attempt state and starts falling notes from the four-second lead-in.
  void startPracticePlayback() {
    AnimationController? controller = fallingNotesAnimationController;

    if (!isMidiConnected || controller == null) {
      return;
    }

    resetWaitModeProgress();
    practicePerformanceTracker.resetAttempt();

    setState(() {
      hasPracticePlaybackStarted = true;
      isPracticePlaybackPaused = false;
      isPracticePlaybackComplete = false;
    });

    controller.forward(from: 0);
  }

  /// Converts animation position into score time by removing the lead-in.
  int currentPracticeScoreElapsedMilliseconds() {
    AnimationController? controller = fallingNotesAnimationController;
    Duration? animationDuration = controller?.duration;

    if (controller == null || animationDuration == null) {
      return 0;
    }

    int animationMilliseconds =
        (animationDuration.inMilliseconds * controller.value).round();
    int scoreMilliseconds =
        animationMilliseconds - fallingNoteApproachDuration.inMilliseconds;

    return scoreMilliseconds;
  }

  /// Pauses or resumes playback without bypassing an active Wait Mode gate.
  void togglePracticePlaybackPause() {
    AnimationController? controller = fallingNotesAnimationController;

    if (controller == null ||
        !hasPracticePlaybackStarted ||
        isPracticePlaybackComplete) {
      return;
    }

    if (isPracticePlaybackPaused) {
      setState(() {
        isPracticePlaybackPaused = false;
      });

      if (!isWaitingForCorrectNotes) {
        controller.forward();
      }

      return;
    }

    controller.stop();

    setState(() {
      isPracticePlaybackPaused = true;
    });
  }

  /// Clears evaluation/wait state and restarts the current score from the top.
  void restartPracticePlayback() {
    AnimationController? controller = fallingNotesAnimationController;

    if (controller == null || !isMidiConnected) {
      return;
    }

    resetWaitModeProgress();
    practicePerformanceTracker.resetAttempt();

    setState(() {
      hasPracticePlaybackStarted = true;
      isPracticePlaybackPaused = false;
      isPracticePlaybackComplete = false;
    });

    controller.forward(from: 0);
  }

  /// Explains and confirms switching between timed and wait-for-correct modes.
  ///
  /// A confirmed mode change resets playback because the two modes advance the
  /// animation and evaluate timing differently.
  Future<void> togglePracticePlaybackMode() async {
    bool switchingToWaitMode = performanceModeEnabled;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            switchingToWaitMode ? Icons.hourglass_empty : Icons.timer,
          ),
          title: Text(
            switchingToWaitMode
                ? 'Switch to Wait Mode?'
                : 'Switch to Performance Mode?',
          ),
          content: Text(
            switchingToWaitMode
                ? 'In Wait Mode, each falling note pauses at the hit line '
                      'until you play the correct key or chord. There is no '
                      'timing pressure.\n\nSwitching modes will reset the current '
                      'attempt.'
                : 'In Performance Mode, the falling notes continue moving '
                      'with the score timeline. Your notes are evaluated as '
                      'early, correct, late, or missed.\n\nSwitching modes will '
                      'reset the current attempt.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Switch mode'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    AnimationController? controller = fallingNotesAnimationController;

    controller?.stop();

    if (controller != null) {
      controller.value = 0;
    }

    resetWaitModeProgress();
    practicePerformanceTracker.resetAttempt();

    setState(() {
      performanceModeEnabled = !performanceModeEnabled;
      hasPracticePlaybackStarted = false;
      isPracticePlaybackPaused = false;
      isPracticePlaybackComplete = false;
    });
  }

  /// Evaluates due Performance groups or stops Wait Mode at its next hit time.
  ///
  /// Wait Mode rewinds to the exact target fraction before stopping, preventing
  /// a frame delay from drawing the target note below the hit line.
  void handlePracticeAnimationTick() {
    AnimationController? controller = fallingNotesAnimationController;

    if (controller == null ||
        !hasPracticePlaybackStarted ||
        isPracticePlaybackPaused ||
        isPracticePlaybackComplete) {
      return;
    }

    if (performanceModeEnabled) {
      bool stateChanged = practicePerformanceTracker.updatePerformanceTime(
        currentPracticeScoreElapsedMilliseconds(),
      );

      if (stateChanged && mounted) {
        setState(() {});
      }

      return;
    }

    if (isWaitingForCorrectNotes ||
        waitModeTargetGroupIndex >=
            practicePerformanceTracker.noteGroups.length) {
      return;
    }

    Duration? animationDuration = controller.duration;

    if (animationDuration == null || animationDuration.inMicroseconds <= 0) {
      return;
    }

    ArPracticeNoteGroup targetGroup =
        practicePerformanceTracker.noteGroups[waitModeTargetGroupIndex];
    int targetMicroseconds =
        fallingNoteApproachDuration.inMicroseconds +
        targetGroup.startTime.inMicroseconds;
    int currentMicroseconds =
        (animationDuration.inMicroseconds * controller.value).round();

    if (currentMicroseconds < targetMicroseconds) {
      return;
    }

    isWaitingForCorrectNotes = true;
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();
    controller.stop();
    controller.value =
        targetMicroseconds / animationDuration.inMicroseconds;

    if (mounted) {
      setState(() {});
    }
  }

  /// Advances Wait Mode once all newly required notes are pressed and held.
  ///
  /// Extra held notes are permitted because a note that began in a previous
  /// group may have a duration overlapping the current group. New wrong attacks
  /// are still recorded separately by the note-on subscription.
  void tryCompleteWaitModeTarget(Set<int> notes) {
    if (performanceModeEnabled ||
        !hasPracticePlaybackStarted ||
        !isWaitingForCorrectNotes ||
        waitModeTargetGroupIndex >=
            practicePerformanceTracker.noteGroups.length) {
      return;
    }

    ArPracticeNoteGroup targetGroup =
        practicePerformanceTracker.noteGroups[waitModeTargetGroupIndex];
    Set<int> expectedNotes = targetGroup.midiNotes;

    // Notes that started in an earlier group may still be held because their
    // score duration overlaps this group. They must not block the newly
    // required notes from completing the current Wait Mode step.
    bool heldNotesMatch = notes.containsAll(expectedNotes);
    bool expectedNotesWerePressed = expectedNotes.every(
      waitModePressedNotes.contains,
    );

    if (!heldNotesMatch || !expectedNotesWerePressed) {
      return;
    }

    if (!waitModeChordTimingMatches(expectedNotes)) {
      practicePerformanceTracker.recordWaitModeTimingMistake(
        waitModeTargetGroupIndex,
      );

      if (mounted) {
        setState(() {});
      }

      return;
    }

    practicePerformanceTracker.completeWaitModeGroup(
      waitModeTargetGroupIndex,
    );

    waitModeTargetGroupIndex++;
    isWaitingForCorrectNotes = false;
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();

    if (mounted) {
      setState(() {});
    }

    if (!isPracticePlaybackPaused) {
      fallingNotesAnimationController?.forward();
    }
  }

  /// Ensures the attacks of a multi-note chord occur within 200 milliseconds.
  bool waitModeChordTimingMatches(Set<int> expectedNotes) {
    if (expectedNotes.length <= 1) {
      return true;
    }

    List<DateTime> pressTimes = expectedNotes
        .map((int note) => waitModeNotePressedAt[note])
        .whereType<DateTime>()
        .toList();

    if (pressTimes.length != expectedNotes.length) {
      return false;
    }

    pressTimes.sort();

    return pressTimes.last.difference(pressTimes.first) <=
        const Duration(milliseconds: 200);
  }

  /// Clears the current Wait Mode gate, held attacks, and chord timestamps.
  void resetWaitModeProgress() {
    waitModeTargetGroupIndex = 0;
    isWaitingForCorrectNotes = false;
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();
  }

  /// Finalizes remaining score groups and schedules completion UI at playback end.
  void handlePracticePlaybackStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    if (performanceModeEnabled) {
      practicePerformanceTracker.finalizeRemainingPerformanceGroups();
    }

    setState(() {
      isPracticePlaybackPaused = false;
      isPracticePlaybackComplete = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showPracticeCompletionDialog();
      }
    });
  }

  /// Shows scrollable, local-only attempt statistics with retry and done actions.
  ///
  /// The guard prevents duplicate dialogs when multiple animation notifications
  /// are delivered near completion.
  Future<void> showPracticeCompletionDialog() async {
    if (isCompletionDialogShowing || !mounted) {
      return;
    }

    isCompletionDialogShowing = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.emoji_events, size: 42),
          title: const Text('Practice complete'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performanceModeEnabled ? 'Performance Mode' : 'Wait Mode',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Accuracy: '
                  '${practicePerformanceTracker.accuracyPercentage}%',
                ),
                Text(
                  'Correct: ${practicePerformanceTracker.correctGroupCount}',
                ),
                Text('Wrong: ${practicePerformanceTracker.wrongGroupCount}'),
                Text(
                  'Missed: ${practicePerformanceTracker.missedGroupCount}',
                ),
                Text(
                  'Mistakes: ${practicePerformanceTracker.mistakeCount}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                restartPracticePlayback();
              },
              child: const Text('Retry'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    isCompletionDialogShowing = false;
  }

  /// Reopens a new mapping for editing or fully redetects a loaded calibration.
  void editConfirmedMapping() {
    if (calibrationStage != PianoCalibrationStage.mappingConfirmed) {
      return;
    }

    if (loadedFromSavedCalibration) {
      detectKeyboardAgain();
      return;
    }

    setState(() {
      normalizedCalibration = null;
      calibrationSaveError = null;
      calibrationStage = PianoCalibrationStage.selectingReferenceKey;
    });
  }

  /// Leaves a newly saved calibration or prepares a loaded one for AR practice.
  ///
  /// Practice preparation validates score coverage, stops costly frame analysis,
  /// creates the falling-note controller, and loads the performance tracker.
  Future<void> finishCalibration() async {
    if (calibrationStage != PianoCalibrationStage.mappingConfirmed) {
      return;
    }

    if (loadedFromSavedCalibration) {
      ArScoreTimeline? timeline = widget.scoreTimeline;

      if (timeline == null || timeline.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The reference score is not ready.')),
        );

        return;
      }

      bool calibrationCoversScore = await validateScoreRange(timeline);

      if (!calibrationCoversScore || !mounted) {
        return;
      }

      await stopCameraImageProcessing();

      if (!mounted) {
        return;
      }

      fallingNotesAnimationController?.dispose();

      Duration completeAnimationDuration =
          fallingNoteApproachDuration + timeline.totalDuration;

      AnimationController newAnimationController = AnimationController(
        vsync: this,
        duration: completeAnimationDuration,
      );

      newAnimationController.addStatusListener(handlePracticePlaybackStatus);
      newAnimationController.addListener(handlePracticeAnimationTick);

      resetWaitModeProgress();
      practicePerformanceTracker.loadTimeline(timeline);

      setState(() {
        fallingNotesAnimationController = newAnimationController;
        isPracticeMode = true;
        activeMidiNotes = <int>{};
        hasPracticePlaybackStarted = false;
        isPracticePlaybackPaused = false;
        isPracticePlaybackComplete = false;
      });

      debugPrint('AR practice ready: ${timeline.noteCount} notes');

      return;
    }

    Navigator.of(context).pop();
  }

  /// Stops computer-vision frames while retaining the camera preview for AR.
  ///
  /// This substantially reduces CPU, heat, and battery usage during playback.
  Future<void> stopCameraImageProcessing() async {
    CameraController? currentCameraController = cameraController;

    if (currentCameraController == null ||
        !currentCameraController.value.isInitialized ||
        !currentCameraController.value.isStreamingImages) {
      return;
    }

    try {
      await currentCameraController.stopImageStream();
      debugPrint('Camera image processing stopped for AR practice.');
    } on CameraException catch (error) {
      debugPrint(
        'Could not stop the camera image stream: ${error.description}',
      );
    }
  }

  /// Verifies that every score MIDI pitch has a calibrated on-screen key.
  ///
  /// Missing pitches are listed in a dialog so falling notes are never silently
  /// omitted because their target coordinates do not exist.
  Future<bool> validateScoreRange(ArScoreTimeline timeline) async {
    Set<int> calibratedMidiNotes = {};

    for (PianoKeyMarker marker in pianoKeyMarkers) {
      int? midiNote = MidiNoteUtils.fromPianoKeyMarker(marker);

      if (midiNote != null) {
        calibratedMidiNotes.add(midiNote);
      }
    }

    Set<int> requiredMidiNotes = {
      for (final noteEvent in timeline.noteEvents) noteEvent.midiNote,
    };

    List<int> missingMidiNotes =
        requiredMidiNotes.difference(calibratedMidiNotes).toList()..sort();

    if (missingMidiNotes.isEmpty) {
      return true;
    }

    List<int> sortedRequiredNotes = requiredMidiNotes.toList()..sort();
    List<int> sortedCalibratedNotes = calibratedMidiNotes.toList()..sort();

    String requiredRange =
        '${MidiNoteUtils.nameForMidiNote(sortedRequiredNotes.first)}'
        '–${MidiNoteUtils.nameForMidiNote(sortedRequiredNotes.last)}';

    String calibrationRange = sortedCalibratedNotes.isEmpty
        ? 'no playable keys'
        : '${MidiNoteUtils.nameForMidiNote(sortedCalibratedNotes.first)}'
              '–${MidiNoteUtils.nameForMidiNote(sortedCalibratedNotes.last)}';

    const int maximumListedMissingNotes = 8;

    String missingNoteNames = missingMidiNotes
        .take(maximumListedMissingNotes)
        .map(MidiNoteUtils.nameForMidiNote)
        .join(', ');

    if (missingMidiNotes.length > maximumListedMissingNotes) {
      int remainingCount = missingMidiNotes.length - maximumListedMissingNotes;

      missingNoteNames = '$missingNoteNames, and $remainingCount more';
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.piano),
          title: const Text('Keyboard range too small'),
          content: Text(
            'This score requires $requiredRange, but this calibration covers '
            '$calibrationRange.\n\n'
            'Missing keys: $missingNoteNames\n\n'
            'Move the camera farther back and recalibrate, or select a '
            'calibration that covers the complete score.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Review calibration'),
            ),
          ],
        );
      },
    );

    return false;
  }

  /// Resets detection, geometry, practice, and scoring state for recalibration.
  void detectKeyboardAgain() {
    pianoKeyboardDetector.reset();
    fallingNotesAnimationController?.dispose();
    fallingNotesAnimationController = null;
    setState(() {
      referenceKeyMarkers = [];
      pianoKeyMarkers = [];
      pianoKeyRegions = [];
      detectedBlackKeyGroups = [];
      normalizedCalibration = null;
      loadedFromSavedCalibration = false;
      isRestoringSavedCalibration = false;
      isPracticeMode = false;
      activeMidiNotes = <int>{};
      practicePerformanceTracker.noteGroups =
          const <ArPracticeNoteGroup>[];
      practicePerformanceTracker.resetAttempt();
      resetWaitModeProgress();
      hasPracticePlaybackStarted = false;
      isPracticePlaybackPaused = false;
      isPracticePlaybackComplete = false;
      calibrationFrame = null;
      whiteKeyAlignmentDetails = null;
      keyboardAreaCorners = null;
      referenceKeyPosition = null;
      isPianoDetected = false;
      detectionGuidance = PianoDetectionGuidance.pointCameraAtKeyboard;
      detectionDetails = 'Candidates: 0 | Pattern: not found';
      lastCameraImageTime = null;
      calibrationStage = PianoCalibrationStage.detectingKeyboard;
    });
  }

  /// Treats the user's tap as C4 and derives every visible key and outline.
  ///
  /// White positions begin with geometric interpolation, optionally use detected
  /// seams, and then black markers/outlines are attached to the labeled octaves.
  void selectReferenceKey(Offset sourcePosition) {
    if (calibrationStage != PianoCalibrationStage.selectingReferenceKey) {
      return;
    }

    KeyboardAreaCorners? currentKeyboardAreaCorners = keyboardAreaCorners;

    if (currentKeyboardAreaCorners == null) {
      return;
    }

    List<ReferenceKeyMarker> derivedMarkers = referenceKeyDeriver
        .deriveVisibleCs(
          selectedC4Position: sourcePosition,
          blackKeyGroups: detectedBlackKeyGroups,
          keyboardAreaCorners: currentKeyboardAreaCorners,
        );

    List<PianoKeyMarker> derivedPianoKeys = whiteKeyPositionDeriver
        .deriveWhiteKeys(
          referenceCMarkers: derivedMarkers,
          blackKeyGroups: detectedBlackKeyGroups,
          keyboardAreaCorners: currentKeyboardAreaCorners,
        );

    CalibrationFrame? currentCalibrationFrame = calibrationFrame;
    List<PianoKeyMarker> finalPianoKeys = derivedPianoKeys;
    String newAlignmentDetails =
        'White-key seams unclear — using estimated centers';

    if (currentCalibrationFrame != null) {
      WhiteKeyBoundaryDetectionResult boundaryResult = whiteKeyBoundaryDetector
          .refineCenters(
            calibrationFrame: currentCalibrationFrame,
            keyboardAreaCorners: currentKeyboardAreaCorners,
            fallbackMarkers: derivedPianoKeys,
          );

      finalPianoKeys = boundaryResult.markers;

      if (boundaryResult.usedDetectedBoundaries) {
        newAlignmentDetails =
            'White-key seams: ${boundaryResult.detectedBoundaryCount}'
            '/${boundaryResult.requiredBoundaryCount}';
      }
    }

    BlackKeyDerivationResult blackKeyResult = blackKeyPositionDeriver
        .deriveBlackKeys(
          blackKeyGroups: detectedBlackKeyGroups,
          whiteKeyMarkers: finalPianoKeys,
          keyboardAreaCorners: currentKeyboardAreaCorners,
          calibrationFrame: currentCalibrationFrame,
        );

    List<PianoKeyMarker> allPianoKeys = [];

    allPianoKeys.addAll(finalPianoKeys);
    allPianoKeys.addAll(blackKeyResult.markers);

    List<PianoKeyRegion> derivedRegions = pianoKeyRegionDeriver.deriveRegions(
      pianoKeyMarkers: allPianoKeys,
      keyboardAreaCorners: currentKeyboardAreaCorners,
      detectedBlackKeyRegions: blackKeyResult.regions,
    );

    setState(() {
      referenceKeyPosition = sourcePosition;
      referenceKeyMarkers = derivedMarkers;
      pianoKeyMarkers = List<PianoKeyMarker>.unmodifiable(allPianoKeys);
      pianoKeyRegions = derivedRegions;
      whiteKeyAlignmentDetails = newAlignmentDetails;
    });
  }

  @override
  /// Releases animation, MIDI, orientation, and camera resources.
  void dispose() {
    fallingNotesAnimationController?.dispose();
    unawaited(disposeMidiInput());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    cameraController?.dispose();

    super.dispose();
  }

  /// Cancels both MIDI subscriptions before disposing the platform service.
  Future<void> disposeMidiInput() async {
    await activeMidiNotesSubscription?.cancel();
    await midiNoteOnSubscription?.cancel();
    await midiInputService.dispose();
  }
}
