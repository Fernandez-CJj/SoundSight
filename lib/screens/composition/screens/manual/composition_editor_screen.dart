import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/widgets/chord_mode_controls.dart';
import 'package:soundsight/screens/composition/controllers/composition_editor_controller.dart';
import 'package:soundsight/screens/composition/widgets/composition_history_controls.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/models/piano_note.dart';
import 'package:soundsight/screens/composition/models/quantized_note.dart';
import 'package:soundsight/screens/composition/widgets/composition_performance_controls.dart';
import 'package:soundsight/screens/composition/widgets/composition_playback_controls.dart';
import 'package:soundsight/screens/composition/services/composition_generation_service.dart';
import 'package:soundsight/screens/composition/services/composition_playback_service.dart';
import 'package:soundsight/screens/composition/services/composition_midi_processor.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';
import 'package:soundsight/screens/composition/dialogs/composition_settings_dialog.dart';
import 'package:soundsight/screens/composition/widgets/composition_timeline.dart';
import 'package:soundsight/screens/composition/widgets/measure_actions_button.dart';
import 'package:soundsight/screens/composition/widgets/note_duration_selector.dart';
import 'package:soundsight/screens/composition/dialogs/unsaved_composition_dialog.dart';
import 'package:soundsight/screens/composition/widgets/virtual_piano_keyboard.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionEditorScreen extends StatefulWidget {
  const CompositionEditorScreen({
    super.key,
    required this.colors,
    required this.composition,
  });

  final AppThemeColors colors;
  final Composition composition;

  @override
  State<CompositionEditorScreen> createState() =>
      _CompositionEditorScreenState();
}

class _CompositionEditorScreenState extends State<CompositionEditorScreen>
    with WidgetsBindingObserver {
  final CompositionService compositionService = CompositionService();
  final CompositionGenerationService compositionGenerationService =
      CompositionGenerationService();
  final CompositionPlaybackService playbackService =
      CompositionPlaybackService();
  final MidiInputService midiInputService = MidiInputService();

  late final CompositionEditorController editorController;

  bool isSaving = false;
  bool isPlaying = false;
  bool isPaused = false;
  bool isPreparingPlayback = false;
  bool isChordMode = false;
  bool isDirty = false;
  bool isDiscarding = false;
  bool isShowingDiscardDialog = false;
  bool playFromCurrentBeat = false;
  bool isLoopEnabled = false;
  bool isSustainEnabled = false;
  bool isMetronomeEnabled = false;
  bool showSongOverview = false;
  double volume = 1;
  int selectedOctave = 4;
  late String compositionTitle;
  late String keySignature;
  late int tempo;
  late String compositionId;
  String? playingNoteId;
  Set<String> playingNoteIds = {};
  int? playbackMeasureIndex;
  String? savedFingerprint;

  StreamSubscription<bool>? midiConnectionSubscription;
  StreamSubscription<MidiNoteEvent>? midiNoteEventSubscription;
  Timer? midiChordWindowTimer;
  final Stopwatch midiStepStopwatch = Stopwatch();
  final Map<int, _PendingMidiStepNote> pendingMidiStepNotes = {};
  bool isConnectingMidi = false;
  bool midiChordWindowIsOpen = false;
  bool isApplyingMidiStep = false;
  bool midiStepReplacesSelectedNote = false;
  double midiStepStartAbsoluteBeat = 0;
  String midiStatus = 'No MIDI piano connected';

  bool get midiIsConnected => midiInputService.isConnected;

  bool get midiStepIsBusy {
    return pendingMidiStepNotes.isNotEmpty || isApplyingMidiStep;
  }

  bool get editorInteractionLocked {
    return isSaving || isPlaying || midiStepIsBusy;
  }

  String get connectedMidiDeviceName {
    return midiInputService.connectedDevice?.name ?? 'MIDI piano connected';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    midiConnectionSubscription = midiInputService.connectionStream.listen(
      handleMidiConnectionChanged,
    );
    midiNoteEventSubscription = midiInputService.noteEventStream.listen(
      handleMidiNoteEvent,
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    editorController = CompositionEditorController(
      initialNotes: widget.composition.notes,
      initialMeasureCount: widget.composition.measureCount,
      beatsPerMeasure: widget.composition.beatsPerMeasure,
      beatUnit: widget.composition.beatUnit,
    );

    compositionTitle = widget.composition.title;
    keySignature = widget.composition.keySignature;
    tempo = widget.composition.tempo;
    compositionId = widget.composition.id;
    savedFingerprint = compositionId.isEmpty
        ? null
        : compositionFingerprint(buildCurrentComposition());
    updateDirtyState();

    preloadPianoOctave(4);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    midiChordWindowTimer?.cancel();
    midiStepStopwatch.stop();
    unawaited(midiConnectionSubscription?.cancel());
    unawaited(midiNoteEventSubscription?.cancel());
    unawaited(midiInputService.dispose());
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    unawaited(playbackService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final selectedNote = editorController.selectedNote;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop:
          !isSaving && !midiStepIsBusy && (!isDirty || isDiscarding),
      onPopInvokedWithResult: handlePop,
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          backgroundColor: colors.backgroundColor,
          foregroundColor: colors.primaryColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: isLandscape ? 48 : null,
          centerTitle: true,
          title: Text(
            compositionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isLandscape
                  ? AppTextSizes.body
                  : AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            buildMidiAppBarAction(colors, isLandscape),
            IconButton(
              tooltip: 'Composition settings',
              onPressed: editorInteractionLocked ? null : editSettings,
              icon: const Icon(Icons.tune_rounded),
            ),
            IconButton(
              tooltip: 'Save composition',
              onPressed: editorInteractionLocked ? null : saveComposition,
              icon: isSaving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colors.primaryColor,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: isLandscape
              ? buildLandscapeEditor(colors)
              : buildPortraitEditor(colors, selectedNote),
        ),
        bottomNavigationBar: isLandscape ? null : buildSaveButton(colors),
      ),
    );
  }

  Widget buildPortraitEditor(
    AppThemeColors colors,
    CompositionNote? selectedNote,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        buildCompositionInformation(colors),
        const Gap(AppSpacing.md),
        CompositionPlaybackControls(
          colors: colors,
          isPlaying: isPlaying,
          isPaused: isPaused,
          isPreparing: isPreparingPlayback,
          onPlay: playOrResumeComposition,
          onPause: pauseComposition,
          onStop: stopComposition,
        ),
        const Gap(AppSpacing.md),
        CompositionPerformanceControls(
          colors: colors,
          volume: volume,
          velocity: editorController.selectedVelocity,
          playFromCursor: playFromCurrentBeat,
          isLoopEnabled: isLoopEnabled,
          isSustainEnabled: isSustainEnabled,
          isMetronomeEnabled: isMetronomeEnabled,
          enabled: !editorInteractionLocked,
          showVelocity: !midiIsConnected,
          onVolumeChanged: changeVolume,
          onVelocityChanged: changeVelocity,
          onPlayFromCursorChanged: changePlayFromCursor,
          onLoopChanged: changeLoop,
          onSustainChanged: changeSustain,
          onMetronomeChanged: changeMetronome,
        ),
        const Gap(AppSpacing.md),
        CompositionTimeline(
          colors: colors,
          currentMeasureIndex:
              playbackMeasureIndex ?? editorController.currentMeasureIndex,
          measureCount: editorController.measureCount,
          beatsPerMeasure: editorController.beatsPerMeasure,
          notes: editorController.notes,
          selectedNoteId: isPlaying
              ? playingNoteId
              : editorController.selectedNoteId,
          selectedNoteIds: isPlaying
              ? playingNoteIds
              : editorController.selectedNoteIds,
          insertionBeat: isPlaying ? null : editorController.insertionBeat,
          onMeasureChanged: changeMeasure,
          onNoteSelected: selectNote,
          onNoteSelectionToggled: toggleNoteSelection,
          onNoteMoved: moveNote,
          selectedOctave: selectedOctave,
          onOctaveChanged: changeSelectedOctave,
          showSongOverview: showSongOverview,
          enabled: !editorInteractionLocked,
          pianoRollHeight: midiIsConnected ? 300 : 190,
        ),
        if (selectedNote != null && !isPlaying) ...[
          const Gap(AppSpacing.md),
          buildSelectedNoteCard(colors),
        ],
        const Gap(AppSpacing.md),
        buildEditorActions(colors),
        const Gap(AppSpacing.md),
        buildMeasureActions(colors),
        const Gap(AppSpacing.md),
        buildHistoryControls(colors),
        if (!midiIsConnected) ...[
          const Gap(AppSpacing.md),
          NoteDurationSelector(
            colors: colors,
            selectedDuration: editorController.selectedDuration,
            beatsPerMeasure: editorController.beatsPerMeasure,
            beatUnit: editorController.beatUnit,
            onDurationSelected: changeDuration,
            enabled: !editorInteractionLocked,
          ),
          const Gap(AppSpacing.md),
          ChordModeControls(
            colors: colors,
            isChordMode: isChordMode,
            isBuildingChord: editorController.isBuildingChord,
            chordNoteCount: editorController.activeChordNoteCount,
            enabled: !editorInteractionLocked,
            onChordModeChanged: toggleChordMode,
            onFinishChord: finishChord,
          ),
          const Gap(AppSpacing.md),
          VirtualPianoKeyboard(
            colors: colors,
            selectedMidiNumber: isPlaying
                ? null
                : editorController.selectedMidiNumber,
            highlightedMidiNumbers: highlightedPianoMidiNumbers,
            octave: selectedOctave,
            enabled: !editorInteractionLocked,
            onKeyPressed: addOrUpdateNote,
            onOctaveChanged: changeSelectedOctave,
          ),
        ],
      ],
    );
  }

  Widget buildLandscapeEditor(AppThemeColors colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: buildCompositionInformation(colors, compact: true),
            ),
            const Gap(AppSpacing.xs),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Expanded(
                    child: CompositionPlaybackControls(
                      colors: colors,
                      isPlaying: isPlaying,
                      isPaused: isPaused,
                      isPreparing: isPreparingPlayback,
                      onPlay: playOrResumeComposition,
                      onPause: pauseComposition,
                      onStop: stopComposition,
                      compact: true,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  CompositionPerformanceControls(
                    colors: colors,
                    volume: volume,
                    velocity: editorController.selectedVelocity,
                    playFromCursor: playFromCurrentBeat,
                    isLoopEnabled: isLoopEnabled,
                    isSustainEnabled: isSustainEnabled,
                    isMetronomeEnabled: isMetronomeEnabled,
                    enabled: !editorInteractionLocked,
                    showVelocity: !midiIsConnected,
                    onVolumeChanged: changeVolume,
                    onVelocityChanged: changeVelocity,
                    onPlayFromCursorChanged: changePlayFromCursor,
                    onLoopChanged: changeLoop,
                    onSustainChanged: changeSustain,
                    onMetronomeChanged: changeMetronome,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!midiIsConnected) ...[
          const Gap(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: NoteDurationSelector(
                  colors: colors,
                  selectedDuration: editorController.selectedDuration,
                  beatsPerMeasure: editorController.beatsPerMeasure,
                  beatUnit: editorController.beatUnit,
                  onDurationSelected: changeDuration,
                  compact: true,
                  enabled: !editorInteractionLocked,
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: ChordModeControls(
                  colors: colors,
                  isChordMode: isChordMode,
                  isBuildingChord: editorController.isBuildingChord,
                  chordNoteCount: editorController.activeChordNoteCount,
                  enabled: !editorInteractionLocked,
                  onChordModeChanged: toggleChordMode,
                  onFinishChord: finishChord,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
        const Gap(AppSpacing.sm),
        if (midiIsConnected) ...[
          SizedBox(
            height: 420,
            child: buildLandscapeTimeline(colors),
          ),
          const Gap(AppSpacing.sm),
          SizedBox(height: 104, child: buildLandscapeActions(colors)),
        ] else
          SizedBox(
            height: 420,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: buildLandscapeTimeline(colors)),
                const Gap(AppSpacing.sm),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 260,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Piano Keyboard',
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Swipe horizontally',
                                  style: TextStyle(
                                    color: colors.secondaryTextColor,
                                    fontSize: AppTextSizes.caption,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(AppSpacing.xs),
                            Expanded(
                              child: VirtualPianoKeyboard(
                                colors: colors,
                                selectedMidiNumber: isPlaying
                                    ? null
                                    : editorController.selectedMidiNumber,
                                highlightedMidiNumbers:
                                    highlightedPianoMidiNumbers,
                                octave: selectedOctave,
                                enabled: !editorInteractionLocked,
                                onKeyPressed: addOrUpdateNote,
                                onOctaveChanged: changeSelectedOctave,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Expanded(child: buildLandscapeActions(colors)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Gap(AppSpacing.sm),
        buildHistoryControls(colors, compact: true),
      ],
    );
  }

  Widget buildMidiAppBarAction(
    AppThemeColors colors,
    bool isLandscape,
  ) {
    if (midiIsConnected) {
      return PopupMenuButton<String>(
        enabled: !isSaving,
        tooltip: midiStatus,
        color: colors.surfaceColor,
        icon: const Icon(Icons.usb_rounded),
        onSelected: (value) {
          if (value == 'disconnect') {
            unawaited(disconnectMidi());
          }
        },
        itemBuilder: (_) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                connectedMidiDeviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'disconnect',
              child: Row(
                children: [
                  Icon(
                    Icons.link_off_rounded,
                    color: colors.primaryColor,
                    size: AppIconSizes.sm,
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Disconnect MIDI',
                    style: TextStyle(color: colors.primaryColor),
                  ),
                ],
              ),
            ),
          ];
        },
      );
    }

    return TextButton.icon(
      onPressed:
          isConnectingMidi || isSaving || isPlaying ? null : connectToMidi,
      icon: isConnectingMidi
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primaryColor,
              ),
            )
          : const Icon(Icons.usb_rounded),
      label: Text(
        isConnectingMidi
            ? 'Connecting'
            : isLandscape
            ? 'MIDI'
            : 'Connect MIDI',
      ),
      style: TextButton.styleFrom(foregroundColor: colors.primaryColor),
    );
  }

  Widget buildLandscapeTimeline(AppThemeColors colors) {
    return CompositionTimeline(
      colors: colors,
      currentMeasureIndex:
          playbackMeasureIndex ?? editorController.currentMeasureIndex,
      measureCount: editorController.measureCount,
      beatsPerMeasure: editorController.beatsPerMeasure,
      notes: editorController.notes,
      selectedNoteId: isPlaying
          ? playingNoteId
          : editorController.selectedNoteId,
      selectedNoteIds: isPlaying
          ? playingNoteIds
          : editorController.selectedNoteIds,
      insertionBeat: isPlaying ? null : editorController.insertionBeat,
      onMeasureChanged: changeMeasure,
      onNoteSelected: selectNote,
      onNoteSelectionToggled: toggleNoteSelection,
      onNoteMoved: moveNote,
      selectedOctave: selectedOctave,
      onOctaveChanged: changeSelectedOctave,
      showSongOverview: showSongOverview,
      compact: true,
      enabled: !editorInteractionLocked,
    );
  }

  Widget buildCompositionInformation(
    AppThemeColors colors, {
    bool compact = false,
  }) {
    final noteCount = editorController.notes.length;
    final noteUsageColor = noteCount >= 256
        ? const Color(0xFFDC2626)
        : noteCount >= 240
        ? const Color(0xFFF59E0B)
        : null;

    return Row(
      children: [
        Expanded(
          child: _InformationCard(
            colors: colors,
            icon: Icons.music_note_rounded,
            label: 'Key',
            value: keySignature,
            compact: compact,
          ),
        ),
        Gap(compact ? AppSpacing.xs : AppSpacing.sm),
        Expanded(
          child: _InformationCard(
            colors: colors,
            icon: Icons.library_music_outlined,
            label: 'Notes',
            value: '$noteCount/256',
            compact: compact,
            accentColor: noteUsageColor,
          ),
        ),
        Gap(compact ? AppSpacing.xs : AppSpacing.sm),
        Expanded(
          child: _InformationCard(
            colors: colors,
            icon: Icons.speed_rounded,
            label: 'Tempo',
            value: '$tempo BPM',
            compact: compact,
          ),
        ),
        Gap(compact ? AppSpacing.xs : AppSpacing.sm),
        Expanded(
          child: _InformationCard(
            colors: colors,
            icon: Icons.grid_view_rounded,
            label: 'Time',
            value:
                '${editorController.beatsPerMeasure}/${editorController.beatUnit}',
            compact: compact,
          ),
        ),
      ],
    );
  }

  Widget buildLandscapeActions(AppThemeColors colors) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: MeasureActionsButton(
                  colors: colors,
                  enabled: !editorInteractionLocked,
                  canMoveLeft: editorController.currentMeasureIndex > 0,
                  canMoveRight:
                      editorController.currentMeasureIndex <
                      editorController.measureCount - 1,
                  canDelete: editorController.measureCount > 1,
                  onSelected: handleMeasureAction,
                ),
              ),
              const Gap(AppSpacing.xs),
              buildLandscapeAction(
                colors: colors,
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                tooltip: 'Move back using selected duration',
                onTap:
                    editorInteractionLocked ||
                        !editorController.canMoveInsertionCursorBack
                    ? null
                    : moveCursorBack,
              ),
              const Gap(AppSpacing.xs),
              buildLandscapeAction(
                colors: colors,
                icon: Icons.arrow_forward_rounded,
                label: 'Forward',
                tooltip: 'Move forward using selected duration',
                onTap:
                    editorInteractionLocked ||
                        !editorController.canMoveInsertionCursorForward(
                          editorController.selectedDuration,
                        )
                    ? null
                    : moveCursorForward,
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.xs),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildLandscapeAction(
                colors: colors,
                icon: Icons.space_bar_rounded,
                label: 'Rest',
                tooltip: 'Insert rest using selected duration',
                onTap: editorInteractionLocked ? null : insertRest,
              ),
              const Gap(AppSpacing.xs),
              buildLandscapeAction(
                colors: colors,
                icon: showSongOverview
                    ? Icons.view_agenda_rounded
                    : Icons.view_week_outlined,
                label: 'Overview',
                tooltip: 'Show or hide full-song overview',
                onTap: editorInteractionLocked
                    ? null
                    : () {
                        setState(() {
                          showSongOverview = !showSongOverview;
                        });
                      },
              ),
              const Gap(AppSpacing.xs),
              buildLandscapeAction(
                colors: colors,
                icon: Icons.save_outlined,
                label: isSaving ? 'Saving' : 'Save',
                tooltip: 'Save composition',
                onTap: editorInteractionLocked ? null : saveComposition,
                filled: true,
                showLoading: isSaving,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildMeasureActions(AppThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: MeasureActionsButton(
            colors: colors,
            enabled: !editorInteractionLocked,
            canMoveLeft: editorController.currentMeasureIndex > 0,
            canMoveRight:
                editorController.currentMeasureIndex <
                editorController.measureCount - 1,
            canDelete: editorController.measureCount > 1,
            onSelected: handleMeasureAction,
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed:
                  editorInteractionLocked ||
                      !editorController.canMoveInsertionCursorBack
                  ? null
                  : moveCursorBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed:
                  editorInteractionLocked ||
                      !editorController.canMoveInsertionCursorForward(
                        editorController.selectedDuration,
                      )
                  ? null
                  : moveCursorForward,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Forward'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: editorInteractionLocked ? null : insertRest,
              icon: const Icon(Icons.space_bar_rounded),
              label: const Text('Insert Rest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildHistoryControls(AppThemeColors colors, {bool compact = false}) {
    final hasSelection = editorController.selectedNoteIds.isNotEmpty;
    final selectedNotes = editorController.selectedNotes;
    final isTieActive =
        selectedNotes.isNotEmpty &&
        selectedNotes.every((note) => note.tieToNext);

    return CompositionHistoryControls(
      colors: colors,
      enabled: !editorInteractionLocked,
      compact: compact,
      canUndo: editorController.canUndo,
      canRedo: editorController.canRedo,
      canCopy: hasSelection,
      canPaste: editorController.hasClipboard,
      canSelectAll: editorController.notes.isNotEmpty,
      canToggleTie: hasSelection,
      isTieActive: isTieActive,
      canDeleteSelection: hasSelection,
      canDeleteChord: hasSelection || editorController.isBuildingChord,
      onUndo: undo,
      onRedo: redo,
      onCopy: copySelection,
      onPaste: pasteSelection,
      onSelectAll: selectAllNotes,
      onToggleTie: toggleSelectedTies,
      onDeleteSelection: deleteSelectedNotes,
      onDeleteChord: deleteSelectedChord,
    );
  }

  Widget buildLandscapeAction({
    required AppThemeColors colors,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback? onTap,
    bool filled = false,
    bool showLoading = false,
  }) {
    final enabled = onTap != null;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Opacity(
          opacity: enabled || showLoading ? 1 : 0.42,
          child: Material(
            color: filled ? colors.primaryColor : colors.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(
                color: filled ? colors.primaryColor : colors.borderColor,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showLoading)
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.backgroundColor,
                      ),
                    )
                  else
                    Icon(
                      icon,
                      size: 16,
                      color: filled
                          ? colors.backgroundColor
                          : colors.primaryColor,
                    ),
                  const Gap(3),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: filled
                            ? colors.backgroundColor
                            : colors.primaryColor,
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSelectedNoteCard(AppThemeColors colors) {
    final note = editorController.selectedNote!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.primaryColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: colors.backgroundColor,
              size: AppIconSizes.md,
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${note.pitch}${note.octave}',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  'Measure ${note.measureIndex + 1}  •  '
                  'Beat ${formatBeatValue(note.startBeat + 1)}  •  '
                  '${formatBeatValue(note.durationBeats)} '
                  '${note.durationBeats == 1 ? 'beat' : 'beats'}'
                  '${note.tieToNext ? '  •  Tied' : ''}',
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear selection',
            onPressed: editorInteractionLocked
                ? null
                : () {
                    setState(() {
                      editorController.clearSelection();
                    });
                  },
            icon: Icon(Icons.close_rounded, color: colors.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget buildEditorActions(AppThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: editorInteractionLocked ? null : addMeasure,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Measure'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                disabledForegroundColor: colors.secondaryTextColor,
                side: BorderSide(color: colors.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed:
                  editorController.selectedNoteIds.isEmpty ||
                      editorInteractionLocked
                  ? null
                  : deleteSelectedNotes,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete Selection'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                disabledForegroundColor: colors.secondaryTextColor,
                side: BorderSide(color: colors.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSaveButton(AppThemeColors colors) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          border: Border(top: BorderSide(color: colors.borderColor)),
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: editorInteractionLocked ? null : saveComposition,
            icon: isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.backgroundColor,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              isSaving ? 'Saving...' : 'Save Composition',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: colors.backgroundColor,
              disabledBackgroundColor: colors.borderColor,
              disabledForegroundColor: colors.secondaryTextColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> connectToMidi() async {
    if (isConnectingMidi || midiIsConnected || midiStepIsBusy) {
      return;
    }

    setState(() {
      isConnectingMidi = true;
      midiStatus = 'Searching for MIDI piano';
    });

    try {
      final devices = await midiInputService.getDevices();
      if (!mounted) return;

      if (devices.isEmpty) {
        setState(() {
          isConnectingMidi = false;
          midiStatus = 'No MIDI piano detected';
        });
        showMessage('No MIDI piano was detected. Check the cable and try again.');
        return;
      }

      final device = devices.first;
      setState(() {
        midiStatus = 'Connecting to ${device.name}';
      });

      await midiInputService.connectToDevice(device);
      if (!mounted) return;

      setState(() {
        isConnectingMidi = false;
        midiStatus = 'Connected: ${device.name}';
        isChordMode = false;
        editorController.finishChord();
        editorController.selectedDuration = 1;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isConnectingMidi = false;
        midiStatus = 'MIDI connection failed';
      });
      showMessage('The MIDI piano could not be connected.');
    }
  }

  Future<void> disconnectMidi() async {
    await midiInputService.disconnect();
  }

  void handleMidiConnectionChanged(bool connected) {
    if (!mounted) return;

    final deviceName = midiInputService.connectedDevice?.name;

    setState(() {
      isConnectingMidi = false;
      midiStatus = connected
          ? deviceName == null
                ? 'MIDI piano connected'
                : 'Connected: $deviceName'
          : 'MIDI piano disconnected';
    });

    if (connected) return;
    cancelPendingMidiStep(
      message: 'MIDI disconnected. The unfinished note was not added.',
    );
  }

  void handleMidiNoteEvent(MidiNoteEvent event) {
    if (!mounted || !midiIsConnected || isApplyingMidiStep) {
      return;
    }

    if (event.type == MidiNoteEventType.noteOff) {
      finishPendingMidiKey(event.noteNumber);
      return;
    }

    if (!PianoNote.isValidMidi(event.noteNumber)) {
      showMessage('That piano key is outside the supported A0 to C8 range.');
      return;
    }

    if (pendingMidiStepNotes.isEmpty) {
      if (isSaving || isPlaying) return;

      if (editorController.selectedNoteIds.length > 1) {
        showMessage(
          'Select only one note, or clear the selection, before playing.',
        );
        return;
      }

      midiStepStartAbsoluteBeat = editorController.insertionAbsoluteBeat;
      midiStepReplacesSelectedNote =
          editorController.selectedNoteIds.length == 1;
      midiStepStopwatch
        ..stop()
        ..reset()
        ..start();
      midiChordWindowIsOpen = true;
      midiChordWindowTimer?.cancel();
      midiChordWindowTimer = Timer(const Duration(milliseconds: 100), () {
        midiChordWindowIsOpen = false;
      });
    } else if (!midiChordWindowIsOpen) {
      return;
    }

    if (pendingMidiStepNotes.containsKey(event.noteNumber)) {
      return;
    }

    pendingMidiStepNotes[event.noteNumber] = _PendingMidiStepNote(
      noteNumber: event.noteNumber,
      velocity: event.velocity,
      pressedAt: midiStepStopwatch.elapsed,
    );

    setState(() {});
  }

  void finishPendingMidiKey(int noteNumber) {
    final pendingNote = pendingMidiStepNotes[noteNumber];
    if (pendingNote == null || pendingNote.releasedAt != null) {
      return;
    }

    final releasedAt = midiStepStopwatch.elapsed;
    pendingNote.releasedAt = releasedAt > pendingNote.pressedAt
        ? releasedAt
        : pendingNote.pressedAt + const Duration(milliseconds: 1);

    final allKeysReleased = pendingMidiStepNotes.values.every((note) {
      return note.releasedAt != null;
    });

    if (allKeysReleased) {
      finalizeMidiStep();
    }
  }

  void finalizeMidiStep() {
    if (pendingMidiStepNotes.isEmpty || isApplyingMidiStep) {
      return;
    }

    final stepNotes = pendingMidiStepNotes.values.toList();
    if (stepNotes.any((note) => note.releasedAt == null)) {
      return;
    }

    if (midiStepReplacesSelectedNote && stepNotes.length > 1) {
      cancelPendingMidiStep();
      showMessage(
        'Clear the selected note before entering a chord.',
      );
      return;
    }

    isApplyingMidiStep = true;
    midiChordWindowTimer?.cancel();
    midiStepStopwatch.stop();
    setState(() {
      isApplyingMidiStep = true;
    });

    var longestHold = Duration.zero;
    for (final note in stepNotes) {
      final holdDuration = note.releasedAt! - note.pressedAt;
      if (holdDuration > longestHold) {
        longestHold = holdDuration;
      }
    }

    final processor = CompositionMidiProcessor(
      tempo: tempo,
      beatUnit: editorController.beatUnit,
      beatsPerMeasure: editorController.beatsPerMeasure,
    );
    final rawDurationBeats = processor.ticksToCompositionBeats(
      processor.timeToTicks(longestHold),
    );
    final stepDuration = nearestStandardMidiDuration(rawDurationBeats);
    final durationTicks = processor.compositionBeatsToTicks(stepDuration);
    final quantizedNotes = stepNotes.map((note) {
      return QuantizedNote(
        noteNumber: note.noteNumber,
        velocity: note.velocity,
        startTick: 0,
        durationTicks: durationTicks,
      );
    }).toList();
    final compositionNotes = processor.createCompositionNotes(
      quantizedNotes,
      startAbsoluteBeat: midiStepStartAbsoluteBeat,
      idPrefix: 'manual-midi-step',
    );
    final errorMessage = editorController.applyMidiStep(
      compositionNotes,
      stepEndAbsoluteBeat: midiStepStartAbsoluteBeat + stepDuration,
      stepDurationBeats: stepDuration,
      replaceSelectedNote: midiStepReplacesSelectedNote,
    );

    pendingMidiStepNotes.clear();
    midiStepStopwatch.reset();
    midiChordWindowIsOpen = false;
    midiStepReplacesSelectedNote = false;
    isApplyingMidiStep = false;
    setState(() {
      if (errorMessage == null) {
        updateDirtyState();
      }
    });

    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }
  }

  double nearestStandardMidiDuration(double rawDurationBeats) {
    final durations = editorController.beatUnit == 8
        ? const <double>[0.5, 2 / 3, 1, 1.5, 2, 3, 4, 6, 8]
        : const <double>[0.25, 0.5, 2 / 3, 0.75, 1, 1.5, 2, 3, 4];
    var nearestDuration = durations.first;
    var nearestDistance = (rawDurationBeats - nearestDuration).abs();

    for (final duration in durations.skip(1)) {
      final distance = (rawDurationBeats - duration).abs();
      if (distance < nearestDistance) {
        nearestDuration = duration;
        nearestDistance = distance;
      }
    }

    return nearestDuration;
  }

  void cancelPendingMidiStep({String? message}) {
    if (pendingMidiStepNotes.isEmpty && !isApplyingMidiStep) return;

    midiChordWindowTimer?.cancel();
    midiStepStopwatch
      ..stop()
      ..reset();
    pendingMidiStepNotes.clear();
    midiChordWindowIsOpen = false;
    midiStepReplacesSelectedNote = false;
    isApplyingMidiStep = false;

    if (mounted) {
      setState(() {});
      if (message != null) {
        showMessage(message);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused) {
      return;
    }

    cancelPendingMidiStep();
  }

  void changeMeasure(int measureIndex) {
    if (editorInteractionLocked) return;

    setState(() {
      editorController.changeMeasure(measureIndex);
    });
  }

  void selectNote(String noteId) {
    if (editorInteractionLocked) return;

    setState(() {
      editorController.selectNote(noteId);
    });
  }

  void toggleNoteSelection(String noteId) {
    if (editorInteractionLocked) return;

    setState(() {
      editorController.toggleNoteSelection(noteId);
    });
  }

  void moveNote(String noteId, double startBeat) {
    if (editorInteractionLocked) return;

    if (!editorController.selectedNoteIds.contains(noteId)) {
      final sourceNote = editorController.notes.firstWhere((note) {
        return note.id == noteId;
      });
      final chordIds = editorController.notes
          .where((note) {
            return note.measureIndex == sourceNote.measureIndex &&
                editorController.sameTiming(
                  note.startBeat,
                  sourceNote.startBeat,
                );
          })
          .map((note) => note.id);
      editorController.selectNotes(chordIds);
    }

    final errorMessage = editorController.moveSelectedNotes(
      measureIndex: editorController.currentMeasureIndex,
      startBeat: startBeat,
      allowStacking: isChordMode,
    );
    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }

    setState(() {
      updateDirtyState();
    });
  }

  void changeDuration(double durationBeats) {
    if (editorInteractionLocked) {
      showMessage('Stop playback before editing the composition.');
      return;
    }

    final errorMessage = editorController.changeDuration(durationBeats);

    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }

    setState(() {
      updateDirtyState();
    });
  }

  void toggleChordMode(bool value) {
    setState(() {
      isChordMode = value;

      if (value) {
        editorController.startChordFromSelectedNote();
      } else {
        editorController.finishChord();
      }
    });
  }

  void finishChord() {
    setState(() {
      editorController.finishChord();
    });
  }

  Future<void> addOrUpdateNote(String pitch, int octave, int midiNumber) async {
    if (editorInteractionLocked) return;

    final previousNoteCount = editorController.notes.length;
    final errorMessage = editorController.addOrUpdateNote(
      pitch: pitch,
      octave: octave,
      midiNumber: midiNumber,
      addToChord: isChordMode,
    );

    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }

    setState(() {
      updateDirtyState();
    });

    final noteCount = editorController.notes.length;
    if (noteCount > previousNoteCount &&
        (noteCount == 240 || noteCount == 250 || noteCount == 255)) {
      showMessage(
        'This composition now has $noteCount of the 256 allowed notes.',
      );
    }

    try {
      await playbackService.playPreview(
        midiNumber,
        allowOverlap: isChordMode,
        velocity: editorController.selectedVelocity,
      );
    } catch (_) {
      if (mounted) {
        showMessage('The piano note could not be played.');
      }
    }
  }

  void preloadPianoOctave(int octave) {
    playbackService.preloadPreviewOctave(octave).catchError((_) {});
  }

  void changeSelectedOctave(int octave) {
    final safeOctave = octave.clamp(0, 8).toInt();

    if (selectedOctave != safeOctave) {
      setState(() {
        selectedOctave = safeOctave;
      });
    }

    preloadPianoOctave(safeOctave);
  }

  void addMeasure() {
    final errorMessage = editorController.addMeasure();
    applyEditorResult(errorMessage);
  }

  void insertRest() {
    final errorMessage = editorController.insertRest(
      editorController.selectedDuration,
    );
    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }
    setState(() {});
  }

  void moveCursorBack() {
    final errorMessage = editorController.moveInsertionCursorBack(
      editorController.selectedDuration,
    );
    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }
    setState(() {});
  }

  void moveCursorForward() {
    final errorMessage = editorController.moveInsertionCursorForward(
      editorController.selectedDuration,
    );
    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }
    setState(() {});
  }

  void handleMeasureAction(MeasureAction action) {
    final currentMeasure = editorController.currentMeasureIndex;
    String? errorMessage;
    var changed = true;

    switch (action) {
      case MeasureAction.addAfter:
        errorMessage = editorController.insertMeasure(currentMeasure + 1);
        break;
      case MeasureAction.insertBefore:
        errorMessage = editorController.insertMeasure(currentMeasure);
        break;
      case MeasureAction.duplicate:
        errorMessage = editorController.duplicateMeasure(currentMeasure);
        break;
      case MeasureAction.moveLeft:
        changed = editorController.moveMeasure(
          currentMeasure,
          currentMeasure - 1,
        );
        break;
      case MeasureAction.moveRight:
        changed = editorController.moveMeasure(
          currentMeasure,
          currentMeasure + 1,
        );
        break;
      case MeasureAction.delete:
        changed = editorController.deleteMeasure(currentMeasure);
        break;
    }

    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }
    if (!changed) {
      showMessage('That measure action is not available.');
      return;
    }

    setState(() {
      updateDirtyState();
    });
  }

  void undo() {
    if (!editorController.undo()) return;
    setState(() {
      isChordMode = editorController.isBuildingChord;
      updateDirtyState();
    });
  }

  void redo() {
    if (!editorController.redo()) return;
    setState(() {
      isChordMode = editorController.isBuildingChord;
      updateDirtyState();
    });
  }

  void copySelection() {
    if (!editorController.copySelectedNotes()) {
      showMessage('Select at least one note first.');
      return;
    }
    setState(() {});
    showMessage('${editorController.clipboardNoteCount} notes copied.');
  }

  void pasteSelection() {
    applyEditorResult(
      editorController.pasteNotes(allowStacking: isChordMode),
    );
  }

  void selectAllNotes() {
    setState(() {
      editorController.selectNotes(
        editorController.notes.map((note) => note.id),
      );
    });
  }

  void toggleSelectedTies() {
    final errorMessage = editorController.toggleTieForSelectedNotes();
    applyEditorResult(errorMessage);
  }

  void deleteSelectedNotes() {
    final deletedCount = editorController.deleteSelectedNotes();
    if (deletedCount == 0) {
      showMessage('Select at least one note first.');
      return;
    }
    setState(updateDirtyState);
  }

  void deleteSelectedChord() {
    if (!editorController.deleteSelectedChord()) {
      showMessage('Select a chord first.');
      return;
    }
    setState(updateDirtyState);
  }

  void applyEditorResult(String? errorMessage) {
    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }
    setState(updateDirtyState);
  }

  void changeVolume(double value) {
    setState(() {
      volume = value;
    });
    playbackService.setVolume(value).catchError((_) {});
  }

  void changeVelocity(double value) {
    if (editorInteractionLocked) return;

    final changesSavedNotes = editorController.selectedNoteIds.isNotEmpty;
    final errorMessage = editorController.changeVelocity(value);
    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }

    setState(() {
      if (changesSavedNotes) updateDirtyState();
    });
  }

  void changePlayFromCursor(bool value) {
    setState(() => playFromCurrentBeat = value);
  }

  void changeLoop(bool value) {
    setState(() {
      isLoopEnabled = value;

      if (value) {
        playFromCurrentBeat = false;
      }
    });
  }

  void changeSustain(bool value) {
    playbackService.sustainEnabled = value;
    setState(() => isSustainEnabled = value);
  }

  void changeMetronome(bool value) {
    playbackService.metronomeEnabled = value;
    setState(() => isMetronomeEnabled = value);
  }

  Future<void> editSettings() async {
    if (editorInteractionLocked) return;

    final settings = await showDialog<CompositionSettings>(
      context: context,
      builder: (_) {
        return CompositionSettingsDialog(
          colors: widget.colors,
          title: compositionTitle,
          tempo: tempo,
          keySignature: keySignature,
          beatsPerMeasure: editorController.beatsPerMeasure,
          beatUnit: editorController.beatUnit,
        );
      },
    );

    if (settings == null || !mounted) return;

    final settingsUnchanged =
        settings.title == compositionTitle &&
        settings.tempo == tempo &&
        settings.keySignature == keySignature &&
        settings.beatsPerMeasure == editorController.beatsPerMeasure &&
        settings.beatUnit == editorController.beatUnit;
    if (settingsUnchanged) return;

    final errorMessage = editorController.updateTimeSignature(
      beatsPerMeasure: settings.beatsPerMeasure,
      beatUnit: settings.beatUnit,
    );
    if (errorMessage != null) {
      showMessage(errorMessage);
      return;
    }

    setState(() {
      compositionTitle = settings.title;
      tempo = settings.tempo;
      keySignature = settings.keySignature;
      updateDirtyState();
    });
  }

  Future<void> handlePop(bool didPop, Object? result) async {
    if (didPop || isSaving || isDiscarding || isShowingDiscardDialog) {
      return;
    }

    cancelPendingMidiStep();

    if (!isDirty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      isShowingDiscardDialog = true;
    });

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (_) => UnsavedCompositionDialog(colors: widget.colors),
    );

    if (!mounted) return;

    setState(() {
      isShowingDiscardDialog = false;
    });

    if (shouldDiscard != true) return;

    setState(() {
      isDiscarding = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> playOrResumeComposition() async {
    if (isSaving || midiStepIsBusy) return;

    if (isPaused) {
      await playbackService.resume();

      if (!mounted) return;

      setState(() {
        isPlaying = playbackService.isPlaying;
        isPaused = playbackService.isPaused;
      });

      return;
    }

    if (editorController.notes.isEmpty) {
      showMessage('Add at least one note before playing.');
      return;
    }

    final playbackComposition = buildCurrentComposition();
    final validationError = compositionService.validateComposition(
      playbackComposition,
    );
    if (validationError != null) {
      showMessage(validationError);
      return;
    }

    final selectedMeasureIndex = editorController.currentMeasureIndex;
    final playbackStartBeat = isLoopEnabled
        ? (selectedMeasureIndex * editorController.beatsPerMeasure).toDouble()
        : playFromCurrentBeat
        ? (selectedMeasureIndex * editorController.beatsPerMeasure) +
              editorController.insertionBeat
        : 0.0;

    setState(() {
      isPlaying = true;
      isPaused = false;
      isPreparingPlayback = true;
      playingNoteId = null;
      playingNoteIds = {};
      playbackMeasureIndex =
          (playbackStartBeat / editorController.beatsPerMeasure).floor();
    });

    try {
      await playbackService.playComposition(
        composition: playbackComposition,
        startBeat: playbackStartBeat,
        loopMeasureIndex: isLoopEnabled ? selectedMeasureIndex : null,
        onPlaybackStarted: () {
          if (!mounted) return;
          setState(() {
            isPreparingPlayback = false;
          });
        },
        onActiveNotesChanged: (noteIds) {
          if (!mounted) return;
          setState(() {
            playingNoteIds = noteIds;
          });
        },
        onNoteChanged: (note) {
          if (!mounted) return;

          setState(() {
            playingNoteId = note?.id;
            if (note != null) playbackMeasureIndex = note.measureIndex;
          });
        },
      );
    } catch (_) {
      if (mounted) {
        showMessage(
          'The composition could not be played. Check the piano audio files.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPlaying = false;
          isPaused = false;
          isPreparingPlayback = false;
          playingNoteId = null;
          playingNoteIds = {};
          playbackMeasureIndex = null;
        });
      }
    }
  }

  Future<void> pauseComposition() async {
    if (isPreparingPlayback) return;

    await playbackService.pause();

    if (!mounted) return;

    setState(() {
      isPlaying = playbackService.isPlaying;
      isPaused = playbackService.isPaused;
    });
  }

  Future<void> stopComposition() async {
    await playbackService.stop();

    if (!mounted) return;

    setState(() {
      isPlaying = false;
      isPaused = false;
      isPreparingPlayback = false;
      playingNoteId = null;
      playingNoteIds = {};
      playbackMeasureIndex = null;
    });
  }

  Composition buildCurrentComposition() {
    return Composition(
      id: compositionId,
      ownerId: widget.composition.ownerId,
      title: compositionTitle,
      tempo: tempo,
      measureCount: editorController.measureCount,
      notes: editorController.sortedNotes,
      creationMethod: widget.composition.creationMethod,
      keySignature: keySignature,
      beatsPerMeasure: editorController.beatsPerMeasure,
      beatUnit: editorController.beatUnit,
      createdAt: widget.composition.createdAt,
      updatedAt: widget.composition.updatedAt,
    );
  }

  Set<int> get highlightedPianoMidiNumbers {
    if (!isPlaying) return editorController.activeChordMidiNumbers;

    return editorController.notes
        .where((note) => playingNoteIds.contains(note.id))
        .map((note) => note.midiNumber)
        .toSet();
  }

  Future<void> saveComposition() async {
    if (editorInteractionLocked) return;

    final updatedComposition = buildCurrentComposition();
    final validationError = compositionService.validateComposition(
      updatedComposition,
    );
    if (validationError != null) {
      showMessage(validationError);
      return;
    }

    setState(() {
      isSaving = true;
    });

    var compositionWasSaved = false;
    var savedComposition = updatedComposition;

    try {
      if (compositionId.isEmpty) {
        compositionId = await compositionService.createComposition(
          updatedComposition,
        );

        savedComposition = updatedComposition.copyWith(
          id: compositionId,
        );
      } else {
        await compositionService.updateComposition(updatedComposition);
      }

      compositionWasSaved = true;

      await compositionGenerationService.generateCompositionFiles(
        savedComposition,
      );

      if (!mounted) return;

      setState(() {
        savedFingerprint = compositionFingerprint(savedComposition);
        isDirty = false;
      });

      Navigator.pop(context, compositionId);
    } catch (_) {
      if (!mounted) return;

      if (compositionWasSaved) {
        setState(() {
          savedFingerprint = compositionFingerprint(savedComposition);
          isDirty = false;
        });

        showMessage(
          'Your composition was saved safely, but its sheet music and '
          'playback files are not ready yet.',
        );

        Navigator.pop(context, compositionId);
      } else {
        showMessage('The composition could not be saved.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  String formatBeatValue(double value) {
    final wholeValue = value.round();
    if ((value - wholeValue).abs() < 0.001) return '$wholeValue';

    final fractions = <double, String>{
      1 / 12: '1/12',
      1 / 6: '1/6',
      0.25: '1/4',
      1 / 3: '1/3',
      5 / 12: '5/12',
      0.5: '1/2',
      7 / 12: '7/12',
      2 / 3: '2/3',
      0.75: '3/4',
      5 / 6: '5/6',
      11 / 12: '11/12',
    };
    final whole = value.floor();
    final fraction = value - whole;

    for (final entry in fractions.entries) {
      if ((fraction - entry.key).abs() < 0.01) {
        return whole == 0 ? entry.value : '$whole ${entry.value}';
      }
    }

    return value.toStringAsFixed(2);
  }

  String compositionFingerprint(Composition composition) {
    return composition.toMap().toString();
  }

  void updateDirtyState() {
    final currentFingerprint = compositionFingerprint(
      buildCurrentComposition(),
    );
    isDirty =
        savedFingerprint == null || currentFingerprint != savedFingerprint;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
    this.accentColor,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String label;
  final String value;
  final bool compact;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 44 : 78,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDarkMode ? 0.16 : 0.04,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: compact
          ? Row(
              children: [
                Icon(icon, color: accentColor ?? colors.primaryColor, size: 16),
                const Gap(AppSpacing.xs),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accentColor ?? colors.primaryColor,
                          fontSize: AppTextSizes.caption,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: accentColor ?? colors.primaryColor,
                      size: AppIconSizes.sm,
                    ),
                    const Gap(AppSpacing.xs),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: AppTextSizes.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: accentColor ?? colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PendingMidiStepNote {
  _PendingMidiStepNote({
    required this.noteNumber,
    required this.velocity,
    required this.pressedAt,
  });

  final int noteNumber;
  final int velocity;
  final Duration pressedAt;
  Duration? releasedAt;
}
