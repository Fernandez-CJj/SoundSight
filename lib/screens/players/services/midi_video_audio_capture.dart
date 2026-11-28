import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/screens/composition/models/piano_note.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';

const _midiAudioSampleRate = 44100;
const _midiAudioRelease = Duration(milliseconds: 120);

/// Captures the physical performance independently of scoring, tempo, pauses,
/// and composition quantization. Timestamps share Android's monotonic clock.
class MidiVideoAudioCapture {
  MidiVideoAudioCapture._();

  static const _channel = MethodChannel('soundsight/recorded_video');
  static Future<void>? _orphanCleanup;
  final Stopwatch _clock = Stopwatch()..start();
  int _nativeOffsetUs = 0;
  final Map<int, _HeldNote> _held = {};
  final List<_HeldNote> _sustained = [];
  final List<_AudioNote> _notes = [];
  StreamSubscription<MidiNoteEvent>? _noteSubscription;
  StreamSubscription<MidiControlEvent>? _controlSubscription;
  bool _sustain = false;
  bool _stopped = false;
  bool _disposed = false;
  bool _overflow = false;
  int? _stoppedAtUs;
  Directory? _directory;
  Future<String>? _preparation;
  Future<void>? _disposal;

  int get nowUs => _clock.elapsedMicroseconds + _nativeOffsetUs;

  static Future<MidiVideoAudioCapture> start({
    required Stream<MidiNoteEvent> notes,
    Stream<MidiControlEvent>? controls,
  }) async {
    await cleanupOrphans();
    final capture = MidiVideoAudioCapture._();
    // Select the least delayed clock sample rather than treating the method
    // channel's delivery time as the instant that video capture began.
    var shortestRoundTrip = 1 << 62;
    for (var index = 0; index < 3; index++) {
      final before = capture._clock.elapsedMicroseconds;
      final native = await _channel.invokeMethod<int>('clock');
      final after = capture._clock.elapsedMicroseconds;
      if (native == null) throw StateError('Recording clock is unavailable.');
      if (after - before < shortestRoundTrip) {
        shortestRoundTrip = after - before;
        capture._nativeOffsetUs = native - ((before + after) ~/ 2);
      }
    }
    capture._noteSubscription = notes.listen(capture._onNote);
    capture._controlSubscription = controls?.listen(capture._onControl);
    return capture;
  }

  void _onNote(MidiNoteEvent event) {
    if (_stopped || _disposed || _overflow ||
        !PianoNote.isValidMidi(event.noteNumber)) return;
    if (_notes.length + _held.length + _sustained.length >= 100000) {
      _overflow = true;
      return;
    }
    final time = nowUs;
    if (event.type == MidiNoteEventType.noteOn && event.velocity > 0) {
      final previous = _held.remove(event.noteNumber);
      if (previous != null) _close(previous, time);
      _held[event.noteNumber] = _HeldNote(
        event.noteNumber, event.velocity.clamp(1, 127).toInt(), time,
      );
    } else {
      final note = _held.remove(event.noteNumber);
      if (note == null) return;
      if (_sustain) {
        _sustained.add(note);
      } else {
        _close(note, time);
      }
    }
  }

  void _onControl(MidiControlEvent event) {
    if (_stopped || _disposed || _overflow) return;
    if (event.controller == 64) {
      _sustain = event.value >= 64;
      if (!_sustain) _releaseSustain(nowUs);
    } else if (event.controller == 120 || event.controller == 123) {
      final time = nowUs;
      for (final note in _held.values) {
        _close(note, time);
      }
      _held.clear();
      _releaseSustain(time);
      _sustain = false;
    } else if (event.controller == 121) {
      _sustain = false;
      _releaseSustain(nowUs);
    }
  }

  void _releaseSustain(int time) {
    for (final note in _sustained) {
      _close(note, time);
    }
    _sustained.clear();
  }

  void _close(_HeldNote note, int time) {
    // Bound optional video capture memory without limiting practice/scoring.
    if (_notes.length >= 100000) {
      _overflow = true;
      return;
    }
    _notes.add(_AudioNote(note.pitch, note.velocity, note.startUs,
        math.max(note.startUs + 1, time)));
  }

  void stop() {
    if (_stopped) return;
    _stoppedAtUs = nowUs;
    _stopped = true;
    unawaited(_noteSubscription?.cancel());
    unawaited(_controlSubscription?.cancel());
    for (final note in _held.values) {
      _close(note, _stoppedAtUs!);
    }
    _held.clear();
    _releaseSustain(_stoppedAtUs!);
  }

  Future<String> prepare(String videoPath, {int? videoStartedAtUs}) {
    return _preparation ??= _prepare(videoPath, videoStartedAtUs).catchError(
      (Object error, StackTrace stack) {
        _preparation = null;
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  Future<String> _prepare(String videoPath, int? videoStartedAtUs) async {
    stop();
    if (_disposed || _overflow) throw StateError('Recording audio is unavailable.');
    final probe = await FFprobeKit.getMediaInformation(videoPath);
    final media = probe.getMediaInformation();
    final seconds = double.tryParse(media?.getDuration() ?? '');
    if (seconds == null || !seconds.isFinite || seconds <= 0 ||
        media?.getStreams().any((stream) => stream.getType() == 'video') != true) {
      throw StateError('The recorded video could not be read.');
    }
    final videoDurationUs = (seconds * Duration.microsecondsPerSecond).round();
    final startUs = videoStartedAtUs != null && videoStartedAtUs > 0
        ? videoStartedAtUs : _stoppedAtUs! - videoDurationUs;
    // Static score screens may encode their final frame before capture stops.
    // Keep the recorded performance's full wall-clock duration and its note
    // release instead of truncating audio to that final video frame. The MP4
    // retains the last picture while the remaining audio finishes.
    var durationUs = math.max(videoDurationUs, _stoppedAtUs! - startUs);
    for (final note in _notes) {
      durationUs = math.max(
        durationUs, note.endUs - startUs + _midiAudioRelease.inMicroseconds,
      );
    }
    final outputSeconds = durationUs / Duration.microsecondsPerSecond;
    _directory ??= await Directory.systemTemp.createTemp('soundsight-midi-video-');
    final directory = _directory!;
    final audio = File('${directory.path}/piano.wav');
    final output = File('${directory.path}/recording.mp4');
    final samples = <int, Uint8List>{};
    for (final pitch in _notes.map((note) => note.pitch).toSet()) {
      if (_disposed) throw StateError('Recording was discarded.');
      // The bundled samples start at C1. Render A0, A#0 and B0 from
      // their samples one octave above rather than failing the whole video.
      final note = PianoNote.fromMidi(pitch < 24 ? pitch + 12 : pitch);
      final name = '${note.pitch.replaceAll('#', 's')}${note.octave}';
      final data = await rootBundle.load('assets/audio/piano/cleaned/$name.wav');
      samples[pitch] = Uint8List.sublistView(data);
    }
    if (_disposed) throw StateError('Recording was discarded.');
    try {
      await compute(_renderMidiAudio, _RenderRequest(
        List<_AudioNote>.of(_notes), samples, startUs, durationUs, directory.path,
      ));
      if (_disposed) throw StateError('Recording was discarded.');
      final session = await FFmpegKit.executeWithArguments([
        '-hide_banner', '-loglevel', 'error', '-y',
        '-i', videoPath, '-i', audio.path,
        '-map', '0:v:0', '-map', '1:a:0',
        '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k',
        '-ar', '$_midiAudioSampleRate', '-ac', '1',
        '-t', outputSeconds.toStringAsFixed(6),
        '-movflags', '+faststart', output.path,
      ]);
      if (_disposed || !ReturnCode.isSuccess(await session.getReturnCode()) ||
          !await output.exists() || await output.length() == 0) {
        throw StateError('The recording audio could not be prepared.');
      }
      final completedProbe = await FFprobeKit.getMediaInformation(output.path);
      final streams = completedProbe.getMediaInformation()?.getStreams();
      if (streams == null || !streams.any((stream) => stream.getType() == 'audio') ||
          !streams.any((stream) => stream.getType() == 'video')) {
        throw StateError('The prepared recording is incomplete.');
      }
      return output.path;
    } catch (_) {
      if (await output.exists()) await output.delete();
      rethrow;
    } finally {
      if (await audio.exists()) await audio.delete();
    }
  }

  static Future<void> cleanupOrphans() => _orphanCleanup ??= _cleanupOrphans();

  static Future<void> _cleanupOrphans() async {
    try {
      await for (final entry in Directory.systemTemp.list(followLinks: false)) {
        if (entry is Directory && entry.path.split(Platform.pathSeparator).last
            .startsWith('soundsight-midi-video-')) {
          try {
            await entry.delete(recursive: true);
          } catch (_) {
            // A later app launch can retry cleanup of this feature's cache.
          }
        }
      }
    } catch (_) {
      // Recording may still work if an orphan sweep is unavailable.
    }
  }

  void cancel() {
    if (_disposed) return;
    _disposed = true;
    stop();
    final directory = _directory;
    if (directory != null) {
      try {
        File('${directory.path}/cancelled').writeAsStringSync('');
      } catch (_) {
        // The job may not have created its temporary directory yet.
      }
    }
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    cancel();
    try {
      await _preparation;
    } catch (_) {
      // Discarding must also clean up a failed or cancelled render.
    }
    try {
      if (_directory != null && await _directory!.exists()) {
        await _directory!.delete(recursive: true);
      }
    } catch (_) {
      // Cleanup failure must not turn an already saved video into a save error.
      // The next app launch retries this feature's orphan cleanup.
    }
    _clock.stop();
  }
}

class _HeldNote {
  const _HeldNote(this.pitch, this.velocity, this.startUs);
  final int pitch;
  final int velocity;
  final int startUs;
}

class _AudioNote {
  const _AudioNote(this.pitch, this.velocity, this.startUs, this.endUs);
  final int pitch;
  final int velocity;
  final int startUs;
  final int endUs;
}

class _RenderRequest {
  const _RenderRequest(this.notes, this.samples, this.startUs, this.durationUs, this.directory);
  final List<_AudioNote> notes;
  final Map<int, Uint8List> samples;
  final int startUs;
  final int durationUs;
  final String directory;
}

Int16List _decodePianoSample(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  String tag(int offset) => String.fromCharCodes(bytes.sublist(offset, offset + 4));
  if (bytes.length < 44 || tag(0) != 'RIFF' || tag(8) != 'WAVE') {
    throw const FormatException('Invalid piano sample.');
  }
  var channels = 0;
  var rate = 0;
  var bits = 0;
  var format = 0;
  var offset = 12;
  var audioOffset = 0;
  var audioSize = 0;
  while (offset + 8 <= bytes.length) {
    final size = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    if (start + size > bytes.length) throw const FormatException('Truncated piano sample.');
    if (tag(offset) == 'fmt ' && size >= 16) {
      format = data.getUint16(start, Endian.little);
      channels = data.getUint16(start + 2, Endian.little);
      rate = data.getUint32(start + 4, Endian.little);
      bits = data.getUint16(start + 14, Endian.little);
    } else if (tag(offset) == 'data') {
      audioOffset = start;
      audioSize = size;
    }
    offset = start + size + (size.isOdd ? 1 : 0);
  }
  if (format != 1 || channels < 1 || rate != 44100 || bits != 16 || audioSize == 0) {
    throw const FormatException('Piano samples must be 44.1 kHz 16-bit PCM WAV.');
  }
  final result = Int16List(audioSize ~/ (channels * 2));
  for (var frame = 0; frame < result.length; frame++) {
    var total = 0;
    for (var channel = 0; channel < channels; channel++) {
      total += data.getInt16(audioOffset + (frame * channels + channel) * 2, Endian.little);
    }
    result[frame] = (total / channels).round();
  }
  return result;
}

/// Streams bounded chunks to disk, then normalizes peak volume in a second
/// pass. Neither an entire performance PCM buffer nor mixing work lives on UI.
void _renderMidiAudio(_RenderRequest request) {
  const rate = _midiAudioSampleRate;
  const chunkSize = 16384;
  final releaseFrames = rate * _midiAudioRelease.inMicroseconds ~/
      Duration.microsecondsPerSecond;
  final totalFrames = (request.durationUs * rate / 1000000).ceil();
  if (totalFrames * 2 > 0xFFFFFFFF - 44) throw StateError('Recording is too long.');
  final samples = request.samples.map((pitch, bytes) {
    final decoded = _decodePianoSample(bytes);
    if (pitch >= 24) return MapEntry(pitch, decoded);
    final lowered = Int16List(decoded.length * 2);
    for (var index = 0; index < decoded.length; index++) {
      lowered[index * 2] = decoded[index];
      final next = index + 1 < decoded.length ? decoded[index + 1] : 0;
      lowered[index * 2 + 1] = (decoded[index] + next) ~/ 2;
    }
    return MapEntry(pitch, lowered);
  });
  final cancel = File('${request.directory}/cancelled');
  final floatingFile = File('${request.directory}/mix.pcm');
  final outputFile = File('${request.directory}/piano.wav');
  final voices = request.notes.map((note) => (
    pitch: note.pitch,
    velocity: note.velocity / 127,
    start: ((note.startUs - request.startUs) * rate / 1000000).round(),
    end: ((note.endUs - request.startUs) * rate / 1000000).round(),
  )).where((note) => note.end + releaseFrames > 0 && note.start < totalFrames).toList();
  var peak = 0.0;
  final floating = floatingFile.openSync(mode: FileMode.write);
  try {
    for (var base = 0; base < totalFrames; base += chunkSize) {
      if (cancel.existsSync()) throw StateError('Recording was discarded.');
      final mixed = Float32List(math.min(chunkSize, totalFrames - base));
      for (final voice in voices) {
        final sample = samples[voice.pitch]!;
        final from = math.max(base, voice.start);
        final until = math.min(base + mixed.length,
            math.min(voice.end + releaseFrames, voice.start + sample.length));
        for (var frame = from; frame < until; frame++) {
          final envelope = frame < voice.end ? 1.0
              : (1 - (frame - voice.end) / releaseFrames).clamp(0.0, 1.0).toDouble();
          mixed[frame - base] += sample[frame - voice.start] / 32768 * voice.velocity * envelope;
        }
      }
      for (final value in mixed) {
        peak = math.max(peak, value.abs());
      }
      floating.writeFromSync(Uint8List.view(mixed.buffer));
    }
  } finally {
    floating.closeSync();
  }
  final output = outputFile.openSync(mode: FileMode.write);
  final input = floatingFile.openSync();
  try {
    final header = ByteData(44);
    void text(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        header.setUint8(offset + index, value.codeUnitAt(index));
      }
    }
    text(0, 'RIFF'); text(8, 'WAVE'); text(12, 'fmt '); text(36, 'data');
    header.setUint32(4, 36 + totalFrames * 2, Endian.little);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, rate, Endian.little);
    header.setUint32(28, rate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint32(40, totalFrames * 2, Endian.little);
    output.writeFromSync(header.buffer.asUint8List());
    final gain = peak > 0.95 ? 0.95 / peak : 1.0;
    for (var base = 0; base < totalFrames; base += chunkSize) {
      if (cancel.existsSync()) throw StateError('Recording was discarded.');
      final count = math.min(chunkSize, totalFrames - base);
      final bytes = input.readSync(count * 4);
      if (bytes.length != count * 4) throw StateError('Incomplete piano audio.');
      final mixed = ByteData.sublistView(bytes);
      final pcm = ByteData(count * 2);
      for (var index = 0; index < count; index++) {
        pcm.setInt16(index * 2,
          (mixed.getFloat32(index * 4, Endian.host) * gain * 32767)
              .round().clamp(-32768, 32767).toInt(), Endian.little);
      }
      output.writeFromSync(pcm.buffer.asUint8List());
    }
  } finally {
    input.closeSync();
    output.closeSync();
    if (floatingFile.existsSync()) floatingFile.deleteSync();
  }
}
