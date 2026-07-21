import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/widgets/synced_octave_piano_roll.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionTimeline extends StatefulWidget {
  const CompositionTimeline({
    super.key,
    required this.colors,
    required this.currentMeasureIndex,
    required this.measureCount,
    required this.beatsPerMeasure,
    required this.notes,
    required this.onMeasureChanged,
    required this.onNoteSelected,
    this.selectedNoteId,
    this.selectedNoteIds = const {},
    this.insertionBeat,
    this.onNoteMoved,
    this.onNoteSelectionToggled,
    this.selectedOctave = 4,
    this.onOctaveChanged,
    this.showSongOverview = false,
    this.compact = false,
    this.enabled = true,
  });

  final AppThemeColors colors;
  final int currentMeasureIndex;
  final int measureCount;
  final int beatsPerMeasure;
  final List<CompositionNote> notes;
  final ValueChanged<int> onMeasureChanged;
  final ValueChanged<String> onNoteSelected;
  final String? selectedNoteId;
  final Set<String> selectedNoteIds;
  final double? insertionBeat;
  final void Function(String noteId, double startBeat)? onNoteMoved;
  final ValueChanged<String>? onNoteSelectionToggled;
  final int selectedOctave;
  final ValueChanged<int>? onOctaveChanged;
  final bool showSongOverview;
  final bool compact;
  final bool enabled;

  @override
  State<CompositionTimeline> createState() => _CompositionTimelineState();
}

class _CompositionTimelineState extends State<CompositionTimeline> {
  @override
  Widget build(BuildContext context) {
    final measureSelector = _MeasureSelector(
      colors: widget.colors,
      currentMeasureIndex: widget.currentMeasureIndex,
      measureCount: widget.measureCount,
      onMeasureChanged: widget.onMeasureChanged,
      compact: widget.compact,
      enabled: widget.enabled,
    );

    final pianoRoll = _buildPianoRoll();
    final overview = widget.showSongOverview
        ? _SongOverview(
            colors: widget.colors,
            currentMeasureIndex: widget.currentMeasureIndex,
            measureCount: widget.measureCount,
            beatsPerMeasure: widget.beatsPerMeasure,
            notes: widget.notes,
            onMeasureChanged: widget.onMeasureChanged,
            compact: widget.compact,
            enabled: widget.enabled,
          )
        : null;

    if (widget.compact) {
      return Column(
        children: [
          measureSelector,
          if (overview != null) ...[const Gap(AppSpacing.xs), overview],
          const Gap(AppSpacing.xs),
          Expanded(child: pianoRoll),
        ],
      );
    }

    return Column(
      children: [
        measureSelector,
        if (overview != null) ...[const Gap(AppSpacing.sm), overview],
        const Gap(AppSpacing.md),
        pianoRoll,
      ],
    );
  }

  Widget _buildPianoRoll() {
    final pianoGrid = _buildPianoGrid();

    return Container(
      padding: EdgeInsets.all(widget.compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.colors.surfaceColor,
        borderRadius: BorderRadius.circular(
          widget.compact ? AppRadius.md : AppRadius.lg,
        ),
        border: Border.all(color: widget.colors.borderColor),
        boxShadow: widget.compact
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    widget.colors.isDarkMode ? 0.18 : 0.05,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Piano Roll',
                style: TextStyle(
                  color: widget.colors.primaryColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Measure ${widget.currentMeasureIndex + 1}',
                style: TextStyle(
                  color: widget.colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Gap(widget.compact ? AppSpacing.xs : AppSpacing.sm),
          _BeatHeader(
            colors: widget.colors,
            beatsPerMeasure: widget.beatsPerMeasure,
          ),
          if (widget.compact)
            Expanded(child: pianoGrid)
          else
            SizedBox(height: 190, child: pianoGrid),
        ],
      ),
    );
  }

  Widget _buildPianoGrid() {
    return SyncedOctavePianoRoll(
      colors: widget.colors,
      currentMeasureIndex: widget.currentMeasureIndex,
      measureCount: widget.measureCount,
      beatsPerMeasure: widget.beatsPerMeasure,
      notes: widget.notes,
      selectedOctave: widget.selectedOctave,
      selectedNoteId: widget.selectedNoteId,
      selectedNoteIds: widget.selectedNoteIds,
      insertionBeat: widget.insertionBeat,
      enabled: widget.enabled,
      compact: widget.compact,
      onOctaveChanged: (octave) {
        widget.onOctaveChanged?.call(octave);
      },
      onNoteSelected: widget.onNoteSelected,
      onNoteSelectionToggled: widget.onNoteSelectionToggled,
      onNoteMoved: widget.onNoteMoved,
    );
  }
}

class _MeasureSelector extends StatelessWidget {
  const _MeasureSelector({
    required this.colors,
    required this.currentMeasureIndex,
    required this.measureCount,
    required this.onMeasureChanged,
    required this.compact,
    required this.enabled,
  });

  final AppThemeColors colors;
  final int currentMeasureIndex;
  final int measureCount;
  final ValueChanged<int> onMeasureChanged;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        height: 40,
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                'Measures',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Gap(AppSpacing.xs),
            Expanded(child: _buildMeasureList()),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDarkMode ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Measures',
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$measureCount total',
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          SizedBox(height: 50, child: _buildMeasureList()),
        ],
      ),
    );
  }

  Widget _buildMeasureList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: measureCount,
      separatorBuilder: (_, __) => Gap(compact ? AppSpacing.xs : AppSpacing.sm),
      itemBuilder: (context, index) {
        final selected = currentMeasureIndex == index;

        return Material(
          color: selected ? colors.primaryColor : colors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              compact ? AppRadius.sm : AppRadius.md,
            ),
            side: BorderSide(
              color: selected ? colors.primaryColor : colors.borderColor,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    onMeasureChanged(index);
                  }
                : null,
            child: SizedBox(
              width: compact ? 82 : 112,
              child: Center(
                child: Text(
                  compact ? '${index + 1}' : 'Measure ${index + 1}',
                  style: TextStyle(
                    color: selected
                        ? colors.backgroundColor
                        : colors.primaryColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SongOverview extends StatelessWidget {
  const _SongOverview({
    required this.colors,
    required this.currentMeasureIndex,
    required this.measureCount,
    required this.beatsPerMeasure,
    required this.notes,
    required this.onMeasureChanged,
    required this.compact,
    required this.enabled,
  });

  final AppThemeColors colors;
  final int currentMeasureIndex;
  final int measureCount;
  final int beatsPerMeasure;
  final List<CompositionNote> notes;
  final ValueChanged<int> onMeasureChanged;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 34 : 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.borderColor),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: measureCount,
        separatorBuilder: (_, __) => const SizedBox(width: 3),
        itemBuilder: (context, measureIndex) {
          return SizedBox(
            width: compact ? 46 : 62,
            child: _OverviewMeasure(
              colors: colors,
              measureIndex: measureIndex,
              beatsPerMeasure: beatsPerMeasure,
              notes: notes.where((note) {
                return note.measureIndex == measureIndex;
              }).toList(),
              selected: measureIndex == currentMeasureIndex,
              enabled: enabled,
              onTap: () {
                onMeasureChanged(measureIndex);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OverviewMeasure extends StatelessWidget {
  const _OverviewMeasure({
    required this.colors,
    required this.measureIndex,
    required this.beatsPerMeasure,
    required this.notes,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final AppThemeColors colors;
  final int measureIndex;
  final int beatsPerMeasure;
  final List<CompositionNote> notes;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chordGroups = <double, List<CompositionNote>>{};

    for (final note in notes) {
      chordGroups.putIfAbsent(note.startBeat, () => []).add(note);
    }

    return Material(
      color: selected
          ? colors.primaryColor.withOpacity(0.14)
          : colors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(
          color: selected ? colors.primaryColor : colors.borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final safeBeatsPerMeasure = math.max(1, beatsPerMeasure);

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (constraints.maxWidth >= 16)
                  Positioned(
                    top: 1,
                    left: 0,
                    right: 0,
                    child: Text(
                      '${measureIndex + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected
                            ? colors.primaryColor
                            : colors.secondaryTextColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                for (final chordEntry in chordGroups.entries)
                  _buildDensityBlock(
                    chordEntry: chordEntry,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    safeBeatsPerMeasure: safeBeatsPerMeasure,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDensityBlock({
    required MapEntry<double, List<CompositionNote>> chordEntry,
    required double width,
    required double height,
    required int safeBeatsPerMeasure,
  }) {
    var maximumDuration = CompositionNote.timingStep;

    for (final note in chordEntry.value) {
      maximumDuration = math.max(maximumDuration, note.durationBeats);
    }

    final blockLeft = ((chordEntry.key / safeBeatsPerMeasure) * width)
        .clamp(0.0, math.max(0.0, width - 1))
        .toDouble();
    final availableWidth = math.max(1.0, width - blockLeft);
    final blockWidth = ((maximumDuration / safeBeatsPerMeasure) * width)
        .clamp(1.0, availableWidth)
        .toDouble();
    final blockHeight = math.min(
      math.max(3.0, height - 12),
      3.0 + (chordEntry.value.length * 1.5),
    );

    return Positioned(
      left: blockLeft,
      bottom: 2,
      width: blockWidth,
      height: blockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryColor.withOpacity(selected ? 0.95 : 0.65),
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

class _BeatHeader extends StatelessWidget {
  const _BeatHeader({required this.colors, required this.beatsPerMeasure});

  final AppThemeColors colors;
  final int beatsPerMeasure;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var beat = 1; beat <= beatsPerMeasure; beat++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '$beat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
