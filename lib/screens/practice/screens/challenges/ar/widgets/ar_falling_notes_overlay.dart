import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../piano_calibration/models/keyboard_area_corners.dart';
import '../../../../../piano_calibration/models/piano_key_marker.dart';
import '../models/ar_note_event.dart';
import '../models/ar_score_timeline.dart';
import '../services/ar_practice_performance_tracker.dart';
import '../utils/midi_note_utils.dart';

/// Non-interactive canvas that draws score notes falling toward calibrated keys.
class ArFallingNotesOverlay extends StatelessWidget {
  const ArFallingNotesOverlay({
    super.key,
    required this.corners,
    required this.pianoKeyMarkers,
    required this.timeline,
    required this.animation,
    required this.approachDuration,
    required this.noteResultsByStartMicroseconds,
  });

  /// Playable-area geometry used to place the perspective-aware hit line.
  final KeyboardAreaCorners corners;
  /// Key targets used to map each MIDI pitch to a horizontal screen position.
  final List<PianoKeyMarker> pianoKeyMarkers;
  /// Notes and durations to render.
  final ArScoreTimeline timeline;
  /// Normalized progress through lead-in plus score duration.
  final Animation<double> animation;
  /// Time each note spends traveling from the screen top to the hit line.
  final Duration approachDuration;
  /// Evaluation colors keyed by simultaneous note-group start time.
  final Map<int, ArPracticeNoteResult> noteResultsByStartMicroseconds;

  @override
  /// Creates a repainting custom painter while allowing touches to pass through.
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ArFallingNotesPainter(
          corners: corners,
          pianoKeyMarkers: pianoKeyMarkers,
          timeline: timeline,
          animation: animation,
          approachDuration: approachDuration,
          noteResultsByStartMicroseconds: noteResultsByStartMicroseconds,
        ),
      ),
    );
  }
}

/// Draws visible note segments, labels, and short-lived result feedback.
class ArFallingNotesPainter extends CustomPainter {
  ArFallingNotesPainter({
    required this.corners,
    required this.pianoKeyMarkers,
    required this.timeline,
    required this.animation,
    required this.approachDuration,
    required this.noteResultsByStartMicroseconds,
  }) : super(repaint: animation) {
    for (PianoKeyMarker marker in pianoKeyMarkers) {
      int? midiNote = MidiNoteUtils.fromPianoKeyMarker(marker);

      if (midiNote != null) {
        markersByMidiNote[midiNote] = marker;
      }
    }
  }

  final KeyboardAreaCorners corners;
  final List<PianoKeyMarker> pianoKeyMarkers;
  final ArScoreTimeline timeline;
  final Animation<double> animation;
  final Duration approachDuration;
  final Map<int, ArPracticeNoteResult> noteResultsByStartMicroseconds;

  final Map<int, PianoKeyMarker> markersByMidiNote = {};

  final double hitLineInsetFraction = 0.08;

  @override
  /// Maps animation time and MIDI pitches into visible falling-note rectangles.
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        approachDuration.inMicroseconds <= 0) {
      return;
    }

    double horizontalScale = size.width / corners.sourceImageWidth;

    double verticalScale = size.height / corners.sourceImageHeight;

    Offset displayedTopLeft = scalePoint(
      corners.topLeft,
      horizontalScale,
      verticalScale,
    );

    Offset displayedTopRight = scalePoint(
      corners.topRight,
      horizontalScale,
      verticalScale,
    );

    Offset displayedBottomLeft = scalePoint(
      corners.bottomLeft,
      horizontalScale,
      verticalScale,
    );

    Offset displayedBottomRight = scalePoint(
      corners.bottomRight,
      horizontalScale,
      verticalScale,
    );

    Offset leftHitPoint = Offset.lerp(
      displayedBottomLeft,
      displayedTopLeft,
      hitLineInsetFraction,
    )!;

    Offset rightHitPoint = Offset.lerp(
      displayedBottomRight,
      displayedTopRight,
      hitLineInsetFraction,
    )!;

    int totalAnimationMicroseconds =
        approachDuration.inMicroseconds + timeline.totalDuration.inMicroseconds;

    int animationMicroseconds = (animation.value * totalAnimationMicroseconds)
        .round();

    int playbackMicroseconds =
        animationMicroseconds - approachDuration.inMicroseconds;

    double whiteKeySpacing = calculateWhiteKeySpacing(horizontalScale);

    for (ArNoteEvent noteEvent in timeline.noteEvents) {
      PianoKeyMarker? marker = markersByMidiNote[noteEvent.midiNote];

      // The note is outside the range covered by this calibration.
      if (marker == null) {
        continue;
      }

      drawFallingNote(
        canvas: canvas,
        marker: marker,
        noteEvent: noteEvent,
        playbackMicroseconds: playbackMicroseconds,
        approachMicroseconds: approachDuration.inMicroseconds,
        horizontalScale: horizontalScale,
        leftHitPoint: leftHitPoint,
        rightHitPoint: rightHitPoint,
        whiteKeySpacing: whiteKeySpacing,
        noteResult:
            noteResultsByStartMicroseconds[noteEvent.startTime.inMicroseconds],
      );
    }
  }

  /// Draws one clipped note block at its calibrated key and current score time.
  ///
  /// Once a short note passes the line, a small result block remains briefly so
  /// red/yellow/green feedback is still visible to the player.
  void drawFallingNote({
    required Canvas canvas,
    required PianoKeyMarker marker,
    required ArNoteEvent noteEvent,
    required int playbackMicroseconds,
    required int approachMicroseconds,
    required double horizontalScale,
    required Offset leftHitPoint,
    required Offset rightHitPoint,
    required double whiteKeySpacing,
    required ArPracticeNoteResult? noteResult,
  }) {
    double displayedX = marker.position.dx * horizontalScale;

    double lineFraction;

    if ((rightHitPoint.dx - leftHitPoint.dx).abs() < 0.001) {
      lineFraction = 0.5;
    } else {
      lineFraction =
          (displayedX - leftHitPoint.dx) / (rightHitPoint.dx - leftHitPoint.dx);

      lineFraction = lineFraction.clamp(0.0, 1.0);
    }

    double hitLineY =
        leftHitPoint.dy + ((rightHitPoint.dy - leftHitPoint.dy) * lineFraction);

    double fallingAreaTop = 0;
    double fallingDistance = hitLineY - fallingAreaTop;

    if (fallingDistance <= 0) {
      return;
    }

    int timeUntilHit =
        noteEvent.startTime.inMicroseconds - playbackMicroseconds;

    double progress = 1 - (timeUntilHit / approachMicroseconds);

    double noteBottom = fallingAreaTop + (fallingDistance * progress);

    double noteHeight = math.max(
      18,
      fallingDistance *
          noteEvent.duration.inMicroseconds /
          approachMicroseconds,
    );

    double noteTop = noteBottom - noteHeight;

    // Clip each note at the top of the screen and at the timing line.
    double visibleTop = math.max(fallingAreaTop, noteTop);
    double visibleBottom = math.min(hitLineY, noteBottom);

    if (visibleBottom <= visibleTop) {
      int elapsedSinceHit =
          playbackMicroseconds - noteEvent.startTime.inMicroseconds;
      const int feedbackDurationMicroseconds = 650000;

      if (noteResult == null ||
          elapsedSinceHit < 0 ||
          elapsedSinceHit > feedbackDurationMicroseconds) {
        return;
      }

      visibleBottom = hitLineY;
      visibleTop = math.max(fallingAreaTop, hitLineY - math.max(28, noteHeight));
    }

    double noteWidth = marker.isBlackKey
        ? whiteKeySpacing * 0.42
        : whiteKeySpacing * 0.68;

    noteWidth = noteWidth.clamp(10.0, 48.0);

    Rect noteRectangle = Rect.fromLTRB(
      displayedX - (noteWidth / 2),
      visibleTop,
      displayedX + (noteWidth / 2),
      visibleBottom,
    );

    RRect roundedNote = RRect.fromRectAndRadius(
      noteRectangle,
      Radius.circular(math.min(8, noteWidth / 3)),
    );

    Color noteColor = switch (noteResult) {
      ArPracticeNoteResult.correct => const Color(0xFF43A047),
      ArPracticeNoteResult.timingMistake => const Color(0xFFFFC107),
      ArPracticeNoteResult.incorrect => const Color(0xFFE53935),
      null => marker.isBlackKey
          ? const Color(0xFFFF4081)
          : const Color(0xFF448AFF),
    };

    Paint glowPaint = Paint()
      ..color = noteColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    Paint fillPaint = Paint()
      ..color = noteColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    Paint outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(roundedNote, glowPaint);
    canvas.drawRRect(roundedNote, fillPaint);
    canvas.drawRRect(roundedNote, outlinePaint);

    if (noteRectangle.height >= 10) {
      drawNoteLabel(
        canvas: canvas,
        rectangle: noteRectangle,
        midiNote: noteEvent.midiNote,
      );
    }
  }

  /// Draws a centered compact pitch label or a bottom-aligned normal label.
  void drawNoteLabel({
    required Canvas canvas,
    required Rect rectangle,
    required int midiNote,
  }) {
    bool usesCompactLabel = rectangle.height < 30;

    double fontSize = usesCompactLabel
        ? (rectangle.height * 0.5).clamp(6.0, 9.0)
        : 11;

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: MidiNoteUtils.nameForMidiNote(midiNote),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    textPainter.layout(maxWidth: rectangle.width);

    Offset textPosition = Offset(
      rectangle.center.dx - (textPainter.width / 2),
      usesCompactLabel
          ? rectangle.center.dy - (textPainter.height / 2)
          : rectangle.bottom - textPainter.height - 5,
    );

    textPainter.paint(canvas, textPosition);
  }

  /// Estimates visual key spacing used to size both white and black note blocks.
  double calculateWhiteKeySpacing(double horizontalScale) {
    List<double> whiteKeyPositions = [
      for (PianoKeyMarker marker in pianoKeyMarkers)
        if (!marker.isBlackKey) marker.position.dx * horizontalScale,
    ]..sort();

    if (whiteKeyPositions.length < 2) {
      return 40;
    }

    double totalSpacing = 0;

    for (int index = 1; index < whiteKeyPositions.length; index++) {
      totalSpacing += whiteKeyPositions[index] - whiteKeyPositions[index - 1];
    }

    return totalSpacing / (whiteKeyPositions.length - 1);
  }

  /// Scales a source-image calibration point into the current canvas size.
  Offset scalePoint(
    Offset sourcePoint,
    double horizontalScale,
    double verticalScale,
  ) {
    return Offset(
      sourcePoint.dx * horizontalScale,
      sourcePoint.dy * verticalScale,
    );
  }

  @override
  /// Repaints when geometry, score, approach timing, or feedback results change.
  bool shouldRepaint(ArFallingNotesPainter oldPainter) {
    return oldPainter.corners != corners ||
        oldPainter.pianoKeyMarkers != pianoKeyMarkers ||
        oldPainter.timeline != timeline ||
        oldPainter.approachDuration != approachDuration ||
        oldPainter.noteResultsByStartMicroseconds !=
            noteResultsByStartMicroseconds;
  }
}
