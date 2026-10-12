import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/recorded_midi_event.dart';
import 'package:soundsight/screens/composition/models/recording_composition_draft.dart';
import 'package:soundsight/screens/composition/screens/recording/dialogs/recording_completion_dialog.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/camera_switch_button.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/midi_connection_button.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/recording_control_button.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/recording_generation_overlay.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/recording_timer_badge.dart';
import 'package:soundsight/screens/composition/services/composition_generation_service.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';
import 'package:soundsight/screens/composition/services/recorded_performance_processor.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
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
  CameraLensDirection selectedLensDirection = CameraLensDirection.front;
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
  bool isStoppingRecording = false;
  bool isGeneratingComposition = false;
  bool stopWhenHeldKeysAreReleased = false;
  bool noteWarningShown = false;
  bool durationWarningShown = false;
  int acceptedNoteOnCount = 0;
  XFile? recordedVideo;
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
          cameraError = 'No camera is available on this device.';
        });
        return;
      }
      final camera =
          selectedCamera ??
          deviceCameras.firstWhere(
            (item) => item.lensDirection == CameraLensDirection.front,
            orElse: () => deviceCameras.first,
          );
      newController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await newController.initialize();
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
        cameraError = error.description ?? 'The camera could not be opened.';
      });
    } catch (_) {
      await newController?.dispose();
      if (!mounted) return;
      setState(() {
        isInitializingCamera = false;
        cameraError = 'The camera could not be opened.';
      });
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
      showMessage('MIDI disconnected. Stopping recording.');
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
      if (acceptedNoteOnCount == 240 && !noteWarningShown) {
        noteWarningShown = true;
        showMessage('You have captured 240 of the 256-note limit.');
      }
      if (acceptedNoteOnCount == RecordedPerformanceProcessor.maximumNotes) {
        stopWhenHeldKeysAreReleased = true;
        showMessage(
          'The 256-note limit was reached. Release held keys to finish.',
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
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isRecordingVideo ||
        !midiIsConnected) {
      return;
    }
    try {
      await deleteTemporaryVideo();
      await controller.startVideoRecording();
      if (!mounted) return;
      recordedMidiEvents.clear();
      performanceResult = null;
      savedComposition = null;
      reservedCompositionId = null;
      acceptedNoteOnCount = 0;
      stopWhenHeldKeysAreReleased = false;
      noteWarningShown = false;
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
      showMessage(error.description ?? 'Could not start recording.');
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
        showMessage('You are close to the maximum recording length.');
      }
      if (elapsed >= maximumDuration) {
        showMessage('The maximum recording length was reached.');
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
      showMessage('Release the held keys to finish the recording.');
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
    recordingTimer?.cancel();
    recordingTimer = null;

    try {
      final video = await controller.stopVideoRecording().timeout(
        const Duration(seconds: 10),
      );
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
        'The camera could not finish saving the video. The camera was restarted.',
      );
    } on CameraException catch (error) {
      await recoverCameraAfterRecordingFailure(
        controller,
        error.description ?? 'The video recording failed.',
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
          'No notes were recorded',
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          'Play at least one complete note on the connected MIDI piano before stopping.',
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.backgroundColor,
            ),
            child: const Text('Record Again'),
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
        detectedTempo: result.detectedTempo,
        measureCount: result.measureCount,
      ),
    );
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
      showMessage('Composition created successfully.');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context, composition.id);
    } catch (_) {
      try {
        await compositionService.markGenerationFailed(
          composition.ownerId,
          composition.id,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() => isGeneratingComposition = false);
      await showGenerationFailureDialog(composition.id);
    }
  }

  Future<void> showSaveFailureDialog() async {
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          'Composition not saved',
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          'Your recording is still available. Check your connection and try saving again.',
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: widget.colors.secondaryTextColor,
            ),
            child: const Text('Record Again'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.backgroundColor,
            ),
            child: const Text('Retry Save'),
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
          'Files were not generated',
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          'The composition was saved, but its PDF, MIDI, MusicXML, and MP3 could not be created.',
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: widget.colors.secondaryTextColor,
            ),
            child: const Text('Finish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.backgroundColor,
            ),
            child: const Text('Retry Generation'),
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
    recordedVideo = null;
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

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final cameraAspectRatio = cameraIsReady
        ? cameraController!.value.aspectRatio
        : 16 / 9;
    final previewAspectRatio = isPortrait
        ? 1 / cameraAspectRatio
        : cameraAspectRatio;

    return PopScope(
      canPop: !isRecording && !isGeneratingComposition,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: cameraIsReady
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: previewAspectRatio,
                        child: CameraPreview(cameraController!),
                      ),
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
                            OutlinedButton.icon(
                              onPressed: initializeCamera,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
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
            if (isGeneratingComposition)
              RecordingGenerationOverlay(colors: widget.colors),
          ],
        ),
      ),
    );
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
