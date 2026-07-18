import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/piano_note.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class VirtualPianoKeyboard extends StatefulWidget {
  const VirtualPianoKeyboard({
    super.key,
    required this.colors,
    required this.onKeyPressed,
    this.selectedMidiNumber,
    this.highlightedMidiNumbers = const {},
    this.enabled = true,
    this.compact = false,
    this.octave = 4,
    this.onOctaveChanged,
  });

  final AppThemeColors colors;
  final void Function(String pitch, int octave, int midiNumber) onKeyPressed;
  final int? selectedMidiNumber;
  final Set<int> highlightedMidiNumbers;
  final bool enabled;
  final bool compact;
  final int octave;
  final ValueChanged<int>? onOctaveChanged;

  @override
  State<VirtualPianoKeyboard> createState() => _VirtualPianoKeyboardState();
}

class _VirtualPianoKeyboardState extends State<VirtualPianoKeyboard> {
  static const int minimumSelectableOctave = 0;
  static const int maximumSelectableOctave = 8;

  PageController? _pageController;

  PageController get pageController {
    return _pageController ??= PageController(initialPage: selectedOctave);
  }

  int selectedOctave = 4;

  @override
  void initState() {
    super.initState();

    selectedOctave = widget.octave
        .clamp(minimumSelectableOctave, maximumSelectableOctave)
        .toInt();
  }

  @override
  void didUpdateWidget(covariant VirtualPianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controlledOctave = widget.octave
        .clamp(minimumSelectableOctave, maximumSelectableOctave)
        .toInt();

    if (oldWidget.octave != widget.octave &&
        selectedOctave != controlledOctave) {
      selectedOctave = controlledOctave;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          moveToOctavePage(controlledOctave);
        }
      });
    }

    final selectedMidiNumber = widget.selectedMidiNumber;

    if (selectedMidiNumber != null &&
        PianoNote.isValidMidi(selectedMidiNumber) &&
        selectedMidiNumber != oldWidget.selectedMidiNumber) {
      final note = PianoNote.fromMidi(selectedMidiNumber);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          selectOctave(note.octave);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final octaveSelector = buildOctaveSelector();
    final keyboard = buildKeyboard();

    if (widget.compact) {
      return Column(
        children: [
          octaveSelector,
          const Gap(AppSpacing.xs),
          Expanded(child: keyboard),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Swipe horizontally to view the piano',
          style: TextStyle(
            color: widget.colors.primaryColor,
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(AppSpacing.sm),
        octaveSelector,
        const Gap(AppSpacing.sm),
        SizedBox(height: 190, child: keyboard),
      ],
    );
  }

  Widget buildOctaveSelector() {
    final colors = widget.colors;

    return Container(
      height: widget.compact ? 44 : 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous octave',
            onPressed: selectedOctave > minimumSelectableOctave
                ? () {
                    selectOctave(selectedOctave - 1);
                  }
                : null,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          PopupMenuButton<int>(
            tooltip: 'Select octave',
            color: colors.surfaceColor,
            onSelected: selectOctave,
            itemBuilder: (context) {
              return [
                for (
                  var octave = minimumSelectableOctave;
                  octave <= maximumSelectableOctave;
                  octave++
                )
                  PopupMenuItem<int>(
                    value: octave,
                    child: Text(
                      'Octave $octave  -  ${octaveRangeLabel(octave)}',
                      style: TextStyle(color: colors.primaryColor),
                    ),
                  ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.piano_rounded,
                    color: colors.primaryColor,
                    size: AppIconSizes.sm,
                  ),
                  const Gap(AppSpacing.xs),
                  Text(
                    'Octave $selectedOctave',
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.secondaryTextColor,
                    size: AppIconSizes.sm,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next octave',
            onPressed: selectedOctave < maximumSelectableOctave
                ? () {
                    selectOctave(selectedOctave + 1);
                  }
                : null,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const Spacer(),
          Text(
            octaveRangeLabel(selectedOctave),
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppSpacing.xs),
        ],
      ),
    );
  }

  Widget buildKeyboard() {
    final colors = widget.colors;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            widget.compact ? AppRadius.md : AppRadius.lg,
          ),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: widget.compact ? 8 : 14,
              offset: Offset(0, widget.compact ? 3 : 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: PageView.builder(
          controller: pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: maximumSelectableOctave + 1,
          onPageChanged: handlePageChanged,
          itemBuilder: (context, octave) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return buildOctaveKeyboard(octave, constraints);
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildOctaveKeyboard(int octave, BoxConstraints constraints) {
    final octaveKeys = PianoNote.allKeys.where((note) {
      return note.octave == octave;
    }).toList();
    final whiteKeys = octaveKeys.where((note) {
      return !note.isBlackKey;
    }).toList();
    final blackKeys = octaveKeys.where((note) {
      return note.isBlackKey;
    }).toList();
    final whiteKeyWidth = constraints.maxWidth / whiteKeys.length;
    final blackKeyWidth = whiteKeyWidth * 0.62;
    final blackKeyHeight = constraints.maxHeight * 0.62;

    return Stack(
      children: [
        for (var index = 0; index < whiteKeys.length; index++)
          Positioned(
            left: index * whiteKeyWidth,
            top: 0,
            bottom: 0,
            width: whiteKeyWidth,
            child: _WhitePianoKey(
              pianoNote: whiteKeys[index],
              selected:
                  widget.selectedMidiNumber == whiteKeys[index].midiNumber ||
                  widget.highlightedMidiNumbers.contains(
                    whiteKeys[index].midiNumber,
                  ),
              enabled: widget.enabled,
              compact: widget.compact,
              onTap: () {
                widget.onKeyPressed(
                  whiteKeys[index].pitch,
                  whiteKeys[index].octave,
                  whiteKeys[index].midiNumber,
                );
              },
            ),
          ),
        for (final blackKey in blackKeys)
          buildBlackKey(
            blackKey: blackKey,
            whiteKeys: whiteKeys,
            whiteKeyWidth: whiteKeyWidth,
            blackKeyWidth: blackKeyWidth,
            blackKeyHeight: blackKeyHeight,
          ),
      ],
    );
  }

  Widget buildBlackKey({
    required PianoNote blackKey,
    required List<PianoNote> whiteKeys,
    required double whiteKeyWidth,
    required double blackKeyWidth,
    required double blackKeyHeight,
  }) {
    final previousWhiteKeyIndex = whiteKeys.indexWhere((whiteKey) {
      return whiteKey.midiNumber == blackKey.midiNumber - 1;
    });

    if (previousWhiteKeyIndex == -1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: ((previousWhiteKeyIndex + 1) * whiteKeyWidth) - (blackKeyWidth / 2),
      top: 0,
      width: blackKeyWidth,
      height: blackKeyHeight,
      child: _BlackPianoKey(
        pianoNote: blackKey,
        selected:
            widget.selectedMidiNumber == blackKey.midiNumber ||
            widget.highlightedMidiNumbers.contains(blackKey.midiNumber),
        enabled: widget.enabled,
        onTap: () {
          widget.onKeyPressed(
            blackKey.pitch,
            blackKey.octave,
            blackKey.midiNumber,
          );
        },
      ),
    );
  }

  void selectOctave(int octave) {
    final safeOctave = octave < minimumSelectableOctave
        ? minimumSelectableOctave
        : octave > maximumSelectableOctave
        ? maximumSelectableOctave
        : octave;

    if (selectedOctave != safeOctave) {
      setState(() {
        selectedOctave = safeOctave;
      });

      widget.onOctaveChanged?.call(safeOctave);
    }

    moveToOctavePage(safeOctave);
  }

  void moveToOctavePage(int octave) {
    if (!pageController.hasClients || pageController.page?.round() == octave) {
      return;
    }

    pageController.animateToPage(
      octave,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void handlePageChanged(int octave) {
    if (octave == selectedOctave || !mounted) return;

    setState(() {
      selectedOctave = octave;
    });
    widget.onOctaveChanged?.call(octave);
  }

  String octaveRangeLabel(int octave) {
    if (octave == 0) return 'A0-B0';
    if (octave == 8) return 'C8';

    return 'C$octave-B$octave';
  }
}

class _WhitePianoKey extends StatelessWidget {
  const _WhitePianoKey({
    required this.pianoNote,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  final PianoNote pianoNote;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PianoKeyPressRegion(
      label: pianoNote.label,
      enabled: enabled,
      onPressed: onTap,
      builder: (pressed) {
        return Material(
          color: selected
              ? const Color(0xFFE5E7EB)
              : pressed
              ? const Color(0xFFF3F4F6)
              : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: selected || pressed
                  ? Colors.black
                  : const Color(0xFFBDBDBD),
              width: selected
                  ? 2
                  : pressed
                  ? 1.2
                  : 0.7,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (selected) ...[
                  const Icon(Icons.circle, color: Colors.black, size: 6),
                  const Gap(AppSpacing.xs),
                ],
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    pianoNote.label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BlackPianoKey extends StatelessWidget {
  const _BlackPianoKey({
    required this.pianoNote,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PianoNote pianoNote;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(AppRadius.sm),
      bottomRight: Radius.circular(AppRadius.sm),
    );

    return _PianoKeyPressRegion(
      label: pianoNote.label,
      enabled: enabled,
      onPressed: onTap,
      builder: (pressed) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 5,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: selected
                ? const Color(0xFF4B5563)
                : pressed
                ? const Color(0xFF272727)
                : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: BorderSide(
                color: selected || pressed
                    ? Colors.white
                    : const Color(0xFF242424),
                width: selected ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              alignment: Alignment.bottomCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  pianoNote.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
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

class _PianoKeyPressRegion extends StatefulWidget {
  const _PianoKeyPressRegion({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.builder,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final Widget Function(bool pressed) builder;

  @override
  State<_PianoKeyPressRegion> createState() => _PianoKeyPressRegionState();
}

class _PianoKeyPressRegionState extends State<_PianoKeyPressRegion> {
  final Set<int> activePointers = {};

  @override
  void didUpdateWidget(covariant _PianoKeyPressRegion oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled && !widget.enabled) {
      activePointers.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Piano key ${widget.label}',
      onTap: widget.enabled ? widget.onPressed : null,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: widget.enabled ? handlePointerDown : null,
          onPointerUp: handlePointerUp,
          onPointerCancel: handlePointerCancel,
          child: widget.builder(activePointers.isNotEmpty),
        ),
      ),
    );
  }

  void handlePointerDown(PointerDownEvent event) {
    setState(() {
      activePointers.add(event.pointer);
    });

    widget.onPressed();
  }

  void handlePointerUp(PointerUpEvent event) {
    removePointer(event.pointer);
  }

  void handlePointerCancel(PointerCancelEvent event) {
    removePointer(event.pointer);
  }

  void removePointer(int pointer) {
    if (!activePointers.contains(pointer)) {
      return;
    }

    setState(() {
      activePointers.remove(pointer);
    });
  }
}
