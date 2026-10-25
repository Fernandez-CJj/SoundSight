import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../models/microphone_audio_level.dart';
import '../models/microphone_input_state.dart';
import 'microphone_note_event_processor.dart';

/// Captures microphone PCM and publishes lightweight diagnostics for the UI.
class MicrophoneAudioCaptureService {
  /// Creates an Android capture service backed by an injectable recorder.
  MicrophoneAudioCaptureService({
    required MicrophoneNoteEventProcessor noteEventProcessor,
    AudioRecorder? recorder,
  }) : _noteEventProcessor = noteEventProcessor,
       _recorder = recorder ?? AudioRecorder();

  static const int sampleRate = 44100;
  static const Duration _levelInterval = Duration(milliseconds: 60);
  static const Duration calibrationDuration = Duration(seconds: 3);
  static const double _quietRmsThreshold = 0.003;
  static const double _noisyFloorThreshold = 0.006;
  static const double _signalAboveNoiseMultiplier = 1.6;
  static const double _clippingPeakThreshold = 0.98;

  final MicrophoneNoteEventProcessor _noteEventProcessor;
  final AudioRecorder _recorder;
  final StreamController<Uint8List> _pcmChunks =
      StreamController<Uint8List>.broadcast();
  final StreamController<MicrophoneAudioLevel> _levels =
      StreamController<MicrophoneAudioLevel>.broadcast();
  final Stopwatch _captureClock = Stopwatch();

  StreamSubscription<Uint8List>? _captureSubscription;
  Duration _lastLevelEmission = Duration.zero;
  double _calibrationRmsTotal = 0;
  int _calibrationSampleCount = 0;
  double _noiseFloorRms = 0;
  int _effectiveSampleRate = sampleRate;
  String? _lastError;
  bool _isStarting = false;
  bool _isListening = false;
  bool _isDisposed = false;

  /// Publishes each in-memory mono PCM16 chunk for future note recognition.
  Stream<Uint8List> get pcmStream => _pcmChunks.stream;

  /// Publishes throttled RMS and peak measurements for the diagnostic meter.
  Stream<MicrophoneAudioLevel> get levelStream => _levels.stream;

  /// Reports whether microphone samples are currently being received.
  bool get isListening => _isListening;

  /// Returns the latest capture or permission error for user guidance.
  String? get lastError => _lastError;

  /// Returns the average ambient RMS measured during the current calibration.
  double get noiseFloorRms => _noiseFloorRms;

  /// Returns the sample rate reported by Android, or the requested rate.
  int get effectiveSampleRate => _effectiveSampleRate;

  /// Requests permission and starts in-memory mono PCM16 microphone capture.
  Future<bool> start() async {
    if (_isDisposed || _isStarting || _isListening) return _isListening;

    _isStarting = true;
    _lastError = null;
    _resetCalibration();
    _effectiveSampleRate = sampleRate;
    _noteEventProcessor.updateState(MicrophoneInputState.starting);
    _noteEventProcessor.updateSignalQuality(MicrophoneSignalQuality.unknown);

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _lastError =
            'Microphone permission was denied. Enable it in your phone settings.';
        _noteEventProcessor.updateState(MicrophoneInputState.failed);
        return false;
      }

      await _recorder.setOnConfigChanged(_handleConfigChanged);
      final audioStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );

      if (_isDisposed) {
        await _recorder.stop();
        return false;
      }

      _captureClock
        ..reset()
        ..start();
      _lastLevelEmission = Duration.zero;
      _isListening = true;
      _captureSubscription = audioStream.listen(
        _handlePcmChunk,
        onError: _handleCaptureError,
        onDone: _handleCaptureDone,
        cancelOnError: true,
      );
      _noteEventProcessor.updateState(MicrophoneInputState.calibrating);
      return true;
    } catch (error) {
      _lastError = 'Microphone capture could not start: $error';
      _noteEventProcessor.updateState(MicrophoneInputState.failed);
      return false;
    } finally {
      _isStarting = false;
    }
  }

  /// Updates the sample rate when Android adjusts the requested PCM format.
  void _handleConfigChanged(RecordConfig config) {
    if (_isDisposed) return;
    _effectiveSampleRate = config.sampleRate;
  }

  /// Stops capture, releases the recorder, and resets microphone input state.
  Future<void> stop({bool interrupted = false}) async {
    if (_isDisposed || (!_isStarting && !_isListening)) {
      if (!_isDisposed) {
        _noteEventProcessor.updateState(
          interrupted
              ? MicrophoneInputState.interrupted
              : MicrophoneInputState.stopped,
        );
      }
      return;
    }

    _isStarting = false;
    _isListening = false;
    _captureClock.stop();
    _resetCalibration();
    await _captureSubscription?.cancel();
    _captureSubscription = null;

    try {
      await _recorder.stop();
    } catch (error) {
      _lastError = 'Microphone capture could not stop cleanly: $error';
    }

    _noteEventProcessor.updateSignalQuality(MicrophoneSignalQuality.unknown);
    _noteEventProcessor.updateState(
      interrupted
          ? MicrophoneInputState.interrupted
          : MicrophoneInputState.stopped,
    );
  }

  /// Copies an incoming PCM chunk and periodically calculates its audio level.
  void _handlePcmChunk(Uint8List bytes) {
    if (_isDisposed || !_isListening || bytes.isEmpty) return;

    final copiedBytes = Uint8List.fromList(bytes);
    _pcmChunks.add(copiedBytes);

    final capturedAt = _captureClock.elapsed;
    if (capturedAt - _lastLevelEmission < _levelInterval) return;
    _lastLevelEmission = capturedAt;

    final level = _measureLevel(copiedBytes, capturedAt);
    if (level == null) return;

    _levels.add(level);

    if (_noteEventProcessor.state == MicrophoneInputState.calibrating) {
      _collectCalibrationLevel(level);
      return;
    }

    _noteEventProcessor.updateSignalQuality(_classifySignal(level));
  }

  /// Collects ambient RMS readings until the three-second baseline is ready.
  void _collectCalibrationLevel(MicrophoneAudioLevel level) {
    _calibrationRmsTotal += level.rms;
    _calibrationSampleCount++;

    if (level.capturedAt < calibrationDuration) return;

    _noiseFloorRms = _calibrationSampleCount == 0
        ? 0
        : _calibrationRmsTotal / _calibrationSampleCount;
    final quality = _classifySignal(level);
    _noteEventProcessor.updateSignalQuality(quality);
    _noteEventProcessor.updateState(
      quality == MicrophoneSignalQuality.tooNoisy
          ? MicrophoneInputState.degraded
          : MicrophoneInputState.ready,
    );
  }

  /// Calculates normalized RMS and peak values from little-endian PCM16 data.
  MicrophoneAudioLevel? _measureLevel(
    Uint8List bytes,
    Duration capturedAt,
  ) {
    final sampleCount = bytes.lengthInBytes ~/ 2;
    if (sampleCount == 0) return null;

    final data = ByteData.sublistView(bytes);
    var sumSquares = 0.0;
    var peak = 0.0;

    for (var sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
      final sample = data.getInt16(sampleIndex * 2, Endian.little);
      final normalized = sample / 32768.0;
      final absolute = normalized.abs();
      sumSquares += normalized * normalized;
      peak = math.max(peak, absolute);
    }

    return MicrophoneAudioLevel(
      rms: math.sqrt(sumSquares / sampleCount).clamp(0.0, 1.0).toDouble(),
      peak: peak.clamp(0.0, 1.0).toDouble(),
      capturedAt: capturedAt,
    );
  }

  /// Classifies basic quiet, usable, and clipping conditions from audio level.
  MicrophoneSignalQuality _classifySignal(MicrophoneAudioLevel level) {
    if (level.peak >= _clippingPeakThreshold) {
      return MicrophoneSignalQuality.clipping;
    }

    final adaptiveThreshold = math.max(
      _quietRmsThreshold,
      _noiseFloorRms * _signalAboveNoiseMultiplier,
    );
    if (level.rms <= adaptiveThreshold) {
      if (_noiseFloorRms >= _noisyFloorThreshold) {
        return MicrophoneSignalQuality.tooNoisy;
      }
      return MicrophoneSignalQuality.tooQuiet;
    }
    return MicrophoneSignalQuality.usable;
  }

  /// Clears the ambient baseline so every new capture session recalibrates.
  void _resetCalibration() {
    _calibrationRmsTotal = 0;
    _calibrationSampleCount = 0;
    _noiseFloorRms = 0;
  }

  /// Converts an asynchronous recorder error into a failed microphone state.
  void _handleCaptureError(Object error, StackTrace stackTrace) {
    if (_isDisposed) return;
    _lastError = 'Microphone capture stopped: $error';
    _finishUnexpectedCapture(MicrophoneInputState.failed);
  }

  /// Treats an unexpected PCM stream closure as an interrupted session.
  void _handleCaptureDone() {
    if (_isDisposed || !_isListening) return;
    _lastError = 'The microphone stream ended unexpectedly.';
    _finishUnexpectedCapture(MicrophoneInputState.interrupted);
  }

  /// Clears local capture state after the recorder stream ends unexpectedly.
  void _finishUnexpectedCapture(MicrophoneInputState state) {
    _isListening = false;
    _captureClock.stop();
    _resetCalibration();
    _captureSubscription = null;
    _noteEventProcessor.updateSignalQuality(MicrophoneSignalQuality.unknown);
    _noteEventProcessor.updateState(state);
  }

  /// Stops capture and permanently releases all recorder and stream resources.
  Future<void> dispose() async {
    if (_isDisposed) return;
    await stop();
    _isDisposed = true;
    await _recorder.dispose();
    await _pcmChunks.close();
    await _levels.close();
  }
}
