import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'microphone_audio_capture_service.dart';
import 'microphone_note_event_processor.dart';

/// Streams live microphone PCM to the development computer's Python backend.
class MicrophoneBackendStreamService {
  /// Creates a stream session around the existing Android capture service.
  MicrophoneBackendStreamService({
    required MicrophoneAudioCaptureService captureService,
    required MicrophoneNoteEventProcessor noteEventProcessor,
    required void Function() onChanged,
  }) : _captureService = captureService,
       _noteEventProcessor = noteEventProcessor,
       _onChanged = onChanged;

  final MicrophoneAudioCaptureService _captureService;
  final MicrophoneNoteEventProcessor _noteEventProcessor;
  final void Function() _onChanged;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<Uint8List>? _pcmSubscription;
  Timer? _readyTimer;
  Future<bool>? _startFuture;
  Future<void>? _stopFuture;
  int _session = 0;
  bool _isDisposed = false;

  bool isStarting = false;
  bool isConnected = false;
  bool isStreaming = false;
  int bytesReceived = 0;
  int chunksReceived = 0;
  int? lastNoteNumber;
  double? lastNoteConfidence;
  int detectedAttacks = 0;
  int detectedReleases = 0;
  String calibrationStatus = 'Not calibrated';
  Set<int> serverActiveNotes = <int>{};
  String status = 'Disconnected';
  String? lastError;
  int _streamSampleRate = MicrophoneAudioCaptureService.sampleRate;

  /// Connects to the LAN host with the selected recognition sensitivity.
  Future<bool> start(String serverAddress, {required int sensitivity}) async {
    if (_isDisposed || isStarting || isStreaming || _stopFuture != null) {
      return false;
    }

    final uri = _serverUri(serverAddress);
    if (uri == null) {
      lastError =
          'Enter your computer LAN address, for example 192.168.0.104:8000.';
      status = 'Disconnected';
      _onChanged();
      return false;
    }

    final session = ++_session;
    isStarting = true;
    isConnected = false;
    isStreaming = false;
    bytesReceived = 0;
    chunksReceived = 0;
    lastNoteNumber = null;
    lastNoteConfidence = null;
    detectedAttacks = 0;
    detectedReleases = 0;
    serverActiveNotes = <int>{};
    calibrationStatus = 'Waiting for calibration';
    lastError = null;
    status = 'Connecting to ${uri.host}:${uri.port}...';
    _onChanged();

    final attempt = _startSession(uri, session, sensitivity);
    _startFuture = attempt;
    try {
      return await attempt;
    } finally {
      _startFuture = null;
    }
  }

  /// Opens the socket, starts capture, and sends its format and sensitivity.
  Future<bool> _startSession(Uri uri, int session, int sensitivity) async {
    try {
      final socket = await WebSocket.connect(
        uri.toString(),
      ).timeout(const Duration(seconds: 8));
      if (_session != session || _isDisposed) {
        await socket.close();
        return false;
      }

      _socket = socket;
      _socketSubscription = socket.listen(
        _handleServerMessage,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        cancelOnError: true,
      );

      final started = await _captureService.start();
      if (_session != session || _isDisposed) {
        if (started) await _captureService.stop(interrupted: true);
        return false;
      }
      if (!started) {
        throw StateError(
          _captureService.lastError ?? 'Microphone capture could not start.',
        );
      }

      _streamSampleRate = _captureService.effectiveSampleRate;
      socket.add(
        jsonEncode({
          'type': 'start',
          'encoding': 'pcm16le',
          'channels': 1,
          'sampleRate': _streamSampleRate,
          'sensitivity': sensitivity,
        }),
      );
      _pcmSubscription = _captureService.pcmStream.listen(_sendPcm);
      isStreaming = true;
      isStarting = false;
      if (!isConnected) status = 'Waiting for server confirmation...';
      _onChanged();
      _readyTimer = Timer(const Duration(seconds: 8), () {
        if (_session == session && !isConnected) {
          unawaited(
            stop(
              interrupted: true,
              reason: 'The server did not confirm the audio format.',
            ),
          );
        }
      });
      return true;
    } catch (error) {
      if (_session == session) {
        lastError = error is StateError
            ? error.message.toString()
            : 'Could not connect to the microphone server: $error';
        await _closeResources(interrupted: true);
        status = 'Disconnected';
        _onChanged();
      }
      return false;
    }
  }

  /// Resolves a computer address to the microphone WebSocket endpoint.
  Uri? _serverUri(String address) {
    final value = address.trim();
    if (value.isEmpty) return null;
    final parsed = Uri.tryParse(value.contains('://') ? value : 'ws://$value');
    if (parsed == null || parsed.host.isEmpty || parsed.scheme != 'ws') {
      return null;
    }
    return Uri(
      scheme: 'ws',
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : 8000,
      path: '/mic/stream',
    );
  }

  /// Forwards each raw PCM16 chunk without writing audio to local storage.
  void _sendPcm(Uint8List bytes) {
    if (!isStreaming || bytes.isEmpty) return;
    try {
      _socket?.add(bytes);
    } catch (error) {
      unawaited(
        stop(interrupted: true, reason: 'Audio upload stopped: $error'),
      );
    }
  }

  /// Applies backend readiness, audio receipt, calibration, and piano results.
  void _handleServerMessage(dynamic message) {
    if (message is! String) return;
    try {
      final data = jsonDecode(message);
      if (data is! Map<String, dynamic>) return;
      switch (data['type']) {
        case 'ready':
          _readyTimer?.cancel();
          isConnected = true;
          status = 'Connected; waiting for audio receipt';
          _onChanged();
          return;
        case 'audio_received':
          _readyTimer?.cancel();
          isConnected = true;
          bytesReceived = (data['bytesReceived'] as num?)?.toInt() ?? 0;
          chunksReceived = (data['chunksReceived'] as num?)?.toInt() ?? 0;
          status = 'Audio arriving at Python';
          _onChanged();
          return;
        case 'calibration':
          calibrationStatus = data['state'] == 'ready'
              ? 'Ready (room noise measured)'
              : 'Keep quiet for about 1 second';
          _onChanged();
          return;
        case 'note_on':
        case 'note_off':
          _handleNoteEvent(data);
          return;
        case 'active_notes':
          final notes = data['notes'];
          if (notes is List) {
            serverActiveNotes = notes.whereType<int>().toSet();
            _onChanged();
          }
          return;
        case 'error':
          unawaited(
            stop(
              interrupted: true,
              reason:
                  data['message']?.toString() ?? 'The server rejected audio.',
            ),
          );
          return;
      }
    } on FormatException {
      unawaited(
        stop(interrupted: true, reason: 'The server sent an invalid response.'),
      );
    }
  }

  /// Converts one Python note event into the microphone processor's contract.
  void _handleNoteEvent(Map<String, dynamic> data) {
    final note = data['noteNumber'];
    final confidence = data['confidence'];
    final velocity = data['estimatedVelocity'];
    final position = data['capturePosition'];
    if (note is! int ||
        note < 0 ||
        note > 127 ||
        confidence is! num ||
        velocity is! int ||
        position is! int ||
        position < 0) {
      return;
    }

    final capturedAt = Duration(
      microseconds: (position * 1000000 / _streamSampleRate).round(),
    );
    if (data['type'] == 'note_on') {
      _noteEventProcessor.acceptNoteOn(
        noteNumber: note,
        estimatedVelocity: velocity,
        confidence: confidence.toDouble(),
        capturedAt: capturedAt,
      );
      lastNoteNumber = note;
      lastNoteConfidence = confidence.toDouble();
      detectedAttacks++;
    } else {
      _noteEventProcessor.acceptNoteOff(
        noteNumber: note,
        confidence: confidence.toDouble(),
        capturedAt: capturedAt,
      );
      detectedReleases++;
    }
    _onChanged();
  }

  /// Closes the session if the WebSocket reports a transport error.
  void _handleSocketError(Object error, StackTrace stackTrace) {
    unawaited(stop(interrupted: true, reason: 'Connection lost: $error'));
  }

  /// Closes the session if the server disconnects unexpectedly.
  void _handleSocketDone() {
    if (_socket == null) return;
    unawaited(
      stop(interrupted: true, reason: 'The microphone server disconnected.'),
    );
  }

  /// Stops streaming, clears note state, and turns off Android capture.
  Future<void> stop({bool interrupted = false, String? reason}) {
    if (_stopFuture != null) return _stopFuture!;
    _session++;
    final stopping = _stopSession(interrupted: interrupted, reason: reason);
    _stopFuture = stopping;
    return stopping.whenComplete(() => _stopFuture = null);
  }

  /// Waits for any pending start before releasing session resources.
  Future<void> _stopSession({required bool interrupted, String? reason}) async {
    await _startFuture;
    await _closeResources(interrupted: interrupted);
    lastError = reason;
    status = reason == null ? 'Disconnected' : 'Input unavailable';
    _onChanged();
  }

  /// Releases the socket and recorder and discards all active microphone notes.
  Future<void> _closeResources({required bool interrupted}) async {
    _readyTimer?.cancel();
    _readyTimer = null;
    isStarting = false;
    isStreaming = false;
    isConnected = false;
    serverActiveNotes = <int>{};
    calibrationStatus = 'Not calibrated';
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    await _captureService.stop(interrupted: interrupted);
    final socket = _socket;
    _socket = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    try {
      if (socket != null) {
        await socket.close().timeout(const Duration(seconds: 2));
      }
    } catch (_) {
      // The microphone is already off; a stalled network close can be ignored.
    }
    _noteEventProcessor.clearActiveNotes();
  }

  /// Permanently closes the streaming session when its screen is removed.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await stop();
  }
}
