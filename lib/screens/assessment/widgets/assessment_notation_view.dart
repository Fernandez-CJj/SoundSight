import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/assessment_notation_question.dart';

/// Displays the musical notation required by one assessment question.
class AssessmentNotationView extends StatelessWidget {
  const AssessmentNotationView({super.key, required this.question});

  /// Supplies the clef, note positions, rhythm, and other notation data.
  final AssessmentNotationQuestion question;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      // The accessibility label identifies the visual without revealing its
      // correct answer.
      label: 'Music notation for the current assessment question',
      image: true,
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: CustomPaint(
          painter: _AssessmentNotationPainter(
            question: question,
            notationColor: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Draws assessment notation directly on Flutter's canvas.
class _AssessmentNotationPainter extends CustomPainter {
  const _AssessmentNotationPainter({
    required this.question,
    required this.notationColor,
  });

  final AssessmentNotationQuestion question;
  final Color notationColor;

  static const double _staffTop = 50;
  static const double _lineSpacing = 16;
  static const double _staffBottom = _staffTop + (_lineSpacing * 4);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = notationColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    switch (question.type) {
      case AssessmentNotationQuestionType.rhythmValue:
        _drawStandaloneRhythm(canvas, size, paint);
        return;

      case AssessmentNotationQuestionType.timeSignature:
        _drawStaff(canvas, size, paint);
        _drawTimeSignature(canvas, size.width / 2, paint);
        return;

      case AssessmentNotationQuestionType.keySignature:
        _drawStaff(canvas, size, paint);
        _drawClef(canvas, question.clef, paint);
        _drawKeySignature(canvas, question.keySignature, question.clef, paint);
        return;

      case AssessmentNotationQuestionType.noteIdentification:
        _drawStaffQuestion(canvas, size, paint);
        return;

      case AssessmentNotationQuestionType.interval:
        _drawStaffQuestion(canvas, size, paint);
        return;

      case AssessmentNotationQuestionType.chord:
        _drawStaffQuestion(canvas, size, paint);
        return;

      case AssessmentNotationQuestionType.shortPassage:
        _drawShortPassage(canvas, size, paint);
        return;
    }
  }

  /// Draws the five horizontal staff lines.
  void _drawStaff(Canvas canvas, Size size, Paint paint) {
    const left = 16.0;
    final right = size.width - 16;

    for (var lineIndex = 0; lineIndex < 5; lineIndex++) {
      final y = _staffTop + (lineIndex * _lineSpacing);
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  /// Draws the clef supplied by the question.
  void _drawClef(Canvas canvas, AssessmentNotationClef? clef, Paint paint) {
    final symbol = clef == AssessmentNotationClef.bass ? '𝄢' : '𝄞';
    final fontSize = clef == AssessmentNotationClef.bass ? 48.0 : 58.0;
    final top = clef == AssessmentNotationClef.bass ? 48.0 : 27.0;

    _drawText(
      canvas: canvas,
      text: symbol,
      position: Offset(25, top),
      fontSize: fontSize,
      color: paint.color,
    );
  }

  /// Draws a single note, interval, or chord on a staff.
  void _drawStaffQuestion(Canvas canvas, Size size, Paint paint) {
    _drawStaff(canvas, size, paint);
    _drawClef(canvas, question.clef, paint);

    final noteX = size.width * 0.64;

    for (var index = 0; index < question.staffSteps.length; index++) {
      final staffStep = question.staffSteps[index];

      _drawLedgerLines(
        canvas: canvas,
        noteX: noteX,
        staffStep: staffStep,
        paint: paint,
      );

      _drawNote(
        canvas: canvas,
        center: Offset(noteX, _yForStaffStep(staffStep)),
        rhythmValue: AssessmentRhythmValue.quarter,
        paint: paint,
      );
    }

    if (question.accidental != AssessmentNotationAccidental.none &&
        question.staffSteps.isNotEmpty) {
      _drawAccidental(
        canvas: canvas,
        accidental: question.accidental,
        position: Offset(
          noteX - 30,
          _yForStaffStep(question.staffSteps.first) - 16,
        ),
        paint: paint,
      );
    }
  }

  /// Draws a rhythm symbol without a staff for beat-value questions.
  void _drawStandaloneRhythm(Canvas canvas, Size size, Paint paint) {
    final rhythmValue = question.rhythmValues.isEmpty
        ? AssessmentRhythmValue.quarter
        : question.rhythmValues.first;

    _drawNote(
      canvas: canvas,
      center: Offset(size.width / 2, 112),
      rhythmValue: rhythmValue,
      paint: paint,
      scale: 1.7,
    );
  }

  /// Draws a complete short passage with its time signature.
  void _drawShortPassage(Canvas canvas, Size size, Paint paint) {
    _drawStaff(canvas, size, paint);
    _drawClef(canvas, question.clef, paint);
    _drawTimeSignature(canvas, 92, paint);

    if (question.staffSteps.isEmpty) {
      return;
    }

    const firstNoteX = 145.0;
    final availableWidth = math.max(0.0, size.width - firstNoteX - 30);
    final gap = question.staffSteps.length == 1
        ? 0.0
        : availableWidth / (question.staffSteps.length - 1);

    for (var index = 0; index < question.staffSteps.length; index++) {
      final staffStep = question.staffSteps[index];
      final noteX = firstNoteX + (gap * index);
      final rhythmValue = index < question.rhythmValues.length
          ? question.rhythmValues[index]
          : AssessmentRhythmValue.quarter;

      _drawLedgerLines(
        canvas: canvas,
        noteX: noteX,
        staffStep: staffStep,
        paint: paint,
      );

      _drawNote(
        canvas: canvas,
        center: Offset(noteX, _yForStaffStep(staffStep)),
        rhythmValue: rhythmValue,
        paint: paint,
      );
    }

    // Close the displayed measure with a final bar line.
    canvas.drawLine(
      Offset(size.width - 17, _staffTop),
      Offset(size.width - 17, _staffBottom),
      paint,
    );
  }

  /// Draws the upper and lower numbers of a time signature.
  void _drawTimeSignature(Canvas canvas, double centerX, Paint paint) {
    final topNumber = question.timeSignatureTop;
    final bottomNumber = question.timeSignatureBottom;

    if (topNumber == null || bottomNumber == null) {
      return;
    }

    _drawCenteredText(
      canvas: canvas,
      text: topNumber.toString(),
      center: Offset(centerX, _staffTop + 15),
      fontSize: 30,
      color: paint.color,
      fontWeight: FontWeight.w600,
    );

    _drawCenteredText(
      canvas: canvas,
      text: bottomNumber.toString(),
      center: Offset(centerX, _staffTop + 49),
      fontSize: 30,
      color: paint.color,
      fontWeight: FontWeight.w600,
    );
  }

  /// Draws the sharps or flats belonging to a supported key signature.
  void _drawKeySignature(
    Canvas canvas,
    AssessmentKeySignature? keySignature,
    AssessmentNotationClef? clef,
    Paint paint,
  ) {
    if (keySignature == null || keySignature == AssessmentKeySignature.cMajor) {
      return;
    }

    final symbols = <({String symbol, int staffStep})>[];

    switch (keySignature) {
      case AssessmentKeySignature.cMajor:
        return;

      case AssessmentKeySignature.gMajor:
        symbols.add((
          symbol: '♯',
          staffStep: clef == AssessmentNotationClef.bass ? 6 : 8,
        ));
        break;

      case AssessmentKeySignature.dMajor:
        symbols.addAll([
          (symbol: '♯', staffStep: clef == AssessmentNotationClef.bass ? 6 : 8),
          (symbol: '♯', staffStep: clef == AssessmentNotationClef.bass ? 3 : 5),
        ]);
        break;

      case AssessmentKeySignature.fMajor:
        symbols.add((
          symbol: '♭',
          staffStep: clef == AssessmentNotationClef.bass ? 2 : 4,
        ));
        break;
    }

    for (var index = 0; index < symbols.length; index++) {
      final item = symbols[index];

      _drawText(
        canvas: canvas,
        text: item.symbol,
        position: Offset(
          82 + (index * 20),
          _yForStaffStep(item.staffStep) - 18,
        ),
        fontSize: 28,
        color: paint.color,
      );
    }
  }

  /// Draws one notehead, its stem, flag, and optional rhythm dot.
  void _drawNote({
    required Canvas canvas,
    required Offset center,
    required AssessmentRhythmValue rhythmValue,
    required Paint paint,
    double scale = 1,
  }) {
    final noteWidth = 15 * scale;
    final noteHeight = 10 * scale;
    final isHollow =
        rhythmValue == AssessmentRhythmValue.whole ||
        rhythmValue == AssessmentRhythmValue.half;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.22);

    final noteRect = Rect.fromCenter(
      center: Offset.zero,
      width: noteWidth,
      height: noteHeight,
    );

    if (isHollow) {
      canvas.drawOval(
        noteRect,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale,
      );
    } else {
      canvas.drawOval(
        noteRect,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();

    if (rhythmValue != AssessmentRhythmValue.whole) {
      final stemX = center.dx + (noteWidth / 2) - 1;
      final stemTop = center.dy - (36 * scale);

      canvas.drawLine(
        Offset(stemX, center.dy),
        Offset(stemX, stemTop),
        paint..strokeWidth = 1.8 * scale,
      );

      if (rhythmValue == AssessmentRhythmValue.eighth) {
        final flagPath = Path()
          ..moveTo(stemX, stemTop)
          ..quadraticBezierTo(
            stemX + (15 * scale),
            stemTop + (9 * scale),
            stemX + (9 * scale),
            stemTop + (22 * scale),
          );

        canvas.drawPath(
          flagPath,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * scale,
        );
      }
    }

    if (rhythmValue == AssessmentRhythmValue.dottedQuarter) {
      canvas.drawCircle(
        Offset(center.dx + (14 * scale), center.dy),
        2.2 * scale,
        Paint()..color = paint.color,
      );
    }

    // Restore the shared paint settings after drawing scaled stems or flags.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
  }

  /// Draws ledger lines required by notes outside the five-line staff.
  void _drawLedgerLines({
    required Canvas canvas,
    required double noteX,
    required int staffStep,
    required Paint paint,
  }) {
    if (staffStep <= -2) {
      for (var step = -2; step >= staffStep; step -= 2) {
        final y = _yForStaffStep(step);
        canvas.drawLine(Offset(noteX - 13, y), Offset(noteX + 13, y), paint);
      }
    }

    if (staffStep >= 10) {
      for (var step = 10; step <= staffStep; step += 2) {
        final y = _yForStaffStep(step);
        canvas.drawLine(Offset(noteX - 13, y), Offset(noteX + 13, y), paint);
      }
    }
  }

  /// Draws a sharp, flat, or natural beside a note.
  void _drawAccidental({
    required Canvas canvas,
    required AssessmentNotationAccidental accidental,
    required Offset position,
    required Paint paint,
  }) {
    final symbol = switch (accidental) {
      AssessmentNotationAccidental.sharp => '♯',
      AssessmentNotationAccidental.flat => '♭',
      AssessmentNotationAccidental.natural => '♮',
      AssessmentNotationAccidental.none => '',
    };

    _drawText(
      canvas: canvas,
      text: symbol,
      position: position,
      fontSize: 28,
      color: paint.color,
    );
  }

  /// Converts a staff step into a vertical canvas coordinate.
  double _yForStaffStep(int staffStep) {
    return _staffBottom - (staffStep * (_lineSpacing / 2));
  }

  /// Draws text using its upper-left corner as the position.
  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset position,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, position);
  }

  /// Draws text centered on the provided point.
  void _drawCenteredText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AssessmentNotationPainter oldDelegate) {
    return oldDelegate.question.id != question.id ||
        oldDelegate.notationColor != notationColor;
  }
}
