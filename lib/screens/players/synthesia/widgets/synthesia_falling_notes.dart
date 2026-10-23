import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ar/models/ar_score_timeline.dart';
import '../../ar/services/ar_practice_performance_tracker.dart';
import '../models/synthesia_wait_note_occurrence.dart';
import 'synthesia_piano_geometry.dart';

class SynthesiaFallingNotes extends StatelessWidget {
  const SynthesiaFallingNotes({
    super.key,
    required this.timeline,
    required this.range,
    required this.animation,
    required this.approachDuration,
    required this.results,
    required this.waitPreviewOriginStartMicroseconds,
    required this.waitHoldProgress,
    required this.waitPreviewAdvanceMicroseconds,
    required this.hiddenGroupStartMicroseconds,
    required this.hiddenWaitOccurrences,
  });

  final ArScoreTimeline timeline;
  final SynthesiaPianoRange range;
  final Animation<double> animation;
  final Duration approachDuration;
  final Map<int, ArPracticeNoteResult> results;
  final int? waitPreviewOriginStartMicroseconds;
  final Map<SynthesiaWaitNoteOccurrence, double> waitHoldProgress;
  final int waitPreviewAdvanceMicroseconds;
  final Set<int> hiddenGroupStartMicroseconds;
  final Set<SynthesiaWaitNoteOccurrence> hiddenWaitOccurrences;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SynthesiaFallingNotesPainter(
          timeline: timeline,
          range: range,
          animation: animation,
          approachDuration: approachDuration,
          results: results,
          waitPreviewOriginStartMicroseconds:
              waitPreviewOriginStartMicroseconds,
          waitHoldProgress: waitHoldProgress,
          waitPreviewAdvanceMicroseconds: waitPreviewAdvanceMicroseconds,
          hiddenGroupStartMicroseconds: hiddenGroupStartMicroseconds,
          hiddenWaitOccurrences: hiddenWaitOccurrences,
        ),
        isComplex: true,
        willChange: true,
      ),
    );
  }
}

class _SynthesiaFallingNotesPainter extends CustomPainter {
  _SynthesiaFallingNotesPainter({
    required this.timeline,
    required this.range,
    required this.animation,
    required this.approachDuration,
    required this.results,
    required this.waitPreviewOriginStartMicroseconds,
    required this.waitHoldProgress,
    required this.waitPreviewAdvanceMicroseconds,
    required this.hiddenGroupStartMicroseconds,
    required this.hiddenWaitOccurrences,
  }) : maximumNoteDurationUs = timeline.noteEvents.fold<int>(
         0,
         (largest, note) => math.max(largest, note.duration.inMicroseconds),
       ),
       super(repaint: animation) {
    List<int> groupStarts = timeline.noteEvents
        .map((note) => note.startTime.inMicroseconds)
        .toSet()
        .toList()
      ..sort();
    for (int index = 0; index < groupStarts.length; index++) {
      groupIndexByStartMicroseconds[groupStarts[index]] = index;
    }
  }

  final ArScoreTimeline timeline;
  final SynthesiaPianoRange range;
  final Animation<double> animation;
  final Duration approachDuration;
  final Map<int, ArPracticeNoteResult> results;
  final int? waitPreviewOriginStartMicroseconds;
  final Map<SynthesiaWaitNoteOccurrence, double> waitHoldProgress;
  final int waitPreviewAdvanceMicroseconds;
  final Set<int> hiddenGroupStartMicroseconds;
  final Set<SynthesiaWaitNoteOccurrence> hiddenWaitOccurrences;
  final int maximumNoteDurationUs;
  final Map<int, int> groupIndexByStartMicroseconds = <int, int>{};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || approachDuration.inMicroseconds <= 0) return;

    final totalAnimationUs =
        approachDuration.inMicroseconds + timeline.totalDuration.inMicroseconds;
    final animationUs = (animation.value * totalAnimationUs).round();
    final scoreUs = animationUs - approachDuration.inMicroseconds;
    final approachUs = approachDuration.inMicroseconds;
    final geometry = SynthesiaPianoGeometry(
      size: Size(size.width, 1),
      range: range,
    );

    final backgroundPaint = Paint()..color = const Color(0xFF07111F);
    canvas.drawRect(Offset.zero & size, backgroundPaint);
    _drawLaneGuides(canvas, size, geometry);

    final earliestStartUs = scoreUs - maximumNoteDurationUs;
    var low = 0;
    var high = timeline.noteEvents.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (timeline.noteEvents[middle].startTime.inMicroseconds <
          earliestStartUs) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    for (var index = low; index < timeline.noteEvents.length; index++) {
      final note = timeline.noteEvents[index];
      int groupStartUs = note.startTime.inMicroseconds;
      SynthesiaWaitNoteOccurrence occurrence = SynthesiaWaitNoteOccurrence(
        groupIndex: groupIndexByStartMicroseconds[groupStartUs] ?? 0,
        groupStartMicroseconds: groupStartUs,
        midiNote: note.midiNote,
      );
      if (hiddenGroupStartMicroseconds.contains(groupStartUs) ||
          hiddenWaitOccurrences.contains(occurrence)) {
        continue;
      }
      if (note.midiNote < range.firstMidi || note.midiNote > range.lastMidi) {
        continue;
      }

      double? holdProgress = waitHoldProgress[occurrence];
      int displayedScoreUs = holdProgress == null ? scoreUs : groupStartUs;
      if (holdProgress == null &&
          waitPreviewOriginStartMicroseconds != null &&
          groupStartUs > waitPreviewOriginStartMicroseconds!) {
        displayedScoreUs += waitPreviewAdvanceMicroseconds;
      }
      final timeUntilHit = note.startTime.inMicroseconds - displayedScoreUs;
      if (timeUntilHit > approachUs) break;
      final noteBottom = size.height * (1 - (timeUntilHit / approachUs));
      final noteHeight = math.max(
        20.0,
        size.height * note.duration.inMicroseconds / approachUs,
      );
      final noteTop = noteBottom - noteHeight;

      if (noteBottom < 0 || noteTop > size.height) continue;

      double visibleTop = math.max(0.0, noteTop);
      final visibleBottom = math.min(size.height, noteBottom);
      if (holdProgress != null) {
        double safeProgress = holdProgress.clamp(0.0, 1.0).toDouble();
        visibleTop = math.max(visibleTop, noteTop + noteHeight * safeProgress);
        if (safeProgress >= 1) continue;
      }
      if (visibleBottom <= visibleTop) continue;

      final lane = geometry.fallingLane(
        note.midiNote,
        visibleBottom - visibleTop,
      );
      final rect = Rect.fromLTWH(
        lane.left,
        visibleTop,
        lane.width,
        visibleBottom - visibleTop,
      );
      final result = results[note.startTime.inMicroseconds];
      final color = switch (result) {
        ArPracticeNoteResult.correct => const Color(0xFF39D98A),
        ArPracticeNoteResult.timingMistake => const Color(0xFFFFC857),
        ArPracticeNoteResult.incorrect => const Color(0xFFFF5D73),
        null => SynthesiaPianoGeometry.isBlackMidi(note.midiNote)
            ? const Color(0xFFD765FF)
            : const Color(0xFF38BDF8),
      };
      final rounded = RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.min(5.0, rect.width / 3)),
      );
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
      canvas.drawRRect(rounded, Paint()..color = color);
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      _drawNoteLabel(canvas, rect, note.midiNote);
    }

    canvas.drawLine(
      Offset(0, size.height - 1.5),
      Offset(size.width, size.height - 1.5),
      Paint()
        ..color = const Color(0xFF7DE3FF)
        ..strokeWidth = 3,
    );
  }

  void _drawNoteLabel(Canvas canvas, Rect rect, int midiNote) {
    final label = _noteName(midiNote);
    const double horizontalPadding = 2;
    const double verticalPadding = 2;
    final availableWidth = rect.width - horizontalPadding * 2;
    final availableHeight = rect.height - verticalPadding * 2;

    if (availableWidth <= 0 || availableHeight <= 0) {
      return;
    }

    TextPainter buildPainter(double fontSize) {
      return TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            shadows: const [
              Shadow(
                color: Color(0xB3000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
    }

    TextPainter painter = buildPainter(8);
    if (painter.width > availableWidth || painter.height > availableHeight) {
      final widthScale = availableWidth / painter.width;
      final heightScale = availableHeight / painter.height;
      final fittedFontSize = 8.0 * math.min(widthScale, heightScale);
      painter = buildPainter(fittedFontSize);
    }

    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  String _noteName(int midiNote) {
    const pitchNames = <String>[
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
    final octave = (midiNote ~/ 12) - 1;
    return '${pitchNames[midiNote % 12]}$octave';
  }

  void _drawLaneGuides(
    Canvas canvas,
    Size size,
    SynthesiaPianoGeometry geometry,
  ) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (var index = 1; index < geometry.whiteMidis.length; index++) {
      final x = index * geometry.whiteKeyWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SynthesiaFallingNotesPainter oldDelegate) {
    return oldDelegate.timeline != timeline ||
        oldDelegate.range.firstMidi != range.firstMidi ||
        oldDelegate.range.lastMidi != range.lastMidi ||
        oldDelegate.results != results ||
        oldDelegate.waitPreviewOriginStartMicroseconds !=
            waitPreviewOriginStartMicroseconds ||
        oldDelegate.waitHoldProgress != waitHoldProgress ||
        oldDelegate.waitPreviewAdvanceMicroseconds !=
            waitPreviewAdvanceMicroseconds ||
        oldDelegate.hiddenGroupStartMicroseconds !=
            hiddenGroupStartMicroseconds ||
        oldDelegate.hiddenWaitOccurrences != hiddenWaitOccurrences;
  }
}
