import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/models/quantized_note.dart';
import 'package:soundsight/screens/composition/models/recorded_midi_event.dart';
import 'package:soundsight/screens/composition/models/recorded_note.dart';
import 'package:soundsight/screens/composition/screens/recording/dialogs/recording_completion_dialog.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/camera_switch_button.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/midi_connection_button.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/recording_control_button.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/recording_generation_overlay.dart';
import 'package:soundsight/screens/composition/screens/recording/widgets/recording_timer_badge.dart';
import 'package:soundsight/screens/composition/services/composition_generation_service.dart';
import 'package:soundsight/screens/composition/services/composition_midi_processor.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:flutter/services.dart';

class RecordCompositionScreen extends StatefulWidget {
  const RecordCompositionScreen({
    super.key,
    required this.colors,
    required this.composition,
  });

  final AppThemeColors colors;
  final Composition composition;

  /// Creates the mutable state that manages recording and generation.
  @override
  State<RecordCompositionScreen> createState() =>
      _RecordCompositionScreenState();
}

class _RecordCompositionScreenState extends State<RecordCompositionScreen>
    with WidgetsBindingObserver {
  // Camera state

  /// Controls the active camera preview and video recording session.
  CameraController? cameraController;

  /// Stores every camera detected on the device so the user can switch lenses.
  List<CameraDescription> deviceCameras = [];

  /// Stores which lens should remain selected when the camera is reopened.
  CameraLensDirection selectedLensDirection = CameraLensDirection.front;

  /// Stores the message shown when the camera cannot be opened.
  String? cameraError;

  /// Prevents another camera initialization while one is already running.
  bool isInitializingCamera = false;

  // MIDI connection state

  /// Discovers MIDI devices, manages the connection, and provides MIDI events.
  final MidiInputService midiInputService = MidiInputService();

  /// Listens for MIDI connection and disconnection changes.
  StreamSubscription<bool>? midiConnectionSubscription;

  /// Listens for changes to the set of piano keys currently being held.
  StreamSubscription<Set<int>>? midiActiveNotesSubscription;

  /// Listens for individual note-on and note-off events from the MIDI piano.
  StreamSubscription<MidiNoteEvent>? midiNoteEventSubscription;

  /// Stores the MIDI note numbers of the keys currently being held down.
  Set<int> activeMidiNotes = {};

  /// Stores the connection message displayed by the MIDI button.
  String midiStatus = 'No MIDI piano connected';

  /// Reports whether the app is currently attempting to connect to MIDI.
  bool isConnectingMidi = false;

  // Recording state and timing

  /// Reports whether video and MIDI event capture are currently active.
  bool isRecording = false;

  /// Prevents multiple stop requests from reaching the camera at once.
  bool isStoppingRecording = false;

  /// Stores the temporary video file returned after recording stops.
  XFile? recordedVideo;

  /// Updates the visible recording duration once per second.
  Timer? recordingTimer;

  /// Stores the elapsed duration displayed in the recording timer badge.
  Duration recordingDuration = Duration.zero;

  /// Provides precise timestamps for MIDI events during the recording.
  final Stopwatch midiRecordingStopwatch = Stopwatch();

  // MIDI processing and notation data

  /// Stores raw timestamped note-on and note-off events captured from MIDI.
  final List<RecordedMidiEvent> recordedMidiEvents = [];

  /// Stores complete notes created by pairing note-on and note-off events.
  final List<RecordedNote> recordedNotes = [];

  /// Stores recorded notes after their timing is snapped to the grid.
  final List<QuantizedNote> quantizedNotes = [];

  /// Groups quantized notes by starting tick so simultaneous notes form chords.
  final Map<int, List<QuantizedNote>> notesByStartTick = {};

  CompositionMidiProcessor get midiProcessor {
    return CompositionMidiProcessor(
      tempo: widget.composition.tempo,
      beatUnit: widget.composition.beatUnit,
      beatsPerMeasure: widget.composition.beatsPerMeasure,
    );
  }

  // Composition saving and generation

  /// Saves and retrieves private composition documents in Firestore.
  final CompositionService compositionService = CompositionService();

  /// Sends saved compositions to the backend for file generation.
  final CompositionGenerationService compositionGenerationService =
      CompositionGenerationService();

  /// Reports whether the backend generation process is currently running.
  bool isGeneratingComposition = false;

  // Derived screen state

  /// Reports whether the MIDI service currently has a connected instrument.
  bool get midiIsConnected {
    return midiInputService.isConnected;
  }

  /// Reports whether a camera controller exists and finished initializing.
  bool get cameraIsReady {
    final controller = cameraController;
    return controller != null && controller.value.isInitialized;
  }

  /// Reports whether both front and back cameras are available for switching.
  bool get canSwitchCamera {
    final hasFrontCamera = deviceCameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    final hasBackCamera = deviceCameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    return hasFrontCamera && hasBackCamera;
  }

  /// Reports whether the required camera and MIDI connection are both ready.
  bool get canStartRecording {
    return cameraIsReady && midiIsConnected;
  }

  /// Formats the elapsed recording duration for the on-screen timer.
  String get recordingDurationText {
    final hours = recordingDuration.inHours.toString().padLeft(2, '0');

    final minutes = recordingDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    final seconds = recordingDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    if (recordingDuration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
  // Screen setup

  /// Registers app and MIDI listeners, enables rotation, and opens the camera.
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

  // Camera setup and switching

  /// Opens the selected camera, or the front camera by default, and replaces
  /// any controller that was previously active.
  Future<void> initializeCamera({CameraDescription? selectedCamera}) async {
    if (isInitializingCamera) {
      return;
    }

    final previousController = cameraController;

    setState(() {
      isInitializingCamera = true;
      cameraError = null;
      cameraController = null;
    });

    if (previousController != null) {
      await previousController.dispose();
    }

    CameraController? newController;

    try {
      if (deviceCameras.isEmpty) {
        deviceCameras = await availableCameras();
      }

      if (deviceCameras.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          isInitializingCamera = false;
          cameraError = 'No camera is available on this device.';
        });

        return;
      }

      final camera =
          selectedCamera ??
          deviceCameras.firstWhere(
            (camera) {
              return camera.lensDirection == CameraLensDirection.front;
            },
            orElse: () {
              return deviceCameras.first;
            },
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

      if (!mounted) {
        return;
      }

      setState(() {
        isInitializingCamera = false;
        cameraError = error.description ?? 'The camera could not be opened.';
      });
    } catch (_) {
      await newController?.dispose();

      if (!mounted) {
        return;
      }

      setState(() {
        isInitializingCamera = false;
        cameraError = 'The camera could not be opened.';
      });
    }
  }

  /// Changes between the front and back cameras when recording is not active.
  Future<void> switchCamera() async {
    if (isRecording || isInitializingCamera || !canSwitchCamera) {
      return;
    }

    final targetDirection = selectedLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final targetCamera = deviceCameras.firstWhere((camera) {
      return camera.lensDirection == targetDirection;
    });

    await initializeCamera(selectedCamera: targetCamera);
  }

  // MIDI connection and live state

  /// Searches for a MIDI device, connects to the first one found, and updates
  /// the connection message shown by the MIDI button.
  Future<void> connectToMidi() async {
    if (isConnectingMidi || midiIsConnected) {
      return;
    }

    setState(() {
      isConnectingMidi = true;
      midiStatus = 'Searching for MIDI piano';
    });

    try {
      final devices = await midiInputService.getDevices();
      if (!mounted) {
        return;
      }

      if (devices.isEmpty) {
        setState(() {
          isConnectingMidi = false;
          midiStatus = 'No MIDI piano detected';
        });
        return;
      }

      final device = devices.first;
      setState(() {
        midiStatus = 'Connecting to ${device.name}';
      });

      await midiInputService.connectToDevice(device);
      if (!mounted) {
        return;
      }

      setState(() {
        isConnectingMidi = false;
        midiStatus = 'Connected ${device.name}';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        isConnectingMidi = false;
        midiStatus = 'MIDI connection failed';
      });
    }
  }

  /// Updates the MIDI connection state and stops an active recording if the
  /// instrument disconnects while the user is playing.
  void handleMidiConnectionChanged(bool connected) {
    if (!mounted) {
      return;
    }

    final midiDisconnectedWhileRecording = !connected && isRecording;

    final deviceName = midiInputService.connectedDevice?.name;

    setState(() {
      isConnectingMidi = false;
      if (connected) {
        midiStatus = deviceName == null
            ? 'MIDI piano connected'
            : 'Connected: $deviceName';
      } else {
        midiStatus = 'MIDI piano disconnected';
      }
    });

    if (midiDisconnectedWhileRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MIDI disconnected. Stopping recording.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      unawaited(stopRecording());
    }
  }

  /// Tells the user that a MIDI piano must be connected before recording.
  void showMidiRequiredSnackBar() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Connect your MIDI piano before recording.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Keeps the screen's active-note set synchronized with the MIDI service.
  void handleActiveMidiNotesChanged(Set<int> notes) {
    if (!mounted) {
      return;
    }

    activeMidiNotes = Set<int>.from(notes);
  }

  // App lifecycle and interface

  /// Releases the camera while the app is inactive and restores the same lens
  /// when the app returns, unless a video recording is currently active.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = cameraController;

    if (state == AppLifecycleState.inactive) {
      if (isRecording) {
        return;
      }

      if (controller == null) {
        return;
      }

      selectedLensDirection = controller.description.lensDirection;

      cameraController = null;
      unawaited(controller.dispose());
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
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

  /// Builds the live camera screen and supplies current state and callbacks to
  /// the smaller visual widgets layered over the preview.
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                              ),
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
                      : () {
                          Navigator.of(context).maybePop();
                        },
                  tooltip: 'Back',
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

  // Recording capture

  /// Starts video capture, resets previous recording data, starts the MIDI
  /// timestamp clock, and begins updating the visible duration timer.
  Future<void> startRecording() async {
    final controller = cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isRecordingVideo ||
        !midiIsConnected) {
      return;
    }

    try {
      await controller.startVideoRecording();
      if (!mounted) {
        return;
      }

      recordedMidiEvents.clear();
      recordedNotes.clear();
      quantizedNotes.clear();
      notesByStartTick.clear();
      midiRecordingStopwatch.reset();
      midiRecordingStopwatch.start();
      setState(() {
        isRecording = true;
        recordedVideo = null;
      });

      startRecordingTimer();
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.description ?? 'Could not start recording.'),
        ),
      );
    }
  }

  /// Resets the displayed duration and updates it once per second while the
  /// camera and MIDI event capture are running.
  void startRecordingTimer() {
    recordingTimer?.cancel();

    setState(() {
      recordingDuration = Duration.zero;
    });

    recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }
      setState(() {
        recordingDuration += Duration(seconds: 1);
      });
    });
  }

  /// Captures each MIDI note-on or note-off event with the time elapsed since
  /// the current recording started.
  void handleMidiNoteEvent(MidiNoteEvent event) {
    if (!isRecording || !midiRecordingStopwatch.isRunning) {
      return;
    }

    final recordedEvent = RecordedMidiEvent(
      type: event.type,
      noteNumber: event.noteNumber,
      velocity: event.velocity,
      timestamp: midiRecordingStopwatch.elapsed,
    );

    recordedMidiEvents.add(recordedEvent);
  }

  /// Cancels the periodic timer so the displayed recording duration stops.
  void stopRecordingTimer() {
    recordingTimer?.cancel();
    recordingTimer = null;
  }

  /// Stops video and MIDI timing, converts captured events into notation data,
  /// and opens the completion dialog once the video file has been saved.
  Future<void> stopRecording() async {
    final controller = cameraController;

    if (isStoppingRecording) {
      return;
    }

    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isRecordingVideo) {
      midiRecordingStopwatch.stop();
      stopRecordingTimer();

      if (mounted) {
        setState(() {
          isRecording = false;
        });
      }

      return;
    }

    isStoppingRecording = true;

    midiRecordingStopwatch.stop();
    stopRecordingTimer();

    try {
      final video = await controller.stopVideoRecording().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) {
        return;
      }

      createRecordedNotes();
      createQuantizedNotes();
      groupQuantizedNotes();

      setState(() {
        isRecording = false;
        recordedVideo = video;
      });

      await showRecordingCompletionDialog(video);
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

  // MIDI event processing and notation conversion

  /// Pairs note-on and note-off events into notes with start and end times,
  /// closing any still-held notes at the end of the recording.
  void createRecordedNotes() {
    recordedNotes
      ..clear()
      ..addAll(
        midiProcessor.pairEvents(
          recordedMidiEvents,
          captureEndTime: midiRecordingStopwatch.elapsed,
        ),
      );
  }

  /// Quantizes every recorded note's start and end times, guarantees a minimum
  /// duration, sorts the result, and resolves repeated-key overlaps.
  void createQuantizedNotes() {
    quantizedNotes
      ..clear()
      ..addAll(midiProcessor.quantizeNotes(recordedNotes));
  }

  /// Groups notes that begin on the same tick so simultaneous notes can later
  /// be treated as a chord.
  void groupQuantizedNotes() {
    notesByStartTick
      ..clear()
      ..addAll(midiProcessor.groupByStartTick(quantizedNotes));
  }

  /// Converts quantized notes into composition notes and splits notes that
  /// cross measure boundaries into tied segments.
  List<CompositionNote> createCompositionNotesFromRecording() {
    return midiProcessor.createCompositionNotes(
      quantizedNotes,
      idPrefix: 'recorded',
    );
  }

  /// Calculates how many measures are needed to contain the latest note end,
  /// while keeping at least one measure for an empty recording.
  int calculateRequiredMeasureCount(List<CompositionNote> compositionNotes) {
    return midiProcessor.calculateRequiredMeasureCount(compositionNotes);
  }

  // Completion choices, saving, and file generation

  /// Shows the post-recording choice and routes the result to either discard
  /// the temporary data or save and generate the composition files.
  Future<void> showRecordingCompletionDialog(XFile video) async {
    final action = await showDialog<RecordingCompletionAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return RecordingCompletionDialog(
          colors: widget.colors,
          compositionTitle: widget.composition.title,
          durationText: recordingDurationText,
          noteCount: recordedNotes.length,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == RecordingCompletionAction.discard) {
      await discardRecording(video);
      return;
    }

    if (action == RecordingCompletionAction.generate) {
      await generateRecordedComposition();
    }
  }

  /// Deletes the temporary video and clears every piece of data collected for
  /// the discarded recording so the user can start again.
  Future<void> discardRecording(XFile video) async {
    try {
      final videoFile = File(video.path);

      if (await videoFile.exists()) {
        await videoFile.delete();
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }

    recordedMidiEvents.clear();
    recordedNotes.clear();
    quantizedNotes.clear();
    notesByStartTick.clear();
    midiRecordingStopwatch.reset();

    setState(() {
      recordedVideo = null;
      recordingDuration = Duration.zero;
    });
  }

  /// Builds the final composition model from the processed recording while
  /// preserving the title, tempo, key, and time signature chosen by the user.
  Composition createRecordedComposition() {
    final compositionNotes = createCompositionNotesFromRecording();

    final requiredMeasureCount = calculateRequiredMeasureCount(
      compositionNotes,
    );

    return Composition(
      id: widget.composition.id,
      ownerId: widget.composition.ownerId,
      title: widget.composition.title,
      tempo: widget.composition.tempo,
      measureCount: requiredMeasureCount,
      notes: compositionNotes,
      creationMethod: Composition.recordingCreationMethod,
      keySignature: widget.composition.keySignature,
      beatsPerMeasure: widget.composition.beatsPerMeasure,
      beatUnit: widget.composition.beatUnit,
      createdAt: widget.composition.createdAt,
      updatedAt: widget.composition.updatedAt,
    );
  }

  /// Saves the recorded composition in Firestore, copies the generated
  /// document ID into the model, and returns that saved model.
  Future<Composition> saveRecordedComposition() async {
    final composition = createRecordedComposition();

    final compositionId = await compositionService.createComposition(
      composition,
    );

    final savedComposition = composition.copyWith(id: compositionId);

    return savedComposition;
  }

  /// Runs the complete persistence and backend generation process while
  /// controlling the loading overlay and reporting success or failure.
  Future<void> generateRecordedComposition() async {
    if (isGeneratingComposition) {
      return;
    }

    setState(() {
      isGeneratingComposition = true;
    });

    Composition? savedComposition;

    try {
      savedComposition = await saveRecordedComposition();

      await compositionGenerationService.generateCompositionFiles(
        savedComposition,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, savedComposition.id);
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (savedComposition != null) {
        Navigator.pop(context, savedComposition.id);
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'The composition could not be saved. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingComposition = false;
        });
      }
    }
  }

  // Failure recovery and debugging

  /// Resets a camera that failed to stop recording, informs the user, and
  /// initializes a fresh controller so another recording can be attempted.
  Future<void> recoverCameraAfterRecordingFailure(
    CameraController failedController,
    String message,
  ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      cameraController = null;
      isRecording = false;
      recordedVideo = null;
    });

    try {
      await failedController.dispose().timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

    unawaited(initializeCamera());
  }

  /// Shows a temporary summary of the captured notes for manual debugging.
  void showRecordedNotesTestResult() {
    final String message;

    if (recordedNotes.isEmpty) {
      message = 'No MIDI notes were captured.';
    } else {
      final firstNote = recordedNotes.first;

      message =
          'Captured ${recordedNotes.length} notes. '
          'First note: MIDI ${firstNote.noteNumber}, '
          '${firstNote.duration.inMilliseconds} ms.';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  // Screen cleanup

  /// Removes lifecycle and MIDI listeners, stops timers, releases the camera
  /// and MIDI service, and restores portrait-only orientation on exit.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    recordingTimer?.cancel();
    final controller = cameraController;

    if (controller != null) {
      unawaited(controller.dispose());
    }

    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );

    unawaited(midiConnectionSubscription?.cancel());
    unawaited(midiActiveNotesSubscription?.cancel());
    unawaited(midiInputService.dispose());
    unawaited(midiNoteEventSubscription?.cancel());
    super.dispose();
  }
}
