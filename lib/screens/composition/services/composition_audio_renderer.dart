import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/models/piano_note.dart';

class CompositionRenderResult {
  const CompositionRenderResult({
    required this.file,
    required this.duration,
  });

  final File file;
  final Duration duration;
}

class CompositionAudioRenderer {
  static const int sampleRate = 44100;
  static const int maximumDurationSeconds = 600;

  final Map<String, Future<CompositionRenderResult>> _renderCache = {};
  final Set<String> _createdFilePaths = {};

  Future<CompositionRenderResult> render(
    Composition composition, {
    required Duration releaseDuration,
  }) {
    final cacheKey = _compositionCacheKey(composition, releaseDuration);
    final existingRender = _renderCache[cacheKey];

    if (existingRender != null) return existingRender;

    late final Future<CompositionRenderResult> renderFuture;

    renderFuture = _renderComposition(
      composition,
      releaseDuration: releaseDuration,
      cacheKey: cacheKey,
    ).catchError((Object error, StackTrace stackTrace) {
      if (identical(_renderCache[cacheKey], renderFuture)) {
        _renderCache.remove(cacheKey);
      }

      Error.throwWithStackTrace(error, stackTrace);
    });

    _renderCache[cacheKey] = renderFuture;
    return renderFuture;
  }

  Future<CompositionRenderResult> _renderComposition(
    Composition composition, {
    required Duration releaseDuration,
    required String cacheKey,
  }) async {
    final microsecondsPerBeat =
        (60000000 / composition.tempo) * (4 / composition.beatUnit);
    final framesPerBeat = sampleRate * microsecondsPerBeat / 1000000;
    final releaseFrames =
        sampleRate * releaseDuration.inMicroseconds ~/ 1000000;
    final spans = _buildNoteSpans(composition);
    var totalFrames = math.max(
      1,
      (composition.measureCount *
              composition.beatsPerMeasure *
              framesPerBeat)
          .ceil(),
    );

    for (final span in spans) {
      final endFrame =
          ((span.endBeat * framesPerBeat).round() + releaseFrames);
      totalFrames = math.max(totalFrames, endFrame);
    }

    if (totalFrames > sampleRate * maximumDurationSeconds) {
      throw StateError(
        'The composition is too long to render. Keep it under '
        '${maximumDurationSeconds ~/ 60} minutes.',
      );
    }

    final requiredMidiNumbers = spans.map((span) {
      return span.note.midiNumber;
    }).toSet();
    final samplesByMidi = <int, _PcmSample>{};

    for (final midiNumber in requiredMidiNumbers) {
      samplesByMidi[midiNumber] = await _loadPcmSample(midiNumber);
    }

    final mixedSamples = Float32List(totalFrames);

    for (final span in spans) {
      final source = samplesByMidi[span.note.midiNumber]!;

      if (source.sampleRate != sampleRate) {
        throw StateError(
          '${_audioAssetPath(span.note.midiNumber)} must use '
          '$sampleRate Hz audio.',
        );
      }

      final startFrame = (span.startBeat * framesPerBeat).round();
      final heldFrames = math.max(
        1,
        ((span.endBeat - span.startBeat) * framesPerBeat).round(),
      );
      final playableFrames = math.min(
        source.samples.length,
        heldFrames + releaseFrames,
      );

      for (var sourceIndex = 0; sourceIndex < playableFrames; sourceIndex++) {
        final targetIndex = startFrame + sourceIndex;

        if (targetIndex >= mixedSamples.length) break;

        var envelope = 1.0;

        if (sourceIndex >= heldFrames && releaseFrames > 0) {
          envelope = 1 - ((sourceIndex - heldFrames) / releaseFrames);
          envelope = envelope.clamp(0.0, 1.0).toDouble();
        }

        mixedSamples[targetIndex] +=
            (source.samples[sourceIndex] / 32768) *
            span.note.velocity *
            envelope;
      }
    }

    var peak = 0.0;

    for (final sample in mixedSamples) {
      peak = math.max(peak, sample.abs());
    }

    final outputScale = peak > 0.95 ? 0.95 / peak : 1.0;
    final wavBytes = _encodeWav(mixedSamples, outputScale: outputScale);
    final outputDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'soundsight_compositions',
    );

    await outputDirectory.create(recursive: true);

    final outputFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}$cacheKey.wav',
    );

    await outputFile.writeAsBytes(wavBytes, flush: true);
    _createdFilePaths.add(outputFile.path);

    return CompositionRenderResult(
      file: outputFile,
      duration: Duration(
        microseconds: totalFrames * 1000000 ~/ sampleRate,
      ),
    );
  }

  List<_RenderedNoteSpan> _buildNoteSpans(Composition composition) {
    final notes = composition.notes.where((note) {
      return note.durationBeats > 0;
    }).toList();

    notes.sort((first, second) {
      final firstStart = _absoluteStartBeat(first, composition);
      final secondStart = _absoluteStartBeat(second, composition);
      final startComparison = firstStart.compareTo(secondStart);

      if (startComparison != 0) return startComparison;

      return first.midiNumber.compareTo(second.midiNumber);
    });

    final consumedNoteIds = <String>{};
    final spans = <_RenderedNoteSpan>[];

    for (final note in notes) {
      if (consumedNoteIds.contains(note.id)) continue;

      final startBeat = _absoluteStartBeat(note, composition);
      var endBeat = startBeat + note.durationBeats;
      var currentNote = note;

      while (currentNote.tieToNext) {
        CompositionNote? tiedNote;

        for (final candidate in notes) {
          if (consumedNoteIds.contains(candidate.id) ||
              candidate.id == currentNote.id ||
              candidate.midiNumber != currentNote.midiNumber) {
            continue;
          }

          final candidateStart = _absoluteStartBeat(candidate, composition);

          if ((candidateStart - endBeat).abs() < 0.0000001) {
            tiedNote = candidate;
            break;
          }
        }

        if (tiedNote == null) break;

        consumedNoteIds.add(tiedNote.id);
        currentNote = tiedNote;
        endBeat =
            _absoluteStartBeat(tiedNote, composition) + tiedNote.durationBeats;
      }

      spans.add(
        _RenderedNoteSpan(
          note: note,
          startBeat: startBeat,
          endBeat: endBeat,
        ),
      );
    }

    return spans;
  }

  double _absoluteStartBeat(
    CompositionNote note,
    Composition composition,
  ) {
    return (note.measureIndex * composition.beatsPerMeasure) + note.startBeat;
  }

  Future<_PcmSample> _loadPcmSample(int midiNumber) async {
    final assetPath = _audioAssetPath(midiNumber);
    final data = await rootBundle.load(assetPath);
    return _decodeWav(data, assetPath: assetPath);
  }

  _PcmSample _decodeWav(ByteData data, {required String assetPath}) {
    if (data.lengthInBytes < 44 ||
        _readText(data, 0, 4) != 'RIFF' ||
        _readText(data, 8, 4) != 'WAVE') {
      throw FormatException('$assetPath is not a valid WAV file.');
    }

    var offset = 12;
    var audioFormat = 0;
    var channelCount = 0;
    var sourceSampleRate = 0;
    var bitsPerSample = 0;
    var dataOffset = -1;
    var dataLength = 0;

    while (offset + 8 <= data.lengthInBytes) {
      final chunkId = _readText(data, offset, 4);
      final chunkLength = data.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;

      if (chunkDataOffset + chunkLength > data.lengthInBytes) break;

      if (chunkId == 'fmt ' && chunkLength >= 16) {
        audioFormat = data.getUint16(chunkDataOffset, Endian.little);
        channelCount = data.getUint16(chunkDataOffset + 2, Endian.little);
        sourceSampleRate = data.getUint32(
          chunkDataOffset + 4,
          Endian.little,
        );
        bitsPerSample = data.getUint16(
          chunkDataOffset + 14,
          Endian.little,
        );
      } else if (chunkId == 'data') {
        dataOffset = chunkDataOffset;
        dataLength = chunkLength;
      }

      offset = chunkDataOffset + chunkLength + (chunkLength.isOdd ? 1 : 0);
    }

    if (audioFormat != 1 ||
        channelCount <= 0 ||
        sourceSampleRate <= 0 ||
        bitsPerSample != 16 ||
        dataOffset < 0) {
      throw FormatException(
        '$assetPath must be a 16-bit PCM WAV file.',
      );
    }

    final frameCount = dataLength ~/ (channelCount * 2);
    final samples = Int16List(frameCount);

    for (var frame = 0; frame < frameCount; frame++) {
      var channelTotal = 0;

      for (var channel = 0; channel < channelCount; channel++) {
        final sampleOffset =
            dataOffset + ((frame * channelCount + channel) * 2);
        channelTotal += data.getInt16(sampleOffset, Endian.little);
      }

      samples[frame] = (channelTotal / channelCount).round();
    }

    return _PcmSample(samples: samples, sampleRate: sourceSampleRate);
  }

  Uint8List _encodeWav(
    Float32List samples, {
    required double outputScale,
  }) {
    final dataLength = samples.length * 2;
    final output = ByteData(44 + dataLength);

    _writeText(output, 0, 'RIFF');
    output.setUint32(4, 36 + dataLength, Endian.little);
    _writeText(output, 8, 'WAVE');
    _writeText(output, 12, 'fmt ');
    output.setUint32(16, 16, Endian.little);
    output.setUint16(20, 1, Endian.little);
    output.setUint16(22, 1, Endian.little);
    output.setUint32(24, sampleRate, Endian.little);
    output.setUint32(28, sampleRate * 2, Endian.little);
    output.setUint16(32, 2, Endian.little);
    output.setUint16(34, 16, Endian.little);
    _writeText(output, 36, 'data');
    output.setUint32(40, dataLength, Endian.little);

    for (var index = 0; index < samples.length; index++) {
      final normalized = (samples[index] * outputScale).clamp(-1.0, 1.0);
      final pcmValue = normalized < 0
          ? (normalized * 32768).round()
          : (normalized * 32767).round();

      output.setInt16(44 + index * 2, pcmValue, Endian.little);
    }

    return output.buffer.asUint8List();
  }

  String _audioAssetPath(int midiNumber) {
    final pianoNote = PianoNote.fromMidi(midiNumber);
    final filePitch = pianoNote.pitch.replaceAll('#', 's');
    return 'assets/audio/piano/cleaned/'
        '$filePitch${pianoNote.octave}.wav';
  }

  String _compositionCacheKey(
    Composition composition,
    Duration releaseDuration,
  ) {
    var hash = 2166136261;

    void addValue(Object? value) {
      final text = value.toString();

      for (final codeUnit in text.codeUnits) {
        hash ^= codeUnit;
        hash = (hash * 16777619) & 0x7fffffff;
      }
    }

    addValue(composition.id);
    addValue(composition.tempo);
    addValue(composition.measureCount);
    addValue(composition.beatsPerMeasure);
    addValue(composition.beatUnit);
    addValue(releaseDuration.inMicroseconds);

    for (final note in composition.notes) {
      addValue(note.id);
      addValue(note.midiNumber);
      addValue(note.measureIndex);
      addValue(note.startBeat);
      addValue(note.durationBeats);
      addValue(note.velocity);
      addValue(note.tieToNext);
    }

    final safeId = composition.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${safeId}_$hash';
  }

  String _readText(ByteData data, int offset, int length) {
    return String.fromCharCodes(
      List<int>.generate(length, (index) => data.getUint8(offset + index)),
    );
  }

  void _writeText(ByteData data, int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      data.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  Future<void> dispose() async {
    _renderCache.clear();

    for (final path in _createdFilePaths) {
      try {
        final file = File(path);

        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Temporary rendered files can be cleared by the operating system.
      }
    }

    _createdFilePaths.clear();
  }
}

class _RenderedNoteSpan {
  const _RenderedNoteSpan({
    required this.note,
    required this.startBeat,
    required this.endBeat,
  });

  final CompositionNote note;
  final double startBeat;
  final double endBeat;
}

class _PcmSample {
  const _PcmSample({required this.samples, required this.sampleRate});

  final Int16List samples;
  final int sampleRate;
}
