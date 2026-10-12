class SightReadingNoteMatcher {
  static const Duration _chordPressWindow = Duration(milliseconds: 200);
  Set<int> _expectedMidiNotes = <int>{};
  Set<int> _activeMidiNotes = <int>{};
  final Set<int> _pressedMidiNotesForStep = <int>{};
  final Map<int, DateTime> _notePressedAtForStep = <int, DateTime>{};
  String _resultText = 'Waiting';
  int _consecutiveMistakes = 0;
  int _totalMistakes = 0;
  bool _hintWasShownDuringExercise = false;
  bool _mistakeCountedForCurrentAttempt = false;
  bool _suppressMistakesUntilNextNoteOn = false;
  bool _cursorIsWrong = false;
  int _currentPositionIndex = 0;
  final Set<int> _completedPositionIndexes = <int>{};
  final Set<int> _positionIndexesWithMistakes = <int>{};

  Set<int> get expectedMidiNotes => Set<int>.unmodifiable(_expectedMidiNotes);

  Set<int> get activeMidiNotes => Set<int>.unmodifiable(_activeMidiNotes);

  String get resultText => _resultText;

  int get consecutiveMistakes => _consecutiveMistakes;

  bool get showExpectedHint =>
      _consecutiveMistakes >= 5 && _expectedMidiNotes.isNotEmpty;

  bool get cursorIsWrong => _cursorIsWrong;

  int get totalMistakes => _totalMistakes;

  bool get hintWasShownDuringExercise => _hintWasShownDuringExercise;

  int get completedPositionCount => _completedPositionIndexes.length;

  int get firstTryCorrectCount => _completedPositionIndexes
      .where((index) => !_positionIndexesWithMistakes.contains(index))
      .length;

  String get scoreText =>
      '$firstTryCorrectCount/'
      '$completedPositionCount';

  void setCurrentPositionIndex(int positionIndex) {
    _currentPositionIndex = positionIndex;
  }

  void updateExpectedNotes(Set<int> notes) {
    _expectedMidiNotes = Set<int>.from(notes);
  }

  void recordNoteOn(int note) {
    _suppressMistakesUntilNextNoteOn = false;
    _pressedMidiNotesForStep.add(note);
    _notePressedAtForStep[note] = DateTime.now();
  }

  bool updateActiveNotes(
    Set<int> notes, {
    Set<int> allowedSustainedNotes = const <int>{},
    bool deferCorrectCompletion = false,
  }) {
    _activeMidiNotes = Set<int>.from(notes);

    final allowedActiveNotes = <int>{
      ..._expectedMidiNotes,
      ...allowedSustainedNotes,
    };

    final heldNotesMatch =
        _expectedMidiNotes.isNotEmpty &&
        _activeMidiNotes.length == allowedActiveNotes.length &&
        _activeMidiNotes.containsAll(allowedActiveNotes);

    final newlyPressedNotesMatch = _expectedMidiNotes.every(
      _pressedMidiNotesForStep.contains,
    );

    final chordTimingMatch = _expectedNotesWerePressedTogether();

    final notesMatch =
        heldNotesMatch && newlyPressedNotesMatch && chordTimingMatch;

    final hasUnexpectedNote =
        _expectedMidiNotes.isNotEmpty &&
        _activeMidiNotes.any((note) => !allowedActiveNotes.contains(note));

    final completedChordWithWrongTiming =
        heldNotesMatch && newlyPressedNotesMatch && !chordTimingMatch;

    final isDefiniteMistake =
        hasUnexpectedNote || completedChordWithWrongTiming;

    if (_activeMidiNotes.isEmpty) {
      _resultText = 'Waiting';
      _cursorIsWrong = false;
      _mistakeCountedForCurrentAttempt = false;
      _suppressMistakesUntilNextNoteOn = false;
    } else if (notesMatch) {
      if (deferCorrectCompletion) {
        _resultText = 'Correct notes — keep holding';
        _cursorIsWrong = false;
      } else {
        completeCurrentPosition();
      }
    } else if (isDefiniteMistake && !_suppressMistakesUntilNextNoteOn) {
      _resultText = 'Wrong note';
      _cursorIsWrong = true;

      if (!_mistakeCountedForCurrentAttempt) {
        _consecutiveMistakes++;
        _totalMistakes++;
        _positionIndexesWithMistakes.add(_currentPositionIndex);
        _mistakeCountedForCurrentAttempt = true;

        if (_consecutiveMistakes >= 5) {
          _hintWasShownDuringExercise = true;
        }
      }
    } else {
      _resultText = 'Keep playing';
      _cursorIsWrong = false;
    }

    return notesMatch;
  }

  void updateHoldProgress(double progress) {
    final percentage = (progress.clamp(0.0, 1.0) * 100).round();
    _resultText = 'Keep holding · $percentage%';
    _cursorIsWrong = false;
  }

  void completeCurrentPosition() {
    completePosition(_currentPositionIndex);
  }

  void completePosition(int positionIndex) {
    _completedPositionIndexes.add(positionIndex);
    _consecutiveMistakes = 0;

    if (positionIndex != _currentPositionIndex) {
      return;
    }

    _resultText = 'Duration complete';
    _cursorIsWrong = false;
    _mistakeCountedForCurrentAttempt = false;
    _suppressMistakesUntilNextNoteOn = true;
    _pressedMidiNotesForStep.clear();
    _notePressedAtForStep.clear();
  }

  void recordDurationMistake({
    required int positionIndex,
    required String message,
  }) {
    _resultText = message;
    _cursorIsWrong = true;

    _consecutiveMistakes++;
    _totalMistakes++;
    _positionIndexesWithMistakes.add(positionIndex);

    if (_consecutiveMistakes >= 5) {
      _hintWasShownDuringExercise = true;
    }

    _suppressMistakesUntilNextNoteOn = true;
    _pressedMidiNotesForStep.clear();
    _notePressedAtForStep.clear();
  }

  void showDurationFeedback(String message, {bool isError = false}) {
    _resultText = message;
    _cursorIsWrong = isError;
  }

  void rewindToPosition(int positionIndex) {
    _currentPositionIndex = positionIndex;
    _completedPositionIndexes.removeWhere((index) => index >= positionIndex);
    _activeMidiNotes = <int>{};
    _pressedMidiNotesForStep.clear();
    _notePressedAtForStep.clear();
    _mistakeCountedForCurrentAttempt = false;
    _suppressMistakesUntilNextNoteOn = true;
  }

  void prepareRetryAfterRelease() {
    _activeMidiNotes = <int>{};
    _pressedMidiNotesForStep.clear();
    _notePressedAtForStep.clear();
    _resultText = 'Try again — hold until the cursor reaches the next note';
    _cursorIsWrong = true;
    _mistakeCountedForCurrentAttempt = false;
    _suppressMistakesUntilNextNoteOn = false;
  }

  bool _expectedNotesWerePressedTogether() {
    if (_expectedMidiNotes.length <= 1) {
      return true;
    }

    final pressTimes = _expectedMidiNotes
        .map((note) => _notePressedAtForStep[note])
        .whereType<DateTime>()
        .toList();

    if (pressTimes.length != _expectedMidiNotes.length) {
      return false;
    }

    pressTimes.sort();

    final timeBetweenFirstAndLast = pressTimes.last.difference(
      pressTimes.first,
    );

    return timeBetweenFirstAndLast <= _chordPressWindow;
  }

  void resetExercise() {
    _expectedMidiNotes = <int>{};
    _activeMidiNotes = <int>{};

    _pressedMidiNotesForStep.clear();
    _notePressedAtForStep.clear();

    _resultText = 'Waiting';

    _consecutiveMistakes = 0;
    _totalMistakes = 0;
    _hintWasShownDuringExercise = false;

    _mistakeCountedForCurrentAttempt = false;

    // Prevents held keys from the previous attempt
    // from becoming an immediate mistake.
    _suppressMistakesUntilNextNoteOn = true;

    _cursorIsWrong = false;

    _currentPositionIndex = 0;
    _completedPositionIndexes.clear();
    _positionIndexesWithMistakes.clear();
  }
}
