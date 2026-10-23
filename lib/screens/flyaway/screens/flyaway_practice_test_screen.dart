import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';

import '../controllers/flyaway_practice_controller.dart';
import '../models/flyaway_finger.dart';
import '../services/flyaway_hand_tracking_service.dart';
import '../widgets/hand_landmark_painter.dart';

/// A standalone practice prototype. It does not open a score or a MIDI device.
class FlyawayPracticeTestScreen extends StatefulWidget {
  const FlyawayPracticeTestScreen({super.key});

  @override
  State<FlyawayPracticeTestScreen> createState() =>
      _FlyawayPracticeTestScreenState();
}

class _FlyawayPracticeTestScreenState extends State<FlyawayPracticeTestScreen>
    with WidgetsBindingObserver {
  final FlyawayHandTrackingService _handTracking = FlyawayHandTrackingService();
  final FlyawayPracticeController _practice = FlyawayPracticeController();

  CameraController? _camera;
  Future<void>? _openingFuture;
  Future<void>? _releaseFuture;
  Future<void>? _frameFuture;
  Timer? _calibrationTimer;
  DateTime? _lastFrameSubmittedAt;
  int _generation = 0;
  int _secondsRemaining = 0;
  bool _ready = false;
  bool _processingFrame = false;
  bool _interrupted = false;
  bool _restarting = false;
  String? _error;
  String? _calibrationMessage;
  List<Hand> _hands = <Hand>[];
  Size? _detectionSize;
  FlyawayFrameResult _frameResult = const FlyawayFrameResult(
    detectedHands: <Handedness>{},
    flaggedFingers: <Handedness, Set<FlyawayFinger>>{},
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_openCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_interrupted) return;
      _interrupted = true;
      _generation++;
      _calibrationTimer?.cancel();
      _calibrationTimer = null;
      _practice.reset();
      if (mounted) {
        setState(() {
          _ready = false;
          _hands = <Hand>[];
          _frameResult = const FlyawayFrameResult(
            detectedHands: <Handedness>{},
            flaggedFingers: <Handedness, Set<FlyawayFinger>>{},
          );
          _calibrationMessage =
              'Camera interrupted. Calibrate again after it reopens.';
        });
      }
      unawaited(_releaseAfterOpening());
    } else if (state == AppLifecycleState.resumed && _interrupted) {
      _interrupted = false;
      unawaited(_restartCamera());
    }
  }

  Future<void> _releaseAfterOpening() async {
    await _openingFuture;
    await _releaseResources();
  }

  Future<void> _openCamera() {
    final existing = _openingFuture;
    if (existing != null) return existing;
    final task = _openCameraImpl();
    _openingFuture = task;
    return task.whenComplete(() {
      if (identical(_openingFuture, task)) _openingFuture = null;
    });
  }

  Future<void> _openCameraImpl() async {
    final generation = ++_generation;
    CameraController? newCamera;
    try {
      if (mounted) {
        setState(() {
          _error = null;
          _ready = false;
        });
      }
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (!mounted || _interrupted || generation != _generation) return;

      final cameras = await availableCameras();
      if (!mounted || _interrupted || generation != _generation) return;
      final rear = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      if (rear.isEmpty) throw StateError('No rear camera is available.');

      newCamera = CameraController(
        rear.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await newCamera.initialize();
      if (!mounted || _interrupted || generation != _generation) {
        await newCamera.dispose();
        return;
      }
      _camera = newCamera;
      await _handTracking.initialize();
      if (!mounted || _interrupted || generation != _generation) {
        await _releaseResources();
        return;
      }
      if (!_handTracking.isInitialized) {
        throw StateError('Hand detector could not start.');
      }
      await newCamera.startImageStream(_onCameraFrame);
      if (!mounted || _interrupted || generation != _generation) {
        await _releaseResources();
        return;
      }
      setState(() => _ready = true);
    } catch (error) {
      if (newCamera != null && !identical(_camera, newCamera)) {
        await newCamera.dispose();
      }
      await _releaseResources();
      if (mounted && !_interrupted && generation == _generation) {
        setState(() {
          _error = error is CameraException
              ? (error.description ?? 'Camera could not start.')
              : error.toString().replaceFirst('Bad state: ', '');
          _ready = false;
        });
      }
    }
  }

  Future<void> _restartCamera() async {
    if (_restarting || !mounted) return;
    _restarting = true;
    _generation++;
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _practice.reset();
    setState(() {
      _ready = false;
      _hands = <Hand>[];
      _error = null;
    });
    try {
      await _openingFuture;
      await _releaseResources();
      if (mounted && !_interrupted) await _openCamera();
    } finally {
      _restarting = false;
    }
  }

  Future<void> _releaseResources() {
    final existing = _releaseFuture;
    if (existing != null) return existing;
    final task = _releaseResourcesImpl();
    _releaseFuture = task;
    return task.whenComplete(() {
      if (identical(_releaseFuture, task)) _releaseFuture = null;
    });
  }

  Future<void> _releaseResourcesImpl() async {
    _ready = false;
    await _frameFuture;
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      try {
        if (camera.value.isStreamingImages) await camera.stopImageStream();
      } catch (_) {
        // Continue releasing the controller after a stream shutdown failure.
      }
      try {
        await camera.dispose();
      } catch (_) {
        // The camera may already have closed during a lifecycle change.
      }
    }
    try {
      await _handTracking.dispose();
    } catch (_) {
      // A failed native shutdown must not block reopening the screen.
    }
  }

  void _onCameraFrame(CameraImage image) {
    if (!_ready || _processingFrame || _interrupted) return;
    final now = DateTime.now();
    final previous = _lastFrameSubmittedAt;
    if (previous != null && now.difference(previous).inMilliseconds < 100) {
      return;
    }
    _lastFrameSubmittedAt = now;
    _processingFrame = true;
    _frameFuture = _analyzeFrame(image, now, _generation);
  }

  Future<void> _analyzeFrame(
    CameraImage image,
    DateTime timestamp,
    int generation,
  ) async {
    try {
      final camera = _camera;
      if (camera == null) return;
      final rotation = rotationForFrame(
        width: image.width,
        height: image.height,
        sensorOrientation: camera.description.sensorOrientation,
        isFrontCamera: false,
        deviceOrientation: camera.value.deviceOrientation,
      );
      final imageSize = detectionSize(
        width: image.width,
        height: image.height,
        rotation: rotation,
        maxDim: 640,
      );
      final hands = await _handTracking.detectHands(
        image: image,
        rotation: rotation,
      );
      if (!mounted || !_ready || generation != _generation) return;
      final result = _practice.acceptHands(hands, timestamp);
      setState(() {
        _hands = hands;
        _detectionSize = imageSize;
        _frameResult = result;
      });
    } catch (error) {
      if (mounted && generation == _generation && !_interrupted) {
        setState(() {
          _error = 'Hand detection failed: $error';
          _ready = false;
          _hands = <Hand>[];
        });
      }
    } finally {
      _processingFrame = false;
    }
  }

  void _beginCalibration() {
    if (!_ready) return;
    _calibrationTimer?.cancel();
    _practice.beginCalibration();
    setState(() {
      _secondsRemaining = 3;
      _calibrationMessage = null;
      _frameResult = const FlyawayFrameResult(
        detectedHands: <Handedness>{},
        flaggedFingers: <Handedness, Set<FlyawayFinger>>{},
      );
    });
    _calibrationTimer = Timer.periodic(
      const Duration(seconds: 1),
      _advanceCalibration,
    );
  }

  void _advanceCalibration(Timer timer) {
    if (!mounted || !_ready) {
      timer.cancel();
      return;
    }
    if (_secondsRemaining > 1) {
      setState(() => _secondsRemaining--);
      return;
    }
    setState(() {
      switch (_practice.stage) {
        case FlyawayPracticeStage.preparing:
          _practice.beginResting();
          _secondsRemaining = 3;
          break;
        case FlyawayPracticeStage.resting:
          _practice.beginMovement();
          _secondsRemaining = 7;
          break;
        case FlyawayPracticeStage.moving:
          timer.cancel();
          _calibrationTimer = null;
          _secondsRemaining = 0;
          if (!_practice.completeCalibration()) {
            _calibrationMessage =
                'Calibration incomplete. Keep your hands visible and try again.';
          }
          break;
        default:
          timer.cancel();
          _calibrationTimer = null;
          break;
      }
    });
  }

  void _startSession() {
    if (!_ready || !_practice.startSession(DateTime.now())) return;
    setState(() => _calibrationMessage = null);
  }

  Future<void> _stopSession() async {
    if (_practice.stage != FlyawayPracticeStage.running) return;
    final summary = _practice.stopSession(DateTime.now());
    setState(() {});
    await _showSummary(summary);
  }

  Future<void> _confirmRecalibrate() async {
    if (_practice.stage == FlyawayPracticeStage.running) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard this session?'),
          content: const Text(
            'Recalibrating clears the current Flyaway counts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Recalibrate'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    _beginCalibration();
  }

  Future<void> _showSummary(FlyawaySessionSummary summary) {
    final rows = <Widget>[];
    for (final handedness in <Handedness>[Handedness.left, Handedness.right]) {
      final fingers = summary.fingers[handedness];
      if (fingers == null) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            _handName(handedness),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (final finger in FlyawayFinger.values) {
        final result = fingers[finger]!;
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${_fingerName(finger)}: ${result.events} events, '
              '${_formatDuration(result.flaggedTime)} flagged',
            ),
          ),
        );
      }
    }
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flyaway session summary'),
        content: SizedBox(
          width: 390,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Session: ${_formatDuration(summary.duration)}'),
                ...rows,
                const SizedBox(height: 12),
                const Text(
                  'These are estimates of excessive finger lift, not measured '
                  'distances from the keys.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final tenths = duration.inMilliseconds.remainder(1000) ~/ 100;
    return minutes > 0
        ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s'
        : '$seconds.${tenths}s';
  }

  String _handName(Handedness handedness) =>
      handedness == Handedness.left ? 'Left hand' : 'Right hand';

  String _fingerName(FlyawayFinger finger) => switch (finger) {
    FlyawayFinger.thumb => 'Thumb',
    FlyawayFinger.indexFinger => 'Index',
    FlyawayFinger.middle => 'Middle',
    FlyawayFinger.ring => 'Ring',
    FlyawayFinger.pinky => 'Pinky',
  };

  String get _instruction {
    if (_error != null) return _error!;
    if (!_ready) return 'Opening rear camera and hand detector...';
    if (_calibrationMessage != null) return _calibrationMessage!;
    switch (_practice.stage) {
      case FlyawayPracticeStage.idle:
        return 'Keep the phone mounted above the keys, then calibrate.';
      case FlyawayPracticeStage.preparing:
        return 'Get ready: $_secondsRemaining';
      case FlyawayPracticeStage.resting:
        return 'Rest fingers on the keys: $_secondsRemaining';
      case FlyawayPracticeStage.moving:
        return 'Move your fingers normally: $_secondsRemaining';
      case FlyawayPracticeStage.ready:
        final names = _practice.calibratedHands.map(_handName).join(' and ');
        return '$names calibrated. Start the session before playing.';
      case FlyawayPracticeStage.running:
        return 'Playing: excessive-lift estimates appear below.';
      case FlyawayPracticeStage.finished:
        return 'Session ended. Recalibrate to practice again.';
    }
  }

  Widget _buildCamera() {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      if (_error != null) return const SizedBox.shrink();
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: camera.value.aspectRatio,
          height: 1,
          child: CameraPreview(camera),
        ),
      ),
    );
  }

  Widget _buildHandIndicators() {
    final hands = _practice.calibratedHands;
    if (hands.isEmpty || _practice.stage != FlyawayPracticeStage.running) {
      return const SizedBox.shrink();
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final handedness in <Handedness>[
          Handedness.left,
          Handedness.right,
        ])
          if (hands.contains(handedness))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    handedness == Handedness.left ? 'L' : 'R',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  for (final finger in FlyawayFinger.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _frameResult.flaggedFingers[handedness]?.contains(
                                    finger,
                                  ) ==
                                  true
                              ? Colors.deepOrange
                              : _frameResult.detectedHands.contains(handedness)
                              ? Colors.blueGrey
                              : Colors.grey.shade800,
                        ),
                        child: Text(
                          _fingerName(finger).substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildControls() {
    final stage = _practice.stage;
    final calibrating =
        stage == FlyawayPracticeStage.preparing ||
        stage == FlyawayPracticeStage.resting ||
        stage == FlyawayPracticeStage.moving;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandIndicators(),
              if (stage == FlyawayPracticeStage.running)
                const SizedBox(height: 7),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  if (stage == FlyawayPracticeStage.idle ||
                      calibrating ||
                      stage == FlyawayPracticeStage.finished)
                    FilledButton.icon(
                      onPressed: _ready ? _beginCalibration : null,
                      icon: const Icon(Icons.tune),
                      label: Text(
                        calibrating
                            ? 'Restart calibration'
                            : 'Start calibration',
                      ),
                    ),
                  if (stage == FlyawayPracticeStage.ready)
                    FilledButton.icon(
                      onPressed: _ready ? _startSession : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start session'),
                    ),
                  if (stage == FlyawayPracticeStage.running)
                    FilledButton.icon(
                      onPressed: _stopSession,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop session'),
                    ),
                  if (stage == FlyawayPracticeStage.ready ||
                      stage == FlyawayPracticeStage.running)
                    OutlinedButton(
                      onPressed: _ready ? _confirmRecalibrate : null,
                      child: const Text('Recalibrate'),
                    ),
                  if (_error != null)
                    FilledButton.icon(
                      onPressed: _restarting ? null : _restartCamera,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry camera'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildCamera()),
          if (_detectionSize != null && _hands.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HandLandmarkPainter(
                    hands: _hands,
                    imageSize: _detectionSize!,
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _instruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _calibrationTimer?.cancel();
    unawaited(_releaseAfterOpening());
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    super.dispose();
  }
}
