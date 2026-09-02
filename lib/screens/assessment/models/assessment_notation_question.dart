/// The clef shown at the beginning of a music staff.
enum AssessmentNotationClef {
  treble,
  bass,
}

/// The notation complexity measured by a question.
///
/// This is not the user's final SoundSight level. Final placement will also
/// depend on piano execution and sight-reading performance.
enum AssessmentNotationDifficulty {
  beginner,
  intermediate,
  advanced,
}

/// Tells the future renderer which musical visual to draw.
enum AssessmentNotationQuestionType {
  noteIdentification,
  rhythmValue,
  timeSignature,
  keySignature,
  interval,
  chord,
  shortPassage,
}

/// An accidental that may be drawn beside a displayed note.
enum AssessmentNotationAccidental {
  none,
  sharp,
  flat,
  natural,
}

/// Rhythm symbols supported by assessment version 1.
enum AssessmentRhythmValue {
  whole,
  half,
  quarter,
  eighth,
  dottedQuarter,
}

/// Key signatures supported by assessment version 1.
enum AssessmentKeySignature {
  cMajor,
  gMajor,
  dMajor,
  fMajor,
}

/// One selectable answer shown below a notation question.
class AssessmentNotationOption {
  const AssessmentNotationOption({
    required this.id,
    required this.label,
  });

  /// The stable value saved to Firestore.
  final String id;

  /// The readable text displayed to the user.
  final String label;
}

/// Describes one notation-reading question and its visual data.
class AssessmentNotationQuestion {
  const AssessmentNotationQuestion({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    this.clef,
    this.staffSteps = const [],
    this.accidental = AssessmentNotationAccidental.none,
    this.rhythmValues = const [],
    this.timeSignatureTop,
    this.timeSignatureBottom,
    this.keySignature,
  });

  /// A permanent identifier used when saving the user's answer.
  final String id;

  /// Determines which kind of notation the renderer displays.
  final AssessmentNotationQuestionType type;

  /// Groups the question for later notation-section scoring.
  final AssessmentNotationDifficulty difficulty;

  /// The instruction displayed above the musical notation.
  final String prompt;

  /// The answer choices displayed to the user.
  final List<AssessmentNotationOption> options;

  /// The ID of the correct option used during scoring.
  final String correctOptionId;

  /// The clef used by questions that display a staff.
  final AssessmentNotationClef? clef;

  /// Positions notes relative to the staff's bottom line.
  ///
  /// Zero is the bottom line. Each increase of one moves upward by one line
  /// or space. Negative values place a note below the staff.
  final List<int> staffSteps;

  /// The accidental drawn beside a single-note question.
  final AssessmentNotationAccidental accidental;

  /// Rhythm symbols drawn for rhythm and short-passage questions.
  final List<AssessmentRhythmValue> rhythmValues;

  /// The upper number of a displayed time signature.
  final int? timeSignatureTop;

  /// The lower number of a displayed time signature.
  final int? timeSignatureBottom;

  /// The key signature displayed after the clef.
  final AssessmentKeySignature? keySignature;
}

/// The fixed notation-reading questions used by assessment version 1.
///
/// The set checks more than isolated note names. It includes rhythm, meter,
/// accidentals, key signatures, intervals, chords, and passage reading.
const List<AssessmentNotationQuestion> assessmentNotationQuestions = [
  AssessmentNotationQuestion(
    id: 'beginner_treble_e4',
    type: AssessmentNotationQuestionType.noteIdentification,
    difficulty: AssessmentNotationDifficulty.beginner,
    prompt: 'Which note is shown?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [0],
    options: [
      AssessmentNotationOption(id: 'c', label: 'C'),
      AssessmentNotationOption(id: 'd', label: 'D'),
      AssessmentNotationOption(id: 'e', label: 'E'),
      AssessmentNotationOption(id: 'f', label: 'F'),
    ],
    correctOptionId: 'e',
  ),
  AssessmentNotationQuestion(
    id: 'beginner_bass_g2',
    type: AssessmentNotationQuestionType.noteIdentification,
    difficulty: AssessmentNotationDifficulty.beginner,
    prompt: 'Which note is shown?',
    clef: AssessmentNotationClef.bass,
    staffSteps: [0],
    options: [
      AssessmentNotationOption(id: 'e', label: 'E'),
      AssessmentNotationOption(id: 'f', label: 'F'),
      AssessmentNotationOption(id: 'g', label: 'G'),
      AssessmentNotationOption(id: 'a', label: 'A'),
    ],
    correctOptionId: 'g',
  ),
  AssessmentNotationQuestion(
    id: 'beginner_treble_c5',
    type: AssessmentNotationQuestionType.noteIdentification,
    difficulty: AssessmentNotationDifficulty.beginner,
    prompt: 'Which note is shown?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [5],
    options: [
      AssessmentNotationOption(id: 'a', label: 'A'),
      AssessmentNotationOption(id: 'b', label: 'B'),
      AssessmentNotationOption(id: 'c', label: 'C'),
      AssessmentNotationOption(id: 'd', label: 'D'),
    ],
    correctOptionId: 'c',
  ),
  AssessmentNotationQuestion(
    id: 'beginner_quarter_note',
    type: AssessmentNotationQuestionType.rhythmValue,
    difficulty: AssessmentNotationDifficulty.beginner,
    prompt: 'In 4/4 time, how many beats does this note receive?',
    rhythmValues: [AssessmentRhythmValue.quarter],
    options: [
      AssessmentNotationOption(id: 'half_beat', label: '1/2 beat'),
      AssessmentNotationOption(id: 'one_beat', label: '1 beat'),
      AssessmentNotationOption(id: 'two_beats', label: '2 beats'),
      AssessmentNotationOption(id: 'four_beats', label: '4 beats'),
    ],
    correctOptionId: 'one_beat',
  ),
  AssessmentNotationQuestion(
    id: 'beginner_half_note',
    type: AssessmentNotationQuestionType.rhythmValue,
    difficulty: AssessmentNotationDifficulty.beginner,
    prompt: 'In 4/4 time, how many beats does this note receive?',
    rhythmValues: [AssessmentRhythmValue.half],
    options: [
      AssessmentNotationOption(id: 'half_beat', label: '1/2 beat'),
      AssessmentNotationOption(id: 'one_beat', label: '1 beat'),
      AssessmentNotationOption(id: 'two_beats', label: '2 beats'),
      AssessmentNotationOption(id: 'four_beats', label: '4 beats'),
    ],
    correctOptionId: 'two_beats',
  ),
  AssessmentNotationQuestion(
    id: 'beginner_four_four_time',
    type: AssessmentNotationQuestionType.timeSignature,
    difficulty: AssessmentNotationDifficulty.beginner,
    prompt: 'What does this time signature mean?',
    timeSignatureTop: 4,
    timeSignatureBottom: 4,
    options: [
      AssessmentNotationOption(
        id: 'two_quarter_beats',
        label: 'Two quarter-note beats per measure',
      ),
      AssessmentNotationOption(
        id: 'three_quarter_beats',
        label: 'Three quarter-note beats per measure',
      ),
      AssessmentNotationOption(
        id: 'four_quarter_beats',
        label: 'Four quarter-note beats per measure',
      ),
      AssessmentNotationOption(
        id: 'four_eighth_beats',
        label: 'Four eighth-note beats per measure',
      ),
    ],
    correctOptionId: 'four_quarter_beats',
  ),
  AssessmentNotationQuestion(
    id: 'intermediate_treble_c4',
    type: AssessmentNotationQuestionType.noteIdentification,
    difficulty: AssessmentNotationDifficulty.intermediate,
    prompt: 'Which ledger-line note is shown?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [-2],
    options: [
      AssessmentNotationOption(id: 'b', label: 'B'),
      AssessmentNotationOption(id: 'c', label: 'C'),
      AssessmentNotationOption(id: 'd', label: 'D'),
      AssessmentNotationOption(id: 'e', label: 'E'),
    ],
    correctOptionId: 'c',
  ),
  AssessmentNotationQuestion(
    id: 'intermediate_bass_e2',
    type: AssessmentNotationQuestionType.noteIdentification,
    difficulty: AssessmentNotationDifficulty.intermediate,
    prompt: 'Which ledger-line note is shown?',
    clef: AssessmentNotationClef.bass,
    staffSteps: [-2],
    options: [
      AssessmentNotationOption(id: 'd', label: 'D'),
      AssessmentNotationOption(id: 'e', label: 'E'),
      AssessmentNotationOption(id: 'f', label: 'F'),
      AssessmentNotationOption(id: 'g', label: 'G'),
    ],
    correctOptionId: 'e',
  ),
  AssessmentNotationQuestion(
    id: 'intermediate_f_sharp',
    type: AssessmentNotationQuestionType.noteIdentification,
    difficulty: AssessmentNotationDifficulty.intermediate,
    prompt: 'Which note with an accidental is shown?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [1],
    accidental: AssessmentNotationAccidental.sharp,
    options: [
      AssessmentNotationOption(id: 'e', label: 'E'),
      AssessmentNotationOption(id: 'f', label: 'F'),
      AssessmentNotationOption(id: 'f_sharp', label: 'F♯'),
      AssessmentNotationOption(id: 'g_flat', label: 'G♭'),
    ],
    correctOptionId: 'f_sharp',
  ),
  AssessmentNotationQuestion(
    id: 'intermediate_g_major',
    type: AssessmentNotationQuestionType.keySignature,
    difficulty: AssessmentNotationDifficulty.intermediate,
    prompt: 'Which major key signature is shown?',
    clef: AssessmentNotationClef.treble,
    keySignature: AssessmentKeySignature.gMajor,
    options: [
      AssessmentNotationOption(id: 'c_major', label: 'C major'),
      AssessmentNotationOption(id: 'g_major', label: 'G major'),
      AssessmentNotationOption(id: 'd_major', label: 'D major'),
      AssessmentNotationOption(id: 'f_major', label: 'F major'),
    ],
    correctOptionId: 'g_major',
  ),
  AssessmentNotationQuestion(
    id: 'intermediate_f_major',
    type: AssessmentNotationQuestionType.keySignature,
    difficulty: AssessmentNotationDifficulty.intermediate,
    prompt: 'Which major key signature is shown?',
    clef: AssessmentNotationClef.bass,
    keySignature: AssessmentKeySignature.fMajor,
    options: [
      AssessmentNotationOption(id: 'c_major', label: 'C major'),
      AssessmentNotationOption(id: 'g_major', label: 'G major'),
      AssessmentNotationOption(id: 'd_major', label: 'D major'),
      AssessmentNotationOption(id: 'f_major', label: 'F major'),
    ],
    correctOptionId: 'f_major',
  ),
  AssessmentNotationQuestion(
    id: 'intermediate_third',
    type: AssessmentNotationQuestionType.interval,
    difficulty: AssessmentNotationDifficulty.intermediate,
    prompt: 'What is the size of the written interval?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [5, 7],
    options: [
      AssessmentNotationOption(id: 'second', label: 'Second'),
      AssessmentNotationOption(id: 'third', label: 'Third'),
      AssessmentNotationOption(id: 'fourth', label: 'Fourth'),
      AssessmentNotationOption(id: 'fifth', label: 'Fifth'),
    ],
    correctOptionId: 'third',
  ),
  AssessmentNotationQuestion(
    id: 'advanced_bass_c4',
    type: AssessmentNotationQuestionType.noteIdentification,
    difficulty: AssessmentNotationDifficulty.advanced,
    prompt: 'Which upper ledger-line note is shown?',
    clef: AssessmentNotationClef.bass,
    staffSteps: [10],
    options: [
      AssessmentNotationOption(id: 'a', label: 'A'),
      AssessmentNotationOption(id: 'b', label: 'B'),
      AssessmentNotationOption(id: 'c', label: 'C'),
      AssessmentNotationOption(id: 'd', label: 'D'),
    ],
    correctOptionId: 'c',
  ),
  AssessmentNotationQuestion(
    id: 'advanced_six_eight_time',
    type: AssessmentNotationQuestionType.timeSignature,
    difficulty: AssessmentNotationDifficulty.advanced,
    prompt: 'How is this compound meter normally felt?',
    timeSignatureTop: 6,
    timeSignatureBottom: 8,
    options: [
      AssessmentNotationOption(
        id: 'two_dotted_quarter_beats',
        label: 'Two dotted-quarter beats',
      ),
      AssessmentNotationOption(
        id: 'three_quarter_beats',
        label: 'Three quarter-note beats',
      ),
      AssessmentNotationOption(
        id: 'four_quarter_beats',
        label: 'Four quarter-note beats',
      ),
      AssessmentNotationOption(
        id: 'six_quarter_beats',
        label: 'Six quarter-note beats',
      ),
    ],
    correctOptionId: 'two_dotted_quarter_beats',
  ),
  AssessmentNotationQuestion(
    id: 'advanced_d_major',
    type: AssessmentNotationQuestionType.keySignature,
    difficulty: AssessmentNotationDifficulty.advanced,
    prompt: 'Which major key signature is shown?',
    clef: AssessmentNotationClef.treble,
    keySignature: AssessmentKeySignature.dMajor,
    options: [
      AssessmentNotationOption(id: 'c_major', label: 'C major'),
      AssessmentNotationOption(id: 'g_major', label: 'G major'),
      AssessmentNotationOption(id: 'd_major', label: 'D major'),
      AssessmentNotationOption(id: 'f_major', label: 'F major'),
    ],
    correctOptionId: 'd_major',
  ),
  AssessmentNotationQuestion(
    id: 'advanced_perfect_fifth',
    type: AssessmentNotationQuestionType.interval,
    difficulty: AssessmentNotationDifficulty.advanced,
    prompt: 'What is the written interval?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [5, 9],
    options: [
      AssessmentNotationOption(id: 'major_third', label: 'Major third'),
      AssessmentNotationOption(id: 'perfect_fourth', label: 'Perfect fourth'),
      AssessmentNotationOption(id: 'perfect_fifth', label: 'Perfect fifth'),
      AssessmentNotationOption(id: 'major_sixth', label: 'Major sixth'),
    ],
    correctOptionId: 'perfect_fifth',
  ),
  AssessmentNotationQuestion(
    id: 'advanced_c_major_triad',
    type: AssessmentNotationQuestionType.chord,
    difficulty: AssessmentNotationDifficulty.advanced,
    prompt: 'Which root-position chord is shown?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [5, 7, 9],
    options: [
      AssessmentNotationOption(id: 'c_major', label: 'C major'),
      AssessmentNotationOption(id: 'd_minor', label: 'D minor'),
      AssessmentNotationOption(id: 'e_minor', label: 'E minor'),
      AssessmentNotationOption(id: 'f_major', label: 'F major'),
    ],
    correctOptionId: 'c_major',
  ),
  AssessmentNotationQuestion(
    id: 'advanced_short_passage',
    type: AssessmentNotationQuestionType.shortPassage,
    difficulty: AssessmentNotationDifficulty.advanced,
    prompt: 'How many quarter-note beats does this passage contain?',
    clef: AssessmentNotationClef.treble,
    staffSteps: [5, 6, 7, 8],
    rhythmValues: [
      AssessmentRhythmValue.quarter,
      AssessmentRhythmValue.eighth,
      AssessmentRhythmValue.eighth,
      AssessmentRhythmValue.half,
    ],
    timeSignatureTop: 4,
    timeSignatureBottom: 4,
    options: [
      AssessmentNotationOption(id: 'two_beats', label: '2 beats'),
      AssessmentNotationOption(id: 'three_beats', label: '3 beats'),
      AssessmentNotationOption(id: 'four_beats', label: '4 beats'),
      AssessmentNotationOption(id: 'five_beats', label: '5 beats'),
    ],
    correctOptionId: 'four_beats',
  ),
];
