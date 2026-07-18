import 'package:soundsight/screens/composition/composition_note.dart';

class CompositionEditorController {
  CompositionEditorController({
    List<CompositionNote> initialNotes = const [],
    int initialMeasureCount = 1,
    int beatsPerMeasure = 4,
    int beatUnit = 4,
  }) : _beatsPerMeasure = beatsPerMeasure < 1 ? 4 : beatsPerMeasure,
       _beatUnit = beatUnit == 8 ? 8 : 4 {
    _notes.addAll(
      initialNotes.map((note) {
        return note.copyWith(
          startBeat: normalizeTiming(note.startBeat),
          durationBeats: normalizeTiming(note.durationBeats),
        );
      }),
    );

    final lastUsedMeasure = _notes.fold<int>(
      0,
      (largest, note) => note.measureIndex > largest
          ? note.measureIndex
          : largest,
    );

    _measureCount = initialMeasureCount < 1 ? 1 : initialMeasureCount;
    if (_measureCount <= lastUsedMeasure) {
      _measureCount = lastUsedMeasure + 1;
    }
    if (_measureCount > maximumMeasureCount) {
      _measureCount = maximumMeasureCount;
    }
  }

  static const int maximumNoteCount = 256;
  static const int maximumMeasureCount = 128;
  static const int maximumHistoryLength = 100;
  static const double timingStep = CompositionNote.timingStep;
  static const String noteLimitError =
      'A composition can contain up to 256 notes.';
  static const String measureLimitError =
      'A composition can contain up to 128 measures.';

  final List<CompositionNote> _notes = [];
  final Set<String> _selectedNoteIds = {};
  final List<CompositionNote> _clipboard = [];
  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];

  late int _measureCount;
  int _beatsPerMeasure;
  int _beatUnit;
  int? _activeChordMeasureIndex;
  double? _activeChordStartBeat;
  String? _selectedNoteId;
  double _insertionBeat = 0;
  int _idSequence = 0;

  int currentMeasureIndex = 0;
  double selectedDuration = 1;
  double selectedVelocity = 0.8;

  static double normalizeTiming(num value) {
    return CompositionNote.normalizeTiming(value);
  }

  int get measureCount => _measureCount;

  int get beatsPerMeasure => _beatsPerMeasure;

  int get beatUnit => _beatUnit;

  List<CompositionNote> get notes {
    return List<CompositionNote>.unmodifiable(_notes);
  }

  List<CompositionNote> get sortedNotes {
    final result = List<CompositionNote>.from(_notes);
    result.sort((first, second) {
      final measureComparison = first.measureIndex.compareTo(
        second.measureIndex,
      );
      if (measureComparison != 0) {
        return measureComparison;
      }

      final beatComparison = first.startBeat.compareTo(second.startBeat);
      if (beatComparison != 0) {
        return beatComparison;
      }

      return first.midiNumber.compareTo(second.midiNumber);
    });
    return result;
  }

  String? get selectedNoteId => _selectedNoteId;

  set selectedNoteId(String? noteId) {
    if (noteId == null) {
      clearSelection();
      return;
    }

    selectNote(noteId);
  }

  Set<String> get selectedNoteIds {
    return Set<String>.unmodifiable(_selectedNoteIds);
  }

  List<CompositionNote> get selectedNotes {
    return _notes.where((note) => _selectedNoteIds.contains(note.id)).toList();
  }

  CompositionNote? get selectedNote {
    if (_selectedNoteId == null) {
      return null;
    }

    for (final note in _notes) {
      if (note.id == _selectedNoteId) {
        return note;
      }
    }

    return null;
  }

  int? get selectedMidiNumber => selectedNote?.midiNumber;

  double get insertionBeat => _insertionBeat;

  bool get canMoveInsertionCursorBack {
    return currentMeasureIndex > 0 || _insertionBeat > 0;
  }

  bool canMoveInsertionCursorForward(num durationBeats) {
    final duration = normalizeTiming(durationBeats);
    final currentAbsoluteBeat =
        (currentMeasureIndex * _beatsPerMeasure) + _insertionBeat;
    final totalBeats = _measureCount * _beatsPerMeasure;

    return duration > 0 && currentAbsoluteBeat + duration < totalBeats;
  }

  bool get isBuildingChord {
    return _activeChordMeasureIndex != null &&
        _activeChordStartBeat != null;
  }

  int? get activeChordMeasureIndex => _activeChordMeasureIndex;

  double? get activeChordStartBeat => _activeChordStartBeat;

  List<CompositionNote> get activeChordNotes {
    if (!isBuildingChord) {
      return const [];
    }

    return _notes.where((note) {
      return note.measureIndex == _activeChordMeasureIndex &&
          sameTiming(note.startBeat, _activeChordStartBeat!);
    }).toList();
  }

  int get activeChordNoteCount => activeChordNotes.length;

  Set<int> get activeChordMidiNumbers {
    return activeChordNotes.map((note) => note.midiNumber).toSet();
  }

  bool get hasClipboard => _clipboard.isNotEmpty;

  int get clipboardNoteCount => _clipboard.length;

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  String? updateBeatsPerMeasure(int value) {
    return updateTimeSignature(
      beatsPerMeasure: value,
      beatUnit: _beatUnit,
    );
  }

  String? updateTimeSignature({
    required int beatsPerMeasure,
    required int beatUnit,
  }) {
    if (beatsPerMeasure < 1) {
      return 'A measure must contain at least 1 beat.';
    }
    if (beatUnit != 4 && beatUnit != 8) {
      return 'Choose a supported time signature.';
    }

    if (beatsPerMeasure == _beatsPerMeasure && beatUnit == _beatUnit) {
      return null;
    }

    final timingScale = beatUnit / _beatUnit;
    final convertedNotes = _notes.map((note) {
      final scaledStartBeat = note.startBeat * timingScale;
      final scaledDuration = note.durationBeats * timingScale;
      return note.copyWith(
        startBeat: normalizeTiming(scaledStartBeat),
        durationBeats: normalizeTiming(scaledDuration),
      );
    }).toList();

    for (var index = 0; index < _notes.length; index++) {
      final source = _notes[index];
      final converted = convertedNotes[index];
      if ((converted.startBeat - (source.startBeat * timingScale)).abs() >
              0.000001 ||
          (converted.durationBeats -
                      (source.durationBeats * timingScale))
                  .abs() >
              0.000001) {
        return 'Some note timing is too precise for the new time signature.';
      }
    }

    final noteOutsideMeasure = convertedNotes.any((note) {
      return note.startBeat < 0 ||
          note.startBeat >= beatsPerMeasure ||
          note.startBeat + note.durationBeats >
              beatsPerMeasure + timingStep / 2;
    });
    if (noteOutsideMeasure) {
      return 'Some notes do not fit in the new time signature.';
    }

    for (var firstIndex = 0;
        firstIndex < convertedNotes.length;
        firstIndex++) {
      final first = convertedNotes[firstIndex];
      for (var secondIndex = firstIndex + 1;
          secondIndex < convertedNotes.length;
          secondIndex++) {
        final second = convertedNotes[secondIndex];
        if (first.measureIndex != second.measureIndex ||
            first.midiNumber != second.midiNumber) {
          continue;
        }
        if (_rangesOverlap(
          first.startBeat,
          first.startBeat + first.durationBeats,
          second.startBeat,
          second.startBeat + second.durationBeats,
        )) {
          return 'Some notes would overlap in the new time signature.';
        }
      }
    }

    _recordUndo();
    _notes
      ..clear()
      ..addAll(convertedNotes);
    _beatsPerMeasure = beatsPerMeasure;
    _beatUnit = beatUnit;
    _insertionBeat = normalizeTiming(
      (_insertionBeat * timingScale).clamp(
        0,
        beatsPerMeasure - timingStep,
      ),
    );
    selectedDuration = normalizeTiming(
      (selectedDuration * timingScale).clamp(
        timingStep,
        beatsPerMeasure,
      ),
    );

    final selected = selectedNote;
    if (selected != null) {
      selectedDuration = selected.durationBeats;
      selectedVelocity = selected.velocity;
    }
    _removeBrokenTiesWithoutHistory();
    _clearChord();
    return null;
  }

  void changeMeasure(int measureIndex) {
    if (measureIndex < 0 || measureIndex >= _measureCount) {
      return;
    }

    _clearChord();
    currentMeasureIndex = measureIndex;
    _insertionBeat = 0;
    clearSelection();
  }

  String? setInsertionBeat(num startBeat) {
    return setInsertionPosition(
      measureIndex: currentMeasureIndex,
      startBeat: startBeat,
    );
  }

  String? setInsertionPosition({
    required int measureIndex,
    required num startBeat,
  }) {
    final normalizedBeat = normalizeTiming(startBeat);

    if (measureIndex < 0 || measureIndex >= _measureCount) {
      return 'Choose an existing measure.';
    }
    if (normalizedBeat < 0 || normalizedBeat >= _beatsPerMeasure) {
      return 'Choose a position inside the measure.';
    }

    _clearChord();
    currentMeasureIndex = measureIndex;
    _insertionBeat = normalizedBeat;
    clearSelection();
    return null;
  }

  String? moveInsertionCursor(num beatOffset) {
    final currentAbsoluteBeat =
        (currentMeasureIndex * _beatsPerMeasure) + _insertionBeat;
    final targetAbsoluteBeat = normalizeTiming(
      currentAbsoluteBeat + beatOffset,
    );
    final totalBeats = _measureCount * _beatsPerMeasure;

    if (targetAbsoluteBeat < 0 || targetAbsoluteBeat >= totalBeats) {
      return 'The cursor cannot move outside the composition.';
    }

    final measureIndex = (targetAbsoluteBeat / _beatsPerMeasure).floor();
    final startBeat = normalizeTiming(
      targetAbsoluteBeat - (measureIndex * _beatsPerMeasure),
    );
    return setInsertionPosition(
      measureIndex: measureIndex,
      startBeat: startBeat,
    );
  }

  String? insertRest(num durationBeats) {
    final duration = normalizeTiming(durationBeats);
    if (duration <= 0) {
      return 'The rest duration must be greater than 0 beats.';
    }

    return moveInsertionCursor(duration);
  }

  String? moveInsertionCursorBack(num durationBeats) {
    final duration = normalizeTiming(durationBeats);
    if (duration <= 0) {
      return 'The duration must be greater than 0 beats.';
    }

    final currentAbsoluteBeat =
        (currentMeasureIndex * _beatsPerMeasure) + _insertionBeat;
    if (currentAbsoluteBeat <= 0) {
      return 'The cursor is already at the beginning.';
    }

    final distance = duration > currentAbsoluteBeat
        ? currentAbsoluteBeat
        : duration;
    return moveInsertionCursor(-distance);
  }

  String? moveInsertionCursorForward(num durationBeats) {
    final duration = normalizeTiming(durationBeats);
    if (duration <= 0) {
      return 'The duration must be greater than 0 beats.';
    }

    return moveInsertionCursor(duration);
  }

  String? changeDuration(num durationBeats) {
    final duration = normalizeTiming(durationBeats);
    if (duration <= 0) {
      return 'The note duration must be greater than 0 beats.';
    }
    if (duration > _beatsPerMeasure) {
      return 'That duration is longer than a measure.';
    }

    final notesToChange = selectedNotes;
    if (notesToChange.isEmpty) {
      selectedDuration = duration;
      return null;
    }

    final replacements = notesToChange.map((note) {
      return note.copyWith(durationBeats: duration);
    }).toList();
    final validationError = _validateReplacements(replacements);
    if (validationError != null) {
      return validationError;
    }

    _recordUndo();
    for (final replacement in replacements) {
      _replaceNoteWithoutHistory(replacement);
    }
    _removeBrokenTiesWithoutHistory();
    selectedDuration = duration;
    return null;
  }

  String? changeVelocity(num velocity) {
    if (velocity.toDouble() < 0 || velocity.toDouble() > 1) {
      return 'Velocity must be between 0 and 1.';
    }

    final normalizedVelocity = CompositionNote.normalizeVelocity(velocity);
    final notesToChange = selectedNotes;
    if (notesToChange.isEmpty) {
      selectedVelocity = normalizedVelocity;
      return null;
    }

    _recordUndo();
    for (final note in notesToChange) {
      _replaceNoteWithoutHistory(
        note.copyWith(velocity: normalizedVelocity),
      );
    }
    selectedVelocity = normalizedVelocity;
    return null;
  }

  String? toggleTieForSelectedNotes() {
    final notesToChange = selectedNotes;
    if (notesToChange.isEmpty) {
      return 'Select at least one note first.';
    }

    final removeTies = notesToChange.every((note) => note.tieToNext);
    if (!removeTies) {
      final noteWithoutContinuation = notesToChange.any((note) {
        return !_hasTieContinuation(note, _notes);
      });
      if (noteWithoutContinuation) {
        return 'Each selected note needs the same key immediately after it.';
      }
    }

    _recordUndo();
    for (final note in notesToChange) {
      _replaceNoteWithoutHistory(
        note.copyWith(tieToNext: !removeTies),
      );
    }
    return null;
  }

  void selectNote(
    String noteId, {
    bool additive = false,
    bool toggle = false,
  }) {
    final note = _noteById(noteId);
    if (note == null) {
      return;
    }

    _clearChord();

    if (!additive && !toggle) {
      _selectedNoteIds.clear();
    }

    if (toggle && _selectedNoteIds.contains(noteId)) {
      _selectedNoteIds.remove(noteId);
      if (_selectedNoteId == noteId) {
        _selectedNoteId = _selectedNoteIds.isEmpty
            ? null
            : _selectedNoteIds.last;
      }
      return;
    }

    _selectedNoteIds.add(noteId);
    _selectedNoteId = noteId;
    selectedDuration = note.durationBeats;
    selectedVelocity = note.velocity;
    currentMeasureIndex = note.measureIndex;
    _insertionBeat = note.startBeat;
  }

  void toggleNoteSelection(String noteId) {
    selectNote(noteId, additive: true, toggle: true);
  }

  void selectNotes(Iterable<String> noteIds) {
    clearSelection();
    for (final noteId in noteIds) {
      final note = _noteById(noteId);
      if (note == null) {
        continue;
      }
      _selectedNoteIds.add(noteId);
      _selectedNoteId = noteId;
    }

    final primary = selectedNote;
    if (primary != null) {
      selectedDuration = primary.durationBeats;
      selectedVelocity = primary.velocity;
      currentMeasureIndex = primary.measureIndex;
      _insertionBeat = primary.startBeat;
    }
  }

  void clearSelection() {
    _selectedNoteIds.clear();
    _selectedNoteId = null;
  }

  String? addOrUpdateNote({
    required String pitch,
    required int octave,
    required int midiNumber,
    bool addToChord = false,
    int? measureIndex,
    num? startBeat,
    num? durationBeats,
    num? velocity,
  }) {
    final note = selectedNote;

    if (addToChord) {
      if (note != null && !isBuildingChord) {
        startChordFromSelectedNote();
      }

      return addNoteToChord(
        pitch: pitch,
        octave: octave,
        midiNumber: midiNumber,
        durationBeats: durationBeats,
        velocity: velocity,
      );
    }

    if (note != null) {
      final updatedNote = note.copyWith(
        pitch: pitch,
        octave: octave,
        midiNumber: midiNumber,
        durationBeats: durationBeats,
        velocity: velocity,
      );
      final validationError = _validateReplacements([updatedNote]);
      if (validationError != null) {
        return validationError;
      }

      _recordUndo();
      _replaceNoteWithoutHistory(updatedNote);
      return null;
    }

    finishChord();

    final targetMeasureIndex = measureIndex ?? currentMeasureIndex;
    final targetStartBeat = normalizeTiming(startBeat ?? _insertionBeat);
    final beatAlreadyHasNote = _notes.any((existingNote) {
      return existingNote.measureIndex == targetMeasureIndex &&
          sameTiming(existingNote.startBeat, targetStartBeat);
    });

    if (beatAlreadyHasNote) {
      return 'Enable Chord Mode to stack notes on this beat.';
    }

    return addNoteAt(
      pitch: pitch,
      octave: octave,
      midiNumber: midiNumber,
      measureIndex: targetMeasureIndex,
      startBeat: targetStartBeat,
      durationBeats: durationBeats ?? selectedDuration,
      velocity: velocity ?? selectedVelocity,
    );
  }

  String? addNoteAt({
    required String pitch,
    required int octave,
    required int midiNumber,
    required int measureIndex,
    required num startBeat,
    num? durationBeats,
    num? velocity,
    bool selectAddedNote = false,
  }) {
    if (_notes.length >= maximumNoteCount) {
      return noteLimitError;
    }

    final duration = normalizeTiming(durationBeats ?? selectedDuration);
    final beat = normalizeTiming(startBeat);
    final noteVelocity = CompositionNote.normalizeVelocity(
      velocity ?? selectedVelocity,
    );

    if (duration <= 0) {
      return 'The note duration must be greater than 0 beats.';
    }
    if (measureIndex < 0 || measureIndex >= _measureCount) {
      return 'Choose an existing measure.';
    }
    if (!canPlaceNote(
      measureIndex: measureIndex,
      startBeat: beat,
      durationBeats: duration,
      midiNumber: midiNumber,
    )) {
      return _placementError(
        measureIndex: measureIndex,
        startBeat: beat,
        durationBeats: duration,
        midiNumber: midiNumber,
      );
    }

    final newNote = CompositionNote(
      id: createNoteId(),
      pitch: pitch,
      octave: octave,
      midiNumber: midiNumber,
      measureIndex: measureIndex,
      startBeat: beat,
      durationBeats: duration,
      velocity: noteVelocity,
    );

    _recordUndo();
    _notes.add(newNote);
    currentMeasureIndex = measureIndex;
    selectedDuration = duration;
    selectedVelocity = noteVelocity;
    _advanceInsertionCursor(beat + duration);

    if (selectAddedNote) {
      _selectedNoteIds
        ..clear()
        ..add(newNote.id);
      _selectedNoteId = newNote.id;
    }

    return null;
  }

  String? moveSelectedNotes({
    required int measureIndex,
    required num startBeat,
    bool allowStacking = false,
  }) {
    final notesToMove = selectedNotes;
    if (notesToMove.isEmpty) {
      return 'Select at least one note first.';
    }
    if (measureIndex < 0 || measureIndex >= _measureCount) {
      return 'Choose an existing measure.';
    }

    final normalizedStartBeat = normalizeTiming(startBeat);
    if (normalizedStartBeat < 0 ||
        normalizedStartBeat >= _beatsPerMeasure) {
      return 'Choose a position inside the measure.';
    }

    final targetAbsoluteBeat =
        (measureIndex * _beatsPerMeasure) + normalizedStartBeat;
    final firstAbsoluteBeat = notesToMove
        .map(_absoluteStartBeat)
        .reduce((first, second) => first < second ? first : second);
    final replacements = <CompositionNote>[];

    for (final note in notesToMove) {
      final absoluteBeat = normalizeTiming(
        targetAbsoluteBeat + (_absoluteStartBeat(note) - firstAbsoluteBeat),
      );
      final targetMeasure = (absoluteBeat / _beatsPerMeasure).floor();
      final targetStart = normalizeTiming(
        absoluteBeat - (targetMeasure * _beatsPerMeasure),
      );
      replacements.add(
        note.copyWith(
          measureIndex: targetMeasure,
          startBeat: targetStart,
        ),
      );
    }

    if (!allowStacking &&
        _wouldStackNotes(
          replacements,
          ignoredExistingIds: notesToMove.map((note) => note.id).toSet(),
        )) {
      return 'Enable Chord Mode to stack notes on this beat.';
    }

    final validationError = _validateReplacements(replacements);
    if (validationError != null) {
      return validationError;
    }

    _recordUndo();
    for (final replacement in replacements) {
      _replaceNoteWithoutHistory(replacement);
    }
    _removeBrokenTiesWithoutHistory();
    currentMeasureIndex = measureIndex;
    _insertionBeat = normalizedStartBeat;
    _clearChord();
    return null;
  }

  bool deleteSelectedNote() {
    return deleteSelectedNotes() > 0;
  }

  int deleteSelectedNotes() {
    if (_selectedNoteIds.isEmpty) {
      return 0;
    }

    final idsToDelete = Set<String>.from(_selectedNoteIds);
    final deletedCount = _notes.where((note) {
      return idsToDelete.contains(note.id);
    }).length;
    if (deletedCount == 0) {
      clearSelection();
      return 0;
    }

    _recordUndo();
    _notes.removeWhere((note) => idsToDelete.contains(note.id));
    _removeBrokenTiesWithoutHistory();
    clearSelection();
    _clearChord();
    return deletedCount;
  }

  bool deleteSelectedChord() {
    final anchors = <_ChordAnchor>{};
    for (final note in selectedNotes) {
      anchors.add(
        _ChordAnchor(
          measureIndex: note.measureIndex,
          startBeat: note.startBeat,
        ),
      );
    }

    if (anchors.isEmpty && isBuildingChord) {
      anchors.add(
        _ChordAnchor(
          measureIndex: _activeChordMeasureIndex!,
          startBeat: _activeChordStartBeat!,
        ),
      );
    }
    if (anchors.isEmpty) {
      return false;
    }

    final idsToDelete = _notes.where((note) {
      return anchors.any((anchor) {
        return note.measureIndex == anchor.measureIndex &&
            sameTiming(note.startBeat, anchor.startBeat);
      });
    }).map((note) => note.id).toSet();
    if (idsToDelete.isEmpty) {
      return false;
    }

    _recordUndo();
    _notes.removeWhere((note) => idsToDelete.contains(note.id));
    _removeBrokenTiesWithoutHistory();
    clearSelection();
    _clearChord();
    return true;
  }

  bool copySelectedNotes() {
    final notesToCopy = selectedNotes;
    if (notesToCopy.isEmpty) {
      return false;
    }

    _clipboard
      ..clear()
      ..addAll(notesToCopy.map((note) {
        final keepTie = note.tieToNext &&
            _hasTieContinuation(note, notesToCopy);
        return note.copyWith(tieToNext: keepTie);
      }));
    return true;
  }

  String? pasteNotes({
    int? measureIndex,
    num? startBeat,
    bool allowStacking = false,
  }) {
    if (_clipboard.isEmpty) {
      return 'Copy at least one note first.';
    }
    if (_notes.length + _clipboard.length > maximumNoteCount) {
      return noteLimitError;
    }

    final destinationMeasure = measureIndex ?? currentMeasureIndex;
    final destinationBeat = normalizeTiming(startBeat ?? _insertionBeat);
    if (destinationMeasure < 0 || destinationMeasure >= _measureCount) {
      return 'Choose an existing measure.';
    }
    if (destinationBeat < 0 || destinationBeat >= _beatsPerMeasure) {
      return 'Choose a position inside the measure.';
    }

    final sourceAnchor = _clipboard
        .map(_absoluteStartBeat)
        .reduce((first, second) => first < second ? first : second);
    final destinationAnchor =
        (destinationMeasure * _beatsPerMeasure) + destinationBeat;
    final pastedNotes = <CompositionNote>[];

    for (final source in _clipboard) {
      final absoluteBeat = normalizeTiming(
        destinationAnchor + (_absoluteStartBeat(source) - sourceAnchor),
      );
      final targetMeasure = (absoluteBeat / _beatsPerMeasure).floor();
      final targetStart = normalizeTiming(
        absoluteBeat - (targetMeasure * _beatsPerMeasure),
      );

      pastedNotes.add(
        source.copyWith(
          id: createNoteId(),
          measureIndex: targetMeasure,
          startBeat: targetStart,
        ),
      );
    }

    if (!allowStacking && _wouldStackNotes(pastedNotes)) {
      return 'Enable Chord Mode to stack notes on this beat.';
    }

    final validationError = _validateNewNotes(pastedNotes);
    if (validationError != null) {
      return validationError;
    }

    _recordUndo();
    _notes.addAll(pastedNotes);
    _removeBrokenTiesWithoutHistory();
    _selectedNoteIds
      ..clear()
      ..addAll(pastedNotes.map((note) => note.id));
    _selectedNoteId = pastedNotes.last.id;
    currentMeasureIndex = destinationMeasure;
    final pastedEnd = pastedNotes
        .map((note) => _absoluteStartBeat(note) + note.durationBeats)
        .reduce((first, second) => first > second ? first : second);
    final endMeasure = (pastedEnd / _beatsPerMeasure).floor();
    if (endMeasure < _measureCount) {
      currentMeasureIndex = endMeasure;
      _insertionBeat = normalizeTiming(
        pastedEnd - (endMeasure * _beatsPerMeasure),
      );
      if (_insertionBeat >= _beatsPerMeasure) {
        _insertionBeat = 0;
      }
    }
    _clearChord();
    return null;
  }

  String? addMeasure() {
    if (_measureCount >= maximumMeasureCount) {
      return measureLimitError;
    }

    _recordUndo();
    _measureCount++;
    currentMeasureIndex = _measureCount - 1;
    _insertionBeat = 0;
    clearSelection();
    _clearChord();
    return null;
  }

  String? insertMeasure(int measureIndex) {
    if (_measureCount >= maximumMeasureCount) {
      return measureLimitError;
    }
    if (measureIndex < 0 || measureIndex > _measureCount) {
      return 'Choose a valid measure position.';
    }

    _recordUndo();
    for (var index = 0; index < _notes.length; index++) {
      final note = _notes[index];
      if (note.measureIndex >= measureIndex) {
        _notes[index] = note.copyWith(measureIndex: note.measureIndex + 1);
      }
    }
    _measureCount++;
    _removeBrokenTiesWithoutHistory();
    currentMeasureIndex = measureIndex;
    _insertionBeat = 0;
    clearSelection();
    _clearChord();
    return null;
  }

  String? duplicateMeasure(int measureIndex) {
    if (_measureCount >= maximumMeasureCount) {
      return measureLimitError;
    }
    if (measureIndex < 0 || measureIndex >= _measureCount) {
      return 'Choose an existing measure.';
    }

    final sourceNotes = _notes.where((note) {
      return note.measureIndex == measureIndex;
    }).toList();
    if (_notes.length + sourceNotes.length > maximumNoteCount) {
      return noteLimitError;
    }

    _recordUndo();
    for (var index = 0; index < _notes.length; index++) {
      final note = _notes[index];
      if (note.measureIndex > measureIndex) {
        _notes[index] = note.copyWith(measureIndex: note.measureIndex + 1);
      }
    }

    final duplicatedNotes = sourceNotes.map((note) {
      return note.copyWith(
        id: createNoteId(),
        measureIndex: measureIndex + 1,
      );
    }).toList();
    _notes.addAll(duplicatedNotes);
    _measureCount++;
    _removeBrokenTiesWithoutHistory();
    currentMeasureIndex = measureIndex + 1;
    _insertionBeat = 0;
    _selectedNoteIds
      ..clear()
      ..addAll(duplicatedNotes.map((note) => note.id));
    _selectedNoteId = duplicatedNotes.isEmpty ? null : duplicatedNotes.last.id;
    _clearChord();
    return null;
  }

  bool deleteMeasure(int measureIndex) {
    if (_measureCount <= 1 ||
        measureIndex < 0 ||
        measureIndex >= _measureCount) {
      return false;
    }

    _recordUndo();
    _notes.removeWhere((note) => note.measureIndex == measureIndex);
    for (var index = 0; index < _notes.length; index++) {
      final note = _notes[index];
      if (note.measureIndex > measureIndex) {
        _notes[index] = note.copyWith(measureIndex: note.measureIndex - 1);
      }
    }
    _measureCount--;
    _removeBrokenTiesWithoutHistory();
    currentMeasureIndex = currentMeasureIndex
        .clamp(0, _measureCount - 1)
        .toInt();
    _insertionBeat = 0;
    clearSelection();
    _clearChord();
    return true;
  }

  bool moveMeasure(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= _measureCount ||
        toIndex < 0 ||
        toIndex >= _measureCount ||
        fromIndex == toIndex) {
      return false;
    }

    _recordUndo();
    for (var index = 0; index < _notes.length; index++) {
      final note = _notes[index];
      var targetMeasure = note.measureIndex;

      if (note.measureIndex == fromIndex) {
        targetMeasure = toIndex;
      } else if (fromIndex < toIndex &&
          note.measureIndex > fromIndex &&
          note.measureIndex <= toIndex) {
        targetMeasure = note.measureIndex - 1;
      } else if (fromIndex > toIndex &&
          note.measureIndex >= toIndex &&
          note.measureIndex < fromIndex) {
        targetMeasure = note.measureIndex + 1;
      }

      if (targetMeasure != note.measureIndex) {
        _notes[index] = note.copyWith(measureIndex: targetMeasure);
      }
    }

    if (currentMeasureIndex == fromIndex) {
      currentMeasureIndex = toIndex;
    } else if (fromIndex < toIndex &&
        currentMeasureIndex > fromIndex &&
        currentMeasureIndex <= toIndex) {
      currentMeasureIndex--;
    } else if (fromIndex > toIndex &&
        currentMeasureIndex >= toIndex &&
        currentMeasureIndex < fromIndex) {
      currentMeasureIndex++;
    }
    _removeBrokenTiesWithoutHistory();
    _clearChord();
    return true;
  }

  double? findAvailableBeat(
    int measureIndex,
    num durationBeats, {
    int? midiNumber,
    num startAt = 0,
  }) {
    final duration = normalizeTiming(durationBeats);
    final firstBeat = normalizeTiming(startAt);
    final lastPossibleBeat = normalizeTiming(_beatsPerMeasure - duration);

    for (
      var startBeat = firstBeat;
      startBeat <= lastPossibleBeat + timingStep / 2;
      startBeat = normalizeTiming(startBeat + timingStep)
    ) {
      if (canPlaceNote(
        measureIndex: measureIndex,
        startBeat: startBeat,
        durationBeats: duration,
        midiNumber: midiNumber,
      )) {
        return startBeat;
      }
    }

    return null;
  }

  bool canPlaceNote({
    required int measureIndex,
    required num startBeat,
    required num durationBeats,
    int? midiNumber,
    String? ignoredNoteId,
    Set<String> ignoredNoteIds = const {},
  }) {
    final beat = normalizeTiming(startBeat);
    final duration = normalizeTiming(durationBeats);
    final endBeat = normalizeTiming(beat + duration);

    if (measureIndex < 0 ||
        measureIndex >= _measureCount ||
        beat < 0 ||
        duration <= 0 ||
        endBeat > _beatsPerMeasure + timingStep / 2) {
      return false;
    }

    for (final note in _notes) {
      if (note.id == ignoredNoteId || ignoredNoteIds.contains(note.id)) {
        continue;
      }
      if (note.measureIndex != measureIndex) {
        continue;
      }
      if (midiNumber != null && note.midiNumber != midiNumber) {
        continue;
      }

      if (_rangesOverlap(
        beat,
        endBeat,
        note.startBeat,
        note.startBeat + note.durationBeats,
      )) {
        return false;
      }
    }

    return true;
  }

  String? addNoteToChord({
    required String pitch,
    required int octave,
    required int midiNumber,
    num? durationBeats,
    num? velocity,
  }) {
    if (_notes.length >= maximumNoteCount) {
      return noteLimitError;
    }

    if (!isBuildingChord) {
      _activeChordMeasureIndex = currentMeasureIndex;
      _activeChordStartBeat = _insertionBeat;
    }

    final duration = normalizeTiming(durationBeats ?? selectedDuration);
    final measureIndex = _activeChordMeasureIndex!;
    final startBeat = _activeChordStartBeat!;

    if (!canPlaceNote(
      measureIndex: measureIndex,
      startBeat: startBeat,
      durationBeats: duration,
      midiNumber: midiNumber,
    )) {
      return _placementError(
        measureIndex: measureIndex,
        startBeat: startBeat,
        durationBeats: duration,
        midiNumber: midiNumber,
      );
    }

    final newNote = CompositionNote(
      id: createNoteId(),
      pitch: pitch,
      octave: octave,
      midiNumber: midiNumber,
      measureIndex: measureIndex,
      startBeat: startBeat,
      durationBeats: duration,
      velocity: velocity ?? selectedVelocity,
    );

    _recordUndo();
    _notes.add(newNote);
    selectedDuration = duration;
    selectedVelocity = newNote.velocity;
    clearSelection();
    return null;
  }

  List<CompositionNote> notesAtPosition(CompositionNote sourceNote) {
    return _notes.where((note) {
      return note.measureIndex == sourceNote.measureIndex &&
          sameTiming(note.startBeat, sourceNote.startBeat);
    }).toList();
  }

  bool startChordFromSelectedNote() {
    final note = selectedNote;
    if (note == null) {
      return false;
    }

    _activeChordMeasureIndex = note.measureIndex;
    _activeChordStartBeat = note.startBeat;
    currentMeasureIndex = note.measureIndex;
    _insertionBeat = note.startBeat;
    selectedDuration = note.durationBeats;
    selectedVelocity = note.velocity;
    clearSelection();
    return true;
  }

  void finishChord() {
    if (isBuildingChord) {
      final chordEnd = activeChordNotes.fold<double>(
        _activeChordStartBeat!,
        (largest, note) {
          final noteEnd = note.startBeat + note.durationBeats;
          return noteEnd > largest ? noteEnd : largest;
        },
      );
      _advanceInsertionCursor(chordEnd);
    }

    _activeChordMeasureIndex = null;
    _activeChordStartBeat = null;
  }

  void _clearChord() {
    _activeChordMeasureIndex = null;
    _activeChordStartBeat = null;
  }

  void replaceNote(CompositionNote updatedNote) {
    final existing = _noteById(updatedNote.id);
    if (existing == null) {
      return;
    }

    final normalized = updatedNote.copyWith(
      startBeat: normalizeTiming(updatedNote.startBeat),
      durationBeats: normalizeTiming(updatedNote.durationBeats),
    );
    final validationError = _validateReplacements([normalized]);
    if (validationError != null) {
      return;
    }

    _recordUndo();
    _replaceNoteWithoutHistory(normalized);
    _removeBrokenTiesWithoutHistory();
  }

  bool undo() {
    if (_undoStack.isEmpty) {
      return false;
    }

    _redoStack.add(_createSnapshot());
    final snapshot = _undoStack.removeLast();
    _restoreSnapshot(snapshot);
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) {
      return false;
    }

    _undoStack.add(_createSnapshot());
    final snapshot = _redoStack.removeLast();
    _restoreSnapshot(snapshot);
    return true;
  }

  String createNoteId() {
    _idSequence++;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'note_${timestamp}_$_idSequence';
  }

  bool sameTiming(num first, num second) {
    return (first.toDouble() - second.toDouble()).abs() < timingStep / 2;
  }

  bool _wouldStackNotes(
    List<CompositionNote> candidates, {
    Set<String> ignoredExistingIds = const {},
  }) {
    for (var firstIndex = 0;
        firstIndex < candidates.length;
        firstIndex++) {
      final first = candidates[firstIndex];

      for (var secondIndex = firstIndex + 1;
          secondIndex < candidates.length;
          secondIndex++) {
        final second = candidates[secondIndex];

        if (first.measureIndex == second.measureIndex &&
            sameTiming(first.startBeat, second.startBeat)) {
          return true;
        }
      }

      final overlapsExistingStart = _notes.any((existingNote) {
        return !ignoredExistingIds.contains(existingNote.id) &&
            existingNote.measureIndex == first.measureIndex &&
            sameTiming(existingNote.startBeat, first.startBeat);
      });

      if (overlapsExistingStart) {
        return true;
      }
    }

    return false;
  }

  CompositionNote? _noteById(String noteId) {
    for (final note in _notes) {
      if (note.id == noteId) {
        return note;
      }
    }
    return null;
  }

  double _absoluteStartBeat(CompositionNote note) {
    return normalizeTiming(
      (note.measureIndex * _beatsPerMeasure) + note.startBeat,
    );
  }

  bool _hasTieContinuation(
    CompositionNote note,
    Iterable<CompositionNote> candidates,
  ) {
    final noteEnd = normalizeTiming(
      _absoluteStartBeat(note) + note.durationBeats,
    );

    return candidates.any((candidate) {
      return candidate.id != note.id &&
          candidate.midiNumber == note.midiNumber &&
          sameTiming(_absoluteStartBeat(candidate), noteEnd);
    });
  }

  void _removeBrokenTiesWithoutHistory() {
    final tiedNotes = _notes.where((note) => note.tieToNext).toList();
    for (final note in tiedNotes) {
      if (!_hasTieContinuation(note, _notes)) {
        _replaceNoteWithoutHistory(note.copyWith(tieToNext: false));
      }
    }
  }

  void _advanceInsertionCursor(num absoluteOrLocalBeat) {
    final beat = normalizeTiming(absoluteOrLocalBeat);
    if (beat < _beatsPerMeasure) {
      _insertionBeat = beat;
      return;
    }

    if (currentMeasureIndex + 1 < _measureCount) {
      currentMeasureIndex++;
      _insertionBeat = 0;
      return;
    }

    _insertionBeat = normalizeTiming(
      (_beatsPerMeasure - selectedDuration).clamp(0, _beatsPerMeasure),
    );
  }

  String _placementError({
    required int measureIndex,
    required double startBeat,
    required double durationBeats,
    required int midiNumber,
  }) {
    if (measureIndex < 0 || measureIndex >= _measureCount) {
      return 'Choose an existing measure.';
    }
    if (startBeat < 0 ||
        durationBeats <= 0 ||
        startBeat + durationBeats > _beatsPerMeasure + timingStep / 2) {
      return 'That note does not fit inside the measure.';
    }
    return 'That key already has a note during this time.';
  }

  String? _validateReplacements(List<CompositionNote> replacements) {
    final replacementIds = replacements.map((note) => note.id).toSet();
    return _validateCandidates(
      replacements,
      ignoredExistingIds: replacementIds,
    );
  }

  String? _validateNewNotes(List<CompositionNote> candidates) {
    return _validateCandidates(candidates);
  }

  String? _validateCandidates(
    List<CompositionNote> candidates, {
    Set<String> ignoredExistingIds = const {},
  }) {
    for (final note in candidates) {
      if (note.measureIndex < 0 || note.measureIndex >= _measureCount) {
        return 'The notes do not fit in the available measures.';
      }
      if (note.durationBeats <= 0 ||
          note.startBeat < 0 ||
          note.startBeat + note.durationBeats >
              _beatsPerMeasure + timingStep / 2) {
        return 'A note does not fit inside its measure.';
      }

      for (final existing in _notes) {
        if (ignoredExistingIds.contains(existing.id) ||
            existing.measureIndex != note.measureIndex ||
            existing.midiNumber != note.midiNumber) {
          continue;
        }
        if (_rangesOverlap(
          note.startBeat,
          note.startBeat + note.durationBeats,
          existing.startBeat,
          existing.startBeat + existing.durationBeats,
        )) {
          return 'The same key cannot overlap itself.';
        }
      }
    }

    for (var firstIndex = 0; firstIndex < candidates.length; firstIndex++) {
      final first = candidates[firstIndex];
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < candidates.length;
        secondIndex++
      ) {
        final second = candidates[secondIndex];
        if (first.id == second.id ||
            first.measureIndex != second.measureIndex ||
            first.midiNumber != second.midiNumber) {
          continue;
        }
        if (_rangesOverlap(
          first.startBeat,
          first.startBeat + first.durationBeats,
          second.startBeat,
          second.startBeat + second.durationBeats,
        )) {
          return 'The same key cannot overlap itself.';
        }
      }
    }

    return null;
  }

  bool _rangesOverlap(
    num firstStart,
    num firstEnd,
    num secondStart,
    num secondEnd,
  ) {
    return firstStart.toDouble() < secondEnd.toDouble() - timingStep / 2 &&
        firstEnd.toDouble() > secondStart.toDouble() + timingStep / 2;
  }

  void _replaceNoteWithoutHistory(CompositionNote updatedNote) {
    final noteIndex = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (noteIndex != -1) {
      _notes[noteIndex] = updatedNote;
    }
  }

  void _recordUndo() {
    _undoStack.add(_createSnapshot());
    if (_undoStack.length > maximumHistoryLength) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  _EditorSnapshot _createSnapshot() {
    return _EditorSnapshot(
      notes: _notes.map((note) => note.copyWith()).toList(),
      measureCount: _measureCount,
      beatsPerMeasure: _beatsPerMeasure,
      beatUnit: _beatUnit,
      currentMeasureIndex: currentMeasureIndex,
      insertionBeat: _insertionBeat,
      selectedDuration: selectedDuration,
      selectedVelocity: selectedVelocity,
      selectedNoteIds: Set<String>.from(_selectedNoteIds),
      selectedNoteId: _selectedNoteId,
      activeChordMeasureIndex: _activeChordMeasureIndex,
      activeChordStartBeat: _activeChordStartBeat,
    );
  }

  void _restoreSnapshot(_EditorSnapshot snapshot) {
    _notes
      ..clear()
      ..addAll(snapshot.notes.map((note) => note.copyWith()));
    _measureCount = snapshot.measureCount;
    _beatsPerMeasure = snapshot.beatsPerMeasure;
    _beatUnit = snapshot.beatUnit;
    currentMeasureIndex = snapshot.currentMeasureIndex;
    _insertionBeat = snapshot.insertionBeat;
    selectedDuration = snapshot.selectedDuration;
    selectedVelocity = snapshot.selectedVelocity;
    _selectedNoteIds
      ..clear()
      ..addAll(snapshot.selectedNoteIds);
    _selectedNoteId = snapshot.selectedNoteId;
    _activeChordMeasureIndex = snapshot.activeChordMeasureIndex;
    _activeChordStartBeat = snapshot.activeChordStartBeat;
  }
}

class _EditorSnapshot {
  const _EditorSnapshot({
    required this.notes,
    required this.measureCount,
    required this.beatsPerMeasure,
    required this.beatUnit,
    required this.currentMeasureIndex,
    required this.insertionBeat,
    required this.selectedDuration,
    required this.selectedVelocity,
    required this.selectedNoteIds,
    required this.selectedNoteId,
    required this.activeChordMeasureIndex,
    required this.activeChordStartBeat,
  });

  final List<CompositionNote> notes;
  final int measureCount;
  final int beatsPerMeasure;
  final int beatUnit;
  final int currentMeasureIndex;
  final double insertionBeat;
  final double selectedDuration;
  final double selectedVelocity;
  final Set<String> selectedNoteIds;
  final String? selectedNoteId;
  final int? activeChordMeasureIndex;
  final double? activeChordStartBeat;
}

class _ChordAnchor {
  const _ChordAnchor({
    required this.measureIndex,
    required this.startBeat,
  });

  final int measureIndex;
  final double startBeat;

  @override
  bool operator ==(Object other) {
    return other is _ChordAnchor &&
        other.measureIndex == measureIndex &&
        (other.startBeat - startBeat).abs() <
            CompositionEditorController.timingStep / 2;
  }

  @override
  int get hashCode {
    final timingTick = (startBeat / CompositionEditorController.timingStep)
        .round();
    return Object.hash(measureIndex, timingTick);
  }
}
