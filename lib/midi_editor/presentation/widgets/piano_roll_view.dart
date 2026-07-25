import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/editor_note.dart';
import '../controllers/midi_editor_controller.dart';
import 'piano_key_geometry.dart';

class PianoRollView extends StatefulWidget {
  const PianoRollView({super.key, required this.controller});

  final MidiEditorController controller;

  @override
  State<PianoRollView> createState() => _PianoRollViewState();
}

class _PianoRollViewState extends State<PianoRollView> {
  static const double baseBeatWidth = 88;
  static const double baseRowHeight = 18;
  static const double portraitKeyboardExtent = 96;

  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  _DragMode _dragMode = _DragMode.none;
  Offset? _lastDragLocal;
  int _seekOriginTick = 0;
  double _pitchOffset = 0;
  Size? _rollViewport;

  double _rowHeight = baseRowHeight;
  double get _pixelsPerTick =>
      baseBeatWidth * widget.controller.horizontalZoom / widget.controller.ticksPerQuarter;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _horizontal.addListener(_sync);
    _vertical.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant PianoRollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  void _sync() {
    final selectedId = widget.controller.selectedId;
    final viewport = _rollViewport;
    if (selectedId != null && viewport != null) {
      final note = widget.controller.noteById(selectedId);
      if (note == null || !_fallingRect(note, viewport.height).translate(-_pitchOffset, 0).overlaps(Offset.zero & viewport)) {
        widget.controller.selectNote(null);
        return;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final landscape = constraints.maxWidth > constraints.maxHeight;
      final visibleWhiteKeys = max(7, PianoKeyGeometry.whiteKeyCount - widget.controller.keyboardZoom * 7);
      _rowHeight = landscape
          ? max(baseRowHeight * widget.controller.verticalZoom, constraints.maxWidth / visibleWhiteKeys * widget.controller.verticalZoom)
          : baseRowHeight * widget.controller.verticalZoom;
      _pitchOffset = _pitchOffset.clamp(0.0, max(0, PianoKeyGeometry.whiteKeyCount * _rowHeight - constraints.maxWidth));
      final keyboardExtent = landscape
          ? min(112.0, constraints.maxHeight * .30)
          : portraitKeyboardExtent;
      final contentWidth = landscape
          ? max(constraints.maxWidth, PianoKeyGeometry.whiteKeyCount * _rowHeight)
          : max(constraints.maxWidth - keyboardExtent, widget.controller.lastTick * _pixelsPerTick + 360);
      final contentHeight = landscape
          ? max(constraints.maxHeight - keyboardExtent, widget.controller.lastTick * _pixelsPerTick + 360)
          : PianoKeyGeometry.whiteKeyCount * _rowHeight;
      final contentSize = Size(contentWidth, contentHeight);

      return ColoredBox(
        color: const Color(0xFF15181B),
        child: landscape
            ? _buildLandscape(context, constraints.biggest, contentSize, keyboardExtent)
            : _buildPortrait(context, constraints.biggest, contentSize, keyboardExtent),
      );
    });
  }

  Widget _buildPortrait(BuildContext context, Size viewport, Size contentSize, double keyboardExtent) {
    return Row(
      children: [
        SizedBox(
          width: keyboardExtent,
          child: RepaintBoundary(
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _KeyboardPainter(
                  rowHeight: _rowHeight,
                  landscape: false,
                  scrollOffset: _vertical.hasClients ? _vertical.offset : 0,
                  activePitches: widget.controller.soundingPitches,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _scrollableRoll(viewport, contentSize, false)),
      ],
    );
  }

  Widget _buildLandscape(BuildContext context, Size viewport, Size contentSize, double keyboardExtent) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _rollViewport = constraints.biggest;
              return ClipRect(
              child: RepaintBoundary(
                child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _selectFallingNote(details.localPosition, constraints.maxHeight),
                onDoubleTapDown: (details) => _deleteFallingNote(details.localPosition, constraints.maxHeight),
                onPanStart: (details) => _beginFallingDrag(details.localPosition, constraints.maxHeight),
                onPanUpdate: (details) => _updateFallingDrag(details, constraints.biggest),
                onPanEnd: (_) {
                  widget.controller.endSelectedEdit();
                  _dragMode = _DragMode.none;
                  _lastDragLocal = null;
                },
                  child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _PianoRollPainter(
                    notes: widget.controller.activeNotes,
                    selectedId: widget.controller.selectedId,
                    ticksPerQuarter: widget.controller.ticksPerQuarter,
                    playheadTick: widget.controller.playheadTick,
                    pixelsPerTick: _pixelsPerTick,
                    rowHeight: _rowHeight,
                    horizontalOffset: 0,
                    pitchOffset: _pitchOffset,
                    verticalOffset: 0,
                    viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
                    landscape: true,
                    falling: true,
                  ),
                  ),
                ),
              ),
              );
            },
          ),
        ),
        SizedBox(
          height: keyboardExtent,
          width: viewport.width,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              final nextOffset = (_pitchOffset - details.delta.dx).clamp(0.0, _maxPitchOffset(viewport.width));
              if (nextOffset != _pitchOffset) {
                setState(() => _pitchOffset = nextOffset);
              }
            },
            child: RepaintBoundary(
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: _KeyboardPainter(
                    rowHeight: _rowHeight,
                    landscape: true,
                    scrollOffset: _pitchOffset,
                    activePitches: widget.controller.soundingPitches,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scrollableRoll(Size viewport, Size contentSize, bool landscape) {
    return Scrollbar(
      controller: _vertical,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          controller: _vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontal,
            child: RepaintBoundary(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleTap(details.localPosition, landscape),
                onDoubleTapDown: (details) => _handleDoubleTap(details.localPosition, landscape),
                onPanStart: (details) => _handlePanStart(details.localPosition, landscape),
                onPanUpdate: (details) => _handlePanUpdate(details, landscape),
                onPanEnd: (_) {
                  widget.controller.endSelectedEdit();
                  _dragMode = _DragMode.none;
                  _lastDragLocal = null;
                },
                child: CustomPaint(
                  size: contentSize,
                  painter: _PianoRollPainter(
                    notes: widget.controller.activeNotes,
                    selectedId: widget.controller.selectedId,
                    ticksPerQuarter: widget.controller.ticksPerQuarter,
                    playheadTick: widget.controller.playheadTick,
                    pixelsPerTick: _pixelsPerTick,
                    rowHeight: _rowHeight,
                    horizontalOffset: _horizontal.hasClients ? _horizontal.offset : 0,
                    pitchOffset: 0,
                    verticalOffset: _vertical.hasClients ? _vertical.offset : 0,
                    viewportSize: viewport,
                    landscape: landscape,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position, bool landscape) {
    widget.controller.selectAt(
      x: position.dx,
      y: position.dy,
      pixelsPerTick: _pixelsPerTick,
      rowHeight: _rowHeight,
      landscape: landscape,
    );
    if (widget.controller.selectedId == null) {
      final tick = landscape ? position.dy / _pixelsPerTick : position.dx / _pixelsPerTick;
      widget.controller.seekToTick(tick.round());
    }
  }

  void _handleDoubleTap(Offset position, bool landscape) {
    widget.controller.deleteAt(
      x: position.dx,
      y: position.dy,
      pixelsPerTick: _pixelsPerTick,
      rowHeight: _rowHeight,
      landscape: landscape,
    );
  }

  Rect _fallingRect(EditorNote note, double rollHeight) => Rect.fromLTWH(
        PianoKeyGeometry.keyStart(note.pitch, _rowHeight),
        rollHeight - (note.startTick - widget.controller.playheadTick) * _pixelsPerTick - note.durationTicks * _pixelsPerTick,
        PianoKeyGeometry.keyWidth(note.pitch, _rowHeight),
        max(6.0, note.durationTicks * _pixelsPerTick),
      );

  EditorNote? _fallingNoteAt(Offset position, double rollHeight) {
    for (final note in widget.controller.activeNotes.reversed) {
      if (_fallingRect(note, rollHeight).translate(-_pitchOffset, 0).inflate(6).contains(position)) {
        return note;
      }
    }
    return null;
  }

  void _selectFallingNote(Offset position, double rollHeight) {
    final note = _fallingNoteAt(position, rollHeight);
    if (note != null) {
      widget.controller.selectNote(note.id);
      return;
    }
    if (widget.controller.addNoteMode) {
      final startTick = widget.controller.playheadTick +
          ((rollHeight - position.dy) / _pixelsPerTick).round();
      widget.controller.addNoteAt(
        pitch: PianoKeyGeometry.pitchFromAxis(position.dx, _rowHeight),
        startTick: startTick,
      );
      return;
    }
    widget.controller.selectNote(null);
  }

  void _deleteFallingNote(Offset position, double rollHeight) {
    final note = _fallingNoteAt(position, rollHeight);
    if (note == null) {
      return;
    }
    widget.controller.selectNote(note.id);
    widget.controller.deleteSelected();
  }

  void _beginFallingDrag(Offset position, double rollHeight) {
    final selected = widget.controller.selectedId == null ? null : widget.controller.noteById(widget.controller.selectedId!);
    final note = selected ?? _fallingNoteAt(position, rollHeight);
    if (selected == null) {
      widget.controller.selectNote(note?.id);
    }
    _lastDragLocal = position;
    _dragMode = note == null && !widget.controller.isPlaying ? _DragMode.seek : note == null ? _DragMode.none : _DragMode.move;
    _seekOriginTick = widget.controller.playheadTick;
    if (note != null) {
      widget.controller.beginSelectedEdit();
    }
  }

  void _updateFallingDrag(DragUpdateDetails details, Size rollSize) {
    final origin = _lastDragLocal;
    if (origin == null) {
      return;
    }
    final current = details.localPosition;
    if (_dragMode == _DragMode.seek) {
      final tick = _seekOriginTick + ((current.dy - origin.dy) / _pixelsPerTick).round();
      widget.controller.seekToTick(tick);
      return;
    }
    if (_dragMode != _DragMode.move) {
      return;
    }
    final deltaTicks = (-(current.dy - origin.dy) / _pixelsPerTick).round();
    final deltaPitch = PianoKeyGeometry.pitchFromAxis(current.dx + _pitchOffset, _rowHeight) -
        PianoKeyGeometry.pitchFromAxis(origin.dx + _pitchOffset, _rowHeight);
    widget.controller.moveSelected(deltaTicks: deltaTicks, deltaPitch: deltaPitch);
  }

  double _maxPitchOffset(double viewportWidth) => max(0, PianoKeyGeometry.whiteKeyCount * _rowHeight - viewportWidth);

  void _handlePanStart(Offset position, bool landscape) {
    widget.controller.selectAt(
      x: position.dx,
      y: position.dy,
      pixelsPerTick: _pixelsPerTick,
      rowHeight: _rowHeight,
      landscape: landscape,
    );
    final selected = widget.controller.selectedId == null
        ? null
        : widget.controller.noteById(widget.controller.selectedId!);
    _lastDragLocal = position;
    _dragMode = selected != null &&
            widget.controller.isOnResizeHandle(
              note: selected,
              x: position.dx,
              y: position.dy,
              pixelsPerTick: _pixelsPerTick,
              rowHeight: _rowHeight,
              landscape: landscape,
            )
        ? _DragMode.resize
        : selected == null
            ? _DragMode.seek
            : _DragMode.move;
    if (_dragMode != _DragMode.seek) {
      widget.controller.beginSelectedEdit();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, bool landscape) {
    final last = _lastDragLocal;
    if (last == null) {
      return;
    }
    final current = details.localPosition;
    final origin = last;
    final delta = current - origin;

    if (_dragMode == _DragMode.seek) {
      final tick = landscape ? current.dy / _pixelsPerTick : current.dx / _pixelsPerTick;
      widget.controller.seekToTick(tick.round());
      return;
    }

    final deltaTicks = ((landscape ? delta.dy : delta.dx) / _pixelsPerTick).round();
    if (_dragMode == _DragMode.resize) {
      widget.controller.resizeSelected(deltaTicks);
      return;
    }

    final previousAxis = landscape ? origin.dx : origin.dy;
    final currentAxis = landscape ? current.dx : current.dy;
    final previousPitch = PianoKeyGeometry.pitchFromAxis(previousAxis, _rowHeight);
    final currentPitch = PianoKeyGeometry.pitchFromAxis(currentAxis, _rowHeight);
    final deltaPitch = currentPitch - previousPitch;
    widget.controller.moveSelected(deltaTicks: deltaTicks, deltaPitch: deltaPitch);
  }
}

enum _DragMode { none, seek, move, resize }

class _PianoRollPainter extends CustomPainter {
  _PianoRollPainter({
    required this.notes,
    required this.selectedId,
    required this.ticksPerQuarter,
    required this.playheadTick,
    required this.pixelsPerTick,
    required this.rowHeight,
    required this.horizontalOffset,
    required this.pitchOffset,
    required this.verticalOffset,
    required this.viewportSize,
    required this.landscape,
    this.falling = false,
  });

  final List<EditorNote> notes;
  final String? selectedId;
  final int ticksPerQuarter;
  final int playheadTick;
  final double pixelsPerTick;
  final double rowHeight;
  final double horizontalOffset;
  final double pitchOffset;
  final double verticalOffset;
  final Size viewportSize;
  final bool landscape;
  final bool falling;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.save();
    if (landscape) {
      canvas.translate(-pitchOffset, 0);
    }
    _paintGrid(canvas, size);
    _paintNotes(canvas);
    canvas.restore();
  }

  void _paintGrid(Canvas canvas, Size size) {
    final rowPaint = Paint()..strokeWidth = 1;
    final beatPaint = Paint()
      ..color = const Color(0xFF2D3338)
      ..strokeWidth = 1;
    final measurePaint = Paint()
      ..color = const Color(0xFF59626B)
      ..strokeWidth = 1.6;
    for (var pitch = MidiEditorController.lowPitch; pitch <= MidiEditorController.highPitch; pitch++) {
      final keyStart = PianoKeyGeometry.keyStart(pitch, rowHeight);
      rowPaint.color =
          PianoKeyGeometry.isBlackKey(pitch) ? const Color(0xFF1A1D20) : const Color(0xFF2D3033);
      if (landscape) {
        if (!PianoKeyGeometry.isBlackKey(pitch)) {
          final keyWidth = PianoKeyGeometry.keyWidth(pitch, rowHeight);
          canvas.drawRect(Rect.fromLTWH(keyStart, 0, keyWidth, size.height), rowPaint);
          canvas.drawLine(
            Offset(keyStart, 0),
            Offset(keyStart, size.height),
            Paint()..color = const Color(0xFF5A5F64),
          );
        }
      } else {
        if (!PianoKeyGeometry.isBlackKey(pitch)) {
          final keyWidth = PianoKeyGeometry.keyWidth(pitch, rowHeight);
          canvas.drawRect(Rect.fromLTWH(0, keyStart, size.width, keyWidth), rowPaint);
          canvas.drawLine(
            Offset(0, keyStart),
            Offset(size.width, keyStart),
            Paint()..color = const Color(0xFF5A5F64),
          );
        }
      }
    }

    _paintBlackKeyGuides(canvas, size);

    final beatWidth = ticksPerQuarter * pixelsPerTick;
    final maxAxis = landscape ? size.height : size.width;
    for (double value = 0; value <= maxAxis; value += beatWidth) {
      final paint = ((value / beatWidth).round() % 4 == 0) ? measurePaint : beatPaint;
      if (landscape) {
        canvas.drawLine(Offset(0, value), Offset(size.width, value), paint);
      } else {
        canvas.drawLine(Offset(value, 0), Offset(value, size.height), paint);
      }
    }
  }

  void _paintBlackKeyGuides(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    final centerLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var pitch = MidiEditorController.lowPitch; pitch <= MidiEditorController.highPitch; pitch++) {
      if (!PianoKeyGeometry.isBlackKey(pitch)) {
        continue;
      }
      final start = PianoKeyGeometry.keyStart(pitch, rowHeight);
      final width = PianoKeyGeometry.keyWidth(pitch, rowHeight);
      final center = PianoKeyGeometry.keyCenter(pitch, rowHeight);
      if (landscape) {
        canvas.drawRect(Rect.fromLTWH(start, 0, width, size.height), guide);
        canvas.drawLine(Offset(center, 0), Offset(center, size.height), centerLine);
      } else {
        canvas.drawRect(Rect.fromLTWH(0, start, size.width, width), guide);
        canvas.drawLine(Offset(0, center), Offset(size.width, center), centerLine);
      }
    }
  }

  void _paintNotes(Canvas canvas) {
    final visible = falling
        ? Rect.fromLTWH(pitchOffset, 0, viewportSize.width, viewportSize.height)
        : Rect.fromLTWH(
            horizontalOffset - 80,
            verticalOffset - 80,
            viewportSize.width + 160,
            viewportSize.height + 160,
          );

    for (final note in notes) {
      final rect = _rectFor(note);
      if (!rect.overlaps(visible)) {
        continue;
      }
      final selected = note.id == selectedId;
      final color = PianoKeyGeometry.isBlackKey(note.pitch)
          ? _darken(_trackColor(note.trackIndex), .14)
          : _trackColor(note.trackIndex);
      final rrect = RRect.fromRectAndRadius(rect.deflate(.5), const Radius.circular(1.5));
      final notePaint = Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [
            (selected ? const Color(0xFFFFE08A) : color).withValues(alpha: 0.98),
            (selected ? const Color(0xFFE9A826) : _darken(color, 0.22)).withValues(alpha: 0.98),
          ],
        );
      canvas.drawShadow(Path()..addRRect(rrect), Colors.black, 3, true);
      canvas.drawRRect(rrect, notePaint);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.4 : 1
          ..color = selected ? Colors.white : Colors.black.withValues(alpha: 0.5),
      );
      final handle = landscape
          ? Rect.fromLTWH(rect.left + 2, rect.bottom - 10, rect.width - 4, 6)
          : Rect.fromLTWH(rect.right - 10, rect.top + 2, 6, rect.height - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(handle, const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: selected ? 0.75 : 0.35),
      );
    }
  }

  Rect _rectFor(EditorNote note) {
    final keyStart = PianoKeyGeometry.keyStart(note.pitch, rowHeight);
    final keyWidth = PianoKeyGeometry.keyWidth(note.pitch, rowHeight);
    if (landscape) {
      final left = keyStart;
      if (falling) {
        final height = max(6.0, note.durationTicks * pixelsPerTick);
        final top = viewportSize.height -
            (note.startTick - playheadTick) * pixelsPerTick -
            height;
        return Rect.fromLTWH(left, top, keyWidth, height);
      }
      final top = note.startTick * pixelsPerTick;
      return Rect.fromLTWH(left, top, keyWidth - 2, max(6, note.durationTicks * pixelsPerTick));
    }
    final left = note.startTick * pixelsPerTick;
    final top = keyStart;
    return Rect.fromLTWH(left, top, max(6, note.durationTicks * pixelsPerTick), keyWidth - 2);
  }

  @override
  bool shouldRepaint(covariant _PianoRollPainter oldDelegate) {
    return notes != oldDelegate.notes ||
        selectedId != oldDelegate.selectedId ||
        playheadTick != oldDelegate.playheadTick ||
        pixelsPerTick != oldDelegate.pixelsPerTick ||
        rowHeight != oldDelegate.rowHeight ||
        horizontalOffset != oldDelegate.horizontalOffset ||
        pitchOffset != oldDelegate.pitchOffset ||
        verticalOffset != oldDelegate.verticalOffset ||
        landscape != oldDelegate.landscape ||
        falling != oldDelegate.falling;
  }
}

class _KeyboardPainter extends CustomPainter {
  const _KeyboardPainter({
    required this.rowHeight,
    required this.landscape,
    required this.scrollOffset,
    required this.activePitches,
  });

  final double rowHeight;
  final bool landscape;
  final double scrollOffset;
  final Set<int> activePitches;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    canvas.save();
    if (landscape) {
      canvas.translate(-scrollOffset, 0);
    } else {
      canvas.translate(0, -scrollOffset);
    }

    _paintWhiteKeyBodies(canvas, size);
    _paintBlackKeyBodies(canvas, size);
    _paintFeltLine(canvas, size);
    canvas.restore();
  }

  void _paintWhiteKeyBodies(Canvas canvas, Size size) {
    final whiteStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF141414);
    final separator = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF5E5B50).withValues(alpha: 0.55);
    final labelStyle = ui.TextStyle(
      color: const Color(0xFF9C9A8E).withValues(alpha: 0.7),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    for (var pitch = MidiEditorController.lowPitch; pitch <= MidiEditorController.highPitch; pitch++) {
      if (PianoKeyGeometry.isBlackKey(pitch)) {
        continue;
      }
      final start = PianoKeyGeometry.keyStart(pitch, rowHeight);
      final extent = PianoKeyGeometry.keyWidth(pitch, rowHeight);
      final rect = landscape
          ? Rect.fromLTWH(start, 0, extent, size.height)
          : Rect.fromLTWH(0, start, size.width, extent);

      final key = RRect.fromRectAndRadius(
        rect.deflate(0.35),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        key,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            landscape ? rect.bottomLeft : rect.topRight,
            const [
              Color(0xFFFFFCED),
              Color(0xFFF0EDDA),
              Color(0xFFFFFDF1),
            ],
            const [0, 0.76, 1],
          ),
      );
      canvas.drawRRect(key, whiteStroke);
      if (activePitches.contains(pitch)) {
        canvas.drawRRect(key, Paint()..color = const Color(0xFFFFE08A).withValues(alpha: .82));
      }

      if (landscape) {
        canvas.drawLine(Offset(rect.left, 0), Offset(rect.left, size.height), separator);
      } else {
        canvas.drawLine(Offset(0, rect.top), Offset(size.width, rect.top), separator);
      }

      {
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(labelStyle)
          ..addText(PianoKeyGeometry.keyLabel(pitch));
        final paragraph = builder.build()
          ..layout(ui.ParagraphConstraints(width: landscape ? rowHeight : size.width));
        final offset = landscape
            ? Offset(rect.left, max(4, size.height - paragraph.height - 10))
            : Offset(max(4, size.width - paragraph.maxIntrinsicWidth - 8), rect.top + max(2, (extent - paragraph.height) / 2));
        canvas.drawParagraph(paragraph, offset);
      }
    }
  }

  void _paintBlackKeyBodies(Canvas canvas, Size size) {
    final blackStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF030303);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var pitch = MidiEditorController.lowPitch; pitch <= MidiEditorController.highPitch; pitch++) {
      if (!PianoKeyGeometry.isBlackKey(pitch)) {
        continue;
      }
      final start = PianoKeyGeometry.keyStart(pitch, rowHeight);
      final extent = PianoKeyGeometry.keyWidth(pitch, rowHeight);
      final rect = landscape
          ? Rect.fromLTWH(start, 0, extent, size.height * PianoKeyGeometry.blackKeyLengthFactor)
          : Rect.fromLTWH(
              size.width * (1 - PianoKeyGeometry.blackKeyLengthFactor),
              start,
              size.width * PianoKeyGeometry.blackKeyLengthFactor,
              extent,
            );
      final key = RRect.fromRectAndRadius(rect, const Radius.circular(3));

      canvas.drawRRect(
        key.shift(landscape ? const Offset(1.5, 2) : const Offset(-2, 1.5)),
        shadow,
      );
      canvas.drawRRect(
        key,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            landscape ? rect.bottomLeft : rect.topRight,
            const [
              Color(0xFF26282B),
              Color(0xFF050506),
              Color(0xFF202226),
            ],
            const [0, 0.68, 1],
          ),
      );
      canvas.drawRRect(key, blackStroke);
      if (activePitches.contains(pitch)) {
        canvas.drawRRect(key, Paint()..color = const Color(0xFFFFE08A));
      }
      final shine = landscape
          ? Rect.fromLTWH(rect.left + rect.width * 0.18, 5, rect.width * 0.16, rect.height - 16)
          : Rect.fromLTWH(rect.left + 8, rect.top + rect.height * 0.18, rect.width - 18, rect.height * 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(shine, const Radius.circular(2)),
        Paint()..color = const Color(0xFF3F444A).withValues(alpha: 0.55),
      );
      final labelWidth = max(16.0, rect.width + 8);
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 1))
        ..pushStyle(ui.TextStyle(color: const Color(0xFFE5E5E5), fontSize: min(10, max(7, rect.width * .82)), fontWeight: FontWeight.w700))
        ..addText(PianoKeyGeometry.keyLabel(pitch));
      final paragraph = builder.build()..layout(ui.ParagraphConstraints(width: landscape ? labelWidth : rect.height));
      if (landscape) {
        canvas.drawParagraph(paragraph, Offset(rect.center.dx - labelWidth / 2, rect.bottom - paragraph.height - 6));
      }
    }
  }

  void _paintFeltLine(Canvas canvas, Size size) {
    final rect = landscape
        ? Rect.fromLTWH(0, 0, PianoKeyGeometry.whiteKeyCount * rowHeight, 4)
        : Rect.fromLTWH(size.width - 4, 0, 4, PianoKeyGeometry.whiteKeyCount * rowHeight);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF5B0B0B));
    canvas.drawRect(
      landscape
          ? Rect.fromLTWH(rect.left, rect.bottom, rect.width, 1)
          : Rect.fromLTWH(rect.left - 1, rect.top, 1, rect.height),
      Paint()..color = const Color(0xFFE3D5B5).withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _KeyboardPainter oldDelegate) =>
      rowHeight != oldDelegate.rowHeight ||
      landscape != oldDelegate.landscape ||
      scrollOffset != oldDelegate.scrollOffset ||
      activePitches != oldDelegate.activePitches;
}

Color _trackColor(int track) {
  const colors = [
    Color(0xFF84A9CD),
    Color(0xFF98E84D),
    Color(0xFF84A9CD),
    Color(0xFF98E84D),
    Color(0xFF84A9CD),
    Color(0xFF98E84D),
  ];
  return colors[track % colors.length];
}

Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0, 1)).toColor();
}
