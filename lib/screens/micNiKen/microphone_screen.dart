import 'dart:async';

import 'package:flutter/material.dart';

import 'models/microphone_audio_level.dart';
import 'models/microphone_input_state.dart';
import 'services/microphone_audio_capture_service.dart';
import 'services/microphone_backend_stream_service.dart';
import 'services/microphone_note_event_processor.dart';

/// Shows Android microphone capture and Python backend connection diagnostics.
class MicrophoneScreen extends StatefulWidget {
  /// Creates the microphone streaming screen.
  const MicrophoneScreen({super.key});

  /// Creates the state that owns this screen's live audio session.
  @override
  State<MicrophoneScreen> createState() => _MicrophoneScreenState();
}

/// Connects the capture service to the backend without processing pitch here.
class _MicrophoneScreenState extends State<MicrophoneScreen>
    with WidgetsBindingObserver {
  static const MicrophoneAudioLevel _silentLevel = MicrophoneAudioLevel(
    rms: 0,
    peak: 0,
    capturedAt: Duration.zero,
  );

  final TextEditingController _serverAddressController = TextEditingController(
    text: '192.168.0.104:8000',
  );
  late final MicrophoneNoteEventProcessor _noteEventProcessor;
  late final MicrophoneAudioCaptureService _captureService;
  late final MicrophoneBackendStreamService _backendService;
  StreamSubscription<MicrophoneAudioLevel>? _levelSubscription;
  StreamSubscription<MicrophoneInputState>? _stateSubscription;

  MicrophoneAudioLevel _level = _silentLevel;
  MicrophoneInputState _inputState = MicrophoneInputState.stopped;
  int _sensitivity = 70;
  bool _isStopping = false;

  /// Creates the capture and backend services and observes capture diagnostics.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noteEventProcessor = MicrophoneNoteEventProcessor();
    _captureService = MicrophoneAudioCaptureService(
      noteEventProcessor: _noteEventProcessor,
    );
    _backendService = MicrophoneBackendStreamService(
      captureService: _captureService,
      noteEventProcessor: _noteEventProcessor,
      onChanged: _refresh,
    );
    _levelSubscription = _captureService.levelStream.listen(_receiveLevel);
    _stateSubscription = _noteEventProcessor.stateStream.listen(_receiveState);
  }

  /// Stops live audio when Android moves the app out of the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_stopListening(interrupted: true));
    }
  }

  /// Refreshes the screen after a backend connection or receipt update.
  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Displays the latest local microphone RMS and peak measurements.
  void _receiveLevel(MicrophoneAudioLevel value) {
    if (mounted) setState(() => _level = value);
  }

  /// Clears the meter and backend session if capture is unexpectedly lost.
  void _receiveState(MicrophoneInputState value) {
    if (!mounted) return;
    setState(() {
      _inputState = value;
      if (value != MicrophoneInputState.ready &&
          value != MicrophoneInputState.degraded &&
          value != MicrophoneInputState.calibrating) {
        _level = _silentLevel;
      }
    });
    if ((value == MicrophoneInputState.failed ||
            value == MicrophoneInputState.interrupted) &&
        _backendService.isStreaming) {
      unawaited(_backendService.stop(
        interrupted: true,
        reason: _captureService.lastError ?? 'Microphone input was interrupted.',
      ));
    }
  }

  /// Starts the LAN stream or stops the current microphone session.
  Future<void> _toggleListening() async {
    if (_backendService.isStreaming) {
      await _stopListening();
      return;
    }
    FocusScope.of(context).unfocus();
    await _backendService.start(
      _serverAddressController.text,
      sensitivity: _sensitivity,
    );
  }

  /// Stops the backend stream and releases Android microphone capture.
  Future<void> _stopListening({bool interrupted = false}) async {
    if (_isStopping) return;
    _isStopping = true;
    try {
      await _backendService.stop(interrupted: interrupted);
    } finally {
      _isStopping = false;
      if (mounted) setState(() => _level = _silentLevel);
    }
  }

  /// Returns a short capture-state label for the device status card.
  String _captureLabel() {
    return switch (_inputState) {
      MicrophoneInputState.stopped => 'Microphone off',
      MicrophoneInputState.starting => 'Starting microphone...',
      MicrophoneInputState.calibrating => 'Capturing audio',
      MicrophoneInputState.ready => 'Capturing audio',
      MicrophoneInputState.degraded => 'Capturing with background noise',
      MicrophoneInputState.interrupted => 'Microphone interrupted',
      MicrophoneInputState.failed => 'Microphone unavailable',
    };
  }

  /// Converts a piano note number into a name such as C4 or F#5.
  String _noteName(int noteNumber) {
    const names = <String>[
      'C', 'C#', 'D', 'D#', 'E', 'F',
      'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];
    return '${names[noteNumber % 12]}${noteNumber ~/ 12 - 1}';
  }

  /// Formats the complete active-note set returned by the Python backend.
  String _activeNotesLabel() {
    final notes = _backendService.serverActiveNotes.toList()..sort();
    if (notes.isEmpty) return 'Detected piano notes: none';
    return 'Detected piano notes: ${notes.map(_noteName).join(', ')}';
  }

  /// Formats the most recently confirmed note attack and its confidence.
  String _lastNoteLabel() {
    final note = _backendService.lastNoteNumber;
    final confidence = _backendService.lastNoteConfidence;
    if (note == null || confidence == null) return 'Last detected note: none';
    return 'Last detected note: ${_noteName(note)} '
        '(${(confidence * 100).toStringAsFixed(0)}% confidence)';
  }

  /// Builds one visual meter with its unscaled microphone level.
  Widget _buildMeter({
    required String label,
    required double value,
    required double visualMultiplier,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('${(value * 100).toStringAsFixed(1)}%')],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (value * visualMultiplier).clamp(0.0, 1.0).toDouble(),
          minHeight: 12,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  /// Builds the LAN address control and live connection/audio indicators.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final busy = _backendService.isStarting || _isStopping;
    final streaming = _backendService.isStreaming;
    final error = _backendService.lastError ?? _captureService.lastError;

    return Scaffold(
      appBar: AppBar(title: const Text('Microphone Piano Input')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Python audio connection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Batch 2 detects one piano note at a time. Do not play the piano '
              'during the first second of each listening session. Keep the fan '
              'in the same state during calibration and testing.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _serverAddressController,
              enabled: !busy && !streaming,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Computer LAN IP and port',
                hintText: '192.168.0.104:8000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Use the computer\'s Wi-Fi IPv4 address, not localhost.'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Input sensitivity')),
                DropdownButton<int>(
                  value: _sensitivity,
                  onChanged: busy || streaming
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _sensitivity = value);
                          }
                        },
                  items: const [
                    DropdownMenuItem(value: 60, child: Text('60%')),
                    DropdownMenuItem(value: 70, child: Text('70%')),
                    DropdownMenuItem(value: 100, child: Text('100%')),
                  ],
                ),
              ],
            ),
            const Text(
              'Lower sensitivity ignores more quiet sounds but may miss soft keys. '
              'Change it before starting a new session.',
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_captureLabel()),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 14,
                          color: _backendService.isConnected
                              ? colors.primary
                              : colors.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_backendService.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Python received ${_backendService.chunksReceived} '
                      'chunks / ${_backendService.bytesReceived} bytes',
                    ),
                    const SizedBox(height: 8),
                    Text('Python calibration: ${_backendService.calibrationStatus}'),
                    if (streaming) ...[
                      const SizedBox(height: 8),
                      Text('PCM16 mono, ${_captureService.effectiveSampleRate} Hz'),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 8),
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
            Text(_activeNotesLabel()),
            const SizedBox(height: 8),
            Text(_lastNoteLabel()),
            const SizedBox(height: 8),
            Text(
              'Note attacks: ${_backendService.detectedAttacks}  '
              'Releases: ${_backendService.detectedReleases}',
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: busy ? null : _toggleListening,
              icon: Icon(streaming ? Icons.stop : Icons.mic),
              label: Text(streaming ? 'Stop listening' : 'Start listening'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Live audio is sent to your computer over Wi-Fi for processing. '
              'The backend keeps no recording.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Stops streaming and releases subscriptions when navigating away.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serverAddressController.dispose();
    unawaited(_levelSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_disposeServices());
    super.dispose();
  }

  /// Releases backend transport before closing capture and event streams.
  Future<void> _disposeServices() async {
    await _backendService.dispose();
    await _captureService.dispose();
    await _noteEventProcessor.dispose();
  }
}
