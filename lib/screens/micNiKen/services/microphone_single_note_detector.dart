import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';

import '../models/microphone_input_state.dart';
import 'microphone_audio_capture_service.dart';
import 'microphone_note_event_processor.dart';

typedef _PitchAnalysis = ({
  bool pitched,
  double frequency,
  double probability,
  double rms,
});

/// Runs YIN pitch analysis away from the UI isolate for one PCM16 frame.
Future<_PitchAnalysis> _analyzePcmFrame(Uint8List frame) async {
  final detector = PitchDetector(
    audioSampleRate: MicrophoneAudioCaptureService.sampleRate.toDouble(),
    bufferSize: MicrophoneSingleNoteDetector.frameSampleCount,
  );
  final result = await detector.getPitchFromIntBuffer(frame);
  final data = ByteData.sublistView(frame);
  var sumSquares = 0.0;

  for (var offset = 0; offset + 1 < frame.lengthInBytes; offset += 2) {
    final normalized = data.getInt16(offset, Endian.little) / 32768.0;
    sumSquares += normalized * normalized;
  }

  return (
    pitched: result.pitched,
    frequency: result.pitch,
    probability: result.probability,
    rms: math.sqrt(sumSquares / MicrophoneSingleNoteDetector.frameSampleCount),
  );
}

/// Detects one dominant piano note from calibrated microphone PCM frames.
class MicrophoneSingleNoteDetector {
  /// Creates a monophonic feasibility detector that publishes accepted events.
  MicrophoneSingleNoteDetector({
    required MicrophoneNoteEventProcessor noteEventProcessor,
  }) : _noteEventProcessor = noteEventProcessor {
    _clock.start();
  }

  static const int frameSampleCount = 2048;
  static const int _frameByteCount = frameSampleCount * 2;
  static const int _minimumPianoNote = 48;
  static const int _maximumPianoNote = 84;
  static const double _minimumProbability = 0.90;
  static const double _maximumCentsError = 45;
  static const int _confirmationFrames = 2;
  static const int _releaseFrames = 4;

  final MicrophoneNoteEventProcessor _noteEventProcessor;
  final Stopwatch _clock = Stopwatch();
  final List<int> _pendingBytes = <int>[];

  int? _candidateNote;
  int _candidateFrames = 0;
  int? _activeNote;
  int _missingFrames = 0;
  int _generation = 0;
  bool _isAnalyzing = false;
  bool _isDisposed = false;

  /// Adds arbitrarily sized PCM16 chunks and extracts complete analysis frames.
  void addPcmChunk(Uint8List chunk) {
    if (_isDisposed || chunk.isEmpty) return;

    final state = _noteEventProcessor.state;
    if (state != MicrophoneInputState.ready &&
        state != MicrophoneInputState.degraded) {
      _pendingBytes.clear();
      return;
    }

    _pendingBytes.addAll(chunk);
    while (_pendingBytes.length >= _frameByteCount) {
      final frame = Uint8List.fromList(
        _pendingBytes.getRange(0, _frameByteCount).toList(),
      );
      _pendingBytes.removeRange(0, _frameByteCount);

      if (_isAnalyzing) continue;
      if (_noteEventProcessor.signalQuality != MicrophoneSignalQuality.usable) {
        _registerMissingPitch(_clock.elapsed);
        continue;
      }

      _isAnalyzing = true;
      final generation = _generation;
      final capturedAt = _clock.elapsed;
      _analyzeFrame(frame, capturedAt, generation);
    }
  }

  /// Processes one frame and ignores results invalidated by stop or restart.
  Future<void> _analyzeFrame(
    Uint8List frame,
    Duration capturedAt,
    int generation,
  ) async {
    try {
      final analysis = await Isolate.run(() => _analyzePcmFrame(frame));
      if (_isDisposed || generation != _generation) return;

      final noteNumber = _acceptedNoteNumber(analysis);
      if (noteNumber == null) {
        _registerMissingPitch(capturedAt);
      } else {
        _registerDetectedPitch(noteNumber, analysis, capturedAt);
      }
    } catch (_) {
      if (!_isDisposed && generation == _generation) {
        _registerMissingPitch(capturedAt);
      }
    } finally {
      if (generation == _generation) _isAnalyzing = false;
    }
  }

  /// Converts a confident in-range frequency into its nearest piano note.
  int? _acceptedNoteNumber(_PitchAnalysis analysis) {
    if (!analysis.pitched ||
        analysis.frequency <= 0 ||
        analysis.probability < _minimumProbability) {
      return null;
    }

    final exactNote =
        69 + 12 * (math.log(analysis.frequency / 440) / math.ln2);
    final noteNumber = exactNote.round();
    final centsError = (exactNote - noteNumber).abs() * 100;
    if (noteNumber < _minimumPianoNote ||
        noteNumber > _maximumPianoNote ||
        centsError > _maximumCentsError) {
      return null;
    }
    return noteNumber;
  }

  /// Confirms a stable pitch before publishing its attack and active state.
  void _registerDetectedPitch(
    int noteNumber,
    _PitchAnalysis analysis,
    Duration capturedAt,
  ) {
    _missingFrames = 0;
    if (_activeNote == noteNumber) {
      _candidateNote = null;
      _candidateFrames = 0;
      return;
    }

    if (_candidateNote == noteNumber) {
      _candidateFrames++;
    } else {
      _candidateNote = noteNumber;
      _candidateFrames = 1;
    }
    if (_candidateFrames < _confirmationFrames) return;

    _releaseActiveNote(capturedAt, analysis.probability);
    _activeNote = noteNumber;
    _candidateNote = null;
    _candidateFrames = 0;
    _noteEventProcessor.acceptNoteOn(
      noteNumber: noteNumber,
      estimatedVelocity: _estimatedVelocity(analysis.rms),
      confidence: analysis.probability,
      capturedAt: capturedAt,
    );
  }

  /// Releases a note after several frames no longer contain a usable pitch.
  void _registerMissingPitch(Duration capturedAt) {
    _candidateNote = null;
    _candidateFrames = 0;
    if (_activeNote == null) return;

    _missingFrames++;
    if (_missingFrames < _releaseFrames) return;
    _releaseActiveNote(capturedAt, 0);
  }

  /// Maps frame loudness to a conservative estimated acoustic velocity.
  int _estimatedVelocity(double rms) {
    return (20 + rms * 700).round().clamp(1, 127).toInt();
  }

  /// Publishes release for the current monophonic note and clears local state.
  void _releaseActiveNote(Duration capturedAt, double confidence) {
    final noteNumber = _activeNote;
    if (noteNumber == null) return;

    _noteEventProcessor.acceptNoteOff(
      noteNumber: noteNumber,
      confidence: confidence,
      capturedAt: capturedAt,
    );
    _activeNote = null;
    _missingFrames = 0;
  }

  /// Clears buffered audio and invalidates analysis from the previous session.
  void reset() {
    _generation++;
    _pendingBytes.clear();
    _candidateNote = null;
    _candidateFrames = 0;
    _activeNote = null;
    _missingFrames = 0;
    _isAnalyzing = false;
  }

  /// Stops accepting PCM and invalidates any in-flight pitch analysis.
  void dispose() {
    if (_isDisposed) return;
    reset();
    _isDisposed = true;
    _clock.stop();
  }
}
