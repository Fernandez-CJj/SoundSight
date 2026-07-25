import 'package:flutter/material.dart';

import '../../domain/snap_value.dart';
import '../../domain/editor_note.dart';
import '../controllers/midi_editor_controller.dart';
import '../widgets/piano_key_geometry.dart';
import '../widgets/piano_roll_view.dart';

class MidiEditorScreen extends StatefulWidget {
  const MidiEditorScreen({super.key});

  @override
  State<MidiEditorScreen> createState() => _MidiEditorScreenState();
}

class _MidiEditorScreenState extends State<MidiEditorScreen> {
  late final MidiEditorController controller;

  @override
  void initState() {
    super.initState();
    controller = MidiEditorController()..addListener(_showErrors);
  }

  @override
  void dispose() {
    controller.removeListener(_showErrors);
    controller.dispose();
    super.dispose();
  }

  void _showErrors() {
    final message = controller.errorMessage;
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showNoteProperties() async {
    final id = controller.selectedId;
    final note = id == null ? null : controller.noteById(id);
    if (note == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _NotePropertiesDialog(note: note, onApply: controller.updateSelected),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Scaffold(
          backgroundColor: const Color(0xFF050505),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _PerformanceToolbar(controller: controller, onProperties: _showNoteProperties),
                    Expanded(
                      child: controller.hasProject
                          ? PianoRollView(controller: controller)
                          : _EmptyState(onImport: controller.importMidi),
                    ),
                  ],
                ),
                if (controller.isBusy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x99000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _NotePropertiesDialog extends StatefulWidget {
  const _NotePropertiesDialog({required this.note, required this.onApply});

  final EditorNote note;
  final void Function({required int pitch, required int startTick, required int durationTicks, required int velocity}) onApply;

  @override
  State<_NotePropertiesDialog> createState() => _NotePropertiesDialogState();
}

class _NotePropertiesDialogState extends State<_NotePropertiesDialog> {
  late final TextEditingController _start;
  late final TextEditingController _duration;
  late int _pitch;
  late int _velocity;

  @override
  void initState() {
    super.initState();
    _start = TextEditingController(text: widget.note.startTick.toString());
    _duration = TextEditingController(text: widget.note.durationTicks.toString());
    _pitch = widget.note.pitch;
    _velocity = widget.note.velocity;
  }

  @override
  void dispose() {
    _start.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text('Note ${PianoKeyGeometry.noteName(_pitch)}'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const SizedBox(width: 58, child: Text('Pitch')),
                Expanded(child: Slider(value: _pitch.toDouble(), min: 21, max: 108, divisions: 87, label: PianoKeyGeometry.noteName(_pitch), onChanged: (value) => setState(() => _pitch = value.round()))),
                SizedBox(width: 42, child: Text(PianoKeyGeometry.noteName(_pitch))),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: _start, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Start time', suffixText: 'ticks'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration', suffixText: 'ticks'))),
              ]),
              Row(children: [
                const SizedBox(width: 58, child: Text('Volume')),
                Expanded(child: Slider(value: _velocity.toDouble(), min: 1, max: 127, divisions: 126, label: '$_velocity', onChanged: (value) => setState(() => _velocity = value.round()))),
                SizedBox(width: 42, child: Text('$_velocity')),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final startTick = int.tryParse(_start.text);
              final durationTicks = int.tryParse(_duration.text);
              if (startTick == null || durationTicks == null) return;
              widget.onApply(pitch: _pitch, startTick: startTick, durationTicks: durationTicks, velocity: _velocity);
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      );
}

class _PerformanceToolbar extends StatelessWidget {
  const _PerformanceToolbar({required this.controller, required this.onProperties});

  final MidiEditorController controller;
  final VoidCallback onProperties;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF1685B9),
        child: SizedBox(
          height: 54,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(0, 38)),
                  child: const Text('Back'),
                ),
              ),
              const VerticalDivider(width: 22, thickness: 1, color: Color(0x553DD0FF)),
              IconButton(
                tooltip: controller.isPlaying ? 'Pause' : 'Play from current position',
                onPressed: controller.hasProject ? () => controller.isPlaying ? controller.pause() : controller.play() : null,
                icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                tooltip: 'Stop and return to beginning',
                onPressed: controller.hasProject ? controller.stop : null,
                icon: const Icon(Icons.stop),
              ),
              IconButton(
                tooltip: 'Selected note properties',
                onPressed: controller.selectedId == null ? null : onProperties,
                icon: const Icon(Icons.edit_note),
              ),
              Tooltip(
                message: 'Add note on empty roll tap',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 20),
                    Switch(
                      value: controller.addNoteMode,
                      onChanged: controller.hasProject ? controller.setAddNoteMode : null,
                    ),
                  ],
                ),
              ),
              IconButton(tooltip: 'Keyboard zoom out: show one more octave', onPressed: controller.zoomKeyboardOut, icon: const Icon(Icons.zoom_out)),
              IconButton(tooltip: 'Keyboard zoom in: show one fewer octave', onPressed: controller.zoomKeyboardIn, icon: const Icon(Icons.zoom_in)),
              const VerticalDivider(width: 14, thickness: 1, color: Color(0x553DD0FF)),
              IconButton(
                tooltip: 'Slower tempo',
                onPressed: () => controller.setTempoFactor((controller.tempoFactor - .05).clamp(.5, 1.5)),
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(controller.tempoFactor * 100).round()}%', style: const TextStyle(fontSize: 20, height: 1)),
                    const Text('Tempo', style: TextStyle(fontSize: 11, height: 1.2)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Faster tempo',
                onPressed: () => controller.setTempoFactor((controller.tempoFactor + .05).clamp(.5, 1.5)),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 12),
              IconButton(tooltip: 'Undo', onPressed: controller.canUndo ? controller.undo : null, icon: const Icon(Icons.undo)),
              IconButton(tooltip: 'Redo', onPressed: controller.canRedo ? controller.redo : null, icon: const Icon(Icons.redo)),
              IconButton(tooltip: 'Import MIDI', onPressed: controller.isBusy ? null : controller.importMidi, icon: const Icon(Icons.folder_open)),
              IconButton(tooltip: 'Save corrected MIDI', onPressed: controller.hasProject && !controller.isBusy ? controller.exportMidi : null, icon: const Icon(Icons.save)),
              PopupMenuButton<SnapValue>(
                tooltip: 'Snap: ${controller.snap.label}',
                icon: const Icon(Icons.settings),
                onSelected: controller.setSnap,
                itemBuilder: (context) => [
                  for (final value in SnapValue.values)
                    CheckedPopupMenuItem(value: value, checked: value == controller.snap, child: Text('Snap ${value.label}')),
                ],
              ),
            ],
            ),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport});
  final VoidCallback onImport;
  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton.icon(onPressed: onImport, icon: const Icon(Icons.folder_open), label: const Text('Import Audiveris MIDI')),
      );
}
