/// The execution complexity measured by a piano task.
///
/// This is only one part of the final SoundSight level. The notation-reading
/// result can still limit the user's final placement.
enum AssessmentPianoDifficulty {
  beginner,
  intermediate,
  advanced,
}

/// Converts a MIDI note number into the scientific pitch name shown to users.
String _displayNameForMidiNote(int midiNote) {
  const pitchNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  final pitchName = pitchNames[midiNote.remainder(12)];
  final octave = midiNote ~/ 12 - 1;

  return '$pitchName$octave';
}

/// One expected piano key or chord at a specific musical beat.
class AssessmentPianoNoteGroup {
  const AssessmentPianoNoteGroup({
    required this.beatOffset,
    required this.midiNotes,
  });

  /// The number of beats after task playback begins.
  final double beatOffset;

  /// One MIDI note for a single key or multiple notes for a chord.
  final Set<int> midiNotes;

  /// A readable key or chord label such as `C4` or `C4 + E4 + G4`.
  String get displayLabel {
    final sortedNotes = midiNotes.toList()..sort();

    return sortedNotes.map(_displayNameForMidiNote).join(' + ');
  }
}

/// Describes one MIDI-measurable piano execution task.
class AssessmentPianoTask {
  const AssessmentPianoTask({
    required this.id,
    required this.difficulty,
    required this.title,
    required this.instruction,
    required this.timingInstruction,
    required this.tempoBpm,
    required this.countInBeats,
    required this.noteGroups,
  });

  /// A permanent identifier used when saving the task result.
  final String id;

  /// Groups the task for later piano-execution scoring.
  final AssessmentPianoDifficulty difficulty;

  /// A short task name displayed to the user.
  final String title;

  /// Explains the required keys without using sheet notation.
  final String instruction;

  /// Explains exactly which metronome clicks require a performance.
  final String timingInstruction;

  /// Controls the task's metronome and expected performance timing.
  final int tempoBpm;

  /// Gives the user time to prepare before MIDI notes are evaluated.
  final int countInBeats;

  /// The ordered notes or chords expected during the performance.
  final List<AssessmentPianoNoteGroup> noteGroups;

  /// Displays the complete performance sequence before the task starts.
  String get displayedSequence {
    return noteGroups.map((group) => group.displayLabel).join('  →  ');
  }

  /// Displays the first key or chord that must be played with GO.
  String get firstGroupLabel {
    return noteGroups.first.displayLabel;
  }

  /// Converts a beat position into elapsed task time.
  Duration scheduledTimeFor(AssessmentPianoNoteGroup group) {
    final microsecondsPerBeat = Duration.microsecondsPerMinute / tempoBpm;

    return Duration(
      microseconds: (group.beatOffset * microsecondsPerBeat).round(),
    );
  }
}

/// Immutable statistics produced after one piano task finishes.
class AssessmentPianoTaskResult {
  const AssessmentPianoTaskResult({
    required this.taskId,
    required this.difficulty,
    required this.totalGroupCount,
    required this.correctGroupCount,
    required this.wrongGroupCount,
    required this.missedGroupCount,
    required this.timingMistakeCount,
  });

  final String taskId;
  final AssessmentPianoDifficulty difficulty;
  final int totalGroupCount;
  final int correctGroupCount;
  final int wrongGroupCount;
  final int missedGroupCount;
  final int timingMistakeCount;

  /// Percentage completed correctly without a recorded mistake.
  int get accuracyPercentage {
    if (totalGroupCount == 0) {
      return 0;
    }

    return (correctGroupCount / totalGroupCount * 100).round();
  }

  /// Converts this immutable result into Firestore-compatible values.
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'difficulty': difficulty.name,
      'totalGroupCount': totalGroupCount,
      'correctGroupCount': correctGroupCount,
      'wrongGroupCount': wrongGroupCount,
      'missedGroupCount': missedGroupCount,
      'timingMistakeCount': timingMistakeCount,
    };
  }
}

/// Aggregated piano-execution score across all nine tasks.
class AssessmentPianoScore {
  const AssessmentPianoScore({
    required this.beginnerCorrectGroups,
    required this.beginnerTotalGroups,
    required this.intermediateCorrectGroups,
    required this.intermediateTotalGroups,
    required this.advancedCorrectGroups,
    required this.advancedTotalGroups,
    required this.totalCorrectGroups,
    required this.totalGroups,
    required this.wrongGroups,
    required this.missedGroups,
    required this.timingMistakes,
  });

  final int beginnerCorrectGroups;
  final int beginnerTotalGroups;
  final int intermediateCorrectGroups;
  final int intermediateTotalGroups;
  final int advancedCorrectGroups;
  final int advancedTotalGroups;
  final int totalCorrectGroups;
  final int totalGroups;
  final int wrongGroups;
  final int missedGroups;
  final int timingMistakes;

  /// Overall MIDI-measurable execution accuracy.
  int get accuracyPercentage {
    if (totalGroups == 0) {
      return 0;
    }

    return (totalCorrectGroups / totalGroups * 100).round();
  }
}

/// Piano execution tasks used by assessment version 1.
///
/// The instructions use key names instead of sheet notation so this section
/// measures MIDI-detectable piano execution separately from notation reading.
const List<AssessmentPianoTask> assessmentPianoTasks = [
  AssessmentPianoTask(
    id: 'beginner_middle_c',
    difficulty: AssessmentPianoDifficulty.beginner,
    title: 'Middle C',
    instruction: 'Play C4, which is Middle C.',
    timingInstruction: 'Play C4 once when GO appears.',
    tempoBpm: 60,
    countInBeats: 2,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {60}),
    ],
  ),
  AssessmentPianoTask(
    id: 'beginner_five_finger_pattern',
    difficulty: AssessmentPianoDifficulty.beginner,
    title: 'Five-finger pattern',
    instruction: 'Play C4, D4, E4, F4, and G4 upward.',
    timingInstruction:
        'Play C4 with GO, then play one note on every following click.',
    tempoBpm: 60,
    countInBeats: 4,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {60}),
      AssessmentPianoNoteGroup(beatOffset: 1, midiNotes: {62}),
      AssessmentPianoNoteGroup(beatOffset: 2, midiNotes: {64}),
      AssessmentPianoNoteGroup(beatOffset: 3, midiNotes: {65}),
      AssessmentPianoNoteGroup(beatOffset: 4, midiNotes: {67}),
    ],
  ),
  AssessmentPianoTask(
    id: 'beginner_c_major_chord',
    difficulty: AssessmentPianoDifficulty.beginner,
    title: 'C major chord',
    instruction: 'Play C4, E4, and G4 together.',
    timingInstruction: 'Play the complete chord once when GO appears.',
    tempoBpm: 60,
    countInBeats: 2,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {60, 64, 67}),
    ],
  ),
  AssessmentPianoTask(
    id: 'intermediate_c_major_scale',
    difficulty: AssessmentPianoDifficulty.intermediate,
    title: 'C major scale',
    instruction:
        'Play the C major scale upward from C4 to C5.',
    timingInstruction:
        'Play C4 with GO, then play one note on every following click.',
    tempoBpm: 80,
    countInBeats: 4,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {60}),
      AssessmentPianoNoteGroup(beatOffset: 1, midiNotes: {62}),
      AssessmentPianoNoteGroup(beatOffset: 2, midiNotes: {64}),
      AssessmentPianoNoteGroup(beatOffset: 3, midiNotes: {65}),
      AssessmentPianoNoteGroup(beatOffset: 4, midiNotes: {67}),
      AssessmentPianoNoteGroup(beatOffset: 5, midiNotes: {69}),
      AssessmentPianoNoteGroup(beatOffset: 6, midiNotes: {71}),
      AssessmentPianoNoteGroup(beatOffset: 7, midiNotes: {72}),
    ],
  ),
  AssessmentPianoTask(
    id: 'intermediate_c_major_arpeggio',
    difficulty: AssessmentPianoDifficulty.intermediate,
    title: 'C major arpeggio',
    instruction:
        'Play C4, E4, G4, C5, G4, E4, and C4.',
    timingInstruction:
        'Play C4 with GO, then play one note on every following click.',
    tempoBpm: 80,
    countInBeats: 4,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {60}),
      AssessmentPianoNoteGroup(beatOffset: 1, midiNotes: {64}),
      AssessmentPianoNoteGroup(beatOffset: 2, midiNotes: {67}),
      AssessmentPianoNoteGroup(beatOffset: 3, midiNotes: {72}),
      AssessmentPianoNoteGroup(beatOffset: 4, midiNotes: {67}),
      AssessmentPianoNoteGroup(beatOffset: 5, midiNotes: {64}),
      AssessmentPianoNoteGroup(beatOffset: 6, midiNotes: {60}),
    ],
  ),
  AssessmentPianoTask(
    id: 'intermediate_chord_progression',
    difficulty: AssessmentPianoDifficulty.intermediate,
    title: 'Chord progression',
    instruction:
        'Play C3-E3-G3, F3-A3-C4, G3-B3-D4, then C3-E3-G3.',
    timingInstruction:
        'Play the first chord with GO, then one chord every second click.',
    tempoBpm: 70,
    countInBeats: 4,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {48, 52, 55}),
      AssessmentPianoNoteGroup(beatOffset: 2, midiNotes: {53, 57, 60}),
      AssessmentPianoNoteGroup(beatOffset: 4, midiNotes: {55, 59, 62}),
      AssessmentPianoNoteGroup(beatOffset: 6, midiNotes: {48, 52, 55}),
    ],
  ),
  AssessmentPianoTask(
    id: 'advanced_two_octave_scale',
    difficulty: AssessmentPianoDifficulty.advanced,
    title: 'Two-octave scale',
    instruction:
        'Play the C major scale upward from C3 to C5.',
    timingInstruction:
        'Play C3 with GO, then play one note on every following click.',
    tempoBpm: 100,
    countInBeats: 4,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {48}),
      AssessmentPianoNoteGroup(beatOffset: 1, midiNotes: {50}),
      AssessmentPianoNoteGroup(beatOffset: 2, midiNotes: {52}),
      AssessmentPianoNoteGroup(beatOffset: 3, midiNotes: {53}),
      AssessmentPianoNoteGroup(beatOffset: 4, midiNotes: {55}),
      AssessmentPianoNoteGroup(beatOffset: 5, midiNotes: {57}),
      AssessmentPianoNoteGroup(beatOffset: 6, midiNotes: {59}),
      AssessmentPianoNoteGroup(beatOffset: 7, midiNotes: {60}),
      AssessmentPianoNoteGroup(beatOffset: 8, midiNotes: {62}),
      AssessmentPianoNoteGroup(beatOffset: 9, midiNotes: {64}),
      AssessmentPianoNoteGroup(beatOffset: 10, midiNotes: {65}),
      AssessmentPianoNoteGroup(beatOffset: 11, midiNotes: {67}),
      AssessmentPianoNoteGroup(beatOffset: 12, midiNotes: {69}),
      AssessmentPianoNoteGroup(beatOffset: 13, midiNotes: {71}),
      AssessmentPianoNoteGroup(beatOffset: 14, midiNotes: {72}),
    ],
  ),
  AssessmentPianoTask(
    id: 'advanced_chord_inversions',
    difficulty: AssessmentPianoDifficulty.advanced,
    title: 'Chord inversions',
    instruction:
        'Play C3-E3-G3, E3-G3-C4, G3-C4-E4, then C4-E4-G4.',
    timingInstruction:
        'Play the first chord with GO, then one chord every second click.',
    tempoBpm: 80,
    countInBeats: 4,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {48, 52, 55}),
      AssessmentPianoNoteGroup(beatOffset: 2, midiNotes: {52, 55, 60}),
      AssessmentPianoNoteGroup(beatOffset: 4, midiNotes: {55, 60, 64}),
      AssessmentPianoNoteGroup(beatOffset: 6, midiNotes: {60, 64, 67}),
    ],
  ),
  AssessmentPianoTask(
    id: 'advanced_parallel_scale',
    difficulty: AssessmentPianoDifficulty.advanced,
    title: 'Parallel scale',
    instruction:
        'Play C3-C4 through C4-C5 with both hands in parallel motion.',
    timingInstruction:
        'Play both C keys with GO, then play the next pair on every click.',
    tempoBpm: 100,
    countInBeats: 4,
    noteGroups: [
      AssessmentPianoNoteGroup(beatOffset: 0, midiNotes: {48, 60}),
      AssessmentPianoNoteGroup(beatOffset: 1, midiNotes: {50, 62}),
      AssessmentPianoNoteGroup(beatOffset: 2, midiNotes: {52, 64}),
      AssessmentPianoNoteGroup(beatOffset: 3, midiNotes: {53, 65}),
      AssessmentPianoNoteGroup(beatOffset: 4, midiNotes: {55, 67}),
      AssessmentPianoNoteGroup(beatOffset: 5, midiNotes: {57, 69}),
      AssessmentPianoNoteGroup(beatOffset: 6, midiNotes: {59, 71}),
      AssessmentPianoNoteGroup(beatOffset: 7, midiNotes: {60, 72}),
    ],
  ),
];
