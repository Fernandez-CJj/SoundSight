import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/practice_mode_toggle.dart';

import '../midi/models/midi_note_event.dart';
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
import 'models/middle_c_guide_result.dart';
import 'models/normalized_piano_calibration.dart';
import 'services/piano_calibration_normalizer.dart';
import 'services/piano_calibration_firestore_service.dart';
import 'services/middle_c_guide_service.dart';
import 'widgets/calibration_name_dialog.dart';
import 'models/restored_piano_calibration.dart';
import 'models/saved_piano_calibration.dart';
import 'services/piano_calibration_restorer.dart';
import '../players/ar/models/ar_score_timeline.dart';
import '../players/ar/models/ar_wait_note_occurrence.dart';
import '../players/ar/services/ar_practice_performance_tracker.dart';
import '../players/ar/utils/midi_note_utils.dart';
import '../players/ar/widgets/ar_falling_notes_overlay.dart';
import '../players/ar/number_notation_video_screen.dart';
import '../players/sight_reading/practice_result_models.dart';
import '../players/sight_reading/practice_result_service.dart';
import '../practice_result/practice_result_detail_screen.dart';

enum _MiddleCGuidePhase {
  inactive,
  waitingForKey,
  waitingForRelease,
  readyToTap,
}

enum _MidiUnavailableAction { retry, manual }

class _ArWaitHeldNoteState {
  _ArWaitHeldNoteState({
    required this.occurrence,
    required this.pressedAt,
    required this.noteDuration,
  });

  final ArWaitNoteOccurrence occurrence;
  Duration pressedAt;
  final Duration noteDuration;
  bool heldTooLong = false;

  int get midiNote {
    return occurrence.midiNote;
  }

  int get groupIndex {
    return occurrence.groupIndex;
  }
}

/// Camera-based piano calibration and AR practice screen.
///
/// With no [savedCalibration], the screen detects, labels, and saves a new
/// mapping. With a saved calibration and [scoreTimeline], it first allows the
/// user to review/recalibrate the mapping and then starts AR practice.
class PianoCalibrationScreen extends StatefulWidget {
  const PianoCalibrationScreen({
    super.key,
    required this.colors,
    this.savedCalibration,
    this.scoreTimeline,
    this.scoreDocumentPath = '',
  });

  final AppThemeColors colors;

  /// Existing mapping to restore instead of running initial detection.
  final SavedPianoCalibration? savedCalibration;

  /// Timed notes rendered after the user chooses to use a saved mapping.
  final ArScoreTimeline? scoreTimeline;

  /// Score source saved with completed AR Performance attempts.
  final String scoreDocumentPath;

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
  String detectionDetails = 'Looking for piano keys';
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
  final MiddleCGuideService middleCGuideService = const MiddleCGuideService();
  StreamSubscription<Set<int>>? activeMidiNotesSubscription;
  StreamSubscription<int>? midiNoteOnSubscription;
  StreamSubscription<MidiNoteEvent>? midiNoteEventSubscription;
  StreamSubscription<bool>? midiConnectionSubscription;
  Set<int> activeMidiNotes = <int>{};
  String midiConnectionStatus = 'Not connected';
  bool isConnectingMidi = false;
  bool isMidiConnected = false;
  _MiddleCGuidePhase _middleCGuidePhase = _MiddleCGuidePhase.inactive;
  MiddleCGuideResult? _middleCGuideResult;
  bool _middleCGuideRequested = false;
  bool hasPracticePlaybackStarted = false;
  bool isPracticePlaybackPaused = false;
  bool isPracticePlaybackComplete = false;
  bool isPracticeControlsSheetOpen = false;
  bool isMidiDisconnectDialogShowing = false;
  bool practiceInterruptedByMidiDisconnect = false;
  int practiceAttemptVersion = 0;
  bool performanceModeEnabled = true;
  final ArPracticePerformanceTracker practicePerformanceTracker =
      ArPracticePerformanceTracker(evaluateNoteDurations: true);
  final PracticeResultService practiceResultService = PracticeResultService();
  Timer? practiceFeedbackTimer;
  Timer? waitModeHoldTimer;
  int waitModeTargetGroupIndex = 0;
  bool isWaitingForCorrectNotes = false;
  bool waitModeSegmentInProgress = false;
  bool waitModeRetryAfterRelease = false;
  bool isCompletionDialogShowing = false;
  final Set<int> waitModePressedNotes = <int>{};
  final Stopwatch waitModeDurationClock = Stopwatch();
  Duration? waitModeSegmentStartedAt;
  Duration waitModeSegmentDuration = Duration.zero;
  int? waitModeSegmentOriginGroupIndex;
  int? waitModePendingRewindGroupIndex;
  int waitModeTimelinePreviewAdvanceMicroseconds = 0;
  Duration? waitModeHeldDurationPausedAt;
  final Set<ArWaitNoteOccurrence> waitModeDurationPausedOccurrences =
      <ArWaitNoteOccurrence>{};
  final Map<int, Duration> waitModeNotePressedAt = <int, Duration>{};
  final Map<ArWaitNoteOccurrence, _ArWaitHeldNoteState> waitModeHeldNotes =
      <ArWaitNoteOccurrence, _ArWaitHeldNoteState>{};
  final Map<ArWaitNoteOccurrence, double> waitModeHoldProgressByOccurrence =
      <ArWaitNoteOccurrence, double>{};
  final Set<ArWaitNoteOccurrence> waitModeHiddenCompletedNoteOccurrences =
      <ArWaitNoteOccurrence>{};
  final Set<int> waitModePassedGroupIndexes = <int>{};

  final Duration fallingNoteApproachDuration = const Duration(seconds: 4);
  final Duration waitModeOverholdTolerance = const Duration(milliseconds: 300);
  static const double waitModeMinimumHoldRatio = 0.9;

  @override
  /// Starts MIDI listeners, locks landscape orientation, and opens the camera.
  void initState() {
    super.initState();
    listenToMidiInput();
    practicePerformanceTracker.applySkillLevel('beginner');
    unawaited(loadArPerformanceDifficulty());
    SavedPianoCalibration? initialSavedCalibration = widget.savedCalibration;

    if (initialSavedCalibration != null) {
      normalizedCalibration = initialSavedCalibration.calibration;
      savedCalibrationId = initialSavedCalibration.documentId;
      savedCalibrationName = initialSavedCalibration.name;
      isRestoringSavedCalibration = true;
      detectionDetails = 'Loading your piano setup...';
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    initializeCamera();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        askForMiddleCHelpBeforeCalibration(
          forSavedAlignment: initialSavedCalibration != null,
        );
      }
    });
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
          if (!isPracticeMode)
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
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    tooltip: context.l10n.back,
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
    String statusText = context.l10n.searchingForPiano;
    String guidanceText = context.l10n.pointCameraAtKeyboard;
    IconData statusIcon = Icons.search;
    Color statusColor = Colors.black54;

    switch (detectionGuidance) {
      case PianoDetectionGuidance.pointCameraAtKeyboard:
        break;
      case PianoDetectionGuidance.moveFartherBack:
        statusText = context.l10n.moveFartherBack;
        guidanceText = context.l10n.makeMorePianoKeysVisible;
        statusIcon = Icons.zoom_out_map;
        statusColor = Colors.orange.shade800;
        break;
      case PianoDetectionGuidance.keepKeyboardClear:
        statusText = context.l10n.keepKeyboardClear;
        guidanceText = context.l10n.moveObjectsOutOfView;
        statusIcon = Icons.visibility;
        statusColor = Colors.amber.shade800;
        break;
      case PianoDetectionGuidance.holdPhoneSteady:
        statusText = context.l10n.holdPhoneSteady;
        guidanceText = context.l10n.keepCameraStill;
        statusIcon = Icons.center_focus_strong;
        statusColor = Colors.blueGrey.shade700;
        break;
      case PianoDetectionGuidance.pianoDetected:
        statusText = context.l10n.pianoDetected;
        guidanceText = context.l10n.visibleKeyboardReady;
        statusIcon = Icons.check_circle;
        statusColor = Colors.green.shade700;
        break;
    }

    if (calibrationStage == PianoCalibrationStage.adjustingKeyboardArea) {
      statusText = context.l10n.checkVisibleKeys;
      guidanceText = context.l10n.dragCornersAroundKeys;
      statusIcon = Icons.open_with;
      statusColor = Colors.teal.shade700;
    }

    if (calibrationStage == PianoCalibrationStage.selectingReferenceKey) {
      if (referenceKeyPosition == null) {
        if (_middleCGuidePhase == _MiddleCGuidePhase.inactive) {
          statusText = context.l10n.selectMiddleC;
          guidanceText = context.l10n.tapMiddleCInCamera;
          statusIcon = Icons.music_note;
          statusColor = Colors.indigo.shade700;
        } else if (!isMidiConnected) {
          statusText = isConnectingMidi
              ? context.l10n.connectingToPiano
              : context.l10n.pianoConnectionNeeded;
          guidanceText = isConnectingMidi
              ? context.l10n.searchingAvailableKeyboard
              : context.l10n.reconnectOrUseManualGuide(midiConnectionStatus);
          statusIcon = isConnectingMidi ? Icons.usb : Icons.usb_off;
          statusColor = Colors.orange.shade800;
        } else if (_middleCGuidePhase == _MiddleCGuidePhase.waitingForRelease) {
          statusText = context.l10n.middleCFound;
          guidanceText = context.l10n.releaseMiddleCToContinue;
          statusIcon = Icons.check_circle;
          statusColor = Colors.green.shade700;
        } else if (_middleCGuidePhase == _MiddleCGuidePhase.readyToTap) {
          statusText = context.l10n.middleCFound;
          guidanceText = context.l10n.tapSameKeyInCamera;
          statusIcon = Icons.touch_app;
          statusColor = Colors.green.shade700;
        } else {
          MiddleCGuideResult? result = _middleCGuideResult;
          statusText = context.l10n.findMiddleC;
          statusIcon = Icons.piano;
          statusColor = Colors.indigo.shade700;

          if (result == null) {
            guidanceText = context.l10n.pressWhiteKeyNearCenter;
          } else if (result.type == MiddleCGuideResultType.blackKey) {
            guidanceText = context.l10n.blackKeyPressed;
          } else if (result.type == MiddleCGuideResultType.moveLeft ||
              result.type == MiddleCGuideResultType.moveRight) {
            String direction = result.type == MiddleCGuideResultType.moveLeft
                ? context.l10n.left
                : context.l10n.right;
            guidanceText = context.l10n.moveWhiteKeys(
              result.whiteKeyDistance,
              direction,
            );
          } else {
            guidanceText = context.l10n.pressWhiteKeyNearCenter;
          }
        }
      } else if (referenceKeyMarkers.length > 1) {
        statusText = context.l10n.pianoKeysReady;
        guidanceText = context.l10n.checkKeyLabels;

        statusIcon = Icons.check_circle;
        statusColor = Colors.indigo.shade700;
      } else {
        statusText = context.l10n.middleCSelected;
        guidanceText = context.l10n.moveBackForMoreKeys;
        statusIcon = Icons.warning_amber;
        statusColor = Colors.orange.shade800;
      }
    }

    if (calibrationStage == PianoCalibrationStage.aligningSavedCalibration) {
      statusIcon = Icons.center_focus_strong;
      statusColor = Colors.black54;

      if (_middleCGuidePhase != _MiddleCGuidePhase.inactive &&
          !isMidiConnected) {
        statusText = isConnectingMidi
            ? context.l10n.connectingToDigitalPiano
            : context.l10n.digitalPianoNotConnected;
        guidanceText = isConnectingMidi
            ? context.l10n.searchingAvailableKeyboard
            : context.l10n.connectPianoOrUseManualGuide;
        statusIcon = isConnectingMidi ? Icons.usb : Icons.usb_off;
        statusColor = Colors.orange.shade800;
      } else if (_middleCGuidePhase == _MiddleCGuidePhase.waitingForRelease) {
        statusText = context.l10n.middleCFound;
        guidanceText = context.l10n.releaseMiddleCThenAlign;
        statusIcon = Icons.check_circle;
        statusColor = Colors.green.shade700;
      } else if (_middleCGuidePhase == _MiddleCGuidePhase.readyToTap) {
        statusText = context.l10n.useMiddleCAsGuide;
        guidanceText = context.l10n.alignSavedC4Shape;
        statusIcon = Icons.center_focus_strong;
        statusColor = Colors.green.shade700;
      } else if (_middleCGuidePhase == _MiddleCGuidePhase.waitingForKey) {
        MiddleCGuideResult? result = _middleCGuideResult;
        statusText = context.l10n.findMiddleC;
        statusIcon = Icons.piano;

        if (result == null) {
          guidanceText = context.l10n.pressWhiteKeyNearCenter;
        } else if (result.type == MiddleCGuideResultType.blackKey) {
          guidanceText = context.l10n.blackKeyPressed;
        } else if (result.type == MiddleCGuideResultType.moveLeft ||
            result.type == MiddleCGuideResultType.moveRight) {
          String direction = result.type == MiddleCGuideResultType.moveLeft
              ? context.l10n.left
              : context.l10n.right;
          guidanceText = context.l10n.moveWhiteKeys(
            result.whiteKeyDistance,
            direction,
          );
        } else {
          guidanceText = context.l10n.pressWhiteKeyNearCenter;
        }
      } else {
        statusText = context.l10n.alignPianoSetup;
        guidanceText = context.l10n.matchSavedShapes;
      }
    }

    if (calibrationStage == PianoCalibrationStage.mappingConfirmed) {
      NormalizedPianoCalibration? currentCalibration = normalizedCalibration;

      statusText = loadedFromSavedCalibration
          ? context.l10n.pianoSetupLoaded
          : context.l10n.pianoSetupSaved;
      statusIcon = Icons.cloud_done;
      statusColor = Colors.green.shade700;

      if (currentCalibration == null) {
        guidanceText = context.l10n.pianoSetupPreparationFailed;
      } else {
        String calibrationName =
            savedCalibrationName ?? context.l10n.pianoSetupDefaultName;
        guidanceText = context.l10n.pianoSetupReady(calibrationName);
      }
    }

    if (isSavingCalibration) {
      statusText = context.l10n.savingPianoSetup;
      guidanceText = context.l10n.keepOpenWhileSavingSetup;
      statusIcon = Icons.cloud_upload;
      statusColor = Colors.blue.shade700;
    }

    if (calibrationSaveError != null &&
        calibrationStage == PianoCalibrationStage.selectingReferenceKey) {
      statusText = context.l10n.pianoSetupNotSaved;
      guidanceText = calibrationSaveError!;
      statusIcon = Icons.cloud_off;
      statusColor = Colors.red.shade700;
    }

    if (isRestoringSavedCalibration) {
      statusText = context.l10n.loadingPianoSetup;
      guidanceText = context.l10n.preparingSavedPianoKeys;
      statusIcon = Icons.cloud_download;
      statusColor = Colors.blue.shade700;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 8, 64, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusText,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  guidanceText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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

    if (calibrationStage == PianoCalibrationStage.aligningSavedCalibration) {
      highlightedMarkerNames.add('C4');
    }

    if (currentKeyboardAreaCorners != null) {
      KeyboardAreaCorners detectedCorners = currentKeyboardAreaCorners;
      bool isSavedAlignment =
          calibrationStage == PianoCalibrationStage.aligningSavedCalibration;

      keyboardOverlay = Opacity(
        opacity: isSavedAlignment ? 0.62 : 1,
        child: KeyboardAreaOverlay(
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
              !isSavingCalibration &&
              (_middleCGuidePhase == _MiddleCGuidePhase.inactive ||
                  _middleCGuidePhase == _MiddleCGuidePhase.readyToTap),
          onCornersChanged: updateKeyboardAreaCorners,
          onReferenceSelected: handleReferenceTap,
        ),
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
              waitModePreviewOriginStartMicroseconds:
                  !performanceModeEnabled &&
                      waitModeSegmentInProgress &&
                      waitModeSegmentOriginGroupIndex != null
                  ? practicePerformanceTracker
                        .noteGroups[waitModeSegmentOriginGroupIndex!]
                        .startTime
                        .inMicroseconds
                  : null,
              waitModeHoldProgressByOccurrence:
                  Map<ArWaitNoteOccurrence, double>.unmodifiable(
                    waitModeHoldProgressByOccurrence,
                  ),
              waitModeTimelinePreviewAdvanceMicroseconds:
                  waitModeTimelinePreviewAdvanceMicroseconds,
              hiddenGroupStartMicroseconds: performanceModeEnabled
                  ? practicePerformanceTracker.finalizedGroupStartMicroseconds
                  : const <int>{},
              hiddenWaitModeNoteOccurrences: performanceModeEnabled
                  ? const <ArWaitNoteOccurrence>{}
                  : Set<ArWaitNoteOccurrence>.unmodifiable(
                      waitModeHiddenCompletedNoteOccurrences,
                    ),
            ),
          ?keyboardOverlay,
        ],
      ),
    );
  }

  /// Mirrors Synthesia's setup and active-practice app bar states.
  Widget buildPracticeControls() {
    AnimationController? currentAnimationController =
        fallingNotesAnimationController;

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.colors.backgroundColor.withValues(alpha: 0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: widget.colors.borderColor.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: currentAnimationController == null
                      ? buildPracticeAppBar()
                      : AnimatedBuilder(
                          animation: currentAnimationController,
                          builder: (BuildContext context, Widget? child) {
                            return buildPracticeAppBar();
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
        if (hasPracticePlaybackStarted && !isPracticePlaybackComplete)
          buildPracticeFeedbackOverlay(),
        if (!hasPracticePlaybackStarted)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 76),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 220,
                    maxWidth: 320,
                    minHeight: 46,
                  ),
                  child: isMidiConnected
                      ? FilledButton.icon(
                          onPressed: currentAnimationController == null
                              ? null
                              : choosePracticeDisplayMode,
                          style: practicePrimaryButtonStyle(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            performanceModeEnabled
                                ? context.l10n.synthesiaStartPerformance
                                : context.l10n.synthesiaStartWaitMode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: isConnectingMidi
                              ? null
                              : () {
                                  unawaited(connectToMidi());
                                },
                          style: practiceSecondaryButtonStyle(),
                          icon: isConnectingMidi
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.usb_rounded),
                          label: Text(
                            isConnectingMidi
                                ? context.l10n.connecting
                                : context.l10n.arPracticeConnectMidiPiano,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildPracticeAppBar() {
    AppThemeColors colors = widget.colors;
    int totalGroups = practicePerformanceTracker.totalGroupCount;
    int completedGroups = practicePerformanceTracker.evaluatedGroupCount;
    double progress = totalGroups > 0
        ? (completedGroups / totalGroups).clamp(0.0, 1.0).toDouble()
        : 0;
    int percentage = (progress * 100).round();
    double screenWidth = MediaQuery.sizeOf(context).width;
    bool showTitle = screenWidth >= 700;
    bool showProgress = screenWidth >= 620;
    bool isRunning = hasPracticePlaybackStarted && !isPracticePlaybackComplete;
    var feedback = practiceFeedbackAppearance();

    if (isRunning) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: context.l10n.back,
                color: colors.primaryColor,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.52,
              child: buildPracticeBarProgress(
                colors: colors,
                completedGroups: completedGroups,
                totalGroups: totalGroups,
                progress: progress,
                percentage: percentage,
                centerLabel: true,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: buildPracticeControlsButton(compact: screenWidth < 760),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: context.l10n.back,
            color: colors.primaryColor,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          if (showTitle) ...[
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 132,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.arPractice,
                    maxLines: 1,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.body,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.scoreTimeline?.pieceTitle ??
                          context.l10n.arPracticePianoPractice,
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          PracticeModeToggle<bool>(
            firstValue: false,
            firstLabel: context.l10n.synthesiaWait,
            secondValue: true,
            secondLabel: context.l10n.synthesiaPerformance,
            selectedValue: performanceModeEnabled,
            colors: colors,
            onChanged: hasPracticePlaybackStarted
                ? null
                : (selectedPerformance) {
                    if (selectedPerformance != performanceModeEnabled) {
                      unawaited(togglePracticePlaybackMode());
                    }
                  },
          ),
          const SizedBox(width: AppSpacing.sm),
          if (showProgress)
            Expanded(
              child: buildPracticeBarProgress(
                colors: colors,
                completedGroups: completedGroups,
                totalGroups: totalGroups,
                progress: progress,
                percentage: percentage,
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: AppSpacing.sm),
          Tooltip(
            message: feedback.text,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: feedback.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                feedback.icon,
                color: feedback.color,
                size: AppIconSizes.sm,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          buildPracticeControlsButton(compact: screenWidth < 760),
        ],
      ),
    );
  }

  Widget buildPracticeControlsButton({required bool compact}) {
    AppThemeColors colors = widget.colors;

    if (compact) {
      return Tooltip(
        message: context.l10n.synthesiaControls,
        child: IconButton.outlined(
          onPressed: () {
            unawaited(showPracticeControlsSheet());
          },
          color: colors.primaryColor,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.tune_rounded, size: 18),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () {
        unawaited(showPracticeControlsSheet());
      },
      style: practiceSecondaryButtonStyle().copyWith(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
      ),
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: Text(context.l10n.synthesiaControls),
    );
  }

  Widget buildPracticeBarProgress({
    required AppThemeColors colors,
    required int completedGroups,
    required int totalGroups,
    required double progress,
    required int percentage,
    bool centerLabel = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: centerLabel
              ? Alignment.center
              : Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: centerLabel
                ? Alignment.center
                : Alignment.centerLeft,
            child: Text(
              '$completedGroups / $totalGroups · $percentage%',
              maxLines: 1,
              textAlign: centerLabel ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: colors.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget buildPracticeFeedbackOverlay() {
    var feedback = practiceFeedbackAppearance();
    String playedNotes = activeMidiNotes.isEmpty
        ? context.l10n.synthesiaNone
        : formatMidiNoteNames(activeMidiNotes);

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 52 + AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Center(
        child: IgnorePointer(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: feedback.color.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(feedback.icon, color: feedback.color, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    context.l10n.synthesiaPlayedNotes(
                      feedback.text,
                      playedNotes,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({String text, IconData icon, Color color}) practiceFeedbackAppearance() {
    AppThemeColors colors = widget.colors;

    if (isPracticePlaybackComplete) {
      return (
        text: context.l10n.synthesiaCompleted,
        icon: Icons.check_circle_rounded,
        color: Colors.green.shade600,
      );
    }

    if (!hasPracticePlaybackStarted) {
      return (
        text: isMidiConnected
            ? context.l10n.synthesiaReady
            : localizedArConnectionStatus(midiConnectionStatus),
        icon: isMidiConnected
            ? Icons.radio_button_checked_rounded
            : Icons.usb_off_rounded,
        color: isMidiConnected
            ? colors.secondaryTextColor
            : Colors.amber.shade700,
      );
    }

    if (practicePerformanceTracker.feedbackKind !=
        ArPracticeFeedbackKind.neutral) {
      return switch (practicePerformanceTracker.feedbackKind) {
        ArPracticeFeedbackKind.correct => (
          text: localizedArFeedback(
            practicePerformanceTracker.feedbackText,
          ),
          icon: Icons.check_circle_outline_rounded,
          color: Colors.green.shade600,
        ),
        ArPracticeFeedbackKind.warning => (
          text: localizedArFeedback(
            practicePerformanceTracker.feedbackText,
          ),
          icon: Icons.schedule_rounded,
          color: Colors.amber.shade700,
        ),
        ArPracticeFeedbackKind.incorrect => (
          text: localizedArFeedback(
            practicePerformanceTracker.feedbackText,
          ),
          icon: Icons.error_outline_rounded,
          color: Colors.red.shade600,
        ),
        ArPracticeFeedbackKind.neutral => (
          text: context.l10n.synthesiaFollowFallingNotes,
          icon: Icons.music_note_rounded,
          color: colors.secondaryTextColor,
        ),
      };
    }

    if (isWaitingForCorrectNotes) {
      return (
        text: context.l10n.synthesiaPlayHighlightedNoteOrChord,
        icon: Icons.piano_rounded,
        color: colors.primaryColor,
      );
    }

    return (
      text: context.l10n.synthesiaFollowFallingNotes,
      icon: Icons.music_note_rounded,
      color: colors.secondaryTextColor,
    );
  }

  String localizedArFeedback(String feedback) {
    return switch (feedback) {
      'Ready' => context.l10n.synthesiaReady,
      'No notes available' => context.l10n.synthesiaNoNotesAvailable,
      'Too early' => context.l10n.synthesiaTooEarly,
      'Too late' => context.l10n.synthesiaTooLate,
      'Wrong note' => context.l10n.synthesiaWrongNote,
      'Complete the chord' => context.l10n.synthesiaCompleteChord,
      'Chord notes were not together' =>
        context.l10n.synthesiaChordNotesNotTogether,
      'Correct notes — keep holding' =>
        context.l10n.sightReadingCorrectNotesKeepHolding,
      'Correct after mistake' => context.l10n.synthesiaCorrectAfterMistake,
      'Correct' => context.l10n.synthesiaCorrect,
      'Released too soon' => context.l10n.synthesiaReleasedTooSoon,
      'Duration complete' => context.l10n.synthesiaDurationComplete,
      'Timing missed' => context.l10n.synthesiaTimingMissed,
      'Wrong' => context.l10n.synthesiaWrong,
      'Missed' => context.l10n.synthesiaMissed,
      _ => feedback,
    };
  }

  String localizedArConnectionStatus(String status) {
    return switch (status) {
      'Not connected' => context.l10n.sightReadingNotConnected,
      'Searching' => context.l10n.searching,
      'Connecting' => context.l10n.connecting,
      'Connection failed' => context.l10n.connectionFailed,
      _ => status,
    };
  }

  ButtonStyle practicePrimaryButtonStyle() {
    AppThemeColors colors = widget.colors;

    return FilledButton.styleFrom(
      backgroundColor: colors.primaryColor,
      foregroundColor: colors.backgroundColor,
      disabledBackgroundColor: colors.borderColor,
      disabledForegroundColor: colors.secondaryTextColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }

  ButtonStyle practiceSecondaryButtonStyle() {
    AppThemeColors colors = widget.colors;

    return OutlinedButton.styleFrom(
      foregroundColor: colors.primaryColor,
      disabledForegroundColor: colors.secondaryTextColor,
      side: BorderSide(color: colors.borderColor),
      backgroundColor: colors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }

  Future<void> showPracticeControlsSheet() async {
    if (!mounted || isPracticeControlsSheetOpen) {
      return;
    }

    isPracticeControlsSheetOpen = true;
    AppThemeColors colors = widget.colors;

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        enableDrag: false,
        isScrollControlled: true,
        builder: (BuildContext sheetContext) {
          return StatefulBuilder(
            builder: (BuildContext sheetContext, StateSetter refreshControls) {
              bool attemptIsRunning =
                  hasPracticePlaybackStarted && !isPracticePlaybackComplete;
              bool canStart =
                  !attemptIsRunning &&
                  !isPracticePlaybackComplete &&
                  isMidiConnected &&
                  fallingNotesAnimationController != null;
              bool canStop =
                  attemptIsRunning &&
                  isMidiConnected &&
                  fallingNotesAnimationController != null;
              var feedback = practiceFeedbackAppearance();

              Future<void> connectFromControls() async {
                Future<bool> connection = connectToMidi(
                  showSuccessDialog: false,
                );
                refreshControls(() {});
                await connection;

                if (sheetContext.mounted) {
                  refreshControls(() {});
                }
              }

              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: colors.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: feedback.color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                feedback.icon,
                                color: feedback.color,
                                size: AppIconSizes.sm,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feedback.text,
                                    style: TextStyle(
                                      color: colors.primaryColor,
                                      fontSize: AppTextSizes.label,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    performanceModeEnabled
                                        ? context.l10n
                                              .sightReadingPerformanceMode
                                        : context.l10n.sightReadingWaitMode,
                                    style: TextStyle(
                                      color: colors.secondaryTextColor,
                                      fontSize: AppTextSizes.caption,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 190),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: colors.backgroundColor,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMidiConnected
                                        ? Icons.usb_rounded
                                        : Icons.usb_off_rounded,
                                    color: colors.primaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      isMidiConnected
                                          ? localizedArConnectionStatus(
                                              midiConnectionStatus,
                                            )
                                          : context.l10n.synthesiaMidiOffline,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.primaryColor,
                                        fontSize: AppTextSizes.caption,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              tooltip: context.l10n.synthesiaCloseControls,
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                              },
                              color: colors.primaryColor,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if (attemptIsRunning) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: colors.backgroundColor,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: Text(
                              context.l10n.arPracticeStopWarning,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.secondaryTextColor,
                                fontSize: AppTextSizes.caption,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isConnectingMidi || isMidiConnected
                                    ? null
                                    : () {
                                        unawaited(connectFromControls());
                                      },
                                style: practiceSecondaryButtonStyle(),
                                icon: isConnectingMidi
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        isMidiConnected
                                            ? Icons.usb_rounded
                                            : Icons.usb_off_rounded,
                                      ),
                                label: Text(
                                  isConnectingMidi
                                      ? context.l10n.connecting
                                      : isMidiConnected
                                      ? context.l10n.synthesiaConnected
                                      : context.l10n.synthesiaConnectMidi,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: attemptIsRunning
                                  ? OutlinedButton.icon(
                                      onPressed: canStop
                                          ? () {
                                              Navigator.of(sheetContext).pop();
                                              preparePracticeRetry();
                                            }
                                          : null,
                                      style: practiceSecondaryButtonStyle(),
                                      icon: const Icon(Icons.stop_rounded),
                                      label: Text(context.l10n.stop),
                                    )
                                  : FilledButton.icon(
                                      onPressed: canStart
                                          ? () {
                                              Navigator.of(sheetContext).pop();
                                              unawaited(
                                                choosePracticeDisplayMode(),
                                              );
                                            }
                                          : null,
                                      style: practicePrimaryButtonStyle(),
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                      ),
                                      label: Text(
                                        performanceModeEnabled
                                            ? context.l10n
                                                  .synthesiaStartPerformance
                                            : context.l10n
                                                  .synthesiaStartWaitMode,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      isPracticeControlsSheetOpen = false;
    }
  }

  /// Lets the user choose the visual notation shown during AR practice.
  Future<void> choosePracticeDisplayMode() async {
    String? selectedMode = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        AppThemeColors colors = widget.colors;

        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: buildCalibrationDialogIcon(Icons.visibility_outlined),
          title: Text(
            context.l10n.arPracticeChooseNotation,
            textAlign: TextAlign.center,
            style: calibrationDialogTitleStyle(),
          ),
          content: Text(
            context.l10n.arPracticeChooseNotationDescription,
            textAlign: TextAlign.center,
            style: calibrationDialogBodyStyle(),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            buildCalibrationDialogActions(
              secondaryLabel: context.l10n.arPracticeNotes,
              onSecondary: () {
                Navigator.of(dialogContext).pop('notes');
              },
              primaryLabel: context.l10n.arPracticeNumberNotation,
              onPrimary: () {
                Navigator.of(dialogContext).pop('numbers');
              },
            ),
          ],
        );
      },
    );

    if (!mounted || selectedMode == null) {
      return;
    }

    if (selectedMode == 'notes') {
      startPracticePlayback();
    } else if (selectedMode == 'numbers') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NumberNotationVideoScreen(),
        ),
      );
    }
  }

  /// Hides successful-note feedback after it has been visible briefly.
  void schedulePracticeFeedbackDismissal() {
    practiceFeedbackTimer?.cancel();

    if (practicePerformanceTracker.feedbackKind !=
            ArPracticeFeedbackKind.correct ||
        practicePerformanceTracker.feedbackText.contains('keep holding')) {
      return;
    }

    practiceFeedbackTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted ||
          practicePerformanceTracker.feedbackKind !=
              ArPracticeFeedbackKind.correct) {
        return;
      }

      setState(() {
        practicePerformanceTracker.clearImmediateFeedback();
      });
    });
  }

  /// Formats technical candidate/group/stability details for calibration review.
  String buildDetectionDetails(PianoDetectionResult detectionResult) {
    if (detectionResult.isStable) {
      return 'Piano keys found';
    }

    if (detectionResult.groupSizes.isNotEmpty) {
      return 'Hold the phone steady';
    }

    return 'Looking for piano keys';
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
          detectionDetails = 'Could not see the piano keys clearly';
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

      pianoKeyboardDetector.reset();

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
        whiteKeyAlignmentDetails = 'Saved piano setup loaded';

        isPianoDetected = true;
        loadedFromSavedCalibration = true;
        detectionGuidance = PianoDetectionGuidance.pianoDetected;
        detectionDetails = 'Saved piano setup loaded';
        lastCameraImageTime = null;
        calibrationStage = PianoCalibrationStage.aligningSavedCalibration;
      });
    } catch (error) {
      debugPrint('Calibration restoration failed: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        normalizedCalibration = null;
        loadedFromSavedCalibration = false;
        detectionDetails = 'Could not load the saved piano setup';
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
            cameraError = context.l10n.noRearCameraAvailable;
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
    } on CameraException catch (_) {
      await newCameraController?.dispose();

      if (mounted) {
        setState(() {
          cameraError = context.l10n.calibrationCameraOpenFailed;
        });
      }
    }
  }

  /// Builds stage-specific actions for area adjustment, mapping, and completion.
  Widget buildCalibrationControls() {
    if (calibrationStage == PianoCalibrationStage.aligningSavedCalibration) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: detectKeyboardAgain,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    context.l10n.recalibrate,
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
                if (_middleCGuidePhase == _MiddleCGuidePhase.inactive)
                  FilledButton.icon(
                    onPressed: startMiddleCGuide,
                    icon: const Icon(Icons.usb),
                    label: Text(
                      context.l10n.useMidiGuide,
                      textAlign: TextAlign.center,
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigo.shade700,
                    ),
                  ),
                if (_middleCGuidePhase != _MiddleCGuidePhase.inactive &&
                    !isMidiConnected)
                  FilledButton.icon(
                    onPressed: isConnectingMidi
                        ? null
                        : retryMiddleCGuideConnection,
                    icon: isConnectingMidi
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.usb),
                    label: Text(
                      isConnectingMidi
                          ? context.l10n.connecting
                          : context.l10n.retry,
                      textAlign: TextAlign.center,
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigo.shade700,
                    ),
                  ),
                if (_middleCGuidePhase != _MiddleCGuidePhase.inactive)
                  OutlinedButton.icon(
                    onPressed: useManualC4Guide,
                    icon: const Icon(Icons.piano),
                    label: Text(
                      context.l10n.useManualGuide,
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.white70),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: useAlignedSavedCalibration,
                  icon: const Icon(Icons.check),
                  label: Text(
                    context.l10n.continueAction,
                    textAlign: TextAlign.center,
                  ),
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

    if (calibrationStage == PianoCalibrationStage.selectingReferenceKey) {
      bool mappingIsReady =
          referenceKeyPosition != null && pianoKeyRegions.isNotEmpty;

      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isSavingCalibration
                      ? null
                      : adjustKeyboardAreaAgain,
                  icon: const Icon(Icons.open_with),
                  label: Text(
                    context.l10n.adjustVisibleKeys,
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
                if (!mappingIsReady &&
                    _middleCGuidePhase == _MiddleCGuidePhase.inactive)
                  FilledButton.icon(
                    onPressed: isSavingCalibration ? null : startMiddleCGuide,
                    icon: const Icon(Icons.usb),
                    label: Text(
                      context.l10n.useMidiGuide,
                      textAlign: TextAlign.center,
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigo.shade700,
                    ),
                  ),
                if (!mappingIsReady &&
                    _middleCGuidePhase != _MiddleCGuidePhase.inactive &&
                    !isMidiConnected)
                  FilledButton.icon(
                    onPressed: isConnectingMidi
                        ? null
                        : retryMiddleCGuideConnection,
                    icon: isConnectingMidi
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.usb),
                    label: Text(
                      isConnectingMidi
                          ? context.l10n.connecting
                          : context.l10n.retry,
                      textAlign: TextAlign.center,
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigo.shade700,
                    ),
                  ),
                if (!mappingIsReady &&
                    _middleCGuidePhase != _MiddleCGuidePhase.inactive)
                  OutlinedButton.icon(
                    onPressed: isSavingCalibration ? null : useManualC4Guide,
                    icon: const Icon(Icons.piano),
                    label: Text(
                      context.l10n.useManualGuide,
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.white70),
                    ),
                  ),
                if (mappingIsReady)
                  FilledButton.icon(
                    onPressed: isSavingCalibration ? null : confirmMapping,
                    icon: Icon(
                      isSavingCalibration ? Icons.cloud_upload : Icons.check,
                    ),
                    label: Text(
                      isSavingCalibration
                          ? context.l10n.saving
                          : context.l10n.savePianoSetup,
                      textAlign: TextAlign.center,
                    ),
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

    if (calibrationStage == PianoCalibrationStage.mappingConfirmed) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isSavingCalibration ? null : editConfirmedMapping,
                  icon: Icon(
                    widget.savedCalibration != null
                        ? Icons.refresh
                        : Icons.edit,
                  ),
                  label: Text(
                    widget.savedCalibration != null
                        ? context.l10n.setUpAgain
                        : context.l10n.makeChanges,
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
                FilledButton.icon(
                  onPressed: finishCalibration,
                  icon: const Icon(Icons.check),
                  label: Text(
                    loadedFromSavedCalibration
                        ? context.l10n.useAction
                        : context.l10n.done,
                    textAlign: TextAlign.center,
                  ),
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
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: detectKeyboardAgain,
                icon: const Icon(Icons.refresh),
                label: Text(
                  context.l10n.tryAgain,
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black54,
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
              FilledButton.icon(
                onPressed: confirmKeyboardArea,
                icon: const Icon(Icons.check),
                label: Text(
                  context.l10n.keysAreVisible,
                  textAlign: TextAlign.center,
                ),
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
      if (_middleCGuideRequested) {
        _middleCGuidePhase = _MiddleCGuidePhase.waitingForKey;
        _middleCGuideResult = null;
      } else {
        resetMiddleCGuide();
      }
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
      resetMiddleCGuide();
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
        calibrationSaveError = context.l10n.pianoSetupSaveFailed;
      });
    }
  }

  /// Opens the validated naming dialog and returns `null` when cancelled.
  Future<String?> askForCalibrationName() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CalibrationNameDialog(
          colors: widget.colors,
          initialName: savedCalibrationName,
        );
      },
    );
  }

  /// Builds the icon treatment shared by calibration and practice dialogs.
  Widget buildCalibrationDialogIcon(IconData icon) {
    AppThemeColors colors = widget.colors;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderColor),
      ),
      child: Icon(icon, color: colors.primaryColor, size: AppIconSizes.lg),
    );
  }

  TextStyle calibrationDialogTitleStyle() {
    return TextStyle(
      color: widget.colors.primaryColor,
      fontSize: AppTextSizes.sectionTitle,
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle calibrationDialogBodyStyle() {
    return TextStyle(
      color: widget.colors.secondaryTextColor,
      fontSize: AppTextSizes.body,
      height: 1.4,
    );
  }

  Widget buildCalibrationDialogActions({
    required String secondaryLabel,
    required VoidCallback? onSecondary,
    required String primaryLabel,
    required VoidCallback? onPrimary,
  }) {
    AppThemeColors colors = widget.colors;

    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(secondaryLabel, textAlign: TextAlign.center),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: colors.backgroundColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                primaryLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCalibrationDialogPrimaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    AppThemeColors colors = widget.colors;

    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.backgroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  /// Offers MIDI assistance before the user positions the phone and keyboard.
  Future<void> askForMiddleCHelpBeforeCalibration({
    bool forSavedAlignment = false,
  }) async {
    AppThemeColors colors = widget.colors;

    bool? wantsHelp = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: buildCalibrationDialogIcon(Icons.help_outline_rounded),
          title: Text(
            context.l10n.needHelpFindingMiddleC,
            textAlign: TextAlign.center,
            style: calibrationDialogTitleStyle(),
          ),
          content: SizedBox(
            width: 440,
            child: Text(
              forSavedAlignment
                  ? context.l10n.middleCHelpSavedAlignment
                  : context.l10n.middleCHelpNewCalibration,
              textAlign: TextAlign.center,
              style: calibrationDialogBodyStyle(),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            buildCalibrationDialogActions(
              secondaryLabel: forSavedAlignment
                  ? context.l10n.manualGuide
                  : context.l10n.iKnowMiddleC,
              onSecondary: () {
                Navigator.of(dialogContext).pop(false);
              },
              primaryLabel: context.l10n.connectPiano,
              onPrimary: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (wantsHelp != true) {
      if (forSavedAlignment) {
        await useManualC4Guide(
          beforeCalibration: true,
          forSavedAlignment: true,
        );
      }
      return;
    }

    await startMiddleCGuide(
      preparingBeforeCalibration: true,
      preparingSavedAlignment: forSavedAlignment,
    );
  }

  /// Starts MIDI Middle C guidance from either calibration workflow.
  Future<void> startMiddleCGuide({
    bool preparingBeforeCalibration = false,
    bool preparingSavedAlignment = false,
  }) async {
    if (!mounted) {
      return;
    }

    bool isSavedAlignment =
        preparingSavedAlignment ||
        calibrationStage == PianoCalibrationStage.aligningSavedCalibration;

    setState(() {
      _middleCGuideRequested = true;
      _middleCGuidePhase = _MiddleCGuidePhase.waitingForKey;
      _middleCGuideResult = null;
    });

    if (isMidiConnected) {
      return;
    }

    await connectForMiddleCGuide(
      preparingBeforeCalibration: preparingBeforeCalibration,
      preparingSavedAlignment: isSavedAlignment,
    );
  }

  /// Reconnects MIDI while retaining the active Middle C helper.
  Future<void> retryMiddleCGuideConnection() async {
    if (_middleCGuidePhase == _MiddleCGuidePhase.inactive) {
      return;
    }

    setState(() {
      _middleCGuidePhase = _MiddleCGuidePhase.waitingForKey;
      _middleCGuideResult = null;
    });

    await connectForMiddleCGuide(
      preparingSavedAlignment:
          calibrationStage == PianoCalibrationStage.aligningSavedCalibration,
    );
  }

  /// Connects without the practice-mode success dialog, then offers fallback.
  Future<void> connectForMiddleCGuide({
    bool preparingBeforeCalibration = false,
    bool preparingSavedAlignment = false,
  }) async {
    bool connected = await connectToMidi(
      showSuccessDialog: preparingBeforeCalibration,
      preparingForCalibration: preparingBeforeCalibration,
    );

    if (connected || !mounted) {
      return;
    }

    _MidiUnavailableAction? action = await showDialog<_MidiUnavailableAction>(
      context: context,
      builder: (BuildContext dialogContext) {
        AppThemeColors colors = widget.colors;

        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: buildCalibrationDialogIcon(Icons.usb_off_rounded),
          title: Text(
            context.l10n.digitalPianoNotFound,
            textAlign: TextAlign.center,
            style: calibrationDialogTitleStyle(),
          ),
          content: SizedBox(
            width: 440,
            child: Text(
              context.l10n.digitalPianoNotFoundDescription,
              textAlign: TextAlign.center,
              style: calibrationDialogBodyStyle(),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            buildCalibrationDialogActions(
              secondaryLabel: context.l10n.manualGuide,
              onSecondary: () {
                Navigator.of(dialogContext).pop(_MidiUnavailableAction.manual);
              },
              primaryLabel: context.l10n.retry,
              onPrimary: () {
                Navigator.of(dialogContext).pop(_MidiUnavailableAction.retry);
              },
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == _MidiUnavailableAction.retry) {
      if (preparingBeforeCalibration) {
        await connectForMiddleCGuide(
          preparingBeforeCalibration: true,
          preparingSavedAlignment: preparingSavedAlignment,
        );
      } else {
        await retryMiddleCGuideConnection();
      }
    } else if (action == _MidiUnavailableAction.manual) {
      await useManualC4Guide(
        beforeCalibration: preparingBeforeCalibration,
        forSavedAlignment: preparingSavedAlignment,
      );
    }
  }

  /// Restores direct camera tapping and explains the visual C-key pattern.
  Future<void> useManualC4Guide({
    bool beforeCalibration = false,
    bool forSavedAlignment = false,
  }) async {
    if (!mounted) {
      return;
    }

    setState(resetMiddleCGuide);

    bool? useMidiGuide = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        AppThemeColors colors = widget.colors;

        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: buildCalibrationDialogIcon(Icons.piano_rounded),
          title: Text(
            context.l10n.findMiddleCManually,
            textAlign: TextAlign.center,
            style: calibrationDialogTitleStyle(),
          ),
          content: SizedBox(
            width: 440,
            child: Text(
              context.l10n.findMiddleCManuallyDescription(
                forSavedAlignment
                    ? context.l10n.manualGuideSavedAlignment
                    : beforeCalibration
                    ? context.l10n.manualGuideBeforeCalibration
                    : context.l10n.manualGuideTapKey,
              ),
              textAlign: TextAlign.center,
              style: calibrationDialogBodyStyle(),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            buildCalibrationDialogActions(
              secondaryLabel: context.l10n.useMidiGuide,
              onSecondary: () {
                Navigator.of(dialogContext).pop(true);
              },
              primaryLabel: context.l10n.gotIt,
              onPrimary: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
          ],
        );
      },
    );

    if (useMidiGuide == true && mounted) {
      await startMiddleCGuide(
        preparingBeforeCalibration: beforeCalibration,
        preparingSavedAlignment: forSavedAlignment,
      );
    }
  }

  /// Updates the on-screen direction for the latest MIDI key press.
  void handleMiddleCGuideNoteOn(int midiNote) {
    MiddleCGuideResult result = middleCGuideService.evaluate(midiNote);

    setState(() {
      _middleCGuideResult = result;

      if (result.type == MiddleCGuideResultType.found) {
        _middleCGuidePhase = _MiddleCGuidePhase.waitingForRelease;
      } else {
        _middleCGuidePhase = _MiddleCGuidePhase.waitingForKey;
      }
    });
  }

  /// Clears transient guidance without closing the shared MIDI connection.
  void resetMiddleCGuide() {
    _middleCGuideRequested = false;
    _middleCGuidePhase = _MiddleCGuidePhase.inactive;
    _middleCGuideResult = null;
  }

  /// Uses the signed-in player's level for AR Performance timing leniency.
  Future<void> loadArPerformanceDifficulty() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      practicePerformanceTracker.applySkillLevel('beginner');
      return;
    }

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final skillLevel =
          userDocument.data()?['skillLevel'] as String? ?? 'beginner';

      practicePerformanceTracker.applySkillLevel(skillLevel);
    } catch (_) {
      practicePerformanceTracker.applySkillLevel('beginner');
    }
  }

  /// Subscribes to MIDI notes and connection changes for guidance and practice.
  void listenToMidiInput() {
    activeMidiNotesSubscription = midiInputService.activeNotesStream.listen((
      Set<int> notes,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        activeMidiNotes = Set<int>.from(notes);

        if (_middleCGuidePhase == _MiddleCGuidePhase.waitingForRelease &&
            !notes.contains(MiddleCGuideService.middleCMidiNote)) {
          _middleCGuidePhase = _MiddleCGuidePhase.readyToTap;
        }
      });

      if (isPracticeMode) {
        if (!performanceModeEnabled && waitModeRetryAfterRelease) {
          maybeFinishWaitModeRewind(notes);
          return;
        }

        tryCompleteWaitModeTarget(notes);
      }
    });

    midiNoteOnSubscription = midiInputService.noteOnStream.listen((
      int midiNote,
    ) {
      if (!mounted) {
        return;
      }

      bool isSelectingNewReference =
          calibrationStage == PianoCalibrationStage.selectingReferenceKey &&
          referenceKeyPosition == null;
      bool isVerifyingSavedReference =
          widget.savedCalibration != null &&
          (isRestoringSavedCalibration ||
              calibrationStage ==
                  PianoCalibrationStage.aligningSavedCalibration);

      if ((isSelectingNewReference || isVerifyingSavedReference) &&
          _middleCGuidePhase != _MiddleCGuidePhase.inactive) {
        handleMiddleCGuideNoteOn(midiNote);
        return;
      }

      if (!isPracticeMode) {
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
          schedulePracticeFeedbackDismissal();
        }

        return;
      }

      if (!isWaitingForCorrectNotes) {
        if (waitModeRetryAfterRelease) {
          return;
        }

        bool isAlreadyHeldPitch = waitModeHeldNotes.values.any(
          (_ArWaitHeldNoteState heldNote) => heldNote.midiNote == midiNote,
        );
        if (isAlreadyHeldPitch) {
          return;
        }

        if (waitModeHeldNotes.isNotEmpty || waitModeSegmentInProgress) {
          handleUnexpectedWaitModeNoteDuringHold(midiNote);
        }
        return;
      }

      if (isWaitingForCorrectNotes) {
        if (waitModeRetryAfterRelease) {
          return;
        }

        bool feedbackChanged = practicePerformanceTracker.recordWaitModeNoteOn(
          waitModeTargetGroupIndex,
          midiNote,
        );

        waitModePressedNotes.add(midiNote);
        waitModeNotePressedAt[midiNote] = waitModeDurationClock.elapsed;

        if (feedbackChanged) {
          setState(() {});
        }

        tryCompleteWaitModeTarget(activeMidiNotes);
      }
    });

    midiNoteEventSubscription = midiInputService.noteEventStream.listen((
      MidiNoteEvent event,
    ) {
      if (!mounted || event.type != MidiNoteEventType.noteOff) {
        return;
      }

      if (!isPracticeMode ||
          !hasPracticePlaybackStarted ||
          isPracticePlaybackComplete) {
        return;
      }

      if (performanceModeEnabled) {
        bool feedbackChanged = practicePerformanceTracker
            .recordPerformanceNoteOff(
              event.noteNumber,
              currentPracticeScoreElapsedMilliseconds(),
            );

        if (feedbackChanged) {
          setState(() {});
          schedulePracticeFeedbackDismissal();
        }

        return;
      }

      handleWaitModeNoteOff(event.noteNumber);
    });

    midiConnectionSubscription = midiInputService.connectionStream.listen((
      bool connected,
    ) {
      if (!mounted) {
        return;
      }

      bool shouldInterruptPractice =
          !connected &&
          isPracticeMode &&
          hasPracticePlaybackStarted &&
          !isPracticePlaybackComplete &&
          !practiceInterruptedByMidiDisconnect;

      if (shouldInterruptPractice) {
        fallingNotesAnimationController?.stop();
        waitModeDurationClock.stop();

        if (!performanceModeEnabled) {
          resetInterruptedWaitModeHold();
        }
      }

      setState(() {
        isMidiConnected = connected;

        if (!connected) {
          isConnectingMidi = false;
          midiConnectionStatus = context.l10n.digitalPianoDisconnected;
          activeMidiNotes = <int>{};

          if (_middleCGuidePhase != _MiddleCGuidePhase.inactive) {
            _middleCGuidePhase = _MiddleCGuidePhase.waitingForKey;
            _middleCGuideResult = null;
          }

          if (shouldInterruptPractice) {
            isPracticePlaybackPaused = true;
            practiceInterruptedByMidiDisconnect = true;
          }
        }
      });

      if (shouldInterruptPractice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(showMidiDisconnectedDialog());
          }
        });
      }
    });
  }

  void handleUnexpectedWaitModeNoteDuringHold(int midiNote) {
    int? rewindGroupIndex;

    for (_ArWaitHeldNoteState heldNote in waitModeHeldNotes.values) {
      int groupIndex = heldNote.groupIndex;
      if (rewindGroupIndex == null || groupIndex < rewindGroupIndex) {
        rewindGroupIndex = groupIndex;
      }
    }

    rewindGroupIndex ??= waitModeSegmentOriginGroupIndex;
    if (rewindGroupIndex == null ||
        rewindGroupIndex < 0 ||
        rewindGroupIndex >= practicePerformanceTracker.noteGroups.length) {
      return;
    }

    practicePerformanceTracker.recordWaitModeNoteOn(
      rewindGroupIndex,
      midiNote,
    );
    beginWaitModeRewind(
      rewindGroupIndex,
      context.l10n.synthesiaReleaseMistakenNotes,
      notesStillHeld: <int>{...activeMidiNotes, midiNote},
    );

    if (mounted) {
      setState(() {});
    }
  }

  void resetInterruptedWaitModeHold() {
    waitModeHoldTimer?.cancel();
    waitModeHoldTimer = null;
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();

    if (waitModeHeldNotes.isNotEmpty) {
      int earliestUnresolvedGroup = waitModeHeldNotes.values
          .map((_ArWaitHeldNoteState note) => note.groupIndex)
          .reduce((int first, int second) => first < second ? first : second);
      waitModePendingRewindGroupIndex = earliestUnresolvedGroup;
      waitModeRetryAfterRelease = true;
    }
  }

  Future<void> showMidiDisconnectedDialog() async {
    if (!mounted ||
        isMidiDisconnectDialogShowing ||
        !practiceInterruptedByMidiDisconnect) {
      return;
    }

    if (isPracticeControlsSheetOpen) {
      Navigator.of(context).pop();
      await Future<void>.delayed(Duration.zero);

      if (!mounted) {
        return;
      }
    }

    isMidiDisconnectDialogShowing = true;
    AppThemeColors colors = widget.colors;
    bool reconnecting = false;
    String? reconnectError;

    bool? shouldResume;

    try {
      shouldResume = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext dialogContext, StateSetter refreshDialog) {
              return PopScope(
                canPop: false,
                child: AlertDialog(
                  backgroundColor: colors.surfaceColor,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  icon: buildCalibrationDialogIcon(Icons.usb_off_rounded),
                  title: Text(
                    context.l10n.digitalPianoDisconnected,
                    textAlign: TextAlign.center,
                    style: calibrationDialogTitleStyle(),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.arPracticeDisconnectedDescription,
                        textAlign: TextAlign.center,
                        style: calibrationDialogBodyStyle(),
                      ),
                      if (reconnectError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          reconnectError!,
                          textAlign: TextAlign.center,
                          style: calibrationDialogBodyStyle().copyWith(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  actions: [
                    buildCalibrationDialogActions(
                      secondaryLabel: context.l10n.arPracticeEndAttempt,
                      onSecondary: reconnecting
                          ? null
                          : () {
                              Navigator.of(dialogContext).pop(false);
                            },
                      primaryLabel: reconnecting
                          ? context.l10n.arPracticeReconnecting
                          : context.l10n.arPracticeReconnect,
                      onPrimary: reconnecting
                          ? null
                          : () async {
                              refreshDialog(() {
                                reconnecting = true;
                                reconnectError = null;
                              });

                              bool connected =
                                  isMidiConnected ||
                                  await connectToMidi(showSuccessDialog: false);

                              if (!dialogContext.mounted) {
                                return;
                              }

                              if (connected) {
                                Navigator.of(dialogContext).pop(true);
                                return;
                              }

                              refreshDialog(() {
                                reconnecting = false;
                                reconnectError =
                                    context.l10n.arPracticeReconnectFailed;
                              });
                            },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      isMidiDisconnectDialogShowing = false;
    }

    if (!mounted || !practiceInterruptedByMidiDisconnect) {
      return;
    }

    if (shouldResume == true && isMidiConnected) {
      resumePracticeAfterMidiReconnect();
    } else {
      endInterruptedPracticeAttempt();
    }
  }

  void resumePracticeAfterMidiReconnect() {
    if (!practiceInterruptedByMidiDisconnect ||
        !hasPracticePlaybackStarted ||
        isPracticePlaybackComplete) {
      return;
    }

    practiceInterruptedByMidiDisconnect = false;

    if (!performanceModeEnabled) {
      waitModeDurationClock.start();
    }

    setState(() {
      isPracticePlaybackPaused = false;
      activeMidiNotes = <int>{};
    });

    if (!performanceModeEnabled && waitModePendingRewindGroupIndex != null) {
      performWaitModeRewind(
        feedbackMessage:
            context.l10n.arPracticeConnectionRestoredTryAgain,
      );
      return;
    }

    if (!performanceModeEnabled &&
        (waitModeSegmentInProgress || waitModeHeldNotes.isNotEmpty)) {
      ensureWaitModeHoldTimer();
    } else if (!isWaitingForCorrectNotes) {
      fallingNotesAnimationController?.forward();
    }
  }

  void endInterruptedPracticeAttempt() {
    practiceInterruptedByMidiDisconnect = false;
    preparePracticeRetry();
  }

  /// Discovers and connects the first available MIDI device.
  ///
  /// UI state is updated for searching/failure, and a success dialog confirms
  /// the connected device without leaving a large status card during playback.
  Future<bool> connectToMidi({
    bool showSuccessDialog = true,
    bool preparingForCalibration = false,
  }) async {
    if (isConnectingMidi) {
      return false;
    }

    setState(() {
      isConnectingMidi = true;
      midiConnectionStatus = context.l10n.searching;
    });

    try {
      final devices = await midiInputService.getDevices();

      if (!mounted) {
        return false;
      }

      if (devices.isEmpty) {
        setState(() {
          isConnectingMidi = false;
          isMidiConnected = false;
          midiConnectionStatus = context.l10n.noDigitalPianoFound;
        });

        return false;
      }

      final device = devices.first;

      setState(() {
        midiConnectionStatus = context.l10n.connecting;
      });

      await midiInputService.connectToDevice(device);

      if (!mounted) {
        return false;
      }

      setState(() {
        isConnectingMidi = false;
        isMidiConnected = true;
        midiConnectionStatus = context.l10n.connectedDevice(device.name);
        activeMidiNotes = <int>{};
      });

      if (showSuccessDialog) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            AppThemeColors colors = widget.colors;

            return AlertDialog(
              scrollable: true,
              backgroundColor: colors.surfaceColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              icon: buildCalibrationDialogIcon(
                Icons.check_circle_outline_rounded,
              ),
              title: Text(
                context.l10n.digitalPianoConnected,
                textAlign: TextAlign.center,
                style: calibrationDialogTitleStyle(),
              ),
              content: SizedBox(
                width: 440,
                child: Text(
                  preparingForCalibration
                      ? context.l10n.digitalPianoReadyForCalibration(
                          device.name,
                        )
                      : context.l10n.digitalPianoReady(device.name),
                  textAlign: TextAlign.center,
                  style: calibrationDialogBodyStyle(),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              actions: [
                buildCalibrationDialogPrimaryAction(
                  label: context.l10n.continueAction,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      }

      return true;
    } catch (error) {
      debugPrint('AR MIDI connection failed: $error');

      if (!mounted) {
        return false;
      }

      setState(() {
        isConnectingMidi = false;
        isMidiConnected = false;
        midiConnectionStatus = context.l10n.connectionFailed;
      });

      return false;
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
    practiceAttemptVersion++;

    if (!performanceModeEnabled) {
      waitModeDurationClock.start();
    }

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
      if (!performanceModeEnabled) {
        waitModeDurationClock.start();
      }

      setState(() {
        isPracticePlaybackPaused = false;
      });

      if (!performanceModeEnabled &&
          (waitModeSegmentInProgress || waitModeHeldNotes.isNotEmpty)) {
        ensureWaitModeHoldTimer();
      } else if (!isWaitingForCorrectNotes) {
        controller.forward();
      }

      return;
    }

    controller.stop();

    if (!performanceModeEnabled) {
      waitModeDurationClock.stop();
    }

    setState(() {
      isPracticePlaybackPaused = true;
    });
  }

  /// Resets a completed attempt to the ready screen without starting it again.
  void preparePracticeRetry() {
    AnimationController? controller = fallingNotesAnimationController;

    if (controller == null) {
      return;
    }

    controller.stop();
    resetWaitModeProgress();
    practicePerformanceTracker.resetAttempt();
    practiceAttemptVersion++;

    setState(() {
      isCompletionDialogShowing = false;
      activeMidiNotes = <int>{};
      hasPracticePlaybackStarted = false;
      isPracticePlaybackPaused = false;
      isPracticePlaybackComplete = false;
    });

    controller.value = 0;
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
        AppThemeColors colors = widget.colors;

        return AlertDialog(
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: buildCalibrationDialogIcon(
            switchingToWaitMode
                ? Icons.hourglass_empty_rounded
                : Icons.timer_outlined,
          ),
          title: Text(
            context.l10n.arPracticeSwitchToModeQuestion(
              switchingToWaitMode
                  ? context.l10n.sightReadingWaitMode
                  : context.l10n.sightReadingPerformanceMode,
            ),
            textAlign: TextAlign.center,
            style: calibrationDialogTitleStyle(),
          ),
          content: Text(
            switchingToWaitMode
                ? context.l10n.arPracticeWaitModeDescription
                : context.l10n.arPracticePerformanceModeDescription,
            textAlign: TextAlign.center,
            style: calibrationDialogBodyStyle(),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            buildCalibrationDialogActions(
              secondaryLabel: context.l10n.cancel,
              onSecondary: () {
                Navigator.of(dialogContext).pop(false);
              },
              primaryLabel: context.l10n.arPracticeSwitchMode,
              onPrimary: () {
                Navigator.of(dialogContext).pop(true);
              },
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
    practiceAttemptVersion++;

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
        schedulePracticeFeedbackDismissal();
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

    pauseWaitModeHeldDurations(waitModeDurationClock.elapsed);
    isWaitingForCorrectNotes = true;
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();
    practiceFeedbackTimer?.cancel();
    practiceFeedbackTimer = null;
    practicePerformanceTracker.clearImmediateFeedback();
    controller.stop();
    controller.value = targetMicroseconds / animationDuration.inMicroseconds;

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
        waitModeRetryAfterRelease ||
        waitModeTargetGroupIndex >=
            practicePerformanceTracker.noteGroups.length) {
      return;
    }

    ArPracticeNoteGroup targetGroup =
        practicePerformanceTracker.noteGroups[waitModeTargetGroupIndex];
    Set<int> expectedNotes = targetGroup.midiNotes;
    Set<int> carriedNotes = waitModeHeldNotes.values
        .where(
          (_ArWaitHeldNoteState heldNote) =>
              heldNote.groupIndex < waitModeTargetGroupIndex,
        )
        .map((_ArWaitHeldNoteState heldNote) => heldNote.midiNote)
        .toSet();
    Set<int> allowedNotes = <int>{...expectedNotes, ...carriedNotes};

    bool heldNotesMatch = notes.containsAll(expectedNotes);
    bool expectedNotesWerePressed = expectedNotes.every(
      waitModePressedNotes.contains,
    );
    bool hasUnexpectedActiveNote = notes.any(
      (int midiNote) => !allowedNotes.contains(midiNote),
    );

    if (!heldNotesMatch ||
        !expectedNotesWerePressed ||
        hasUnexpectedActiveNote) {
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

    acceptWaitModeTarget(targetGroup, waitModeTargetGroupIndex);
  }

  /// Accepts one onset while keeping all earlier sustained notes active.
  void acceptWaitModeTarget(ArPracticeNoteGroup targetGroup, int groupIndex) {
    Duration now = waitModeDurationClock.elapsed;
    resumeWaitModeHeldDurations(now);

    for (int midiNote in targetGroup.midiNotes) {
      Duration noteDuration = targetGroup.durationFor(midiNote);
      ArWaitNoteOccurrence occurrence = ArWaitNoteOccurrence(
        groupIndex: groupIndex,
        groupStartMicroseconds: targetGroup.startTime.inMicroseconds,
        midiNote: midiNote,
      );

      waitModeHeldNotes[occurrence] = _ArWaitHeldNoteState(
        occurrence: occurrence,
        pressedAt: now,
        noteDuration: noteDuration,
      );
      waitModeHoldProgressByOccurrence[occurrence] = 0;
    }

    waitModePassedGroupIndexes.add(groupIndex);
    waitModeTargetGroupIndex = groupIndex + 1;
    isWaitingForCorrectNotes = false;
    waitModeRetryAfterRelease = false;
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();
    waitModeTimelinePreviewAdvanceMicroseconds = 0;
    practiceFeedbackTimer?.cancel();
    practicePerformanceTracker.showDurationFeedback(
      context.l10n.sightReadingCorrectNotesKeepHolding,
    );

    if (waitModeTargetGroupIndex <
        practicePerformanceTracker.noteGroups.length) {
      ArPracticeNoteGroup nextGroup =
          practicePerformanceTracker.noteGroups[waitModeTargetGroupIndex];
      waitModeSegmentOriginGroupIndex = groupIndex;
      waitModeSegmentStartedAt = now;
      waitModeSegmentDuration = nextGroup.startTime - targetGroup.startTime;
      waitModeSegmentInProgress = true;
    } else {
      waitModeSegmentOriginGroupIndex = null;
      waitModeSegmentStartedAt = null;
      waitModeSegmentDuration = Duration.zero;
      waitModeSegmentInProgress = false;
    }

    ensureWaitModeHoldTimer();

    if (mounted) {
      setState(() {});
    }
  }

  /// Refreshes hold/release guidance and detects keys held past their deadline.
  void ensureWaitModeHoldTimer() {
    waitModeHoldTimer ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => updateWaitModeHoldProgress(),
    );
  }

  void updateWaitModeHoldProgress() {
    if (!mounted ||
        performanceModeEnabled ||
        isPracticePlaybackPaused ||
        waitModeRetryAfterRelease ||
        (!waitModeSegmentInProgress && waitModeHeldNotes.isEmpty)) {
      return;
    }

    Duration now = waitModeDurationClock.elapsed;
    List<_ArWaitHeldNoteState> dueForRelease = [];

    for (_ArWaitHeldNoteState heldNote in waitModeHeldNotes.values) {
      if (!activeMidiNotes.contains(heldNote.midiNote)) {
        continue;
      }

      Duration durationNow = _waitModeDurationEvaluationTime(heldNote, now);
      Duration heldDuration = durationNow - heldNote.pressedAt;
      int noteDurationMicroseconds = heldNote.noteDuration.inMicroseconds;
      double holdProgress = noteDurationMicroseconds <= 0
          ? 1
          : (heldDuration.inMicroseconds / noteDurationMicroseconds)
                .clamp(0.0, 1.0)
                .toDouble();
      waitModeHoldProgressByOccurrence[heldNote.occurrence] = holdProgress;

      if (heldDuration >= requiredWaitModeHoldDuration(heldNote)) {
        dueForRelease.add(heldNote);
      }

      if (heldDuration > heldNote.noteDuration + waitModeOverholdTolerance) {
        if (!heldNote.heldTooLong) {
          heldNote.heldTooLong = true;
          practicePerformanceTracker.recordWaitModeDurationMistake(
            heldNote.groupIndex,
            context.l10n.sightReadingNoteHeldTooLong(
              MidiNoteUtils.nameForMidiNote(heldNote.midiNote),
            ),
          );
        }

        beginWaitModeRewind(
          heldNote.groupIndex,
          context.l10n.sightReadingReleaseHeldTooLong(
            MidiNoteUtils.nameForMidiNote(heldNote.midiNote),
          ),
        );

        if (mounted) {
          setState(() {});
        }

        return;
      }
    }

    Duration? segmentStartedAt = waitModeSegmentStartedAt;

    if (waitModeSegmentInProgress && segmentStartedAt != null) {
      Duration segmentElapsed = now - segmentStartedAt;
      int maximumAdvanceMicroseconds = waitModeSegmentDuration.inMicroseconds;
      waitModeTimelinePreviewAdvanceMicroseconds = segmentElapsed.inMicroseconds
          .clamp(0, maximumAdvanceMicroseconds)
          .toInt();

      if (segmentElapsed >= waitModeSegmentDuration) {
        completeWaitModeSegment(
          durationPauseAt: segmentStartedAt + waitModeSegmentDuration,
        );
      }
    }

    if (dueForRelease.isNotEmpty) {
      practicePerformanceTracker.showDurationFeedback(
        context.l10n.sightReadingReleaseNotes(
          formatMidiNoteNames(dueForRelease.map((note) => note.midiNote)),
        ),
      );
    } else if (isWaitingForCorrectNotes && waitModeHeldNotes.isNotEmpty) {
      String heldNames = formatMidiNoteNames(
        waitModeHeldNotes.values
            .where(
              (_ArWaitHeldNoteState note) =>
                  activeMidiNotes.contains(note.midiNote),
            )
            .map((_ArWaitHeldNoteState note) => note.midiNote),
      );
      String expectedNames =
          waitModeTargetGroupIndex <
              practicePerformanceTracker.noteGroups.length
          ? formatMidiNoteNames(
              practicePerformanceTracker
                  .noteGroups[waitModeTargetGroupIndex]
                  .midiNotes,
            )
          : '';

      practicePerformanceTracker.showDurationFeedback(
        heldNames.isEmpty
            ? context.l10n.synthesiaPlayNotes(expectedNames)
            : context.l10n.sightReadingHoldWhilePlaying(
                heldNames,
                expectedNames,
              ),
      );
    } else if (waitModeSegmentInProgress) {
      practicePerformanceTracker.showDurationFeedback(
        waitModeHeldNotes.isEmpty
            ? context.l10n.synthesiaGetReadyNextNote
            : context.l10n.sightReadingCorrectNotesKeepHolding,
      );
    }

    if (!waitModeSegmentInProgress && waitModeHeldNotes.isEmpty) {
      waitModeHoldTimer?.cancel();
      waitModeHoldTimer = null;
    }

    setState(() {});
  }

  /// Commits the temporary visual movement and waits for the next onset.
  void completeWaitModeSegment({required Duration durationPauseAt}) {
    pauseWaitModeHeldDurations(durationPauseAt);
    waitModeSegmentInProgress = false;
    waitModeSegmentStartedAt = null;
    waitModeSegmentDuration = Duration.zero;
    waitModeSegmentOriginGroupIndex = null;
    waitModeTimelinePreviewAdvanceMicroseconds = 0;

    if (waitModeTargetGroupIndex >=
        practicePerformanceTracker.noteGroups.length) {
      return;
    }

    AnimationController? controller = fallingNotesAnimationController;
    Duration? animationDuration = controller?.duration;

    if (controller != null &&
        animationDuration != null &&
        animationDuration.inMicroseconds > 0) {
      ArPracticeNoteGroup targetGroup =
          practicePerformanceTracker.noteGroups[waitModeTargetGroupIndex];
      int targetMicroseconds =
          fallingNoteApproachDuration.inMicroseconds +
          targetGroup.startTime.inMicroseconds;
      controller.value = targetMicroseconds / animationDuration.inMicroseconds;
    }

    isWaitingForCorrectNotes = true;
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();
  }

  /// Handles a Wait Mode key release and advances only after valid durations.
  void handleWaitModeNoteOff(int midiNote) {
    _ArWaitHeldNoteState? heldNote;

    for (_ArWaitHeldNoteState candidate in waitModeHeldNotes.values) {
      if (candidate.midiNote == midiNote) {
        heldNote = candidate;
        break;
      }
    }

    if (heldNote == null) {
      waitModeNotePressedAt.remove(midiNote);
      return;
    }

    if (waitModeRetryAfterRelease) {
      return;
    }

    Duration heldDuration =
        _waitModeDurationEvaluationTime(
          heldNote,
          waitModeDurationClock.elapsed,
        ) -
        heldNote.pressedAt;

    if (heldDuration >
        heldNote.noteDuration + waitModeOverholdTolerance) {
      heldNote.heldTooLong = true;
      practicePerformanceTracker.recordWaitModeDurationMistake(
        heldNote.groupIndex,
        context.l10n.sightReadingNoteHeldTooLong(
          MidiNoteUtils.nameForMidiNote(heldNote.midiNote),
        ),
      );
      beginWaitModeRewind(
        heldNote.groupIndex,
        context.l10n.sightReadingReleaseHeldTooLong(
          MidiNoteUtils.nameForMidiNote(heldNote.midiNote),
        ),
      );

      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (!isWaitModeFallingNoteConsumed(heldNote)) {
      practicePerformanceTracker.recordWaitModeDurationMistake(
        heldNote.groupIndex,
        context.l10n.sightReadingNoteReleasedTooSoon(
          MidiNoteUtils.nameForMidiNote(midiNote),
        ),
      );
      beginWaitModeRewind(
        heldNote.groupIndex,
        context.l10n.synthesiaReleasedTooSoonTryAgain,
      );

      if (mounted) {
        setState(() {});
      }

      return;
    }

    waitModeHoldProgressByOccurrence[heldNote.occurrence] = 1;
    waitModeHiddenCompletedNoteOccurrences.add(heldNote.occurrence);
    waitModeHeldNotes.remove(heldNote.occurrence);
    waitModeNotePressedAt.remove(midiNote);
    finalizeReleasedWaitModeGroup(heldNote.groupIndex);
    maybeCompleteWaitModePractice();

    if (mounted) {
      setState(() {});
    }
  }

  void finalizeReleasedWaitModeGroup(int groupIndex) {
    bool hasOutstandingNote = waitModeHeldNotes.values.any(
      (_ArWaitHeldNoteState heldNote) => heldNote.groupIndex == groupIndex,
    );

    if (hasOutstandingNote ||
        !waitModePassedGroupIndexes.contains(groupIndex)) {
      return;
    }

    practicePerformanceTracker.completeWaitModeGroup(groupIndex);
    schedulePracticeFeedbackDismissal();
  }

  /// Uses the falling-note body as the release guide for one held pitch.
  bool isWaitModeFallingNoteConsumed(_ArWaitHeldNoteState heldNote) {
    Duration heldDuration =
        _waitModeDurationEvaluationTime(
          heldNote,
          waitModeDurationClock.elapsed,
        ) -
        heldNote.pressedAt;
    const Duration releaseGrace = Duration(milliseconds: 40);

    return heldDuration + releaseGrace >=
        requiredWaitModeHoldDuration(heldNote);
  }

  Duration requiredWaitModeHoldDuration(_ArWaitHeldNoteState heldNote) {
    return Duration(
      microseconds:
          (heldNote.noteDuration.inMicroseconds * waitModeMinimumHoldRatio)
              .round(),
    );
  }

  void pauseWaitModeHeldDurations(Duration pauseAt) {
    if (waitModeHeldDurationPausedAt != null) {
      return;
    }

    waitModeHeldDurationPausedAt = pauseAt;
    waitModeDurationPausedOccurrences.clear();

    for (_ArWaitHeldNoteState heldNote in waitModeHeldNotes.values) {
      Duration heldDuration = pauseAt - heldNote.pressedAt;
      if (heldDuration < heldNote.noteDuration) {
        waitModeDurationPausedOccurrences.add(heldNote.occurrence);
      }
    }
  }

  Duration _waitModeDurationEvaluationTime(
    _ArWaitHeldNoteState heldNote,
    Duration now,
  ) {
    Duration? pausedAt = waitModeHeldDurationPausedAt;
    if (pausedAt != null &&
        waitModeDurationPausedOccurrences.contains(heldNote.occurrence)) {
      return pausedAt;
    }

    Duration? segmentStartedAt = waitModeSegmentStartedAt;
    if (waitModeSegmentInProgress && segmentStartedAt != null) {
      Duration segmentEnd = segmentStartedAt + waitModeSegmentDuration;
      if (now > segmentEnd) {
        return segmentEnd;
      }
    }

    return now;
  }

  void resumeWaitModeHeldDurations(Duration now) {
    Duration? pausedAt = waitModeHeldDurationPausedAt;
    if (pausedAt == null) {
      return;
    }

    Duration excludedWait = now - pausedAt;
    if (excludedWait > Duration.zero) {
      for (_ArWaitHeldNoteState heldNote in waitModeHeldNotes.values) {
        if (waitModeDurationPausedOccurrences.contains(heldNote.occurrence)) {
          heldNote.pressedAt += excludedWait;
        }
      }
    }

    waitModeHeldDurationPausedAt = null;
    waitModeDurationPausedOccurrences.clear();
  }

  void maybeCompleteWaitModePractice() {
    if (performanceModeEnabled ||
        waitModeRetryAfterRelease ||
        waitModeSegmentInProgress ||
        waitModeTargetGroupIndex <
            practicePerformanceTracker.noteGroups.length ||
        waitModeHeldNotes.isNotEmpty ||
        isPracticePlaybackComplete) {
      return;
    }

    waitModeHoldTimer?.cancel();
    waitModeHoldTimer = null;
    waitModeDurationClock.stop();
    completePracticePlayback(finalizePerformanceGroups: false);
    fallingNotesAnimationController?.value = 1;
  }

  void beginWaitModeRewind(
    int groupIndex,
    String feedbackMessage, {
    Set<int>? notesStillHeld,
  }) {
    int rewindGroupIndex = groupIndex;

    for (_ArWaitHeldNoteState heldNote in waitModeHeldNotes.values) {
      if (heldNote.groupIndex < rewindGroupIndex) {
        rewindGroupIndex = heldNote.groupIndex;
      }
    }

    int? pendingRewind = waitModePendingRewindGroupIndex;
    waitModePendingRewindGroupIndex = pendingRewind == null
        ? rewindGroupIndex
        : (pendingRewind < rewindGroupIndex ? pendingRewind : rewindGroupIndex);
    waitModeRetryAfterRelease = true;
    waitModeSegmentInProgress = false;
    waitModeSegmentStartedAt = null;
    waitModeSegmentDuration = Duration.zero;
    waitModeSegmentOriginGroupIndex = null;
    waitModeTimelinePreviewAdvanceMicroseconds = 0;
    waitModeHeldDurationPausedAt = null;
    waitModeDurationPausedOccurrences.clear();
    isWaitingForCorrectNotes = false;
    fallingNotesAnimationController?.stop();
    waitModeHoldTimer?.cancel();
    waitModeHoldTimer = null;
    practicePerformanceTracker.showDurationFeedback(
      feedbackMessage,
      isError: true,
    );

    maybeFinishWaitModeRewind(notesStillHeld ?? activeMidiNotes);
  }

  void maybeFinishWaitModeRewind(Set<int> notes) {
    if (!waitModeRetryAfterRelease || notes.isNotEmpty) {
      return;
    }

    performWaitModeRewind(
      feedbackMessage: context.l10n.arPracticeTryAgainFullLength,
    );
  }

  void performWaitModeRewind({required String feedbackMessage}) {
    int? rewindGroupIndex = waitModePendingRewindGroupIndex;

    if (rewindGroupIndex == null ||
        rewindGroupIndex < 0 ||
        rewindGroupIndex >= practicePerformanceTracker.noteGroups.length) {
      return;
    }

    waitModeHoldTimer?.cancel();
    waitModeHoldTimer = null;
    practicePerformanceTracker.rewindWaitModeFromGroup(rewindGroupIndex);
    waitModePassedGroupIndexes.removeWhere(
      (int groupIndex) => groupIndex >= rewindGroupIndex,
    );
    waitModeHiddenCompletedNoteOccurrences.removeWhere(
      (ArWaitNoteOccurrence occurrence) =>
          occurrence.groupIndex >= rewindGroupIndex,
    );
    waitModeHeldNotes.clear();
    waitModeHoldProgressByOccurrence.clear();
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();
    waitModeTargetGroupIndex = rewindGroupIndex;
    waitModeRetryAfterRelease = false;
    waitModePendingRewindGroupIndex = null;
    waitModeSegmentInProgress = false;
    waitModeSegmentStartedAt = null;
    waitModeSegmentDuration = Duration.zero;
    waitModeSegmentOriginGroupIndex = null;
    waitModeTimelinePreviewAdvanceMicroseconds = 0;
    pauseWaitModeHeldDurations(waitModeDurationClock.elapsed);
    isWaitingForCorrectNotes = true;

    AnimationController? controller = fallingNotesAnimationController;
    Duration? animationDuration = controller?.duration;

    if (controller != null &&
        animationDuration != null &&
        animationDuration.inMicroseconds > 0) {
      ArPracticeNoteGroup targetGroup =
          practicePerformanceTracker.noteGroups[rewindGroupIndex];
      int targetMicroseconds =
          fallingNoteApproachDuration.inMicroseconds +
          targetGroup.startTime.inMicroseconds;
      controller.value = targetMicroseconds / animationDuration.inMicroseconds;
    }

    practicePerformanceTracker.showDurationFeedback(
      feedbackMessage,
      isError: true,
    );

    if (mounted) {
      setState(() {});
    }
  }

  String formatMidiNoteNames(Iterable<int> midiNotes) {
    List<int> sortedNotes = midiNotes.toSet().toList()..sort();
    return sortedNotes.map(MidiNoteUtils.nameForMidiNote).join(' + ');
  }

  /// Ensures the attacks of a multi-note chord occur within 200 milliseconds.
  bool waitModeChordTimingMatches(Set<int> expectedNotes) {
    if (expectedNotes.length <= 1) {
      return true;
    }

    List<Duration> pressTimes = expectedNotes
        .map((int note) => waitModeNotePressedAt[note])
        .whereType<Duration>()
        .toList();

    if (pressTimes.length != expectedNotes.length) {
      return false;
    }

    pressTimes.sort();

    return (pressTimes.last - pressTimes.first) <=
        const Duration(milliseconds: 200);
  }

  /// Clears the current Wait Mode gate, held attacks, and chord timestamps.
  void resetWaitModeProgress() {
    practiceFeedbackTimer?.cancel();
    practiceFeedbackTimer = null;
    waitModeHoldTimer?.cancel();
    waitModeHoldTimer = null;
    waitModeDurationClock.stop();
    waitModeDurationClock.reset();
    waitModeTargetGroupIndex = 0;
    isWaitingForCorrectNotes = false;
    waitModeSegmentInProgress = false;
    waitModeRetryAfterRelease = false;
    waitModeSegmentStartedAt = null;
    waitModeSegmentDuration = Duration.zero;
    waitModeSegmentOriginGroupIndex = null;
    waitModePendingRewindGroupIndex = null;
    waitModeTimelinePreviewAdvanceMicroseconds = 0;
    waitModeHeldDurationPausedAt = null;
    waitModeDurationPausedOccurrences.clear();
    waitModeHeldNotes.clear();
    waitModePressedNotes.clear();
    waitModeNotePressedAt.clear();
    waitModeHoldProgressByOccurrence.clear();
    waitModeHiddenCompletedNoteOccurrences.clear();
    waitModePassedGroupIndexes.clear();
  }

  /// Finalizes remaining score groups and schedules completion UI at playback end.
  void handlePracticePlaybackStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    if (!performanceModeEnabled && isWaitingForCorrectNotes) {
      return;
    }

    completePracticePlayback(finalizePerformanceGroups: performanceModeEnabled);
  }

  /// Completes one attempt and opens its result dialog exactly once.
  void completePracticePlayback({required bool finalizePerformanceGroups}) {
    if (!mounted || isPracticePlaybackComplete) {
      return;
    }

    if (finalizePerformanceGroups) {
      practicePerformanceTracker.finalizeRemainingPerformanceGroups();
    }

    setState(() {
      isPracticePlaybackPaused = false;
      isPracticePlaybackComplete = true;
    });

    int completedAttemptVersion = practiceAttemptVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          practiceAttemptVersion == completedAttemptVersion &&
          isPracticePlaybackComplete) {
        showPracticeCompletionDialog();
      }
    });
  }

  /// Shows the shared player-result layout and saves timed AR performances.
  ///
  /// The guard prevents duplicate dialogs when multiple animation notifications
  /// are delivered near completion.
  Future<void> showPracticeCompletionDialog() async {
    if (isCompletionDialogShowing || !mounted) {
      return;
    }

    isCompletionDialogShowing = true;
    AppThemeColors colors = widget.colors;
    int totalGroups = practicePerformanceTracker.totalGroupCount;
    int totalMistakes = practicePerformanceTracker.mistakeCount;
    bool isPerfect = totalMistakes == 0;
    Color accentColor = isPerfect
        ? Colors.green.shade600
        : Colors.amber.shade700;
    IconData icon = isPerfect
        ? Icons.check_circle
        : Icons.warning_amber_rounded;
    String title = isPerfect
        ? context.l10n.synthesiaPerfect
        : context.l10n.synthesiaExerciseCompleted;
    String message = isPerfect
        ? context.l10n.synthesiaCompletedWithoutMistakes
        : context.l10n.synthesiaCompletedWithMistakes(totalMistakes);
    String scoreText = performanceModeEnabled
        ? '${practicePerformanceTracker.correctGroupCount}/$totalGroups'
        : '${practicePerformanceTracker.evaluatedGroupCount}/$totalGroups';
    List<({String label, String value})> resultStats = performanceModeEnabled
        ? <({String label, String value})>[
            (
              label: context.l10n.synthesiaCorrectOnTime,
              value:
                  '${practicePerformanceTracker.correctGroupCount}/$totalGroups',
            ),
            (
              label: context.l10n.synthesiaWrongNotes,
              value: '${practicePerformanceTracker.wrongGroupCount}',
            ),
            (
              label: context.l10n.synthesiaNotPlayed,
              value: '${practicePerformanceTracker.missedGroupCount}',
            ),
            (
              label: context.l10n.synthesiaPlayedOnTime,
              value: '${practicePerformanceTracker.accuracyPercentage}%',
            ),
            (
              label: context.l10n.synthesiaMusicLength,
              value: formatPracticeDuration(
                widget.scoreTimeline?.totalDuration ?? Duration.zero,
              ),
            ),
          ]
        : <({String label, String value})>[
            (
              label: context.l10n.synthesiaCompleted,
              value:
                  '${practicePerformanceTracker.evaluatedGroupCount}/$totalGroups',
            ),
            (
              label: context.l10n.synthesiaFirstTry,
              value: '${practicePerformanceTracker.correctGroupCount}',
            ),
            (
              label: context.l10n.synthesiaMistakes,
              value: '$totalMistakes',
            ),
            (
              label: context.l10n.synthesiaTime,
              value: context.l10n.synthesiaNoLimit,
            ),
          ];
    final SightReadingPerformanceReport? performanceReport =
        performanceModeEnabled ? buildArPerformanceReport() : null;
    Future<String>? activeResultSaveFuture = performanceReport == null
        ? null
        : practiceResultService.savePerformanceResult(performanceReport);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            backgroundColor: colors.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: BorderSide(color: colors.borderColor),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: accentColor,
                            size: AppIconSizes.lg,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: colors.primaryColor,
                                  fontSize: AppTextSizes.sectionTitle,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                message,
                                style: TextStyle(
                                  color: colors.secondaryTextColor,
                                  fontSize: AppTextSizes.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          children: [
                            Text(
                              context.l10n.synthesiaScoreLabel,
                              style: TextStyle(
                                color: colors.secondaryTextColor,
                                fontSize: AppTextSizes.caption,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              scoreText,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: AppTextSizes.display,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: resultStats
                          .map(
                            (stat) => buildPracticeResultStatTile(
                              colors: colors,
                              label: stat.label,
                              value: stat.value,
                            ),
                          )
                          .toList(),
                    ),
                    if (performanceReport != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      buildArPerformanceInsights(
                        colors: colors,
                        report: performanceReport,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (activeResultSaveFuture != null)
                      buildPracticeResultSaveStatus(
                        colors: colors,
                        saveFuture: activeResultSaveFuture,
                        onRetry: performanceReport == null
                            ? null
                            : () {
                                setDialogState(() {
                                  activeResultSaveFuture = practiceResultService
                                      .savePerformanceResult(performanceReport);
                                });
                              },
                        onViewResult: performanceReport == null
                            ? null
                            : (String resultId) {
                                Navigator.of(dialogContext).pop();
                                unawaited(
                                  openPracticeResultFromAr(
                                    result: performanceReport.summary.copyWith(
                                      id: resultId,
                                      completedAt: DateTime.now(),
                                    ),
                                  ),
                                );
                              },
                      )
                    else
                      buildWaitModeResultNotice(colors),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 460,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                preparePracticeRetry();
                              },
                              style: practiceResultSecondaryButtonStyle(colors),
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(context.l10n.retry),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              style: practiceResultPrimaryButtonStyle(colors),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: Text(context.l10n.done),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    isCompletionDialogShowing = false;
  }

  Widget buildPracticeResultStatTile({
    required AppThemeColors colors,
    required String label,
    required String value,
  }) {
    return Container(
      width: 126,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildArPerformanceInsights({
    required AppThemeColors colors,
    required SightReadingPerformanceReport report,
  }) {
    List<String> attentionItems = buildArAttentionItems(report);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: buildArInsightPanel(
            colors: colors,
            icon: Icons.troubleshoot_rounded,
            title: context.l10n.synthesiaWhatToWorkOn,
            items: attentionItems,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: buildArInsightPanel(
            colors: colors,
            icon: Icons.lightbulb_outline_rounded,
            title: context.l10n.synthesiaHowToImprove,
            items: report.suggestions,
          ),
        ),
      ],
    );
  }

  Widget buildArInsightPanel({
    required AppThemeColors colors,
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primaryColor, size: AppIconSizes.sm),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...items.take(3).map((String item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '• $item',
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  height: 1.25,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<String> buildArAttentionItems(SightReadingPerformanceReport report) {
    if (report.errorEvents.isEmpty) {
      return <String>[context.l10n.synthesiaNoRepeatedProblems];
    }

    List<String> items = <String>[];
    List<NotePerformanceBreakdown> difficultNotes =
        report.summary.noteBreakdown
            .where((item) => item.errorCount > 0)
            .toList()
          ..sort(
            (first, second) => second.errorCount.compareTo(first.errorCount),
          );

    if (difficultNotes.isNotEmpty) {
      NotePerformanceBreakdown note = difficultNotes.first;
      items.add(
        context.l10n.synthesiaTroubleWithNoteTimes(
          MidiNoteUtils.nameForMidiNote(note.midiNote),
          note.errorCount,
        ),
      );
    }

    Map<PerformanceIssueType, int> issueCounts = <PerformanceIssueType, int>{};

    for (PracticeResultErrorEvent event in report.errorEvents) {
      for (PerformanceIssueType issueType in event.issueTypes) {
        issueCounts.update(issueType, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    if ((issueCounts[PerformanceIssueType.releasedEarly] ?? 0) > 0) {
      items.add(
        context.l10n.synthesiaGroupsReleasedEarly(
          issueCounts[PerformanceIssueType.releasedEarly]!,
        ),
      );
    }

    items.add(
      context.l10n.synthesiaCorrectGroupsNeedReview(
        report.summary.correctCount,
        report.errorEvents.length,
      ),
    );
    return items.take(3).toList(growable: false);
  }

  Future<void> openPracticeResultFromAr({
    required PracticeResultSummary result,
  }) async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) {
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PracticeResultDetailScreen(result: result, colors: widget.colors),
        ),
      );
    } finally {
      if (mounted) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);

        if (mounted) {
          preparePracticeRetry();
        }
      }
    }
  }

  String formatPracticeDuration(Duration duration) {
    int totalSeconds = duration.inSeconds;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget buildPracticeResultSaveStatus({
    required AppThemeColors colors,
    required Future<String>? saveFuture,
    required VoidCallback? onRetry,
    required ValueChanged<String>? onViewResult,
  }) {
    return FutureBuilder<String>(
      future: saveFuture,
      builder: (context, snapshot) {
        bool isSaving = snapshot.connectionState == ConnectionState.waiting;
        bool isSaved = snapshot.hasData;
        Color statusColor = isSaved
            ? Colors.green.shade700
            : snapshot.hasError
            ? Colors.red.shade700
            : colors.secondaryTextColor;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSaving)
                SizedBox(
                  width: AppIconSizes.sm,
                  height: AppIconSizes.sm,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: statusColor,
                  ),
                )
              else
                Icon(
                  isSaved
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: statusColor,
                  size: AppIconSizes.sm,
                ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  isSaving
                      ? context.l10n.arPracticeSavingResult
                      : isSaved
                      ? context.l10n.arPracticeResultSaved
                      : context.l10n.arPracticeResultNotSaved,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (snapshot.hasError && onRetry != null) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.synthesiaRetrySave),
                ),
              ],
              if (snapshot.hasData && onViewResult != null)
                TextButton.icon(
                  onPressed: () => onViewResult(snapshot.data!),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(context.l10n.synthesiaViewFullResult),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildWaitModeResultNotice(AppThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryTextColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            color: colors.secondaryTextColor,
            size: AppIconSizes.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              context.l10n.synthesiaWaitModeNotSaved,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.label,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SightReadingPerformanceReport buildArPerformanceReport() {
    Map<int, int> noteTotals = <int, int>{};
    Map<int, int> noteErrors = <int, int>{};
    Map<int, int> noteMisses = <int, int>{};
    Map<int, int> wrongPlayedCounts = <int, int>{};
    List<PracticeResultErrorEvent> errorEvents =
        practicePerformanceTracker.performanceErrorEvents;

    for (ArPracticeNoteGroup group in practicePerformanceTracker.noteGroups) {
      for (int midiNote in group.midiNotes) {
        noteTotals.update(midiNote, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    for (PracticeResultErrorEvent event in errorEvents) {
      bool wasMissed = event.issueTypes.contains(PerformanceIssueType.missed);

      for (int midiNote in event.expectedMidiNotes) {
        noteErrors.update(midiNote, (value) => value + 1, ifAbsent: () => 1);

        if (wasMissed) {
          noteMisses.update(midiNote, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      Set<int> expectedNotes = event.expectedMidiNotes.toSet();

      for (int midiNote in event.playedMidiNotes) {
        if (!expectedNotes.contains(midiNote)) {
          wrongPlayedCounts.update(
            midiNote,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    Set<int> allNotes = <int>{...noteTotals.keys, ...wrongPlayedCounts.keys};
    List<NotePerformanceBreakdown> noteBreakdown =
        allNotes.map((midiNote) {
          return NotePerformanceBreakdown(
            midiNote: midiNote,
            totalCount: noteTotals[midiNote] ?? 0,
            errorCount: noteErrors[midiNote] ?? 0,
            missedCount: noteMisses[midiNote] ?? 0,
            wrongPlayedCount: wrongPlayedCounts[midiNote] ?? 0,
          );
        }).toList()..sort((first, second) {
          int errorComparison = second.errorCount.compareTo(first.errorCount);
          return errorComparison != 0
              ? errorComparison
              : second.wrongPlayedCount.compareTo(first.wrongPlayedCount);
        });

    List<String> suggestions = buildArPerformanceSuggestions(
      noteBreakdown: noteBreakdown,
      errorEvents: errorEvents,
    );
    ArScoreTimeline? timeline = widget.scoreTimeline;
    int targetDurationMs = timeline?.totalDuration.inMilliseconds ?? 0;
    int elapsedDurationMs = currentPracticeScoreElapsedMilliseconds()
        .clamp(0, targetDurationMs)
        .toInt();
    String cleanDocumentPath = widget.scoreDocumentPath.trim();
    bool isComposition =
        cleanDocumentPath.startsWith('compositionPosts/') ||
        cleanDocumentPath.contains('/compositions/');
    PracticeResultSummary summary = PracticeResultSummary(
      practiceType: PracticeResultType.arPerformance,
      ownerId: '',
      scoreDocumentPath: cleanDocumentPath,
      source: cleanDocumentPath.startsWith('available_pieces/')
          ? 'musicLibrary'
          : isComposition
          ? 'composition'
          : 'musicSheet',
      pieceTitle: timeline?.pieceTitle ?? context.l10n.synthesiaUntitledScore,
      completedAt: null,
      targetDurationMs: targetDurationMs,
      elapsedDurationMs: elapsedDurationMs,
      correctCount: practicePerformanceTracker.correctGroupCount,
      wrongCount: practicePerformanceTracker.wrongGroupCount,
      missedCount: practicePerformanceTracker.missedGroupCount,
      totalCount: practicePerformanceTracker.totalGroupCount,
      timingAccuracyPercentage: practicePerformanceTracker.accuracyPercentage,
      noteBreakdown: noteBreakdown,
      clefBreakdown: const <ClefPerformanceBreakdown>[],
      suggestions: suggestions,
      errorEventCount: errorEvents.length,
    );

    return SightReadingPerformanceReport(
      summary: summary,
      errorEvents: errorEvents,
      suggestions: suggestions,
    );
  }

  List<String> buildArPerformanceSuggestions({
    required List<NotePerformanceBreakdown> noteBreakdown,
    required List<PracticeResultErrorEvent> errorEvents,
  }) {
    if (errorEvents.isEmpty) {
      return <String>[
        context.l10n.synthesiaSuggestionPerfect,
      ];
    }

    Map<PerformanceIssueType, int> issueCounts = <PerformanceIssueType, int>{};

    for (PracticeResultErrorEvent event in errorEvents) {
      for (PerformanceIssueType issueType in event.issueTypes) {
        issueCounts.update(issueType, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    List<String> suggestions = <String>[];
    int totalGroups = practicePerformanceTracker.totalGroupCount;

    if (errorEvents.length <=
        (totalGroups * 0.10).ceil().clamp(1, totalGroups)) {
      suggestions.add(
        context.l10n.synthesiaSuggestionAlmostPerfect,
      );
    }

    List<NotePerformanceBreakdown> difficultNotes =
        noteBreakdown.where((item) => item.errorCount > 0).toList()..sort(
          (first, second) => second.errorCount.compareTo(first.errorCount),
        );

    if (difficultNotes.isNotEmpty && suggestions.length < 3) {
      NotePerformanceBreakdown note = difficultNotes.first;
      suggestions.add(
        context.l10n.synthesiaSuggestionDifficultNote(
          MidiNoteUtils.nameForMidiNote(note.midiNote),
        ),
      );
    }

    int releasedEarly = issueCounts[PerformanceIssueType.releasedEarly] ?? 0;
    int missed = issueCounts[PerformanceIssueType.missed] ?? 0;
    int early = issueCounts[PerformanceIssueType.early] ?? 0;
    int late = issueCounts[PerformanceIssueType.late] ?? 0;
    int chordTiming = issueCounts[PerformanceIssueType.chordTiming] ?? 0;
    int wrongNotes = issueCounts[PerformanceIssueType.wrongNote] ?? 0;

    if (releasedEarly > 0 && suggestions.length < 3) {
      suggestions.add(
        context.l10n.synthesiaSuggestionReleasedTooSoon,
      );
    }

    if (missed > 0 && suggestions.length < 3) {
      suggestions.add(
        context.l10n.synthesiaSuggestionMissedNotes,
      );
    }

    if (late > early && suggestions.length < 3) {
      suggestions.add(
        context.l10n.synthesiaSuggestionPlayedLate,
      );
    } else if (early > late && suggestions.length < 3) {
      suggestions.add(
        context.l10n.synthesiaSuggestionPlayedEarly,
      );
    }

    if (chordTiming > 0 && suggestions.length < 3) {
      suggestions.add(
        context.l10n.synthesiaSuggestionChordTiming,
      );
    }

    if (wrongNotes > 0 && suggestions.length < 3) {
      suggestions.add(
        context.l10n.synthesiaSuggestionWrongNotes,
      );
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        context.l10n.synthesiaSuggestionGeneralPractice,
      );
    }

    return suggestions.take(3).toList(growable: false);
  }

  ButtonStyle practiceResultPrimaryButtonStyle(AppThemeColors colors) {
    return FilledButton.styleFrom(
      backgroundColor: colors.primaryColor,
      foregroundColor: colors.backgroundColor,
      disabledBackgroundColor: colors.borderColor,
      disabledForegroundColor: colors.secondaryTextColor,
    );
  }

  ButtonStyle practiceResultSecondaryButtonStyle(AppThemeColors colors) {
    return OutlinedButton.styleFrom(
      foregroundColor: colors.primaryColor,
      disabledForegroundColor: colors.secondaryTextColor.withValues(
        alpha: 0.55,
      ),
      side: BorderSide(color: colors.borderColor),
    );
  }

  /// Reopens a new mapping for editing or fully redetects a loaded calibration.
  void editConfirmedMapping() {
    if (calibrationStage != PianoCalibrationStage.mappingConfirmed) {
      return;
    }

    if (widget.savedCalibration != null) {
      detectKeyboardAgain();
      return;
    }

    setState(() {
      resetMiddleCGuide();
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

    if (widget.scoreTimeline != null) {
      ArScoreTimeline? timeline = widget.scoreTimeline;

      if (timeline == null || timeline.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.songStillLoading)),
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
        ? context.l10n.noPlayableKeys
        : '${MidiNoteUtils.nameForMidiNote(sortedCalibratedNotes.first)}'
              '–${MidiNoteUtils.nameForMidiNote(sortedCalibratedNotes.last)}';

    const int maximumListedMissingNotes = 8;

    String missingNoteNames = missingMidiNotes
        .take(maximumListedMissingNotes)
        .map(MidiNoteUtils.nameForMidiNote)
        .join(', ');

    if (missingMidiNotes.length > maximumListedMissingNotes) {
      int remainingCount = missingMidiNotes.length - maximumListedMissingNotes;

      missingNoteNames = context.l10n.remainingNotes(
        missingNoteNames,
        remainingCount,
      );
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        AppThemeColors colors = widget.colors;

        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: buildCalibrationDialogIcon(Icons.piano_rounded),
          title: Text(
            context.l10n.morePianoKeysNeeded,
            textAlign: TextAlign.center,
            style: calibrationDialogTitleStyle(),
          ),
          content: SizedBox(
            width: 440,
            child: Text(
              context.l10n.morePianoKeysDescription(
                requiredRange,
                calibrationRange,
                missingNoteNames,
              ),
              textAlign: TextAlign.center,
              style: calibrationDialogBodyStyle(),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            buildCalibrationDialogPrimaryAction(
              label: context.l10n.reviewPianoSetup,
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );

    return false;
  }

  /// Resets detection, geometry, practice, and scoring state for recalibration.
  void detectKeyboardAgain() {
    bool shouldOfferMiddleCHelp = widget.savedCalibration != null;

    pianoKeyboardDetector.reset();
    fallingNotesAnimationController?.dispose();
    fallingNotesAnimationController = null;
    setState(() {
      resetMiddleCGuide();
      referenceKeyMarkers = [];
      pianoKeyMarkers = [];
      pianoKeyRegions = [];
      detectedBlackKeyGroups = [];
      normalizedCalibration = null;
      loadedFromSavedCalibration = false;
      isRestoringSavedCalibration = false;
      isPracticeMode = false;
      activeMidiNotes = <int>{};
      practicePerformanceTracker.noteGroups = const <ArPracticeNoteGroup>[];
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
      detectionDetails = 'Looking for piano keys';
      lastCameraImageTime = null;
      calibrationStage = PianoCalibrationStage.detectingKeyboard;
    });

    if (shouldOfferMiddleCHelp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          askForMiddleCHelpBeforeCalibration();
        }
      });
    }
  }

  /// Uses a camera tap to select Middle C for a new calibration.
  void handleReferenceTap(Offset sourcePosition) {
    selectReferenceKey(sourcePosition);
  }

  /// Opens AR practice after the user finishes positioning the camera.
  Future<void> useAlignedSavedCalibration() async {
    if (calibrationStage != PianoCalibrationStage.aligningSavedCalibration) {
      return;
    }

    ArScoreTimeline? timeline = widget.scoreTimeline;

    if (timeline == null || timeline.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.songStillLoading)),
      );
      return;
    }

    bool calibrationCoversScore = await validateScoreRange(timeline);

    if (!calibrationCoversScore || !mounted) {
      return;
    }

    setState(() {
      calibrationStage = PianoCalibrationStage.mappingConfirmed;
    });

    await finishCalibration();
  }

  /// Treats the user's tap as C4 and derives every visible key and outline.
  ///
  /// White positions begin with geometric interpolation, optionally use detected
  /// seams, and then black markers/outlines are attached to the labeled octaves.
  void selectReferenceKey(Offset sourcePosition) {
    if (calibrationStage != PianoCalibrationStage.selectingReferenceKey ||
        (_middleCGuidePhase != _MiddleCGuidePhase.inactive &&
            _middleCGuidePhase != _MiddleCGuidePhase.readyToTap)) {
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
      resetMiddleCGuide();
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
    practiceFeedbackTimer?.cancel();
    waitModeHoldTimer?.cancel();
    waitModeDurationClock.stop();
    fallingNotesAnimationController?.dispose();
    unawaited(disposeMidiInput());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    cameraController?.dispose();

    super.dispose();
  }

  /// Cancels all MIDI subscriptions before disposing the platform service.
  Future<void> disposeMidiInput() async {
    await activeMidiNotesSubscription?.cancel();
    await midiNoteOnSubscription?.cancel();
    await midiNoteEventSubscription?.cancel();
    await midiConnectionSubscription?.cancel();
    await midiInputService.dispose();
  }
}
