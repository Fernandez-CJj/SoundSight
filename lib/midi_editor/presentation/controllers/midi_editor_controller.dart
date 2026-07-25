import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:dart_midi_pro/dart_midi_pro.dart';

import '../../data/midi_editor_repository.dart';
import '../../domain/editor_note.dart';
import '../../domain/midi_project.dart';
import '../../domain/snap_value.dart';
import '../services/midi_playback_service.dart';
import '../widgets/piano_key_geometry.dart';

class MidiEditorController extends ChangeNotifier {
  MidiEditorController({
    MidiEditorRepository? repository,
    MidiPlaybackService? playback,
  })  : _repository = repository ?? MidiEditorRepository(),
        _playback = playback ?? MidiPlaybackService();

  static const int lowPitch = 21;
  static const int highPitch = 108;

  final MidiEditorRepository _repository;
  final MidiPlaybackService _playback;
  final _undo = <_Snapshot>[];
  final _redo = <_Snapshot>[];

  MidiProject? _project;
  List<EditorNote> _notes = const [];
  Set<String> _deletedNoteIds = const {};
  String? _selectedId;
  String? _filePath;
  EditorNote? _editingOriginalNote;
  String? errorMessage;
  bool isBusy = false;
  bool isPlaying = false;
  bool addNoteMode = false;
  int keyboardZoom = 0;
  int playheadTick = 0;
  double tempoFactor = 1;
  SnapValue snap = SnapValue.sixteenth;
  double horizontalZoom = 1;
  double verticalZoom = 1;
  Timer? _playheadTimer;
  bool _isPollingPlayback = false;

  MidiProject? get project => _project;
  List<EditorNote> get notes => _notes;
  String get fileName => _project?.fileName ?? 'No MIDI loaded';
  int get ticksPerQuarter => _project?.ticksPerQuarter ?? 480;
  int get lastTick => max(_project?.lastTick ?? 0, _notes.fold(0, (v, n) => max(v, n.endTick)));
  String? get selectedId => _selectedId;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get hasProject => _project != null;
  List<EditorNote> get activeNotes =>
      _notes.where((note) => !_deletedNoteIds.contains(note.id)).toList(growable: false);
  Set<int> get soundingPitches => {
        for (final note in activeNotes)
          if (playheadTick >= note.startTick && playheadTick < note.endTick) note.pitch,
      };

  EditorNote? noteById(String id) {
    for (final note in _notes) {
      if (note.id == id && !_deletedNoteIds.contains(id)) {
        return note;
      }
    }
    return null;
  }

  Future<void> importMidi() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mid', 'midi'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    await _runBusy(() async {
      final imported = await _repository.importFile(File(path));
      _project = imported;
      _filePath = path;
      _notes = imported.notes.map((note) {
        note.noteOn.velocity = 88;
        return note.copyWith(velocity: 88);
      }).toList(growable: false);
      _deletedNoteIds = const {};
      _selectedId = null;
      _undo.clear();
      _redo.clear();
      playheadTick = 0;
      await _reloadPlayback();
    });
  }

  Future<void> exportMidi() async {
    final project = _project;
    if (project == null) {
      return;
    }

    await _runBusy(() async {
      final bytes = _exportBytes();
      final name = _suggestedExportName();
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save corrected MIDI',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: const ['mid', 'midi'],
        bytes: bytes,
      );
    });
  }

  void selectAt({
    required double x,
    required double y,
    required double pixelsPerTick,
    required double rowHeight,
    required bool landscape,
  }) {
    final id = hitTest(
      x: x,
      y: y,
      pixelsPerTick: pixelsPerTick,
      rowHeight: rowHeight,
      landscape: landscape,
    );
    _selectedId = id;
    notifyListeners();
  }

  void selectNote(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  String? hitTest({
    required double x,
    required double y,
    required double pixelsPerTick,
    required double rowHeight,
    required bool landscape,
  }) {
    for (final note in activeNotes.reversed) {
      final rect = _noteRect(note, pixelsPerTick, rowHeight, landscape);
      if (rect.inflate(6).contains(_Point(x, y))) {
        return note.id;
      }
    }
    return null;
  }

  bool isOnResizeHandle({
    required EditorNote note,
    required double x,
    required double y,
    required double pixelsPerTick,
    required double rowHeight,
    required bool landscape,
  }) {
    final rect = _noteRect(note, pixelsPerTick, rowHeight, landscape);
    if (!rect.inflate(8).contains(_Point(x, y))) {
      return false;
    }
    return landscape ? (rect.bottom - y).abs() <= 14 : (rect.right - x).abs() <= 14;
  }

  void moveSelected({
    required int deltaTicks,
    required int deltaPitch,
  }) {
    final selected = _editingOriginalNote ?? _selectedNote();
    if (selected == null) {
      return;
    }
    final next = selected.copyWith(
      startTick: snap.snapTick(selected.startTick + deltaTicks, ticksPerQuarter),
      pitch: (selected.pitch + deltaPitch).clamp(lowPitch, highPitch),
    );
    _replaceNote(_withoutSameLaneOverlap(next, selected.id));
    notifyListeners();
  }

  void resizeSelected(int deltaTicks) {
    final selected = _editingOriginalNote ?? _selectedNote();
    if (selected == null) {
      return;
    }
    final minimum = snap.intervalTicks(ticksPerQuarter);
    final snappedEnd = snap.snapTick(selected.endTick + deltaTicks, ticksPerQuarter);
    final duration = max(minimum, snappedEnd - selected.startTick);
    final next = selected.copyWith(durationTicks: duration);
    _replaceNote(_withoutSameLaneOverlap(next, selected.id));
    notifyListeners();
  }

  void beginSelectedEdit() {
    final selected = _selectedNote();
    if (selected == null || _editingOriginalNote != null) {
      return;
    }
    _pushUndo();
    _redo.clear();
    _editingOriginalNote = selected;
  }

  void endSelectedEdit() {
    if (_editingOriginalNote == null) {
      return;
    }
    _editingOriginalNote = null;
    unawaited(_reloadPlayback());
  }

  void deleteAt({
    required double x,
    required double y,
    required double pixelsPerTick,
    required double rowHeight,
    required bool landscape,
  }) {
    final id = hitTest(
      x: x,
      y: y,
      pixelsPerTick: pixelsPerTick,
      rowHeight: rowHeight,
      landscape: landscape,
    );
    if (id == null) {
      return;
    }
    _pushUndo();
    _deletedNoteIds = {..._deletedNoteIds, id};
    if (_selectedId == id) {
      _selectedId = null;
    }
    _redo.clear();
    notifyListeners();
    unawaited(_reloadPlayback());
  }

  void deleteSelected() {
    if (_selectedId == null) {
      return;
    }
    _pushUndo();
    _deletedNoteIds = {..._deletedNoteIds, _selectedId!};
    _selectedId = null;
    _redo.clear();
    notifyListeners();
    unawaited(_reloadPlayback());
  }

  void updateSelected({
    required int pitch,
    required int startTick,
    required int durationTicks,
    required int velocity,
  }) {
    final selected = _selectedNote();
    if (selected == null) {
      return;
    }
    _pushUndo();
    final resolvedVelocity = velocity.clamp(1, 127);
    selected.noteOn.velocity = resolvedVelocity;
    final next = selected.copyWith(
      pitch: pitch.clamp(lowPitch, highPitch),
      startTick: snap.snapTick(max(0, startTick), ticksPerQuarter),
      durationTicks: max(1, durationTicks),
      velocity: resolvedVelocity,
    );
    _replaceNote(_withoutSameLaneOverlap(next, selected.id));
    _redo.clear();
    notifyListeners();
    unawaited(_reloadPlayback());
  }

  void setAddNoteMode(bool value) {
    addNoteMode = value;
    notifyListeners();
  }

  void zoomKeyboardIn() {
    if (keyboardZoom >= 5) {
      return;
    }
    keyboardZoom++;
    notifyListeners();
  }

  void zoomKeyboardOut() {
    if (keyboardZoom <= 0) {
      return;
    }
    keyboardZoom--;
    notifyListeners();
  }

  void addNoteAt({required int pitch, required int startTick}) {
    if (_project == null) {
      return;
    }
    _pushUndo();
    final template = _selectedNote();
    final duration = snap.intervalTicks(ticksPerQuarter);
    final start = snap.snapTick(max(0, startTick), ticksPerQuarter);
    final noteOn = NoteOnEvent()
      ..channel = template?.channel ?? 0
      ..noteNumber = pitch.clamp(lowPitch, highPitch)
      ..velocity = 88;
    final noteOff = NoteOffEvent()
      ..channel = noteOn.channel
      ..noteNumber = noteOn.noteNumber
      ..velocity = 0;
    final note = EditorNote(
      id: 'new_${DateTime.now().microsecondsSinceEpoch}',
      trackIndex: template?.trackIndex ?? 0,
      channel: noteOn.channel,
      pitch: noteOn.noteNumber,
      startTick: start,
      durationTicks: duration,
      velocity: noteOn.velocity,
      noteOn: noteOn,
      noteOff: noteOff,
      noteOffVelocity: 0,
      originalStartTick: start,
      originalEndTick: start + duration,
    );
    final resolved = _withoutSameLaneOverlap(note, note.id);
    _notes = [..._notes, resolved]..sort((a, b) => a.startTick.compareTo(b.startTick));
    _selectedId = resolved.id;
    _redo.clear();
    notifyListeners();
    unawaited(_reloadPlayback());
  }

  void setSnap(SnapValue value) {
    snap = value;
    notifyListeners();
  }

  void setHorizontalZoom(double value) {
    horizontalZoom = value;
    notifyListeners();
  }

  void setVerticalZoom(double value) {
    verticalZoom = value;
    notifyListeners();
  }

  Future<void> play() async {
    await _reloadPlayback();
    await _playback.seek(playheadTick);
    await _playback.setTempoFactor(tempoFactor);
    await _playback.play();
    isPlaying = true;
    _startPlayheadTimer();
    notifyListeners();
  }

  Future<void> pause() async {
    await _playback.pause();
    isPlaying = false;
    _playheadTimer?.cancel();
    notifyListeners();
  }

  Future<void> stop() async {
    await _playback.stop();
    isPlaying = false;
    playheadTick = 0;
    _playheadTimer?.cancel();
    await _playback.seek(0);
    notifyListeners();
  }

  Future<void> seekToTick(int tick) async {
    playheadTick = tick.clamp(0, lastTick);
    await _playback.seek(playheadTick);
    notifyListeners();
  }

  Future<void> setTempoFactor(double factor) async {
    tempoFactor = factor.clamp(0.5, 1.5);
    await _playback.setTempoFactor(tempoFactor);
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) {
      return;
    }
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
    unawaited(_reloadPlayback());
  }

  void redo() {
    if (_redo.isEmpty) {
      return;
    }
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
    unawaited(_reloadPlayback());
  }

  Uint8List _exportBytes() {
    final project = _project!;
    return _repository.exportProject(project, _notes, _deletedNoteIds);
  }

  Future<void> _reloadPlayback() async {
    final project = _project;
    if (project == null) {
      return;
    }
    await _playback.loadMidi(_exportBytes());
    await _playback.setTempoFactor(tempoFactor);
  }

  void _startPlayheadTimer() {
    _playheadTimer?.cancel();
    _playheadTimer = Timer.periodic(const Duration(milliseconds: 16), (_) async {
      if (_isPollingPlayback) {
        return;
      }
      _isPollingPlayback = true;
      final state = await _playback.state();
      _isPollingPlayback = false;
      if (state == null) {
        return;
      }
      playheadTick = state.currentTick;
      isPlaying = state.isPlaying;
      notifyListeners();
      if (!isPlaying) {
        _playheadTimer?.cancel();
      }
    });
  }

  Future<void> _runBusy(Future<void> Function() body) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await body();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  EditorNote? _selectedNote() => _selectedId == null ? null : noteById(_selectedId!);

  void _replaceNote(EditorNote note) {
    _notes = [
      for (final item in _notes) item.id == note.id ? note : item,
    ]..sort((a, b) => a.startTick.compareTo(b.startTick));
  }

  EditorNote _withoutSameLaneOverlap(EditorNote candidate, String ignoredId) {
    var start = candidate.startTick;
    var end = max(candidate.startTick + 1, candidate.endTick);
    for (final note in activeNotes) {
      if (note.id == ignoredId ||
          note.trackIndex != candidate.trackIndex ||
          note.channel != candidate.channel ||
          note.pitch != candidate.pitch) {
        continue;
      }
      if (end > note.startTick && start < note.endTick) {
        if (candidate.startTick < note.startTick) {
          end = min(end, note.startTick);
        } else {
          start = max(start, note.endTick);
        }
      }
    }
    final minimum = snap.intervalTicks(ticksPerQuarter);
    if (end - start < minimum) {
      end = start + minimum;
    }
    return candidate.copyWith(startTick: max(0, start), durationTicks: max(1, end - start));
  }

  void _pushUndo() {
    _undo.add(_snapshot());
    if (_undo.length > 100) {
      _undo.removeAt(0);
    }
  }

  _Snapshot _snapshot() => _Snapshot(
        notes: List<EditorNote>.from(_notes),
        deletedNoteIds: Set<String>.from(_deletedNoteIds),
        selectedId: _selectedId,
      );

  void _restore(_Snapshot snapshot) {
    _notes = snapshot.notes;
    _deletedNoteIds = snapshot.deletedNoteIds;
    _selectedId = snapshot.selectedId;
    notifyListeners();
  }

  String _suggestedExportName() {
    final source = _filePath == null ? fileName : File(_filePath!).uri.pathSegments.last;
    final dot = source.lastIndexOf('.');
    final stem = dot <= 0 ? source : source.substring(0, dot);
    return '${stem}_corrected.mid';
  }

  @override
  void dispose() {
    _playheadTimer?.cancel();
    unawaited(_playback.dispose());
    super.dispose();
  }
}

class _Snapshot {
  const _Snapshot({
    required this.notes,
    required this.deletedNoteIds,
    required this.selectedId,
  });

  final List<EditorNote> notes;
  final Set<String> deletedNoteIds;
  final String? selectedId;
}

class _Rect {
  const _Rect(this.left, this.top, this.right, this.bottom);
  final double left;
  final double top;
  final double right;
  final double bottom;
  _Rect inflate(double value) => _Rect(left - value, top - value, right + value, bottom + value);
  bool contains(_Point point) =>
      point.x >= left && point.x <= right && point.y >= top && point.y <= bottom;
}

class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}

_Rect _noteRect(EditorNote note, double pixelsPerTick, double rowHeight, bool landscape) {
  final keyStart = PianoKeyGeometry.keyStart(note.pitch, rowHeight);
  final keyWidth = PianoKeyGeometry.keyWidth(note.pitch, rowHeight);
  if (landscape) {
    final left = keyStart;
    final top = note.startTick * pixelsPerTick;
    return _Rect(left, top, left + keyWidth - 2, top + note.durationTicks * pixelsPerTick);
  }

  final left = note.startTick * pixelsPerTick;
  final top = keyStart;
  return _Rect(left, top, left + note.durationTicks * pixelsPerTick, top + keyWidth - 2);
}
