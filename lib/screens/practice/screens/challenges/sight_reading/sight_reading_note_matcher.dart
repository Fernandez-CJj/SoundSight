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
  int _completedPositionCount = 0;
  int _firstTryCorrectCount = 0;
  bool _currentPositionHadMistake = false;

  Set<int> get expectedMidiNotes => Set<int>.unmodifiable(_expectedMidiNotes);

  Set<int> get activeMidiNotes => Set<int>.unmodifiable(_activeMidiNotes);

  String get resultText => _resultText;

  int get consecutiveMistakes => _consecutiveMistakes;

  bool get showExpectedHint =>
      _consecutiveMistakes >= 5 && _expectedMidiNotes.isNotEmpty;

  bool get cursorIsWrong => _cursorIsWrong;

  int get totalMistakes => _totalMistakes;

  bool get hintWasShownDuringExercise => _hintWasShownDuringExercise;

  int get completedPositionCount => _completedPositionCount;

  int get firstTryCorrectCount => _firstTryCorrectCount;

  String get scoreText =>
      '$_firstTryCorrectCount/'
      '$_completedPositionCount';

  void updateExpectedNotes(Set<int> notes) {
    _expectedMidiNotes = Set<int>.from(notes);
  }

  void recordNoteOn(int note) {
    _suppressMistakesUntilNextNoteOn = false;
    _pressedMidiNotesForStep.add(note);
    _notePressedAtForStep[note] = DateTime.now();
  }

  bool updateActiveNotes(Set<int> notes) {
    _activeMidiNotes = Set<int>.from(notes);

    final heldNotesMatch =
        _expectedMidiNotes.isNotEmpty &&
        _activeMidiNotes.length == _expectedMidiNotes.length &&
        _activeMidiNotes.containsAll(_expectedMidiNotes);

    final newlyPressedNotesMatch = _expectedMidiNotes.every(
      _pressedMidiNotesForStep.contains,
    );

    final chordTimingMatch = _expectedNotesWerePressedTogether();

    final notesMatch =
        heldNotesMatch && newlyPressedNotesMatch && chordTimingMatch;

    final hasUnexpectedNote =
        _expectedMidiNotes.isNotEmpty &&
        _activeMidiNotes.any((note) => !_expectedMidiNotes.contains(note));

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
      _completedPositionCount++;

      if (!_currentPositionHadMistake) {
        _firstTryCorrectCount++;
      }

      _currentPositionHadMistake = false;
      _resultText = 'Correct';
      _consecutiveMistakes = 0;
      _cursorIsWrong = false;
      _mistakeCountedForCurrentAttempt = false;
      _suppressMistakesUntilNextNoteOn = true;
      _pressedMidiNotesForStep.clear();
      _notePressedAtForStep.clear();
    } else if (isDefiniteMistake && !_suppressMistakesUntilNextNoteOn) {
      _resultText = 'Wrong note';
      _cursorIsWrong = true;

      if (!_mistakeCountedForCurrentAttempt) {
        _consecutiveMistakes++;
        _totalMistakes++;
        _currentPositionHadMistake = true;
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

    _completedPositionCount = 0;
    _firstTryCorrectCount = 0;
    _currentPositionHadMistake = false;
  }
}
