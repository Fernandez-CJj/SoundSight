import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/screens/practice_result/practice_result_detail_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/practice_mode_toggle.dart';

import '../ar/services/ar_practice_performance_tracker.dart';
import '../ar/utils/midi_note_utils.dart';
import '../sight_reading/practice_result_models.dart';
import '../sight_reading/practice_result_service.dart';
import '../sight_reading/score_audio_playback_service.dart';
import 'models/synthesia_score.dart';
import 'models/synthesia_score_source.dart';
import 'models/synthesia_wait_note_occurrence.dart';
import 'services/synthesia_performance_report_builder.dart';
import 'services/synthesia_score_loader.dart';
import 'services/synthesia_wait_mode_engine.dart';
import 'widgets/synthesia_falling_notes.dart';
import 'widgets/synthesia_keyboard.dart';
import 'widgets/synthesia_piano_geometry.dart';

enum SynthesiaMode { wait, performance }

class SynthesiaScreen extends StatefulWidget {
  const SynthesiaScreen({
    super.key,
    required this.colors,
    required this.source,
  });

  final AppThemeColors colors;
  final SynthesiaScoreSource source;

  @override
  State<SynthesiaScreen> createState() => _SynthesiaScreenState();
}

class _SynthesiaScreenState extends State<SynthesiaScreen>
    with SingleTickerProviderStateMixin {
  static const Duration approachDuration = Duration(seconds: 4);
  static const Duration waitReleaseGrace = Duration(milliseconds: 40);
  static const Duration waitOverholdTolerance = Duration(milliseconds: 300);

  final SynthesiaScoreLoader scoreLoader = SynthesiaScoreLoader();
  final ScoreAudioPlaybackService scoreAudioPlaybackService =
      ScoreAudioPlaybackService();
  final MidiInputService midiInputService = MidiInputService();
  final ArPracticePerformanceTracker performanceTracker =
      ArPracticePerformanceTracker(evaluateNoteDurations: true);
  final PracticeResultService practiceResultService = PracticeResultService();
  final SynthesiaWaitModeEngine waitModeEngine = SynthesiaWaitModeEngine();
  final SynthesiaPerformanceReportBuilder performanceReportBuilder =
      const SynthesiaPerformanceReportBuilder();

  StreamSubscription<Set<int>>? activeNotesSubscription;
  StreamSubscription<int>? noteOnSubscription;
  StreamSubscription<MidiNoteEvent>? noteEventSubscription;
  StreamSubscription<bool>? connectionSubscription;
  AnimationController? timelineController;
  Timer? waitModeTimer;

  SynthesiaScore? score;
  SynthesiaPianoRange? pianoRange;
  SynthesiaMode mode = SynthesiaMode.performance;
  Set<int> activeMidiNotes = <int>{};

  bool isLoading = true;
  bool isConnectingMidi = false;
  bool isMidiConnected = false;
  bool hasStarted = false;
  bool isPaused = false;
  bool isComplete = false;
  bool isWaiting = false;
  bool isScrubbing = false;
  bool requireReleaseAfterSeek = false;
  bool completionDialogOpen = false;
  bool scorePreviewPreparing = false;
  bool scorePreviewPlaying = false;
  bool practiceControlsSheetOpen = false;
  bool midiReconnectSheetScheduled = false;
  bool performanceInterruptedByDisconnect = false;
  String? loadingError;
  String midiStatus = '';
  int scrubTargetGroupIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _listenToMidi();
    performanceTracker.applySkillLevel('beginner');
    unawaited(_loadPerformanceDifficulty());
    unawaited(_loadScore());
  }

  void _listenToMidi() {
    activeNotesSubscription = midiInputService.activeNotesStream.listen((
      notes,
    ) {
      if (!mounted) return;
      setState(() {
        activeMidiNotes = Set<int>.from(notes);
        if (requireReleaseAfterSeek && activeMidiNotes.isEmpty) {
          requireReleaseAfterSeek = false;
        }
      });

      if (mode == SynthesiaMode.wait && waitModeEngine.retryAfterRelease) {
        int? rewindGroup = waitModeEngine.finishRewindIfReleased(notes);
        if (rewindGroup != null) {
          performanceTracker.rewindWaitModeFromGroup(rewindGroup);
          _snapWaitTimelineToGroup(rewindGroup);
          performanceTracker.showDurationFeedback(
            context.l10n.synthesiaTryAgainHoldFullLength,
            isError: true,
          );
          if (mounted) setState(() => isWaiting = true);
        }
        return;
      }

      if (mode == SynthesiaMode.wait &&
          waitModeEngine.targetRetryAfterRelease) {
        if (waitModeEngine.finishTargetRetryIfReleased(notes)) {
          performanceTracker.showDurationFeedback(
            context.l10n.synthesiaTryHighlightedAgain,
          );
          setState(() {
            isWaiting = true;
          });
        }
        return;
      }

      _tryCompleteWaitTarget();
    });

    noteOnSubscription = midiInputService.noteOnStream.listen((midiNote) {
      if (!mounted ||
          !hasStarted ||
          isPaused ||
          isComplete ||
          isScrubbing ||
          _leadInActive ||
          requireReleaseAfterSeek) {
        return;
      }

      if (mode == SynthesiaMode.performance) {
        final changed = performanceTracker.recordPerformanceNoteOn(
          midiNote,
          _scoreElapsed.inMilliseconds,
        );
        if (changed) setState(() {});
        return;
      }

      if (waitModeEngine.segmentInProgress &&
          waitModeEngine.canBufferUpcomingPress &&
          waitModeEngine.expectedNotes.contains(midiNote)) {
        waitModeEngine.recordNoteOn(midiNote);
        return;
      }

      if (!isWaiting) {
        if (waitModeEngine.retryAfterRelease ||
            waitModeEngine.targetRetryAfterRelease) {
          return;
        }

        bool isAlreadyHeldPitch = waitModeEngine.heldNotes.values.any(
          (heldNote) => heldNote.midiNote == midiNote,
        );
        if (isAlreadyHeldPitch) {
          return;
        }

        if (waitModeEngine.heldNotes.isNotEmpty ||
            waitModeEngine.segmentInProgress) {
          _handleUnexpectedWaitNoteDuringHold(midiNote);
        }
        return;
      }

      if (waitModeEngine.targetRetryAfterRelease) return;
      final expectedNotes = waitModeEngine.expectedNotes;
      final carriedNotes = waitModeEngine.carriedNotes;
      final isUnexpectedNote =
          !expectedNotes.contains(midiNote) &&
          !carriedNotes.contains(midiNote);
      final changed = performanceTracker.recordWaitModeNoteOn(
        waitModeEngine.targetGroupIndex,
        midiNote,
      );
      waitModeEngine.recordNoteOn(midiNote);
      if (changed) setState(() {});

      if (isUnexpectedNote) {
        waitModeEngine.beginTargetRetry(<int>{
          ...waitModeEngine.pressedNotes,
          midiNote,
        });
        performanceTracker.showDurationFeedback(
          context.l10n.synthesiaReleaseMistakenNotes,
          isError: true,
        );
        setState(() {});
        return;
      }
      _tryCompleteWaitTarget();
    });

    noteEventSubscription = midiInputService.noteEventStream.listen((event) {
      if (!mounted ||
          event.type != MidiNoteEventType.noteOff ||
          !hasStarted ||
          isPaused ||
          isComplete) {
        return;
      }

      if (mode == SynthesiaMode.performance) {
        bool changed = performanceTracker.recordPerformanceNoteOff(
          event.noteNumber,
          _scoreElapsed.inMilliseconds,
        );
        if (changed) setState(() {});
        return;
      }

      _handleWaitModeNoteOff(event.noteNumber);
    });

    connectionSubscription = midiInputService.connectionStream.listen((
      connected,
    ) {
      if (!mounted) return;
      bool interrupted = !connected && hasStarted && !isComplete;
      if (interrupted) {
        timelineController?.stop();
        waitModeTimer?.cancel();
        waitModeTimer = null;
        if (mode == SynthesiaMode.wait) {
          waitModeEngine.interruptForDisconnect();
        } else {
          performanceInterruptedByDisconnect = true;
          performanceTracker.resetAttempt();
          timelineController?.value = 0;
        }
      }
      setState(() {
        isMidiConnected = connected;
        isConnectingMidi = false;
        if (!connected) {
          activeMidiNotes = <int>{};
          midiStatus = context.l10n.synthesiaMidiDisconnected;
          if (interrupted && mode == SynthesiaMode.wait) {
            isPaused = true;
          } else if (interrupted) {
            hasStarted = false;
            isPaused = false;
            isWaiting = false;
            isComplete = false;
          }
        }
      });

      if (!connected) {
        _scheduleMidiReconnectControls();
      } else {
        _resumeAfterMidiReconnect();
      }
    });
  }

  void _handleUnexpectedWaitNoteDuringHold(int midiNote) {
    int? rewindGroupIndex;

    for (SynthesiaWaitHeldNote heldNote in waitModeEngine.heldNotes.values) {
      int groupIndex = heldNote.groupIndex;
      if (rewindGroupIndex == null || groupIndex < rewindGroupIndex) {
        rewindGroupIndex = groupIndex;
      }
    }

    rewindGroupIndex ??= waitModeEngine.segmentOriginGroupIndex;
    if (rewindGroupIndex == null ||
        rewindGroupIndex < 0 ||
        rewindGroupIndex >= performanceTracker.noteGroups.length) {
      return;
    }

    performanceTracker.recordWaitModeNoteOn(rewindGroupIndex, midiNote);
    waitModeEngine.beginRewind(rewindGroupIndex);
    waitModeTimer?.cancel();
    waitModeTimer = null;
    performanceTracker.showDurationFeedback(
      context.l10n.synthesiaReleaseMistakenNotes,
      isError: true,
    );
    setState(() => isWaiting = false);
  }

  Future<void> _loadPerformanceDifficulty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      performanceTracker.applySkillLevel('beginner');
      return;
    }

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final skillLevel =
          document.data()?['skillLevel'] as String? ?? 'beginner';
      performanceTracker.applySkillLevel(skillLevel);
    } catch (_) {
      performanceTracker.applySkillLevel('beginner');
    }
  }

  void _resumeAfterMidiReconnect() {
    if (!mounted) return;

    if (performanceInterruptedByDisconnect) {
      performanceInterruptedByDisconnect = false;
      _showMessage(context.l10n.synthesiaConnectionRestoredStartAgain);
      return;
    }

    if (mode != SynthesiaMode.wait || !hasStarted || isComplete) return;
    waitModeEngine.resume();
    int? rewindGroup = waitModeEngine.finishPendingRewind();
    if (rewindGroup != null) {
      performanceTracker.rewindWaitModeFromGroup(rewindGroup);
      _snapWaitTimelineToGroup(rewindGroup);
      performanceTracker.showDurationFeedback(
        context.l10n.synthesiaConnectionRestoredPlayAgain,
        isError: true,
      );
    }
    if (waitModeEngine.segmentInProgress ||
        waitModeEngine.heldNotes.isNotEmpty) {
      _ensureWaitModeTimer();
    } else if (!waitModeEngine.waiting) {
      timelineController?.forward();
    }
    setState(() {
      isPaused = false;
      isWaiting = waitModeEngine.waiting;
    });
  }

  Future<void> _loadScore() async {
    await scoreAudioPlaybackService.stop();
    if (!mounted) return;
    timelineController?.dispose();
    timelineController = null;
    setState(() {
      isLoading = true;
      loadingError = null;
      score = null;
      scorePreviewPreparing = false;
      scorePreviewPlaying = false;
    });

    try {
      final loadedScore = await scoreLoader.load(widget.source);
      if (!mounted) return;
      final controller =
          AnimationController(
              vsync: this,
              duration: approachDuration + loadedScore.timeline.totalDuration,
            )
            ..addListener(_handleTimelineTick)
            ..addStatusListener(_handleTimelineStatus);
      performanceTracker.loadTimeline(loadedScore.timeline);
      waitModeEngine.loadGroups(performanceTracker.noteGroups);
      setState(() {
        score = loadedScore;
        pianoRange = SynthesiaPianoRange.forTimeline(loadedScore.timeline);
        timelineController = controller;
        isLoading = false;
        _resetAttemptState();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadingError = context.l10n.synthesiaScorePreparationFailed;
      });
    }
  }

  Future<void> _connectMidi() async {
    if (isConnectingMidi || isMidiConnected) return;
    setState(() {
      isConnectingMidi = true;
      midiStatus = context.l10n.synthesiaSearchingMidiPiano;
    });

    try {
      final devices = await midiInputService.getDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() {
          isConnectingMidi = false;
          midiStatus = context.l10n.synthesiaNoMidiPianoDetected;
        });
        _scheduleMidiReconnectControls();
        return;
      }
      final device = devices.first;
      setState(() {
        midiStatus = context.l10n.synthesiaConnectingToDevice(device.name);
      });
      await midiInputService.connectToDevice(device);
      if (!mounted) return;
      if (!midiInputService.isConnected) {
        setState(() {
          isConnectingMidi = false;
          isMidiConnected = false;
          midiStatus = context.l10n.synthesiaMidiConnectionFailed;
        });
        _scheduleMidiReconnectControls();
        return;
      }
      setState(() {
        isConnectingMidi = false;
        isMidiConnected = true;
        midiStatus = device.name;
        activeMidiNotes = <int>{};
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isConnectingMidi = false;
        isMidiConnected = false;
        midiStatus = context.l10n.synthesiaCouldNotConnectMidiPiano;
      });
      _showMessage(context.l10n.synthesiaMidiConnectionFailed);
      _scheduleMidiReconnectControls();
    }
  }

  void _scheduleMidiReconnectControls() {
    if (!mounted || midiReconnectSheetScheduled || practiceControlsSheetOpen) {
      return;
    }

    midiReconnectSheetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      midiReconnectSheetScheduled = false;
      if (!mounted || practiceControlsSheetOpen || isMidiConnected) return;
      unawaited(_showPracticeControlsSheet());
    });
  }

  Duration get _scoreElapsed {
    final controller = timelineController;
    if (controller == null || controller.duration == null) return Duration.zero;
    final animationUs = (controller.duration!.inMicroseconds * controller.value)
        .round();
    return Duration(
      microseconds: (animationUs - approachDuration.inMicroseconds)
          .clamp(0, score?.timeline.totalDuration.inMicroseconds ?? 0)
          .toInt(),
    );
  }

  bool get _leadInActive {
    final controller = timelineController;
    if (controller == null || controller.duration == null) return false;
    return controller.duration!.inMicroseconds * controller.value <
        approachDuration.inMicroseconds;
  }

  void _startOrResume() {
    final controller = timelineController;
    if (controller == null || !isMidiConnected || isComplete) return;

    if (isPaused) {
      if (mode == SynthesiaMode.wait) {
        waitModeEngine.resume();
        _ensureWaitModeTimer();
      }
      setState(() => isPaused = false);
      if (mode == SynthesiaMode.performance && !isWaiting) {
        controller.forward();
      }
      return;
    }

    if (!hasStarted) {
      performanceTracker.resetAttempt();
      _resetWaitState();
      setState(() {
        hasStarted = true;
        isPaused = false;
        isComplete = false;
      });
      if (mode == SynthesiaMode.wait) waitModeEngine.start();
      controller.forward(from: 0);
    }
  }

  void _restart() {
    final controller = timelineController;
    if (controller == null || !isMidiConnected) return;
    performanceTracker.resetAttempt();
    _resetWaitState();
    controller.stop();
    setState(() {
      hasStarted = true;
      isPaused = false;
      isComplete = false;
    });
    if (mode == SynthesiaMode.wait) waitModeEngine.start();
    controller.forward(from: 0);
  }

  void _prepareRetry() {
    final controller = timelineController;
    if (controller == null) return;

    controller.stop();
    performanceTracker.resetAttempt();
    setState(() {
      completionDialogOpen = false;
      activeMidiNotes = <int>{};
      _resetAttemptState();
    });
    controller.value = 0;
  }

  void _stopPractice() {
    final controller = timelineController;
    if (controller == null) return;

    controller.stop();
    performanceTracker.resetAttempt();
    _resetWaitState();
    controller.value = 0;
    setState(() {
      hasStarted = false;
      isPaused = false;
      isComplete = false;
      completionDialogOpen = false;
      requireReleaseAfterSeek = activeMidiNotes.isNotEmpty;
    });
  }

  void _resetAttemptState() {
    hasStarted = false;
    isPaused = false;
    isComplete = false;
    _resetWaitState();
  }

  void _resetWaitState() {
    waitModeTimer?.cancel();
    waitModeTimer = null;
    waitModeEngine.reset();
    scrubTargetGroupIndex = 0;
    isWaiting = false;
    isScrubbing = false;
    requireReleaseAfterSeek = false;
  }

  Future<void> _changeMode(SynthesiaMode newMode) async {
    if (newMode == mode) return;

    final colors = widget.colors;
    final isPerformanceMode = newMode == SynthesiaMode.performance;
    final modeName = isPerformanceMode
        ? context.l10n.synthesiaPerformanceMode
        : context.l10n.synthesiaWaitMode;
    final modeIcon = isPerformanceMode
        ? Icons.timer_outlined
        : Icons.hourglass_empty_rounded;
    final modeDescription = isPerformanceMode
        ? context.l10n.synthesiaPerformanceModeDescription
        : context.l10n.synthesiaWaitModeDescription;
    final modeDetails = isPerformanceMode
        ? [
            context.l10n.synthesiaPerformanceDetailMovingNotes,
            context.l10n.synthesiaPerformanceDetailEvaluation,
            context.l10n.synthesiaPerformanceDetailSkillTiming,
          ]
        : [
            context.l10n.synthesiaWaitDetailNoTimeLimit,
            context.l10n.synthesiaWaitDetailHoldNotes,
            context.l10n.synthesiaWaitDetailReleaseKeys,
            context.l10n.synthesiaWaitDetailDragTimeline,
          ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          iconPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          icon: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: Icon(
              modeIcon,
              color: colors.primaryColor,
              size: AppIconSizes.md,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          title: Text(
            context.l10n.synthesiaSwitchToModeQuestion(modeName),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 155, maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  modeDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                    height: 1.25,
                  ),
                ),
                const Gap(AppSpacing.sm),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: modeDetails
                        .map(
                          (detail) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: colors.primaryColor,
                                  size: 18,
                                ),
                                const Gap(AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: TextStyle(
                                      color: colors.primaryColor,
                                      fontSize: AppTextSizes.caption,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        context.l10n.cancel,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        context.l10n.synthesiaSwitchMode,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    timelineController?.stop();
    timelineController?.value = 0;
    performanceTracker.resetAttempt();
    setState(() {
      mode = newMode;
      _resetAttemptState();
    });

    if (newMode == SynthesiaMode.wait && mounted && !isMidiConnected) {
      await _showMidiConnectionRequiredDialog(forPerformanceMode: false);
    }
  }

  Future<void> _handleStartPressed() async {
    if (scorePreviewPreparing || scorePreviewPlaying) {
      await _stopScorePreview();
    }

    if (isMidiConnected) {
      _startOrResume();
      return;
    }

    await _showMidiConnectionRequiredDialog(
      forPerformanceMode: mode == SynthesiaMode.performance,
    );
    if (mounted && isMidiConnected) {
      _startOrResume();
    }
  }

  Future<void> _showMidiConnectionRequiredDialog({
    required bool forPerformanceMode,
  }) async {
    if (!mounted || isMidiConnected) return;

    final colors = widget.colors;
    final shouldConnect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: Icon(
              Icons.piano_rounded,
              color: colors.primaryColor,
              size: AppIconSizes.md,
            ),
          ),
          title: Text(
            context.l10n.synthesiaConnectMidiKeyboard,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            forPerformanceMode
                ? context.l10n.synthesiaPerformanceRequiresMidi
                : context.l10n.synthesiaWaitRequiresMidi,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.body,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        context.l10n.cancel,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.usb_rounded, size: 18),
                      label: Text(
                        context.l10n.synthesiaConnectMidi,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted || shouldConnect != true) return;
    await _connectMidi();
  }

  Future<void> _toggleScorePreview() async {
    if (scorePreviewPreparing || scorePreviewPlaying) {
      await _stopScorePreview();
      return;
    }
    if (hasStarted) return;

    final audioUrl = score?.audioUrl?.trim() ?? '';
    if (audioUrl.isEmpty) {
      _showMessage(context.l10n.synthesiaNoMp3Preview);
      return;
    }

    setState(() {
      scorePreviewPreparing = true;
      activeMidiNotes = <int>{};
    });

    await scoreAudioPlaybackService.play(
      audioUrl: audioUrl,
      onStarted: () {
        if (!mounted) return;
        setState(() {
          scorePreviewPreparing = false;
          scorePreviewPlaying = true;
        });
      },
      onFinished: () {
        if (!mounted) return;
        setState(() {
          scorePreviewPreparing = false;
          scorePreviewPlaying = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          scorePreviewPreparing = false;
          scorePreviewPlaying = false;
        });
        _showMessage(context.l10n.synthesiaMp3PlaybackFailed);
      },
    );
  }

  Future<void> _stopScorePreview() async {
    await scoreAudioPlaybackService.stop();
    if (!mounted) return;
    setState(() {
      scorePreviewPreparing = false;
      scorePreviewPlaying = false;
    });
  }

  void _handleTimelineTick() {
    if (!mounted || !hasStarted || isPaused || isComplete || isScrubbing) {
      return;
    }

    if (mode == SynthesiaMode.performance) {
      final changed = performanceTracker.updatePerformanceTime(
        _scoreElapsed.inMilliseconds,
      );
      if (changed) setState(() {});
      return;
    }

    final targetGroupIndex = waitModeEngine.targetGroupIndex;
    if (isWaiting ||
        targetGroupIndex >= performanceTracker.noteGroups.length) {
      return;
    }

    final controller = timelineController;
    if (controller == null || controller.duration == null) return;
    final target = performanceTracker.noteGroups[targetGroupIndex];
    final targetAnimationUs =
        approachDuration.inMicroseconds + target.startTime.inMicroseconds;
    final currentAnimationUs =
        (controller.duration!.inMicroseconds * controller.value).round();
    if (currentAnimationUs < targetAnimationUs) return;

    controller.stop();
    waitModeEngine.beginWaiting();
    setState(() => isWaiting = true);
    controller.value = targetAnimationUs / controller.duration!.inMicroseconds;
  }

  void _tryCompleteWaitTarget() {
    final targetGroupIndex = waitModeEngine.targetGroupIndex;
    if (!mounted ||
        mode != SynthesiaMode.wait ||
        !hasStarted ||
        isPaused ||
        !isWaiting ||
        waitModeEngine.targetRetryAfterRelease ||
        requireReleaseAfterSeek ||
        targetGroupIndex >= performanceTracker.noteGroups.length) {
      return;
    }

    final group = performanceTracker.noteGroups[targetGroupIndex];
    Set<int> allowedNotes = <int>{
      ...group.midiNotes,
      ...waitModeEngine.carriedNotes,
    };
    bool expectedReady = activeMidiNotes.containsAll(group.midiNotes) &&
        group.midiNotes.every(waitModeEngine.pressedNotes.contains);
    bool hasUnexpectedNote = activeMidiNotes.any(
      (midiNote) => !allowedNotes.contains(midiNote),
    );

    if (!expectedReady || hasUnexpectedNote) {
      return;
    }

    if (!waitModeEngine.chordTimingMatches(
      performanceTracker.chordPressWindow,
    )) {
      performanceTracker.recordWaitModeTimingMistake(targetGroupIndex);
      waitModeEngine.beginTargetRetry(group.midiNotes);
      performanceTracker.showDurationFeedback(
        context.l10n.synthesiaReleaseChordPressTogether,
        isError: true,
      );
      setState(() {});
      return;
    }

    waitModeEngine.acceptCurrentGroup();
    performanceTracker.showDurationFeedback(
      context.l10n.synthesiaCorrectNotesKeepHolding,
    );
    _ensureWaitModeTimer();
    setState(() => isWaiting = false);
  }

  void _ensureWaitModeTimer() {
    waitModeTimer ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _updateWaitModeProgress(),
    );
  }

  void _updateWaitModeProgress() {
    if (!mounted ||
        mode != SynthesiaMode.wait ||
        isPaused ||
        isComplete ||
        waitModeEngine.retryAfterRelease) {
      return;
    }

    SynthesiaWaitTickResult result = waitModeEngine.tick(
      activeMidiNotes,
      waitOverholdTolerance,
    );
    if (result.overheldGroupIndex != null &&
        result.overheldMidiNote != null) {
      _showWaitModeOverholdError(
        result.overheldGroupIndex!,
        result.overheldMidiNote!,
      );
      return;
    }

    if (result.segmentCompleted &&
        waitModeEngine.targetGroupIndex <
            performanceTracker.noteGroups.length) {
      _snapWaitTimelineToGroup(waitModeEngine.targetGroupIndex);
      isWaiting = true;
      _tryCompleteWaitTarget();
    }

    List<SynthesiaWaitHeldNote> dueForRelease = waitModeEngine
        .heldNotes
        .values
        .where(
          (note) =>
              activeMidiNotes.contains(note.midiNote) &&
              waitModeEngine.isReadyForRelease(note),
        )
        .toList();
    if (dueForRelease.isNotEmpty) {
      performanceTracker.showDurationFeedback(
        context.l10n.synthesiaReleaseNotes(
          _formatMidiNotes(dueForRelease.map((note) => note.midiNote)),
        ),
      );
    } else if (waitModeEngine.waiting &&
        waitModeEngine.heldNotes.isNotEmpty) {
      String heldNames = _formatMidiNotes(
        waitModeEngine.heldNotes.values
            .where((note) => activeMidiNotes.contains(note.midiNote))
            .map((note) => note.midiNote),
      );
      String expectedNames = _formatMidiNotes(waitModeEngine.expectedNotes);
      performanceTracker.showDurationFeedback(
        heldNames.isEmpty
            ? context.l10n.synthesiaPlayNotes(expectedNames)
            : context.l10n.synthesiaHoldWhilePlaying(
                heldNames,
                expectedNames,
              ),
      );
    } else if (waitModeEngine.segmentInProgress) {
      performanceTracker.showDurationFeedback(
        waitModeEngine.heldNotes.isEmpty
            ? context.l10n.synthesiaGetReadyNextNote
            : context.l10n.synthesiaCorrectNotesKeepHolding,
      );
    }

    if (!waitModeEngine.segmentInProgress &&
        waitModeEngine.heldNotes.isEmpty) {
      waitModeTimer?.cancel();
      waitModeTimer = null;
    }
    setState(() => isWaiting = waitModeEngine.waiting);
  }

  void _handleWaitModeNoteOff(int midiNote) {
    SynthesiaWaitReleaseResult result = waitModeEngine.releaseNote(
      midiNote,
      waitReleaseGrace,
      waitOverholdTolerance,
    );
    if (result.type == SynthesiaWaitReleaseType.heldTooLong) {
      _showWaitModeOverholdError(result.groupIndex!, midiNote);
      return;
    }
    if (result.type == SynthesiaWaitReleaseType.releasedEarly) {
      performanceTracker.recordWaitModeDurationMistake(
        result.groupIndex!,
        context.l10n.synthesiaNoteReleasedTooSoon(
          MidiNoteUtils.nameForMidiNote(midiNote),
        ),
      );
      performanceTracker.showDurationFeedback(
        context.l10n.synthesiaReleasedTooSoonTryAgain,
        isError: true,
      );
      waitModeTimer?.cancel();
      waitModeTimer = null;
      setState(() => isWaiting = false);
      return;
    }

    if (result.type == SynthesiaWaitReleaseType.completed) {
      if (result.groupCompleted) {
        performanceTracker.completeWaitModeGroup(result.groupIndex!);
      }
      if (waitModeEngine.isComplete) {
        _completeWaitMode();
        return;
      }
      setState(() {});
    }
  }

  void _showWaitModeOverholdError(int groupIndex, int midiNote) {
    performanceTracker.recordWaitModeDurationMistake(
      groupIndex,
      context.l10n.synthesiaNoteHeldTooLong(
        MidiNoteUtils.nameForMidiNote(midiNote),
      ),
    );
    performanceTracker.showDurationFeedback(
      context.l10n.synthesiaReleaseAllNoteHeldTooLong(
        MidiNoteUtils.nameForMidiNote(midiNote),
      ),
      isError: true,
    );
    waitModeTimer?.cancel();
    waitModeTimer = null;
    setState(() => isWaiting = false);
  }

  void _completeWaitMode() {
    if (isComplete) return;
    waitModeTimer?.cancel();
    waitModeTimer = null;
    waitModeEngine.pause();
    setState(() {
      isComplete = true;
      isPaused = false;
      isWaiting = false;
    });
    timelineController?.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showCompletionDialog());
    });
  }

  void _snapWaitTimelineToGroup(int groupIndex) {
    final controller = timelineController;
    if (controller == null ||
        controller.duration == null ||
        groupIndex < 0 ||
        groupIndex >= performanceTracker.noteGroups.length) {
      return;
    }
    ArPracticeNoteGroup group = performanceTracker.noteGroups[groupIndex];
    int targetAnimationUs =
        approachDuration.inMicroseconds + group.startTime.inMicroseconds;
    controller.value = targetAnimationUs / controller.duration!.inMicroseconds;
  }

  String _formatMidiNotes(Iterable<int> midiNotes) {
    List<int> notes = midiNotes.toSet().toList()..sort();
    return notes.map(MidiNoteUtils.nameForMidiNote).join(' + ');
  }

  void _beginScrub(DragStartDetails details) {
    if (mode != SynthesiaMode.wait || !hasStarted || isComplete) return;
    if (activeMidiNotes.isNotEmpty || waitModeEngine.heldNotes.isNotEmpty) {
      _showMessage(context.l10n.synthesiaReleaseAllBeforeMoving);
      return;
    }
    timelineController?.stop();
    waitModeTimer?.cancel();
    waitModeTimer = null;
    waitModeEngine.pause();
    setState(() => isScrubbing = true);
  }

  void _updateScrub(DragUpdateDetails details, double travelHeight) {
    final controller = timelineController;
    if (!isScrubbing || controller == null || controller.duration == null) {
      return;
    }
    final deltaUs =
        (details.delta.dy / travelHeight * approachDuration.inMicroseconds)
            .round();
    final currentUs = (controller.duration!.inMicroseconds * controller.value)
        .round();
    final nextUs = (currentUs + deltaUs).clamp(
      approachDuration.inMicroseconds,
      controller.duration!.inMicroseconds,
    );
    controller.value = nextUs / controller.duration!.inMicroseconds;
    scrubTargetGroupIndex = _nearestGroupIndex(_scoreElapsed);
    setState(() {});
  }

  void _finishScrub(DragEndDetails details) {
    if (!isScrubbing) return;
    final controller = timelineController;
    final groups = performanceTracker.noteGroups;
    if (controller == null || controller.duration == null || groups.isEmpty) {
      setState(() => isScrubbing = false);
      return;
    }

    final groupIndex = _nearestGroupIndex(_scoreElapsed);
    final target = groups[groupIndex];
    final targetAnimationUs =
        approachDuration.inMicroseconds + target.startTime.inMicroseconds;
    controller.value = targetAnimationUs / controller.duration!.inMicroseconds;
    performanceTracker.resetAttempt();
    performanceTracker.nextEvaluationIndex = groupIndex;
    waitModeEngine.resetFromGroup(groupIndex);
    setState(() {
      scrubTargetGroupIndex = groupIndex;
      isScrubbing = false;
      isWaiting = true;
      requireReleaseAfterSeek = activeMidiNotes.isNotEmpty;
    });
  }

  int _nearestGroupIndex(Duration position) {
    final groups = performanceTracker.noteGroups;
    if (groups.isEmpty) return 0;
    var nearest = 0;
    var distance = (groups.first.startTime - position).abs();
    for (var index = 1; index < groups.length; index++) {
      final candidateDistance = (groups[index].startTime - position).abs();
      if (candidateDistance < distance) {
        distance = candidateDistance;
        nearest = index;
      }
    }
    return nearest;
  }

  void _handleTimelineStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        !hasStarted ||
        isComplete) {
      return;
    }
    if (mode == SynthesiaMode.wait && !waitModeEngine.isComplete) return;
    if (mode == SynthesiaMode.performance) {
      performanceTracker.finalizeRemainingPerformanceGroups();
    }
    waitModeTimer?.cancel();
    waitModeTimer = null;
    waitModeEngine.pause();
    setState(() {
      isComplete = true;
      isPaused = false;
      isWaiting = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showCompletionDialog());
    });
  }

  Future<void> _showCompletionDialog() async {
    if (completionDialogOpen) return;
    completionDialogOpen = true;

    final colors = widget.colors;
    final totalGroups = performanceTracker.totalGroupCount;
    final totalMistakes = performanceTracker.mistakeCount;
    final isPerfect = totalMistakes == 0;
    final accentColor = isPerfect
        ? Colors.green.shade700
        : Colors.amber.shade800;
    final icon = isPerfect ? Icons.check_circle : Icons.warning_amber_rounded;
    final title = isPerfect
        ? context.l10n.synthesiaPerfect
        : context.l10n.synthesiaExerciseCompleted;
    final message = isPerfect
        ? context.l10n.synthesiaCompletedWithoutMistakes
        : context.l10n.synthesiaCompletedWithMistakes(totalMistakes);
    final scoreText = mode == SynthesiaMode.performance
        ? '${performanceTracker.correctGroupCount}/$totalGroups'
        : '${performanceTracker.evaluatedGroupCount}/$totalGroups';
    final resultStats = mode == SynthesiaMode.performance
        ? <({String label, String value})>[
            (
              label: context.l10n.synthesiaCorrectOnTime,
              value: '${performanceTracker.correctGroupCount}/$totalGroups',
            ),
            (
              label: context.l10n.synthesiaWrongNotes,
              value: '${performanceTracker.wrongGroupCount}',
            ),
            (
              label: context.l10n.synthesiaNotPlayed,
              value: '${performanceTracker.missedGroupCount}',
            ),
            (
              label: context.l10n.synthesiaPlayedOnTime,
              value: '${performanceTracker.accuracyPercentage}%',
            ),
            (
              label: context.l10n.synthesiaMusicLength,
              value: _formatDuration(score?.timeline.totalDuration ?? Duration.zero),
            ),
          ]
        : <({String label, String value})>[
            (
              label: context.l10n.synthesiaCompleted,
              value: '${performanceTracker.evaluatedGroupCount}/$totalGroups',
            ),
            (
              label: context.l10n.synthesiaFirstTry,
              value: '${performanceTracker.correctGroupCount}',
            ),
            (label: context.l10n.synthesiaMistakes, value: '$totalMistakes'),
            (
              label: context.l10n.synthesiaTime,
              value: context.l10n.synthesiaNoLimit,
            ),
          ];
    final performanceReport = mode == SynthesiaMode.performance
        ? _buildSynthesiaPerformanceReport()
        : null;
    Future<String>? activeResultSaveFuture = performanceReport == null
        ? null
        : practiceResultService.savePerformanceResult(performanceReport);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                        const Gap(AppSpacing.md),
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
                                softWrap: true,
                                style: TextStyle(
                                  color: colors.secondaryTextColor,
                                  fontSize: AppTextSizes.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(AppSpacing.md),
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
                    const Gap(AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: resultStats
                          .map(
                            (stat) => _buildResultStatTile(
                              colors: colors,
                              label: stat.label,
                              value: stat.value,
                            ),
                          )
                          .toList(),
                    ),
                    if (performanceReport != null) ...[
                      const Gap(AppSpacing.md),
                      _buildPerformanceInsights(
                        colors: colors,
                        report: performanceReport,
                      ),
                    ],
                    const Gap(AppSpacing.md),
                    if (activeResultSaveFuture != null)
                      _buildResultSaveStatus(
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
                            : (resultId) {
                                Navigator.of(dialogContext).pop();
                                unawaited(
                                  _openPracticeResult(
                                    result: performanceReport.summary.copyWith(
                                      id: resultId,
                                      completedAt: DateTime.now(),
                                    ),
                                  ),
                                );
                              },
                      )
                    else
                      _buildWaitModeResultNotice(colors),
                    const Gap(AppSpacing.md),
                    SizedBox(
                      width: 460,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _prepareRetry();
                              },
                              style: _secondaryButtonStyle(colors),
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(
                                context.l10n.retry,
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              style: _primaryButtonStyle(colors),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: Text(
                                context.l10n.done,
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
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
    completionDialogOpen = false;
  }

  Widget _buildResultStatTile({
    required AppThemeColors colors,
    required String label,
    required String value,
  }) {
    return Container(
      width: 150,
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
            softWrap: true,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
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

  Widget _buildResultSaveStatus({
    required AppThemeColors colors,
    required Future<String>? saveFuture,
    required VoidCallback? onRetry,
    required ValueChanged<String>? onViewResult,
  }) {
    return FutureBuilder<String>(
      future: saveFuture,
      builder: (context, snapshot) {
        final isSaving = snapshot.connectionState == ConnectionState.waiting;
        final isSaved = snapshot.hasData;
        final statusColor = isSaved
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                  const Gap(AppSpacing.sm),
                  Flexible(
                    child: Text(
                      isSaving
                          ? context.l10n.synthesiaSavingResult
                          : isSaved
                          ? context.l10n.synthesiaResultSaved
                          : context.l10n.synthesiaResultNotSaved,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if ((snapshot.hasError && onRetry != null) ||
                  (snapshot.hasData && onViewResult != null)) ...[
                const Gap(AppSpacing.xs),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (snapshot.hasError && onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: Text(context.l10n.synthesiaRetrySave),
                      ),
                    if (snapshot.hasData && onViewResult != null)
                      TextButton.icon(
                        onPressed: () => onViewResult(snapshot.data!),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primaryColor,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(
                          context.l10n.synthesiaViewFullResult,
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPracticeResult({
    required PracticeResultSummary result,
  }) async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) return;

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
        if (mounted) _prepareRetry();
      }
    }
  }

  Widget _buildPerformanceInsights({
    required AppThemeColors colors,
    required SightReadingPerformanceReport report,
  }) {
    final attentionItems = _buildAttentionItems(report);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInsightPanel(
            colors: colors,
            icon: Icons.troubleshoot_rounded,
            title: context.l10n.synthesiaWhatToWorkOn,
            items: attentionItems,
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: _buildInsightPanel(
            colors: colors,
            icon: Icons.lightbulb_outline_rounded,
            title: context.l10n.synthesiaHowToImprove,
            items: report.suggestions,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightPanel({
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
              const Gap(AppSpacing.xs),
              Text(
                title,
                softWrap: true,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xs),
          ...items.take(3).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '• $item',
                softWrap: true,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildAttentionItems(SightReadingPerformanceReport report) {
    if (report.errorEvents.isEmpty) {
      return <String>[context.l10n.synthesiaNoRepeatedProblems];
    }

    final difficultNotes = report.summary.noteBreakdown
        .where((item) => item.errorCount > 0)
        .toList()
      ..sort(
        (first, second) => second.errorCount.compareTo(first.errorCount),
      );
    final items = <String>[];
    if (difficultNotes.isNotEmpty) {
      final note = difficultNotes.first;
      items.add(
        context.l10n.synthesiaTroubleWithNoteTimes(
          MidiNoteUtils.nameForMidiNote(note.midiNote),
          note.errorCount,
        ),
      );
    }

    final issueCounts = <PerformanceIssueType, int>{};
    for (final event in report.errorEvents) {
      for (final issueType in event.issueTypes) {
        issueCounts.update(issueType, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final releasedEarly = issueCounts[PerformanceIssueType.releasedEarly] ?? 0;
    if (releasedEarly > 0) {
      items.add(
        context.l10n.synthesiaGroupsReleasedEarly(releasedEarly),
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

  Widget _buildWaitModeResultNotice(AppThemeColors colors) {
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
          const Gap(AppSpacing.sm),
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

  String get _resultDocumentPath {
    final source = widget.source;
    if (source is SynthesiaCompositionSource) {
      return 'users/${source.composition.ownerId}/compositions/${source.composition.id}';
    }
    if (source is SynthesiaPublishedCompositionSource) {
      return 'compositionPosts/${source.composition.id}/versions/${source.composition.currentVersion}';
    }
    if (source is SynthesiaDocumentSource) return source.documentPath;
    if (source is SynthesiaLibraryPieceSource) return source.documentPath;
    return '';
  }

  String get _resultSource {
    if (widget.source is SynthesiaLibraryPieceSource) return 'musicLibrary';
    return widget.source is SynthesiaDocumentSource ? 'musicSheet' : 'composition';
  }

  SightReadingPerformanceReport _buildSynthesiaPerformanceReport() {
    return performanceReportBuilder.build(
      tracker: performanceTracker,
      scoreDocumentPath: _resultDocumentPath,
      source: _resultSource,
      pieceTitle: score?.title ?? context.l10n.synthesiaUntitledScore,
      targetDurationMs: score?.timeline.totalDuration.inMilliseconds ?? 0,
      elapsedDurationMs: _scoreElapsed.inMilliseconds,
      messages: SynthesiaPerformanceReportMessages(
        perfectPerformance: context.l10n.synthesiaSuggestionPerfect,
        almostPerfect: context.l10n.synthesiaSuggestionAlmostPerfect,
        difficultNote: context.l10n.synthesiaSuggestionDifficultNote,
        releasedTooSoon: context.l10n.synthesiaSuggestionReleasedTooSoon,
        missedNotes: context.l10n.synthesiaSuggestionMissedNotes,
        playedLate: context.l10n.synthesiaSuggestionPlayedLate,
        playedEarly: context.l10n.synthesiaSuggestionPlayedEarly,
        chordTiming: context.l10n.synthesiaSuggestionChordTiming,
        wrongNotes: context.l10n.synthesiaSuggestionWrongNotes,
        generalPractice: context.l10n.synthesiaSuggestionGeneralPractice,
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(AppThemeColors colors) {
    return FilledButton.styleFrom(
      backgroundColor: colors.primaryColor,
      foregroundColor: colors.backgroundColor,
      disabledBackgroundColor: colors.borderColor,
      disabledForegroundColor: colors.secondaryTextColor,
    );
  }

  ButtonStyle _secondaryButtonStyle(AppThemeColors colors) {
    return OutlinedButton.styleFrom(
      foregroundColor: colors.primaryColor,
      disabledForegroundColor: colors.secondaryTextColor.withValues(
        alpha: 0.55,
      ),
      side: BorderSide(color: colors.borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildStatusScreen(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.synthesiaPreparing),
          ],
        ),
      );
    }
    if (loadingError != null || score == null || pianoRange == null) {
      return _buildStatusScreen(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52),
            const SizedBox(height: 12),
            Text(
              loadingError ?? context.l10n.synthesiaScorePreparationFailed,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.back),
                ),
                FilledButton(
                  onPressed: _loadScore,
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final loadedScore = score!;
    final range = pianoRange!;
    final controller = timelineController!;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller.stop();
          waitModeTimer?.cancel();
          waitModeTimer = null;
          waitModeEngine.pause();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050B14),
        body: SafeArea(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) => _buildControlBar(loadedScore),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboardHeight = (constraints.maxHeight * 0.24)
                        .clamp(82.0, 150.0)
                        .toDouble();
                    final fallingHeight =
                        constraints.maxHeight - keyboardHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: fallingHeight,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragStart: _beginScrub,
                                onVerticalDragUpdate: (details) {
                                  _updateScrub(details, fallingHeight);
                                },
                                onVerticalDragEnd: _finishScrub,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    SynthesiaFallingNotes(
                                      timeline: loadedScore.timeline,
                                      range: range,
                                      animation: controller,
                                      approachDuration: approachDuration,
                                      results: performanceTracker
                                          .noteResultsByStartMicroseconds,
                                      waitPreviewOriginStartMicroseconds:
                                          mode == SynthesiaMode.wait &&
                                              waitModeEngine
                                                  .segmentInProgress &&
                                              waitModeEngine
                                                      .segmentOriginGroupIndex !=
                                                  null
                                          ? performanceTracker
                                                .noteGroups[waitModeEngine
                                                    .segmentOriginGroupIndex!]
                                                .startTime
                                                .inMicroseconds
                                          : null,
                                      waitHoldProgress:
                                          mode == SynthesiaMode.wait
                                          ? Map<
                                              SynthesiaWaitNoteOccurrence,
                                              double
                                            >.unmodifiable(
                                              waitModeEngine.holdProgress,
                                            )
                                          : const <
                                              SynthesiaWaitNoteOccurrence,
                                              double
                                            >{},
                                      waitPreviewAdvanceMicroseconds:
                                          mode == SynthesiaMode.wait
                                          ? waitModeEngine
                                                .timelinePreviewAdvanceMicroseconds
                                          : 0,
                                      hiddenGroupStartMicroseconds:
                                          mode == SynthesiaMode.performance
                                          ? performanceTracker
                                                .finalizedGroupStartMicroseconds
                                          : const <int>{},
                                      hiddenWaitOccurrences:
                                          mode == SynthesiaMode.wait
                                          ? Set<
                                              SynthesiaWaitNoteOccurrence
                                            >.unmodifiable(
                                              waitModeEngine.hiddenOccurrences,
                                            )
                                          : const <
                                              SynthesiaWaitNoteOccurrence
                                            >{},
                                    ),
                                    _buildFeedbackOverlay(),
                                    if (isScrubbing) _buildScrubOverlay(),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: keyboardHeight,
                              child: SynthesiaKeyboard(
                                range: range,
                                activeMidiNotes: activeMidiNotes,
                                expectedMidiNotes: _expectedMidiNotes,
                              ),
                            ),
                          ],
                        ),
                        if (_shouldShowStartButton())
                          _buildStartButton(
                            widget.colors,
                            bottom: keyboardHeight + AppSpacing.sm,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowStartButton() {
    return !hasStarted && !isComplete && !isScrubbing && !completionDialogOpen;
  }

  bool get _isPracticeRunning {
    return hasStarted && !isComplete;
  }

  bool _canStartPractice() {
    return _shouldShowStartButton() &&
        timelineController != null &&
        !isConnectingMidi &&
        !scorePreviewPreparing &&
        !scorePreviewPlaying;
  }

  Widget _buildStartButton(AppThemeColors colors, {required double bottom}) {
    final buttonLabel = mode == SynthesiaMode.performance
        ? context.l10n.synthesiaStartPerformance
        : context.l10n.synthesiaStartWaitMode;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, minHeight: 48),
          child: FilledButton.icon(
            onPressed: _canStartPractice()
                ? () {
                    unawaited(_handleStartPressed());
                  }
                : null,
            style: _primaryButtonStyle(colors).copyWith(
              elevation: const WidgetStatePropertyAll(4),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              buttonLabel,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusScreen({required Widget child}) {
    return Scaffold(
      backgroundColor: widget.colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.colors.backgroundColor,
        foregroundColor: widget.colors.primaryColor,
        title: Text(context.l10n.synthesia),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    );
  }

  Widget _buildControlBar(SynthesiaScore loadedScore) {
    final colors = widget.colors;
    final totalGroups = performanceTracker.totalGroupCount;
    final completedGroups = performanceTracker.evaluatedGroupCount.clamp(
      0,
      totalGroups,
    ).toInt();
    final progress = totalGroups > 0
        ? (completedGroups / totalGroups).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final percentage = (progress * 100).round();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showTitle = screenWidth >= 700;
    final showProgress = screenWidth >= 620;
    final canSwitchMode =
        !hasStarted &&
        !isScrubbing &&
        !isWaiting &&
        !scorePreviewPreparing &&
        !scorePreviewPlaying &&
        !completionDialogOpen;
    final feedback = _feedbackAppearance(colors);

    if (_isPracticeRunning) {
      return _buildActivePracticeBar(
        colors: colors,
        loadedScore: loadedScore,
        completedGroups: completedGroups,
        totalGroups: totalGroups,
        progress: progress,
        percentage: percentage,
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border(bottom: BorderSide(color: colors.borderColor)),
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
            const Gap(AppSpacing.xs),
            SizedBox(
              width: 132,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.synthesia,
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
                      loadedScore.title,
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
          const Gap(AppSpacing.sm),
          PracticeModeToggle<SynthesiaMode>(
            firstValue: SynthesiaMode.wait,
            firstLabel: context.l10n.synthesiaWait,
            secondValue: SynthesiaMode.performance,
            secondLabel: context.l10n.synthesiaPerformance,
            selectedValue: mode,
            colors: colors,
            onChanged: canSwitchMode
                ? (selectedMode) {
                    unawaited(_changeMode(selectedMode));
                  }
                : null,
          ),
          const Gap(AppSpacing.sm),
          if (showProgress)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$completedGroups / $totalGroups · $percentage% · ${_compactTimeStatus(loadedScore)}',
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.caption,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: colors.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Gap(AppSpacing.sm),
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
          const Gap(AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => unawaited(_showPracticeControlsSheet()),
            style: _secondaryButtonStyle(colors).copyWith(
              visualDensity: VisualDensity.compact,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(context.l10n.synthesiaControls),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePracticeBar({
    required AppThemeColors colors,
    required SynthesiaScore loadedScore,
    required int completedGroups,
    required int totalGroups,
    required double progress,
    required int percentage,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border(bottom: BorderSide(color: colors.borderColor)),
      ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$completedGroups / $totalGroups · $percentage% · ${_compactTimeStatus(loadedScore)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Gap(AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: colors.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _stopPractice,
              style: _secondaryButtonStyle(colors).copyWith(
                visualDensity: VisualDensity.compact,
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
              ),
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: Text(context.l10n.stop),
            ),
          ),
        ],
      ),
    );
  }

  ({String text, IconData icon, Color color}) _feedbackAppearance(
    AppThemeColors colors,
  ) {
    if (scorePreviewPreparing) {
      return (
        text: context.l10n.synthesiaLoadingMp3Preview,
        icon: Icons.hourglass_top_rounded,
        color: colors.secondaryTextColor,
      );
    }
    if (scorePreviewPlaying) {
      return (
        text: context.l10n.synthesiaListeningMp3Preview,
        icon: Icons.volume_up_rounded,
        color: colors.primaryColor,
      );
    }
    if (isComplete) {
      return (
        text: context.l10n.synthesiaCompleted,
        icon: Icons.check_circle_rounded,
        color: Colors.green.shade600,
      );
    }
    if (isPaused) {
      return (
        text: context.l10n.synthesiaPracticeInterrupted,
        icon: Icons.warning_amber_rounded,
        color: Colors.amber.shade700,
      );
    }
    if (waitModeEngine.targetRetryAfterRelease) {
      return (
        text: _localizedTrackerFeedback(performanceTracker.feedbackText),
        icon: Icons.warning_amber_rounded,
        color: Colors.amber.shade700,
      );
    }
    if (isWaiting) {
      return (
        text: performanceTracker.feedbackText == 'Ready'
            ? context.l10n.synthesiaPlayHighlightedNoteOrChord
            : _localizedTrackerFeedback(performanceTracker.feedbackText),
        icon: Icons.piano_rounded,
        color: colors.primaryColor,
      );
    }
    if (!hasStarted) {
      return (
        text: context.l10n.synthesiaReady,
        icon: Icons.radio_button_checked_rounded,
        color: colors.secondaryTextColor,
      );
    }

    return switch (performanceTracker.feedbackKind) {
      ArPracticeFeedbackKind.correct => (
        text: _localizedTrackerFeedback(performanceTracker.feedbackText),
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green.shade600,
      ),
      ArPracticeFeedbackKind.warning => (
        text: _localizedTrackerFeedback(performanceTracker.feedbackText),
        icon: Icons.schedule_rounded,
        color: Colors.amber.shade700,
      ),
      ArPracticeFeedbackKind.incorrect => (
        text: _localizedTrackerFeedback(performanceTracker.feedbackText),
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

  Future<void> _showPracticeControlsSheet() async {
    if (!mounted || practiceControlsSheetOpen) return;

    practiceControlsSheetOpen = true;
    final colors = widget.colors;

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        enableDrag: false,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, refreshControls) {
              final feedback = _feedbackAppearance(colors);
              final canTogglePreview =
                  timelineController != null &&
                  (!hasStarted || scorePreviewPreparing || scorePreviewPlaying);
              final canConnectMidi =
                  !isConnectingMidi &&
                  !isMidiConnected &&
                  !scorePreviewPreparing &&
                  !scorePreviewPlaying;
              final canStart =
                  timelineController != null &&
                  !isConnectingMidi &&
                  (!hasStarted || isPaused);
              final canRestart = isMidiConnected && hasStarted;
              final showMidiReconnectPrompt =
                  !isMidiConnected && !isConnectingMidi;

              Future<void> runAndRefresh(Future<void> Function() action) async {
                final actionFuture = action();
                if (sheetContext.mounted) refreshControls(() {});
                await actionFuture;
                if (sheetContext.mounted) refreshControls(() {});
              }

              return SafeArea(
                child: SingleChildScrollView(
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
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feedback.text,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.label,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  mode == SynthesiaMode.performance
                                      ? context.l10n.synthesiaPerformanceMode
                                      : context.l10n.synthesiaWaitMode,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: colors.secondaryTextColor,
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Container(
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
                                  const Gap(AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      isMidiConnected
                                          ? midiStatus
                                          : context.l10n.synthesiaMidiOffline,
                                      softWrap: true,
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
                          ),
                          const Gap(AppSpacing.sm),
                          IconButton(
                            tooltip: context.l10n.synthesiaCloseControls,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            color: colors.primaryColor,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      if (showMidiReconnectPrompt) ...[
                        const Gap(AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: Colors.amber.shade700.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade700,
                                size: AppIconSizes.sm,
                              ),
                              const Gap(AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  context.l10n.synthesiaMidiReconnectPrompt,
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Gap(AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: canTogglePreview
                                  ? () => unawaited(
                                      runAndRefresh(_toggleScorePreview),
                                    )
                                  : null,
                              style: _secondaryButtonStyle(colors),
                              icon: scorePreviewPreparing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      scorePreviewPlaying
                                          ? Icons.stop_rounded
                                          : Icons.volume_up_rounded,
                                    ),
                              label: Text(
                                scorePreviewPreparing
                                    ? context.l10n.loading
                                    : scorePreviewPlaying
                                    ? context.l10n.stop
                                    : context.l10n.synthesiaListen,
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: canConnectMidi
                                  ? () => unawaited(runAndRefresh(_connectMidi))
                                  : null,
                              style: _secondaryButtonStyle(colors),
                              icon: isConnectingMidi
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
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
                                softWrap: true,
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: canStart
                                  ? () {
                                      Navigator.of(sheetContext).pop();
                                      unawaited(_handleStartPressed());
                                    }
                                  : null,
                              style: _primaryButtonStyle(colors),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                isPaused
                                    ? context.l10n.resume
                                    : context.l10n.synthesiaStart,
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: canRestart
                                  ? () {
                                      Navigator.of(sheetContext).pop();
                                      _restart();
                                    }
                                  : null,
                              style: _secondaryButtonStyle(colors),
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(
                                context.l10n.synthesiaRestart,
                                textAlign: TextAlign.center,
                                softWrap: true,
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
      practiceControlsSheetOpen = false;
    }
  }

  Widget _buildFeedbackOverlay() {
    final colors = widget.colors;
    final feedback = _feedbackAppearance(colors);
    final activeNotesText = _activeNotesText;
    final text = requireReleaseAfterSeek
        ? context.l10n.synthesiaReleaseAllKeysToContinue
        : isWaiting && performanceTracker.feedbackText == 'Ready'
        ? context.l10n.synthesiaPlayHighlightedNoteOrChord
        : feedback.text;

    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Center(
        child: IgnorePointer(
          child: Container(
            width: 430,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: feedback.color.withValues(alpha: 0.35)),
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
                const Gap(AppSpacing.xs),
                Flexible(
                  child: Text(
                    context.l10n.synthesiaPlayedNotes(text, activeNotesText),
                    softWrap: true,
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

  String get _activeNotesText {
    final sortedActiveNotes = activeMidiNotes.toList()..sort();
    return sortedActiveNotes.isEmpty
        ? context.l10n.synthesiaNone
        : sortedActiveNotes.map(MidiNoteUtils.nameForMidiNote).join(' + ');
  }

  Set<int> get _expectedMidiNotes {
    if (mode != SynthesiaMode.wait ||
        !isWaiting ||
        waitModeEngine.targetGroupIndex < 0 ||
        waitModeEngine.targetGroupIndex >=
            performanceTracker.noteGroups.length) {
      return const <int>{};
    }
    return waitModeEngine.expectedNotes;
  }

  Widget _buildScrubOverlay() {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7DE3FF)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            context.l10n.synthesiaNoteGroupPosition(
              _formatDuration(_scoreElapsed),
              scrubTargetGroupIndex + 1,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _compactTimeStatus(SynthesiaScore loadedScore) {
    if (mode == SynthesiaMode.wait) {
      return context.l10n.synthesiaNoTimeLimitCompact;
    }

    final target = _formatDuration(loadedScore.timeline.totalDuration);
    if (!hasStarted && !isComplete) {
      return context.l10n.synthesiaTargetDuration(target);
    }

    return '${_formatDuration(_scoreElapsed)} / $target';
  }

  String _localizedTrackerFeedback(String feedback) {
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
        context.l10n.synthesiaCorrectNotesKeepHolding,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    waitModeTimer?.cancel();
    waitModeEngine.reset();
    timelineController?.dispose();
    unawaited(activeNotesSubscription?.cancel());
    unawaited(noteOnSubscription?.cancel());
    unawaited(noteEventSubscription?.cancel());
    unawaited(connectionSubscription?.cancel());
    unawaited(midiInputService.dispose());
    unawaited(scoreAudioPlaybackService.dispose());
    scoreLoader.dispose();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}
