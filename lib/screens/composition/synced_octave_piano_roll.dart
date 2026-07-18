import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/composition_note.dart';
import 'package:soundsight/screens/composition/piano_note.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class SyncedOctavePianoRoll extends StatefulWidget {
  const SyncedOctavePianoRoll({
    super.key,
    required this.colors,
    required this.currentMeasureIndex,
    required this.measureCount,
    required this.beatsPerMeasure,
    required this.notes,
    required this.selectedOctave,
    required this.onNoteSelected,
    required this.onOctaveChanged,
    this.selectedNoteId,
    this.selectedNoteIds = const {},
    this.insertionBeat,
    this.onNoteMoved,
    this.onNoteSelectionToggled,
    this.enabled = true,
    this.compact = false,
  });

  final AppThemeColors colors;
  final int currentMeasureIndex;
  final int measureCount;
  final int beatsPerMeasure;
  final List<CompositionNote> notes;
  final int selectedOctave;
  final ValueChanged<String> onNoteSelected;
  final ValueChanged<int> onOctaveChanged;
  final String? selectedNoteId;
  final Set<String> selectedNoteIds;
  final double? insertionBeat;
  final void Function(String noteId, double startBeat)? onNoteMoved;
  final ValueChanged<String>? onNoteSelectionToggled;
  final bool enabled;
  final bool compact;

  @override
  State<SyncedOctavePianoRoll> createState() {
    return _SyncedOctavePianoRollState();
  }
}

class _SyncedOctavePianoRollState extends State<SyncedOctavePianoRoll> {
  String? draggingNoteId;
  double dragStartBeat = 0;
  double dragDistance = 0;
  double dragMaximumBeat = 0;

  int get safeOctave {
    return widget.selectedOctave.clamp(0, 8).toInt();
  }

  int get firstVisibleMidi {
    if (safeOctave == 0) {
      return PianoNote.minimumMidi;
    }

    return (safeOctave + 1) * 12;
  }

  int get lastVisibleMidi {
    if (safeOctave == 0) return 23;
    if (safeOctave == 8) return PianoNote.maximumMidi;

    return firstVisibleMidi + 11;
  }

  List<CompositionNote> get currentMeasureNotes {
    return widget.notes.where((note) {
      return note.measureIndex == widget.currentMeasureIndex;
    }).toList();
  }

  List<CompositionNote> get visibleNotes {
    return currentMeasureNotes.where((note) {
      return note.midiNumber >= firstVisibleMidi &&
          note.midiNumber <= lastVisibleMidi;
    }).toList();
  }

  List<CompositionNote> get notesBelow {
    return currentMeasureNotes.where((note) {
      return note.midiNumber < firstVisibleMidi;
    }).toList();
  }

  List<CompositionNote> get notesAbove {
    return currentMeasureNotes.where((note) {
      return note.midiNumber > lastVisibleMidi;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildOctaveControls(),
        const Gap(AppSpacing.xs),
        Expanded(child: buildGrid()),
      ],
    );
  }

  Widget buildOctaveControls() {
    final below = notesBelow;
    final above = notesAbove;

    return Container(
      height: widget.compact ? 40 : 46,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: widget.colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: widget.colors.borderColor),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous octave',
            onPressed: widget.enabled && safeOctave > 0
                ? () {
                    changeOctave(safeOctave - 1);
                  }
                : null,
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Octave $safeOctave',
                  maxLines: 1,
                  style: TextStyle(
                    color: widget.colors.primaryColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  octaveRangeLabel(),
                  maxLines: 1,
                  style: TextStyle(
                    color: widget.colors.secondaryTextColor,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next octave',
            onPressed: widget.enabled && safeOctave < 8
                ? () {
                    changeOctave(safeOctave + 1);
                  }
                : null,
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          if (below.isNotEmpty)
            _HiddenNotesButton(
              colors: widget.colors,
              icon: Icons.keyboard_arrow_down_rounded,
              count: below.length,
              tooltip: '${below.length} notes below this octave',
              onTap: widget.enabled
                  ? () {
                      final nearestNote = below.reduce((first, second) {
                        return first.midiNumber > second.midiNumber
                            ? first
                            : second;
                      });

                      changeOctave(octaveForMidi(nearestNote.midiNumber));
                    }
                  : null,
            ),
          if (above.isNotEmpty)
            _HiddenNotesButton(
              colors: widget.colors,
              icon: Icons.keyboard_arrow_up_rounded,
              count: above.length,
              tooltip: '${above.length} notes above this octave',
              onTap: widget.enabled
                  ? () {
                      final nearestNote = above.reduce((first, second) {
                        return first.midiNumber < second.midiNumber
                            ? first
                            : second;
                      });

                      changeOctave(octaveForMidi(nearestNote.midiNumber));
                    }
                  : null,
            ),
          IconButton(
            tooltip: 'View all notes',
            onPressed: showAllNotes,
            visualDensity: VisualDensity.compact,
            iconSize: 19,
            icon: const Icon(Icons.library_music_outlined),
          ),
        ],
      ),
    );
  }

  Widget buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeBeatsPerMeasure = math.max(1, widget.beatsPerMeasure);

        final rowCount = lastVisibleMidi - firstVisibleMidi + 1;

        final rowHeight = constraints.maxHeight / rowCount;
        final beatWidth = constraints.maxWidth / safeBeatsPerMeasure;

        return Container(
          decoration: BoxDecoration(
            color: widget.colors.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: widget.colors.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var row = 0; row < rowCount; row++)
                buildPitchRow(row: row, rowHeight: rowHeight),
              for (var row = 1; row < rowCount; row++)
                Positioned(
                  top: row * rowHeight,
                  left: 0,
                  right: 0,
                  child: Container(height: 1, color: widget.colors.borderColor),
                ),
              for (var beat = 1; beat < safeBeatsPerMeasure; beat++)
                Positioned(
                  left: beat * beatWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 1, color: widget.colors.borderColor),
                ),
              if (widget.insertionBeat != null)
                buildInsertionMarker(
                  beatWidth: beatWidth,
                  gridWidth: constraints.maxWidth,
                ),
              for (final note in visibleNotes)
                buildNoteBlock(
                  note: note,
                  beatWidth: beatWidth,
                  rowHeight: rowHeight,
                  gridWidth: constraints.maxWidth,
                ),
              if (visibleNotes.isEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: widget.colors.surfaceColor.withValues(
                            alpha: 0.92,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          currentMeasureNotes.isEmpty
                              ? 'Tap a piano key to add a note'
                              : 'No notes in this octave',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.colors.secondaryTextColor,
                            fontSize: widget.compact
                                ? 10
                                : AppTextSizes.caption,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPitchRow({required int row, required double rowHeight}) {
    final midiNumber = lastVisibleMidi - row;
    final pianoNote = PianoNote.fromMidi(midiNumber);

    return Positioned(
      top: row * rowHeight,
      left: 0,
      right: 0,
      height: rowHeight,
      child: ColoredBox(
        color: pianoNote.isBlackKey
            ? widget.colors.primaryColor.withValues(alpha: 0.045)
            : widget.colors.backgroundColor,
      ),
    );
  }

  Widget buildInsertionMarker({
    required double beatWidth,
    required double gridWidth,
  }) {
    final maximumLeft = math.max(0.0, gridWidth - 2);

    final markerLeft = (widget.insertionBeat! * beatWidth)
        .clamp(0.0, maximumLeft)
        .toDouble();

    return Positioned(
      left: markerLeft,
      top: 0,
      bottom: 0,
      width: 2,
      child: IgnorePointer(
        child: ColoredBox(
          color: widget.colors.primaryColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget buildNoteBlock({
    required CompositionNote note,
    required double beatWidth,
    required double rowHeight,
    required double gridWidth,
  }) {
    final row = lastVisibleMidi - note.midiNumber;
    final horizontalInset = widget.compact ? 2.0 : 3.0;

    final isDragging = draggingNoteId == note.id;

    final displayedStartBeat = isDragging
        ? (dragStartBeat + (dragDistance / beatWidth))
              .clamp(0.0, dragMaximumBeat)
              .toDouble()
        : note.startBeat;

    final left = (displayedStartBeat * beatWidth) + horizontalInset;

    final remainingWidth = math.max(1.0, gridWidth - left).toDouble();

    final calculatedWidth =
        (note.durationBeats * beatWidth) - (horizontalInset * 2);

    final minimumWidth = math.min(24.0, remainingWidth).toDouble();

    final blockWidth = calculatedWidth
        .clamp(minimumWidth, remainingWidth)
        .toDouble();

    final selected = isSelected(note);
    final label =
        '${note.pitch}${note.octave}'
        '${note.tieToNext ? ' →' : ''}';

    return Positioned(
      left: left,
      top: row * rowHeight,
      width: blockWidth,
      height: rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: !widget.enabled || widget.onNoteMoved == null
              ? null
              : (_) {
                  startDragging(note);
                },
          onHorizontalDragUpdate: !widget.enabled || widget.onNoteMoved == null
              ? null
              : (details) {
                  setState(() {
                    dragDistance += details.delta.dx;
                  });
                },
          onHorizontalDragEnd: !widget.enabled || widget.onNoteMoved == null
              ? null
              : (_) {
                  finishDragging(beatWidth);
                },
          onHorizontalDragCancel: !widget.enabled || widget.onNoteMoved == null
              ? null
              : cancelDragging,
          child: Tooltip(
            message: label,
            child: Material(
              color: selected
                  ? widget.colors.primaryColor
                  : widget.colors.primaryColor.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: widget.colors.primaryColor,
                  width: selected ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.enabled
                    ? () {
                        widget.onNoteSelected(note.id);
                      }
                    : null,
                onLongPress:
                    !widget.enabled || widget.onNoteSelectionToggled == null
                    ? null
                    : () {
                        widget.onNoteSelectionToggled?.call(note.id);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected
                              ? widget.colors.backgroundColor
                              : widget.colors.primaryColor,
                          fontSize: widget.compact ? 10 : AppTextSizes.caption,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void startDragging(CompositionNote note) {
    setState(() {
      draggingNoteId = note.id;
      dragStartBeat = note.startBeat;
      dragDistance = 0;
      dragMaximumBeat = math
          .max(0.0, widget.beatsPerMeasure - note.durationBeats)
          .toDouble();
    });
  }

  void finishDragging(double beatWidth) {
    final noteId = draggingNoteId;

    final newStartBeat = quantizeBeat(
      dragStartBeat + (dragDistance / beatWidth),
      dragMaximumBeat,
    );

    setState(clearDrag);

    if (noteId != null) {
      widget.onNoteMoved?.call(noteId, newStartBeat);
    }
  }

  void cancelDragging() {
    setState(clearDrag);
  }

  void clearDrag() {
    draggingNoteId = null;
    dragStartBeat = 0;
    dragDistance = 0;
    dragMaximumBeat = 0;
  }

  bool isSelected(CompositionNote note) {
    return note.id == widget.selectedNoteId ||
        widget.selectedNoteIds.contains(note.id);
  }

  double quantizeBeat(double beat, double maximumBeat) {
    return CompositionNote.normalizeTiming(
      beat,
    ).clamp(0.0, maximumBeat).toDouble();
  }

  void changeOctave(int octave) {
    widget.onOctaveChanged(octave.clamp(0, 8).toInt());
  }

  int octaveForMidi(int midiNumber) {
    if (midiNumber < 24) {
      return 0;
    }

    return PianoNote.fromMidi(midiNumber).octave.clamp(0, 8).toInt();
  }

  String octaveRangeLabel() {
    if (safeOctave == 0) return 'A0 – B0';
    if (safeOctave == 8) return 'C8';

    return 'C$safeOctave – B$safeOctave';
  }

  Future<void> showAllNotes() async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return _AllNotesDialog(
          colors: widget.colors,
          measureCount: widget.measureCount,
          notes: widget.notes,
        );
      },
    );
  }
}

class _HiddenNotesButton extends StatelessWidget {
  const _HiddenNotesButton({
    required this.colors,
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onTap,
  });

  final AppThemeColors colors;
  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: colors.primaryColor),
                Text(
                  '$count',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllNotesDialog extends StatelessWidget {
  const _AllNotesDialog({
    required this.colors,
    required this.measureCount,
    required this.notes,
  });

  final AppThemeColors colors;
  final int measureCount;
  final List<CompositionNote> notes;

  @override
  Widget build(BuildContext context) {
    final measuresWithNotes = <int>[];

    for (var measureIndex = 0; measureIndex < measureCount; measureIndex++) {
      if (notes.any((note) => note.measureIndex == measureIndex)) {
        measuresWithNotes.add(measureIndex);
      }
    }

    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      title: Row(
        children: [
          Icon(Icons.library_music_outlined, color: colors.primaryColor),
          const Gap(AppSpacing.sm),
          Text('All Notes', style: TextStyle(color: colors.primaryColor)),
        ],
      ),
      content: SizedBox(
        width: math
            .min(MediaQuery.sizeOf(context).width * 0.75, 560)
            .toDouble(),
        height: math
            .min(MediaQuery.sizeOf(context).height * 0.65, 420)
            .toDouble(),
        child: measuresWithNotes.isEmpty
            ? Center(
                child: Text(
                  'No notes have been added yet.',
                  style: TextStyle(color: colors.secondaryTextColor),
                ),
              )
            : ListView.separated(
                itemCount: measuresWithNotes.length,
                separatorBuilder: (_, __) {
                  return const Gap(AppSpacing.sm);
                },
                itemBuilder: (context, index) {
                  final measureIndex = measuresWithNotes[index];

                  final measureNotes = notes.where((note) {
                    return note.measureIndex == measureIndex;
                  }).toList();

                  return buildMeasure(measureIndex, measureNotes);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget buildMeasure(int measureIndex, List<CompositionNote> measureNotes) {
    final groupedNotes = <double, List<CompositionNote>>{};

    for (final note in measureNotes) {
      groupedNotes.putIfAbsent(note.startBeat, () => []).add(note);
    }

    final beats = groupedNotes.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measure ${measureIndex + 1}',
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.label,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final beat in beats)
                buildBeatGroup(beat, groupedNotes[beat]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBeatGroup(double beat, List<CompositionNote> beatNotes) {
    beatNotes.sort((first, second) {
      return first.midiNumber.compareTo(second.midiNumber);
    });

    final labels = beatNotes
        .map((note) {
          return '${note.pitch}${note.octave}';
        })
        .join(' + ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.borderColor),
      ),
      child: Text(
        'Beat ${formatBeat(beat + 1)}: $labels',
        style: TextStyle(
          color: colors.primaryColor,
          fontSize: AppTextSizes.caption,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String formatBeat(double beat) {
    final rounded = beat.round();

    if ((beat - rounded).abs() < 0.001) {
      return '$rounded';
    }

    return beat.toStringAsFixed(2);
  }
}
