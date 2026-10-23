import 'package:flutter/material.dart';

import 'synthesia_piano_geometry.dart';

class SynthesiaKeyboard extends StatelessWidget {
  const SynthesiaKeyboard({
    super.key,
    required this.range,
    required this.activeMidiNotes,
    this.expectedMidiNotes = const <int>{},
  });

  final SynthesiaPianoRange range;
  final Set<int> activeMidiNotes;
  final Set<int> expectedMidiNotes;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _SynthesiaKeyboardPainter(
              range: range,
              activeMidiNotes: activeMidiNotes,
              expectedMidiNotes: expectedMidiNotes,
            ),
            isComplex: true,
          ),
        ),
      ),
    );
  }
}

class _SynthesiaKeyboardPainter extends CustomPainter {
  const _SynthesiaKeyboardPainter({
    required this.range,
    required this.activeMidiNotes,
    required this.expectedMidiNotes,
  });

  final SynthesiaPianoRange range;
  final Set<int> activeMidiNotes;
  final Set<int> expectedMidiNotes;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = SynthesiaPianoGeometry(size: size, range: range);
    final whitePaint = Paint()..color = const Color(0xFFF5F7FA);
    final whiteActivePaint = Paint()..color = const Color(0xFF54D4FF);
    final whiteExpectedPaint = Paint()..color = const Color(0xFFFFD166);
    final blackPaint = Paint()..color = const Color(0xFF11151C);
    final blackActivePaint = Paint()..color = const Color(0xFF1AA8E8);
    final blackExpectedPaint = Paint()..color = const Color(0xFFE6A817);
    final borderPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final midi in geometry.whiteMidis) {
      final rect = geometry.keyRect(midi);
      canvas.drawRect(
        rect,
        activeMidiNotes.contains(midi)
            ? whiteActivePaint
            : expectedMidiNotes.contains(midi)
            ? whiteExpectedPaint
            : whitePaint,
      );
      canvas.drawRect(rect, borderPaint);
      if (midi % 12 == 0 && geometry.whiteKeyWidth >= 11) {
        _drawLabel(canvas, rect, midi);
      }
    }

    for (var midi = range.firstMidi; midi <= range.lastMidi; midi++) {
      if (!SynthesiaPianoGeometry.isBlackMidi(midi)) continue;
      final rect = geometry.keyRect(midi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        activeMidiNotes.contains(midi)
            ? blackActivePaint
            : expectedMidiNotes.contains(midi)
            ? blackExpectedPaint
            : blackPaint,
      );
    }

    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      Paint()
        ..color = const Color(0xFF64D8FF)
        ..strokeWidth = 3,
    );
  }

  void _drawLabel(Canvas canvas, Rect rect, int midi) {
    final octave = (midi ~/ 12) - 1;
    final painter = TextPainter(
      text: TextSpan(
        text: 'C$octave',
        style: const TextStyle(
          color: Color(0xFF4B5563),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.bottom - painter.height - 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SynthesiaKeyboardPainter oldDelegate) {
    return oldDelegate.range.firstMidi != range.firstMidi ||
        oldDelegate.range.lastMidi != range.lastMidi ||
        oldDelegate.activeMidiNotes != activeMidiNotes ||
        oldDelegate.expectedMidiNotes != expectedMidiNotes;
  }
}
