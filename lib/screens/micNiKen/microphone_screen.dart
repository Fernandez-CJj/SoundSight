import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'models/microphone_audio_level.dart';
import 'models/microphone_input_state.dart';
import 'models/microphone_note_event.dart';
import 'services/microphone_audio_capture_service.dart';
import 'services/microphone_note_event_processor.dart';
import 'services/microphone_single_note_detector.dart';

/// Displays Android microphone capture controls and live audio diagnostics.
class MicrophoneScreen extends StatefulWidget {
  /// Creates the Android microphone input diagnostic screen.
  const MicrophoneScreen({super.key});

  /// Creates the state that owns this screen's microphone capture session.
  @override
  State<MicrophoneScreen> createState() => _MicrophoneScreenState();
}

/// Coordinates capture lifecycle while keeping PCM processing in its service.
class _MicrophoneScreenState extends State<MicrophoneScreen>
    with WidgetsBindingObserver {
  static const MicrophoneAudioLevel _silentLevel = MicrophoneAudioLevel(
    rms: 0,
    peak: 0,
    capturedAt: Duration.zero,
  );

  late final MicrophoneNoteEventProcessor _noteEventProcessor;
  late final MicrophoneAudioCaptureService _captureService;
  late final MicrophoneSingleNoteDetector _singleNoteDetector;
  StreamSubscription<MicrophoneAudioLevel>? _levelSubscription;
  StreamSubscription<MicrophoneInputState>? _stateSubscription;
  StreamSubscription<MicrophoneSignalQuality>? _qualitySubscription;
  StreamSubscription<Set<int>>? _activeNotesSubscription;
  StreamSubscription<MicrophoneNoteEvent>? _noteEventSubscription;
  StreamSubscription<Uint8List>? _pcmSubscription;

  MicrophoneAudioLevel _level = _silentLevel;
  MicrophoneInputState _inputState = MicrophoneInputState.stopped;
  MicrophoneSignalQuality _signalQuality = MicrophoneSignalQuality.unknown;
  Set<int> _activeNotes = const <int>{};
  int? _lastDetectedNote;
  double? _lastDetectionConfidence;

  /// Creates microphone services and subscribes the screen to their state.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noteEventProcessor = MicrophoneNoteEventProcessor();
    _singleNoteDetector = MicrophoneSingleNoteDetector(
      noteEventProcessor: _noteEventProcessor,
    );
    _captureService = MicrophoneAudioCaptureService(
      noteEventProcessor: _noteEventProcessor,
    );
    _levelSubscription = _captureService.levelStream.listen(_receiveLevel);
    _stateSubscription = _noteEventProcessor.stateStream.listen(_receiveState);
    _qualitySubscription = _noteEventProcessor.signalQualityStream.listen(
      _receiveQuality,
    );
    _activeNotesSubscription = _noteEventProcessor.activeNotesStream.listen(
      _receiveActiveNotes,
    );
    _noteEventSubscription = _noteEventProcessor.noteEventStream.listen(
      _receiveNoteEvent,
    );
    _pcmSubscription = _captureService.pcmStream.listen(
      _singleNoteDetector.addPcmChunk,
    );
  }

  /// Stops listening whenever Android moves the app away from the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_stopListening(interrupted: true));
    }
  }

  /// Applies the newest microphone level to the live diagnostic meters.
  void _receiveLevel(MicrophoneAudioLevel value) {
    if (!mounted) return;
    setState(() => _level = value);
  }

  /// Applies microphone lifecycle changes and clears meters after capture ends.
  void _receiveState(MicrophoneInputState value) {
    if (!mounted) return;
    setState(() {
      _inputState = value;
      if (value != MicrophoneInputState.ready &&
          value != MicrophoneInputState.degraded) {
        _level = _silentLevel;
      }
    });
  }

  /// Applies the latest signal-quality classification to the guidance card.
  void _receiveQuality(MicrophoneSignalQuality value) {
    if (!mounted) return;
    setState(() => _signalQuality = value);
  }

  /// Displays the latest complete set of acoustically active piano notes.
  void _receiveActiveNotes(Set<int> value) {
    if (!mounted) return;
    setState(() => _activeNotes = value);
  }

  /// Retains the latest accepted attack so confidence remains visible.
  void _receiveNoteEvent(MicrophoneNoteEvent event) {
    if (!mounted || event.type != MicrophoneNoteEventType.noteOn) return;
    setState(() {
      _lastDetectedNote = event.noteNumber;
      _lastDetectionConfidence = event.confidence;
    });
  }

  /// Starts capture or stops the active session when the main button is tapped.
  Future<void> _toggleListening() async {
    if (_captureService.isListening) {
      await _stopListening();
      return;
    }

    _singleNoteDetector.reset();
    setState(() {
      _lastDetectedNote = null;
      _lastDetectionConfidence = null;
    });
    await _captureService.start();
    if (mounted) setState(() {});
  }

  /// Stops microphone capture and resets the visible audio meters.
  Future<void> _stopListening({bool interrupted = false}) async {
    _singleNoteDetector.reset();
    await _captureService.stop(interrupted: interrupted);
    if (!mounted) return;
    setState(() => _level = _silentLevel);
  }

  /// Returns a concise user-facing label for the capture lifecycle state.
  String _stateLabel(MicrophoneInputState state) {
    return switch (state) {
      MicrophoneInputState.stopped => 'Stopped',
      MicrophoneInputState.starting => 'Starting microphone...',
      MicrophoneInputState.calibrating => 'Calibrating',
      MicrophoneInputState.ready => 'Listening',
      MicrophoneInputState.degraded => 'Listening with limited quality',
      MicrophoneInputState.interrupted => 'Stopped when app left foreground',
      MicrophoneInputState.failed => 'Could not listen',
    };
  }

  /// Returns Android-focused guidance for the current signal classification.
  String _qualityLabel(MicrophoneSignalQuality quality) {
    if (_inputState == MicrophoneInputState.calibrating) {
      return 'Keep the room quiet for 3 seconds while background noise is measured.';
    }

    return switch (quality) {
      MicrophoneSignalQuality.unknown =>
        'Start listening to check the microphone signal.',
      MicrophoneSignalQuality.tooQuiet =>
        'Signal is very quiet. Move the phone closer to the piano.',
      MicrophoneSignalQuality.usable =>
        'The microphone is receiving a usable signal.',
      MicrophoneSignalQuality.clipping =>
        'Signal is clipping. Move the phone farther from the piano.',
      MicrophoneSignalQuality.tooNoisy =>
        'Background noise is too high for reliable recognition.',
    };
  }

  /// Converts a piano note number into a readable pitch such as C4 or F#5.
  String _noteName(int noteNumber) {
    const pitchClasses = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final pitchClass = pitchClasses[noteNumber % 12];
    final octave = noteNumber ~/ 12 - 1;
    return '$pitchClass$octave';
  }

  /// Formats the currently active monophonic detection for the diagnostic UI.
  String _activeNotesLabel() {
    if (_activeNotes.isEmpty) return 'Detected piano notes: none';
    final notes = _activeNotes.toList()..sort();
    return 'Detected piano notes: ${notes.map(_noteName).join(', ')}';
  }

  /// Formats the latest accepted attack and its detector confidence.
  String _lastDetectionLabel() {
    final noteNumber = _lastDetectedNote;
    final confidence = _lastDetectionConfidence;
    if (noteNumber == null || confidence == null) {
      return 'Last detected note: none';
    }
    return 'Last detected note: ${_noteName(noteNumber)} '
        '(${(confidence * 100).toStringAsFixed(0)}% confidence)';
  }

  /// Selects a status color that distinguishes usable and problem states.
  Color _qualityColor(ColorScheme colors) {
    return switch (_signalQuality) {
      MicrophoneSignalQuality.usable => colors.primary,
      MicrophoneSignalQuality.tooQuiet => colors.tertiary,
      MicrophoneSignalQuality.clipping ||
      MicrophoneSignalQuality.tooNoisy => colors.error,
      MicrophoneSignalQuality.unknown => colors.outline,
    };
  }

  /// Builds one scaled meter while retaining the raw normalized percentage.
  Widget _buildMeter({
    required String label,
    required double value,
    required double visualMultiplier,
    required Color color,
  }) {
    final visualValue = (value * visualMultiplier).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('${(value * 100).toStringAsFixed(1)}%')],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: visualValue,
          minHeight: 12,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  /// Builds the Android microphone diagnostic and its capture controls.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isStarting = _inputState == MicrophoneInputState.starting;
    final isListening = _captureService.isListening;
    final error = _captureService.lastError;

    return Scaffold(
      appBar: AppBar(title: const Text('Microphone Piano Input')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Android microphone check',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'This feasibility step detects one piano note at a time. '
              'Chord recognition will be added separately.',
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stateLabel(_inputState),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 14,
                          color: _qualityColor(colors),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_qualityLabel(_signalQuality))),
                      ],
                    ),
                    if (error != null &&
                        (_inputState == MicrophoneInputState.failed ||
                            _inputState ==
                                MicrophoneInputState.interrupted)) ...[
                      const SizedBox(height: 12),
                      Text(error, style: TextStyle(color: colors.error)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildMeter(
              label: 'RMS level',
              value: _level.rms,
              visualMultiplier: 8,
              color: colors.primary,
            ),
            const SizedBox(height: 20),
            _buildMeter(
              label: 'Peak level',
              value: _level.peak,
              visualMultiplier: 2,
              color: colors.tertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'Ambient baseline: '
              '${(_captureService.noiseFloorRms * 100).toStringAsFixed(2)}%',
            ),
            const SizedBox(height: 8),
            Text(_activeNotesLabel()),
            const SizedBox(height: 8),
            Text(_lastDetectionLabel()),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: isStarting ? null : _toggleListening,
              icon: Icon(isListening ? Icons.stop : Icons.mic),
              label: Text(isListening ? 'Stop listening' : 'Start listening'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Audio stays in memory for live processing and is not saved or uploaded.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Cancels UI subscriptions before asynchronously releasing the microphone.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_levelSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_qualitySubscription?.cancel());
    unawaited(_activeNotesSubscription?.cancel());
    unawaited(_noteEventSubscription?.cancel());
    unawaited(_pcmSubscription?.cancel());
    _singleNoteDetector.dispose();
    unawaited(_disposeServices());
    super.dispose();
  }

  /// Releases capture before closing the downstream microphone event streams.
  Future<void> _disposeServices() async {
    await _captureService.dispose();
    await _noteEventProcessor.dispose();
  }
}
