import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';
import 'midi_video_audio_capture.dart';

enum PerformanceRecordingState {
  idle,
  requestingPermission,
  starting,
  recording,
  finalizing,
  ready,
  saving,
  saved,
  unavailable,
  disposed,
}

abstract class PerformanceRecordingBackend {
  Stream<Map<dynamic, dynamic>> get events;
  Future<String> start(String attemptId);
  Future<String?> finish(String attemptId);
  Future<void> discard(String attemptId);
  Future<bool> save(String path, String name);
}

class NativePerformanceRecordingBackend implements PerformanceRecordingBackend {
  NativePerformanceRecordingBackend._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'status') {
        _events.add(Map<dynamic, dynamic>.from(call.arguments as Map));
      }
    });
  }
  static final instance = NativePerformanceRecordingBackend._();
  static const _channel = MethodChannel('soundsight/performance_recording');
  static const _saveChannel = MethodChannel('soundsight/recorded_video');
  final _events = StreamController<Map<dynamic, dynamic>>.broadcast();
  @override
  Stream<Map<dynamic, dynamic>> get events => _events.stream;
  static Future<void> cleanupOrphans() async {
    await MidiVideoAudioCapture.cleanupOrphans();
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('cleanupOrphans');
      } on PlatformException catch (_) {
        /* Capture remains optional. */
      }
    }
  }

  @override
  Future<String> start(String attemptId) async {
    if (kIsWeb || !Platform.isAndroid) return 'unavailable';
    final result = await _channel.invokeMapMethod<String, dynamic>('start', {
      'attemptId': attemptId,
    });
    return result?['state'] as String? ?? 'unavailable';
  }

  @override
  Future<String?> finish(String attemptId) =>
      _channel.invokeMethod<String>('finish', {'attemptId': attemptId});

  Future<int?> captureStartedAtUs(String attemptId) async {
    final timing = await _channel.invokeMapMethod<String, dynamic>(
      'timing', {'attemptId': attemptId},
    );
    return (timing?['captureStartedAtUs'] as num?)?.toInt();
  }
  @override
  Future<void> discard(String attemptId) =>
      _channel.invokeMethod<void>('discard', {'attemptId': attemptId});
  @override
  Future<bool> save(String path, String name) async =>
      await _saveChannel.invokeMethod<bool>('saveVideo', {
        'path': path,
        'name': name,
      }) ??
      false;
}

/// A route owns one controller; every operation and callback belongs to one attempt.
class PerformanceRecordingController extends ChangeNotifier {
  PerformanceRecordingController({PerformanceRecordingBackend? backend})
    : _backend = backend ?? NativePerformanceRecordingBackend.instance {
    _subscription = _backend.events.listen((event) {
      if (event['attemptId'] != _attemptId || _closed) return;
      if (event['state'] == 'starting' &&
          state == PerformanceRecordingState.requestingPermission) {
        _setState(PerformanceRecordingState.starting);
      } else if (event['state'] == 'interrupted' ||
          event['state'] == 'unavailable') {
        _audioCapture?.cancel();
        path = null;
        _setState(PerformanceRecordingState.unavailable);
      }
    });
  }
  final PerformanceRecordingBackend _backend;
  late final StreamSubscription<Map<dynamic, dynamic>> _subscription;
  PerformanceRecordingState state = PerformanceRecordingState.idle;
  String? path;
  String? _attemptId;
  int _generation = 0;
  static int _sequence = 0;
  bool _closed = false;
  bool _starting = false;
  Future<void> _cleanup = Future.value();
  Future<void>? _finishing;
  Future<void>? _saving;
  Future<void>? _closing;
  Future<void> Function()? releasePreview;
  bool saveFailed = false;
  MidiVideoAudioCapture? _audioCapture;
  bool get isStarting => _starting;
  bool get isSaving => state == PerformanceRecordingState.saving;
  bool get hasAttempt => _attemptId != null;
  String? get attemptId => _attemptId;

  void _setState(PerformanceRecordingState next) {
    state = next;
    if (!_closed) notifyListeners();
  }

  Future<void> start({
    Stream<MidiNoteEvent>? midiEvents,
    Stream<MidiControlEvent>? midiControls,
  }) async {
    if (_closed || _starting || _attemptId != null) return;
    _starting = true;
    final generation = ++_generation;
    await _cleanup;
    if (_closed || generation != _generation) {
      _starting = false;
      return;
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
    _attemptId = id;
    _finishing = null;
    path = null;
    saveFailed = false;
    _setState(PerformanceRecordingState.requestingPermission);
    try {
      if (midiEvents == null && _backend is NativePerformanceRecordingBackend) {
        _setState(PerformanceRecordingState.unavailable);
        return;
      }
      if (midiEvents != null) {
        final capture = await MidiVideoAudioCapture.start(
          notes: midiEvents, controls: midiControls,
        );
        if (_closed || generation != _generation) {
          await capture.dispose();
          return;
        }
        _audioCapture = capture;
      }
      final outcome = await _backend.start(id);
      if (_closed || generation != _generation) return;
      if (outcome != 'recording') {
        await _audioCapture?.dispose();
        _audioCapture = null;
      }
      _setState(
        outcome == 'recording'
            ? PerformanceRecordingState.recording
            : PerformanceRecordingState.unavailable,
      );
    } catch (_) {
      await _audioCapture?.dispose();
      _audioCapture = null;
      if (!_closed && generation == _generation) {
        _setState(PerformanceRecordingState.unavailable);
      }
    } finally {
      _starting = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> finish({VoidCallback? onVideoStopped}) =>
      _finishing ??= _finish(onVideoStopped);
  Future<void> _finish(VoidCallback? onVideoStopped) async {
    final id = _attemptId;
    final generation = _generation;
    if (id == null || state != PerformanceRecordingState.recording) return;
    final capture = _audioCapture;
    capture?.stop();
    _setState(PerformanceRecordingState.finalizing);
    String? result;
    try {
      result = await _backend.finish(id);
      if (_closed || generation != _generation) return;
      if (result != null && capture != null) {
        onVideoStopped?.call();
        final backend = _backend;
        final startUs = backend is NativePerformanceRecordingBackend
            ? await backend.captureStartedAtUs(id) : null;
        if (_closed || generation != _generation) return;
        result = await capture.prepare(result, videoStartedAtUs: startUs);
      }
    } catch (_) {
      result = null;
      /* Results are independent of video. */
    }
    if (_closed || generation != _generation) return;
    path = result;
    _setState(
      result == null
          ? PerformanceRecordingState.unavailable
          : PerformanceRecordingState.ready,
    );
  }

  Future<void> save(String pieceTitle) =>
      _saving ??= _save(pieceTitle).whenComplete(() => _saving = null);
  Future<void> _save(String pieceTitle) async {
    final file = path;
    final id = _attemptId;
    final generation = _generation;
    final release = releasePreview;
    if (_closed || file == null || state != PerformanceRecordingState.ready) {
      return;
    }
    saveFailed = false;
    _setState(PerformanceRecordingState.saving);
    final title = pieceTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    try {
      final saved = await _backend.save(
        file,
        '${title.isEmpty ? 'SoundSight' : title}_$timestamp.mp4',
      );
      if (saved) {
        try {
          await release?.call();
        } catch (_) {
          /* File cleanup must still run. */
        }
        await _audioCapture?.dispose();
        _audioCapture = null;
        if (id != null) {
          try {
            await _backend.discard(id);
          } catch (_) {
            /* Startup sweep retries. */
          }
        }
        path = null;
        if (generation == _generation) {
          _setState(PerformanceRecordingState.saved);
        }
      } else if (generation == _generation) {
        saveFailed = true;
        _setState(PerformanceRecordingState.ready);
      }
    } catch (_) {
      if (generation == _generation) {
        saveFailed = true;
        _setState(PerformanceRecordingState.ready);
      }
    }
  }

  /// Invalidates callbacks synchronously, then waits for handles before deletion.
  Future<void> discard({String? expectedAttemptId}) {
    if (expectedAttemptId != null && expectedAttemptId != _attemptId) {
      return Future.value();
    }
    final id = _attemptId;
    _attemptId = null;
    ++_generation;
    final finishing = _finishing;
    final saving = _saving;
    final release = releasePreview;
    final capture = _audioCapture;
    _audioCapture = null;
    capture?.cancel();
    _finishing = null;
    path = null;
    _setState(PerformanceRecordingState.idle);
    _cleanup = _cleanup.then((_) async {
      if (saving != null) await saving;
      try {
        await release?.call();
      } catch (_) {
        /* Do not leak media after preview errors. */
      }
      if (finishing != null) await finishing;
      await capture?.dispose();
      // Cancel pending permission/start immediately; native serializes media teardown.
      if (id != null) {
        try {
          await _backend.discard(id);
        } catch (_) {
          /* Startup sweep retries cleanup. */
        }
      }
    });
    return _cleanup;
  }

  Future<void> close() {
    dispose();
    return _closing!;
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _closing = discard().then((_) => _subscription.cancel());
    state = PerformanceRecordingState.disposed;
    super.dispose();
  }
}
