import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ar/models/ar_score_timeline.dart';

class SynthesiaPianoRange {
  const SynthesiaPianoRange({required this.firstMidi, required this.lastMidi});

  final int firstMidi;
  final int lastMidi;

  factory SynthesiaPianoRange.forTimeline(ArScoreTimeline timeline) {
    var lowest = 108;
    var highest = 21;

    for (final event in timeline.noteEvents) {
      lowest = math.min(lowest, event.midiNote);
      highest = math.max(highest, event.midiNote);
    }

    if (highest - lowest >= 72) {
      return const SynthesiaPianoRange(firstMidi: 21, lastMidi: 108);
    }

    var first = (lowest - 12).clamp(21, 108).toInt();
    var last = (highest + 12).clamp(21, 108).toInt();

    while (last - first < 24) {
      if (first > 21) {
        first--;
      } else if (last < 108) {
        last++;
      } else {
        break;
      }
    }

    while (first > 21 && _isBlack(first)) {
      first--;
    }
    while (last < 108 && _isBlack(last)) {
      last++;
    }

    return SynthesiaPianoRange(firstMidi: first, lastMidi: last);
  }

  static bool _isBlack(int midi) {
    return const {1, 3, 6, 8, 10}.contains(midi % 12);
  }
}

class SynthesiaPianoGeometry {
  SynthesiaPianoGeometry({
    required this.size,
    required this.range,
  }) : whiteMidis = [
         for (var midi = range.firstMidi; midi <= range.lastMidi; midi++)
           if (!isBlackMidi(midi)) midi,
       ];

  final Size size;
  final SynthesiaPianoRange range;
  final List<int> whiteMidis;

  double get whiteKeyWidth => size.width / whiteMidis.length;
  double get blackKeyWidth => whiteKeyWidth * 0.62;
  double get blackKeyHeight => size.height * 0.62;

  static bool isBlackMidi(int midi) {
    return const {1, 3, 6, 8, 10}.contains(midi % 12);
  }

  Rect keyRect(int midi) {
    if (!isBlackMidi(midi)) {
      final index = whiteMidis.indexOf(midi);
      return Rect.fromLTWH(
        index * whiteKeyWidth,
        0,
        whiteKeyWidth,
        size.height,
      );
    }

    var precedingWhiteIndex = -1;
    for (var index = 0; index < whiteMidis.length; index++) {
      if (whiteMidis[index] < midi) precedingWhiteIndex = index;
    }
    final centerX = (precedingWhiteIndex + 1) * whiteKeyWidth;
    return Rect.fromCenter(
      center: Offset(centerX, blackKeyHeight / 2),
      width: blackKeyWidth,
      height: blackKeyHeight,
    );
  }

  Rect fallingLane(int midi, double height) {
    final key = keyRect(midi);
    final width = isBlackMidi(midi)
        ? math.max(4.0, key.width * 0.88)
        : math.max(5.0, key.width * 0.84);
    return Rect.fromCenter(
      center: Offset(key.center.dx, height / 2),
      width: width,
      height: height,
    );
  }
}
