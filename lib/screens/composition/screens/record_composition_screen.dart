import 'package:soundsight/screens/onboarding/widgets/screen_feature_tour.dart';
import 'package:soundsight/services/processing_job_service.dart';
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/composition_limits.dart';
import 'package:soundsight/screens/composition/models/recorded_midi_event.dart';
import 'package:soundsight/screens/composition/models/recording_composition_draft.dart';
import 'package:soundsight/screens/composition/dialogs/recording/recording_completion_dialog.dart';
import 'package:soundsight/screens/composition/widgets/recording/camera_switch_button.dart';
import 'package:soundsight/screens/composition/widgets/recording/midi_connection_button.dart';
import 'package:soundsight/screens/composition/widgets/recording/recording_control_button.dart';
import 'package:soundsight/screens/composition/widgets/recording/recording_generation_overlay.dart';
import 'package:soundsight/screens/composition/widgets/recording/recording_timer_badge.dart';
import 'package:soundsight/screens/composition/services/composition_generation_service.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';
import 'package:soundsight/screens/composition/services/recorded_performance_processor.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/screens/players/services/midi_video_audio_capture.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class RecordCompositionScreen extends StatefulWidget {
  const RecordCompositionScreen({
    super.key,
    required this.colors,
    required this.draft,
  });

  final AppThemeColors colors;
  final RecordingCompositionDraft draft;

  @override
  State<RecordCompositionScreen> createState() =>
      _RecordCompositionScreenState();
}

class _RecordCompositionScreenState extends State<RecordCompositionScreen>
    with WidgetsBindingObserver {
  CameraController? cameraController;
  List<CameraDescription> deviceCameras = [];
  CameraLensDirection selectedLensDirection = CameraLensDirection.back;
  String? cameraError;
  bool isInitializingCamera = false;

  final MidiInputService midiInputService = MidiInputService();
  StreamSubscription<bool>? midiConnectionSubscription;
  StreamSubscription<Set<int>>? midiActiveNotesSubscription;
  StreamSubscription<MidiNoteEvent>? midiNoteEventSubscription;
  Set<int> activeMidiNotes = {};
  String midiStatus = 'No MIDI piano connected';
  bool isConnectingMidi = false;

  bool isRecording = false;
  bool isStartingRecording = false;
  bool isStoppingRecording = false;
  bool isGeneratingComposition = false;
  bool stopWhenHeldKeysAreReleased = false;
  bool durationWarningShown = false;
  int acceptedNoteOnCount = 0;
  XFile? recordedVideo;
  MidiVideoAudioCapture? videoAudioCapture;
  Future<void> Function()? releaseVideoPreview;
  Timer? recordingTimer;
  Duration recordingDuration = Duration.zero;
  final Stopwatch midiRecordingStopwatch = Stopwatch();
  final List<RecordedMidiEvent> recordedMidiEvents = [];
  RecordedPerformanceResult? performanceResult;
  Composition? savedComposition;
  String? reservedCompositionId;

  final CompositionService compositionService = CompositionService();
  final CompositionGenerationService compositionGenerationService =
      CompositionGenerationService();

  RecordedPerformanceProcessor get performanceProcessor {
    return RecordedPerformanceProcessor(
      beatsPerMeasure: widget.draft.beatsPerMeasure,
      beatUnit: widget.draft.beatUnit,
    );
  }

  bool get midiIsConnected => midiInputService.isConnected;
  bool get cameraIsReady =>
      cameraController != null && cameraController!.value.isInitialized;
  bool get canStartRecording => cameraIsReady && midiIsConnected;
  bool get canSwitchCamera {
    final hasFront = deviceCameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    final hasBack = deviceCameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    return hasFront && hasBack;
  }

  String get recordingDurationText => formatDuration(recordingDuration);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    midiConnectionSubscription = midiInputService.connectionStream.listen(
      handleMidiConnectionChanged,
    );
    midiActiveNotesSubscription = midiInputService.activeNotesStream.listen(
      handleActiveMidiNotesChanged,
    );
    midiNoteEventSubscription = midiInputService.noteEventStream.listen(
      handleMidiNoteEvent,
    );
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(initializeCamera());
  }

  Future<void> initializeCamera({CameraDescription? selectedCamera}) async {
    if (isInitializingCamera) return;
    final previousController = cameraController;
    setState(() {
      isInitializingCamera = true;
      cameraError = null;
      cameraController = null;
    });
    await previousController?.dispose();

    CameraController? newController;
    try {
      if (deviceCameras.isEmpty) deviceCameras = await availableCameras();
      if (deviceCameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          isInitializingCamera = false;
          cameraError = context.l10n.noCameraAvailable;
        });
        return;
      }
      final camera =
          selectedCamera ??
          deviceCameras.firstWhere(
            (item) => item.lensDirection == selectedLensDirection,
            orElse: () => deviceCameras.first,
          );
      newController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await newController.initialize();
      await setRecordingFocus(newController, locked: false);
      await disableRecordingStabilization(newController);
      if (!mounted) {
        await newController.dispose();
        return;
      }
      setState(() {
        cameraController = newController;
        selectedLensDirection = camera.lensDirection;
        isInitializingCamera = false;
      });
    } on CameraException catch (error) {
      await newController?.dispose();
      if (!mounted) return;
      setState(() {
        isInitializingCamera = false;
        cameraError = error.description ?? context.l10n.cameraOpenFailed;
      });
    } catch (_) {
      await newController?.dispose();
      if (!mounted) return;
      setState(() {
        isInitializingCamera = false;
        cameraError = context.l10n.cameraOpenFailed;
      });
    }
  }

  Future<void> disableRecordingStabilization(CameraController controller) async {
    try {
      await controller.setVideoStabilizationMode(VideoStabilizationMode.off);
    } catch (_) {
      // Optional camera controls are not available on every device.
    }
  }

  Future<void> setRecordingFocus(
    CameraController controller, {
    required bool locked,
  }) async {
    try {
      await controller.setFocusMode(locked ? FocusMode.locked : FocusMode.auto);
    } catch (_) {
      // Fixed-focus cameras can still record without focus controls.
    }
  }

  Future<void> switchCamera() async {
    if (isRecording || isInitializingCamera || !canSwitchCamera) return;
    final targetDirection = selectedLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final targetCamera = deviceCameras.firstWhere(
      (camera) => camera.lensDirection == targetDirection,
    );
    await initializeCamera(selectedCamera: targetCamera);
  }

  Future<void> connectToMidi() async {
    if (isConnectingMidi || midiIsConnected) return;
    setState(() {
      isConnectingMidi = true;
      midiStatus = 'Searching for MIDI piano';
    });
    try {
      final devices = await midiInputService.getDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() {
          isConnectingMidi = false;
          midiStatus = 'No MIDI piano detected';
        });
        return;
      }
      final device = devices.first;
      setState(() => midiStatus = 'Connecting to ${device.name}');
      await midiInputService.connectToDevice(device);
      if (!mounted) return;
      setState(() {
        isConnectingMidi = false;
        midiStatus = 'Connected: ${device.name}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isConnectingMidi = false;
        midiStatus = 'MIDI connection failed';
      });
    }
  }

  void handleMidiConnectionChanged(bool connected) {
    if (!mounted) return;
    final disconnectedDuringRecording = !connected && isRecording;
    final deviceName = midiInputService.connectedDevice?.name;
    setState(() {
      isConnectingMidi = false;
      midiStatus = connected
          ? deviceName == null
                ? 'MIDI piano connected'
                : 'Connected: $deviceName'
          : 'MIDI piano disconnected';
    });
    if (disconnectedDuringRecording) {
      showMessage(
        'MIDI disconnected. Stopping recording.',
        type: AppSnackBarType.warning,
      );
      unawaited(stopRecording(closeHeldNotes: true));
    }
  }

  void handleActiveMidiNotesChanged(Set<int> notes) {
    activeMidiNotes = Set<int>.from(notes);
    if (isRecording && stopWhenHeldKeysAreReleased && activeMidiNotes.isEmpty) {
      unawaited(stopRecording());
    }
  }

  void handleMidiNoteEvent(MidiNoteEvent event) {
    if (!isRecording || !midiRecordingStopwatch.isRunning) return;
    final elapsed = Duration(
      microseconds: midiRecordingStopwatch.elapsedMicroseconds,
    );
    final maximumDuration = performanceProcessor.maximumRecordingDuration;
    if (elapsed >= maximumDuration) {
      unawaited(
        stopRecording(closeHeldNotes: true, maximumEndTime: maximumDuration),
      );
      return;
    }

    if (event.type == MidiNoteEventType.noteOn) {
      if (acceptedNoteOnCount >= RecordedPerformanceProcessor.maximumNotes) {
        stopWhenHeldKeysAreReleased = true;
        if (activeMidiNotes.isEmpty) unawaited(stopRecording());
        return;
      }
      acceptedNoteOnCount++;
      if (CompositionLimits.warningMilestones.contains(acceptedNoteOnCount)) {
        showMessage(
          context.l10n.recordingNoteLimitWarning(
            acceptedNoteOnCount, CompositionLimits.maximumNotes,
          ),
          type: AppSnackBarType.warning,
        );
      }
      if (acceptedNoteOnCount == RecordedPerformanceProcessor.maximumNotes) {
        stopWhenHeldKeysAreReleased = true;
        showMessage(
          context.l10n.recordingNoteLimitReached(CompositionLimits.maximumNotes),
          type: AppSnackBarType.warning,
        );
      }
    }

    recordedMidiEvents.add(
      RecordedMidiEvent(
        type: event.type,
        noteNumber: event.noteNumber,
        velocity: event.velocity,
        timestamp: elapsed,
      ),
    );
  }

  Future<void> startRecording() async {
    final controller = cameraController;
    if (isStartingRecording || isStoppingRecording || isGeneratingComposition ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isRecordingVideo ||
        !midiIsConnected) {
      return;
    }
    setState(() => isStartingRecording = true);
    try {
      await deleteTemporaryVideo();
      final capture = await MidiVideoAudioCapture.start(
        notes: midiInputService.noteEventStream,
        controls: midiInputService.controlEventStream,
      );
      if (!mounted || !midiIsConnected) {
        await capture.dispose();
        return;
      }
      videoAudioCapture = capture;
      // A stationary keyboard should keep its focus when CameraX adds the
      // video use case, rather than continuously refocusing on moving hands.
      await setRecordingFocus(controller, locked: true);
      await disableRecordingStabilization(controller);
      if (!mounted || !midiIsConnected || !identical(cameraController, controller)) {
        await capture.dispose();
        await setRecordingFocus(controller, locked: false);
        return;
      }
      await controller.startVideoRecording();
      // CameraX can reconfigure its capture session when video starts.
      await disableRecordingStabilization(controller);
      if (!mounted) {
        await capture.dispose();
        return;
      }
      recordedMidiEvents.clear();
      performanceResult = null;
      savedComposition = null;
      reservedCompositionId = null;
      acceptedNoteOnCount = 0;
      stopWhenHeldKeysAreReleased = false;
      durationWarningShown = false;
      midiRecordingStopwatch
        ..reset()
        ..start();
      setState(() {
        isRecording = true;
        recordingDuration = Duration.zero;
      });
      startRecordingTimer();
    } on CameraException catch (error) {
      await setRecordingFocus(controller, locked: false);
      await videoAudioCapture?.dispose();
      videoAudioCapture = null;
      if (!mounted) return;
      showMessage(
        error.description ?? context.l10n.recordingStartFailed,
        type: AppSnackBarType.error,
      );
    } catch (_) {
      await setRecordingFocus(controller, locked: false);
      await videoAudioCapture?.dispose();
      videoAudioCapture = null;
      if (mounted) {
        showMessage(context.l10n.recordingStartFailed, type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => isStartingRecording = false);
    }
  }

  void startRecordingTimer() {
    recordingTimer?.cancel();
    final maximumDuration = performanceProcessor.maximumRecordingDuration;
    final warningDuration = Duration(
      microseconds: (maximumDuration.inMicroseconds * 0.9).round(),
    );
    recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !isRecording) return;
      final elapsed = Duration(
        microseconds: midiRecordingStopwatch.elapsedMicroseconds,
      );
      setState(() => recordingDuration = elapsed);
      if (!durationWarningShown && elapsed >= warningDuration) {
        durationWarningShown = true;
        showMessage(
          context.l10n.recordingLengthWarning,
          type: AppSnackBarType.warning,
        );
      }
      if (elapsed >= maximumDuration) {
        showMessage(
          context.l10n.recordingLengthReached,
          type: AppSnackBarType.warning,
        );
        unawaited(
          stopRecording(closeHeldNotes: true, maximumEndTime: maximumDuration),
        );
      }
    });
  }

  Future<void> stopRecording({
    bool closeHeldNotes = false,
    Duration? maximumEndTime,
  }) async {
    if (isStoppingRecording) return;
    if (!closeHeldNotes && activeMidiNotes.isNotEmpty) {
      stopWhenHeldKeysAreReleased = true;
      showMessage(context.l10n.releaseHeldKeysToFinish);
      return;
    }
    final controller = cameraController;
    if (controller == null || !controller.value.isRecordingVideo) return;
    isStoppingRecording = true;
    var stopTime = Duration(
      microseconds: midiRecordingStopwatch.elapsedMicroseconds,
    );
    if (maximumEndTime != null && stopTime > maximumEndTime) {
      stopTime = maximumEndTime;
      recordedMidiEvents.removeWhere(
        (event) => event.timestamp > maximumEndTime,
      );
    }
    if (closeHeldNotes) {
      for (final noteNumber in unmatchedRecordedNoteNumbers()) {
        recordedMidiEvents.add(
          RecordedMidiEvent(
            type: MidiNoteEventType.noteOff,
            noteNumber: noteNumber,
            velocity: 0,
            timestamp: stopTime,
          ),
        );
      }
    }
    midiRecordingStopwatch.stop();
    videoAudioCapture?.stop();
    recordingTimer?.cancel();
    recordingTimer = null;

    try {
      final video = await controller.stopVideoRecording().timeout(
        const Duration(seconds: 10),
      );
      await setRecordingFocus(controller, locked: false);
      final result = performanceProcessor.process(recordedMidiEvents);
      if (!mounted) {
        try {
          final file = File(video.path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
        return;
      }
      setState(() {
        isRecording = false;
        recordedVideo = video;
        performanceResult = result;
        recordingDuration = Duration(microseconds: result.durationUs);
      });
      if (result.notes.isEmpty) {
        await showEmptyRecordingDialog();
        await discardRecording();
        return;
      }
      await showRecordingCompletionDialog();
    } on TimeoutException {
      await recoverCameraAfterRecordingFailure(
        controller,
        context.l10n.cameraSaveRestarted,
      );
    } on CameraException catch (error) {
      await recoverCameraAfterRecordingFailure(
        controller,
        error.description ?? context.l10n.videoRecordingFailed,
      );
    } finally {
      isStoppingRecording = false;
    }
  }

  List<int> unmatchedRecordedNoteNumbers() {
    final unmatchedCounts = <int, int>{};
    for (final event in recordedMidiEvents) {
      final currentCount = unmatchedCounts[event.noteNumber] ?? 0;
      if (event.type == MidiNoteEventType.noteOn) {
        unmatchedCounts[event.noteNumber] = currentCount + 1;
      } else if (currentCount > 1) {
        unmatchedCounts[event.noteNumber] = currentCount - 1;
      } else {
        unmatchedCounts.remove(event.noteNumber);
      }
    }
    return [
      for (final entry in unmatchedCounts.entries)
        for (var count = 0; count < entry.value; count++) entry.key,
    ];
  }

  Future<void> showEmptyRecordingDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          context.l10n.noNotesRecorded,
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          context.l10n.noNotesRecordedDescription,
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.backgroundColor,
            ),
            child: Text(context.l10n.recordAgain),
          ),
        ],
      ),
    );
  }

  Future<void> showRecordingCompletionDialog() async {
    final video = recordedVideo;
    final result = performanceResult;
    if (video == null || result == null || !mounted) return;
    final action = await showDialog<RecordingCompletionAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordingCompletionDialog(
        colors: widget.colors,
        compositionTitle: widget.draft.title,
        durationText: formatDuration(Duration(microseconds: result.durationUs)),
        noteCount: result.notes.length,
        videoPath: video.path,
        prepareVideo: () {
          final capture = videoAudioCapture;
          if (capture == null) throw StateError('Recording audio is unavailable.');
          return capture.prepare(video.path);
        },
        onPreviewReleaseReady: (release) => releaseVideoPreview = release,
        detectedTempo: result.detectedTempo,
        measureCount: result.measureCount,
      ),
    );
    await releaseVideoPreview?.call();
    releaseVideoPreview = null;
    if (!mounted) return;
    if (action == RecordingCompletionAction.discard) {
      await discardRecording();
    } else if (action == RecordingCompletionAction.generate) {
      await generateRecordedComposition();
    }
  }

  Composition createRecordedComposition() {
    final result = performanceResult;
    if (result == null || result.notes.isEmpty) {
      throw StateError('Record at least one complete MIDI note.');
    }
    return Composition(
      id: savedComposition?.id ?? reservedCompositionId ?? '',
      ownerId: widget.draft.ownerId,
      title: widget.draft.title,
      tempo: result.detectedTempo,
      measureCount: result.measureCount,
      notes: const [],
      recordingSchemaVersion: Composition.currentRecordingSchemaVersion,
      performanceNotes: result.notes,
      performanceDurationUs: result.durationUs,
      creationMethod: Composition.recordingCreationMethod,
      keySignature: widget.draft.keySignature,
      beatsPerMeasure: widget.draft.beatsPerMeasure,
      beatUnit: widget.draft.beatUnit,
      createdAt: savedComposition?.createdAt,
      updatedAt: savedComposition?.updatedAt,
    );
  }

  Future<Composition> saveRecordedCompositionOnce() async {
    if (savedComposition != null) return savedComposition!;
    reservedCompositionId ??= compositionService.reserveCompositionId(
      widget.draft.ownerId,
    );
    final composition = createRecordedComposition();
    final id = await compositionService.createComposition(composition);
    savedComposition = composition.copyWith(id: id);
    return savedComposition!;
  }

  Future<void> generateRecordedComposition() async {
    if (isGeneratingComposition) return;
    setState(() => isGeneratingComposition = true);
    Composition? composition;
    try {
      composition = await saveRecordedCompositionOnce();
    } catch (_) {
      if (mounted) {
        setState(() => isGeneratingComposition = false);
        await showSaveFailureDialog();
      }
      return;
    }

    try {
      await compositionGenerationService.generateCompositionFiles(composition);
      await deleteTemporaryVideo();
      if (!mounted) return;
      setState(() => isGeneratingComposition = false);
      showMessage(context.l10n.jobAccepted);
      if (mounted) Navigator.pop(context, composition.id);
    } catch (error) {
      await deleteTemporaryVideo();
      if (!mounted) return;
      setState(() => isGeneratingComposition = false);
      showMessage(
        error is ProcessingJobException
            ? '${context.l10n.compositionSaved} ${error.message(context)}'
            : context.l10n.jobSavedNotQueued,
        type: AppSnackBarType.warning,
      );
      Navigator.pop(context, composition.id);
    }
  }

  Future<void> showSaveFailureDialog() async {
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          context.l10n.compositionNotSaved,
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          context.l10n.recordingStillAvailable,
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: widget.colors.secondaryTextColor,
            ),
            child: Text(context.l10n.recordAgain),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.backgroundColor,
            ),
            child: Text(context.l10n.retrySave),
          ),
        ],
      ),
    );
    if (retry == true) {
      await generateRecordedComposition();
    } else {
      await discardRecording();
    }
  }

  Future<void> showGenerationFailureDialog(String compositionId) async {
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          context.l10n.filesNotGenerated,
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          context.l10n.filesNotGeneratedDescription,
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: widget.colors.secondaryTextColor,
            ),
            child: Text(context.l10n.finish),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.backgroundColor,
            ),
            child: Text(context.l10n.retryGeneration),
          ),
        ],
      ),
    );
    if (retry == true) {
      await generateRecordedComposition();
      return;
    }
    await deleteTemporaryVideo();
    if (mounted) Navigator.pop(context, compositionId);
  }

  Future<void> discardRecording() async {
    await deleteTemporaryVideo();
    recordedMidiEvents.clear();
    performanceResult = null;
    savedComposition = null;
    reservedCompositionId = null;
    midiRecordingStopwatch.reset();
    if (!mounted) return;
    setState(() {
      recordingDuration = Duration.zero;
      acceptedNoteOnCount = 0;
      stopWhenHeldKeysAreReleased = false;
    });
  }

  Future<void> deleteTemporaryVideo() async {
    final video = recordedVideo;
    final capture = videoAudioCapture;
    final release = releaseVideoPreview;
    releaseVideoPreview = null;
    videoAudioCapture = null;
    recordedVideo = null;
    await release?.call();
    await capture?.dispose();
    if (video == null) return;
    try {
      final file = File(video.path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> recoverCameraAfterRecordingFailure(
    CameraController failedController,
    String message,
  ) async {
    if (!mounted) return;
    setState(() {
      cameraController = null;
      isRecording = false;
    });
    try {
      await failedController.dispose().timeout(const Duration(seconds: 3));
    } catch (_) {}
    await deleteTemporaryVideo();
    if (!mounted) return;
    showMessage(message);
    unawaited(initializeCamera());
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  void showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showLatestSnackBar(
      appSnackBar(colors: widget.colors, message: message, type: type),
    );
  }

  void showMidiRequiredSnackBar() {
    showMessage('Connect your MIDI piano before recording.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = cameraController;
    if (state == AppLifecycleState.inactive && !isRecording) {
      if (controller == null) return;
      selectedLensDirection = controller.description.lensDirection;
      cameraController = null;
      unawaited(controller.dispose());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed &&
        cameraController == null &&
        !isInitializingCamera) {
      CameraDescription? cameraToRestore;
      for (final camera in deviceCameras) {
        if (camera.lensDirection == selectedLensDirection) {
          cameraToRestore = camera;
          break;
        }
      }
      unawaited(initializeCamera(selectedCamera: cameraToRestore));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFeatureTour(featureId: 'recording_composition', key: ValueKey('recording_composition'), colors: widget.colors, canStart: () => !isRecording && !isStartingRecording && !isStoppingRecording && !isGeneratingComposition && !isInitializingCamera, child: PopScope(
      canPop: !isRecording && !isStartingRecording && !isStoppingRecording && !isGeneratingComposition,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: cameraIsReady
                  ? Center(
                      // CameraPreview uses the camera's own orientation and
                      // aspect ratio, including the orientation of a recording.
                      // Loose constraints keep the image in proportion.
                      child: CameraPreview(cameraController!),
                    )
                  : cameraError != null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off_rounded,
                              color: Colors.white70,
                              size: AppIconSizes.xl,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              cameraError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              onPressed: initializeCamera,
                              child: Text(context.l10n.tryAgain),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              left: AppSpacing.md,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: isRecording
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  color: Colors.white,
                  disabledColor: Colors.white38,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
            MidiConnectionButton(
              status: midiStatus,
              isConnecting: isConnectingMidi,
              isConnected: midiIsConnected,
              isRecording: isRecording,
              onConnect: connectToMidi,
            ),
            if (isRecording)
              RecordingTimerBadge(durationText: recordingDurationText),
            RecordingControlButton(
              isRecording: isRecording,
              midiIsConnected: midiIsConnected,
              cameraIsReady: cameraIsReady,
              onStartRecording: startRecording,
              onStopRecording: stopRecording,
              onMidiRequired: showMidiRequiredSnackBar,
            ),
            if (canSwitchCamera)
              CameraSwitchButton(
                isRecording: isRecording,
                onSwitch: switchCamera,
              ),
            if (isGeneratingComposition || isStartingRecording)
              RecordingGenerationOverlay(
                colors: widget.colors,
                title: isStartingRecording ? context.l10n.performanceVideoPreparing : null,
              ),
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    recordingTimer?.cancel();
    midiRecordingStopwatch.stop();
    unawaited(deleteTemporaryVideo());
    unawaited(cameraController?.dispose());
    unawaited(midiConnectionSubscription?.cancel());
    unawaited(midiActiveNotesSubscription?.cancel());
    unawaited(midiNoteEventSubscription?.cancel());
    unawaited(midiInputService.dispose());
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    super.dispose();
  }
}
