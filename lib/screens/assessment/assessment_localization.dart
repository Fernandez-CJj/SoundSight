import 'package:soundsight/l10n/generated/app_localizations.dart';
import 'package:soundsight/screens/assessment/models/assessment_notation_question.dart';
import 'package:soundsight/screens/assessment/models/assessment_piano_task.dart';
import 'package:soundsight/screens/assessment/models/assessment_questionnaire.dart';

String localizedQuestionnaireQuestion(
  AppLocalizations l10n,
  AssessmentQuestionnaireQuestion question,
) {
  return switch (question.id) {
    'piano_experience' => l10n.assessmentQuestionPianoExperience,
    'sheet_music_experience' =>
      l10n.assessmentQuestionSheetMusicExperience,
    'learning_method' => l10n.assessmentQuestionLearningMethod,
    'primary_goal' => l10n.assessmentQuestionPrimaryGoal,
    _ => question.title,
  };
}

String localizedQuestionnaireOption(
  AppLocalizations l10n,
  AssessmentQuestionnaireOption option,
) {
  return switch (option.id) {
    'new_to_piano' => l10n.assessmentOptionNewToPiano,
    'under_one_year' => l10n.assessmentOptionUnderOneYear,
    'one_to_three_years' => l10n.assessmentOptionOneToThreeYears,
    'more_than_three_years' => l10n.assessmentOptionMoreThanThreeYears,
    'not_familiar' => l10n.assessmentOptionNotFamiliar,
    'basic_familiarity' => l10n.assessmentOptionBasicFamiliarity,
    'moderate_familiarity' => l10n.assessmentOptionModerateFamiliarity,
    'comfortable' => l10n.assessmentOptionComfortable,
    'no_formal_learning' => l10n.assessmentOptionNoFormalLearning,
    'teacher' => l10n.assessmentOptionTeacher,
    'self_taught' => l10n.assessmentOptionSelfTaught,
    'mixed_learning' => l10n.assessmentOptionMixedLearning,
    'learn_notation' => l10n.assessmentOptionLearnNotation,
    'improve_sight_reading' => l10n.assessmentOptionImproveSightReading,
    'improve_coordination' => l10n.assessmentOptionImproveCoordination,
    'track_progress' => l10n.assessmentOptionTrackProgress,
    _ => option.label,
  };
}

String localizedNotationPrompt(
  AppLocalizations l10n,
  AssessmentNotationQuestion question,
) {
  return switch (question.id) {
    'beginner_treble_e4' ||
    'beginner_bass_g2' ||
    'beginner_treble_c5' => l10n.assessmentNotationPromptNote,
    'beginner_quarter_note' ||
    'beginner_half_note' => l10n.assessmentNotationPromptBeatValue,
    'beginner_four_four_time' =>
      l10n.assessmentNotationPromptTimeSignature,
    'intermediate_treble_c4' ||
    'intermediate_bass_e2' => l10n.assessmentNotationPromptLedgerNote,
    'intermediate_f_sharp' => l10n.assessmentNotationPromptAccidental,
    'intermediate_g_major' ||
    'intermediate_f_major' ||
    'advanced_d_major' => l10n.assessmentNotationPromptMajorKey,
    'intermediate_third' => l10n.assessmentNotationPromptIntervalSize,
    'advanced_bass_c4' => l10n.assessmentNotationPromptUpperLedgerNote,
    'advanced_six_eight_time' =>
      l10n.assessmentNotationPromptCompoundMeter,
    'advanced_perfect_fifth' =>
      l10n.assessmentNotationPromptWrittenInterval,
    'advanced_c_major_triad' => l10n.assessmentNotationPromptRootChord,
    'advanced_short_passage' => l10n.assessmentNotationPromptPassageBeats,
    _ => question.prompt,
  };
}

String localizedNotationOption(
  AppLocalizations l10n,
  AssessmentNotationOption option,
) {
  return switch (option.id) {
    'half_beat' => l10n.assessmentOptionHalfBeat,
    'one_beat' => l10n.assessmentOptionOneBeat,
    'two_beats' => l10n.assessmentOptionTwoBeats,
    'three_beats' => l10n.assessmentOptionThreeBeats,
    'four_beats' => l10n.assessmentOptionFourBeats,
    'five_beats' => l10n.assessmentOptionFiveBeats,
    'two_quarter_beats' => l10n.assessmentOptionTwoQuarterBeats,
    'three_quarter_beats' => l10n.assessmentOptionThreeQuarterBeats,
    'four_quarter_beats' => l10n.assessmentOptionFourQuarterBeats,
    'four_eighth_beats' => l10n.assessmentOptionFourEighthBeats,
    'two_dotted_quarter_beats' =>
      l10n.assessmentOptionTwoDottedQuarterBeats,
    'six_quarter_beats' => l10n.assessmentOptionSixQuarterBeats,
    'second' => l10n.assessmentOptionSecond,
    'third' => l10n.assessmentOptionThird,
    'fourth' => l10n.assessmentOptionFourth,
    'fifth' => l10n.assessmentOptionFifth,
    'major_third' => l10n.assessmentOptionMajorThird,
    'perfect_fourth' => l10n.assessmentOptionPerfectFourth,
    'perfect_fifth' => l10n.assessmentOptionPerfectFifth,
    'major_sixth' => l10n.assessmentOptionMajorSixth,
    _ => option.label,
  };
}

String localizedPianoTaskTitle(
  AppLocalizations l10n,
  AssessmentPianoTask task,
) {
  return switch (task.id) {
    'beginner_middle_c' => l10n.assessmentTaskMiddleCTitle,
    'beginner_five_finger_pattern' => l10n.assessmentTaskFiveFingerTitle,
    'beginner_c_major_chord' => l10n.assessmentTaskCMajorChordTitle,
    'intermediate_c_major_scale' => l10n.assessmentTaskCMajorScaleTitle,
    'intermediate_c_major_arpeggio' =>
      l10n.assessmentTaskCMajorArpeggioTitle,
    'intermediate_chord_progression' =>
      l10n.assessmentTaskChordProgressionTitle,
    'advanced_two_octave_scale' => l10n.assessmentTaskTwoOctaveTitle,
    'advanced_chord_inversions' => l10n.assessmentTaskChordInversionsTitle,
    'advanced_parallel_scale' => l10n.assessmentTaskParallelScaleTitle,
    _ => task.title,
  };
}

String localizedPianoTaskInstruction(
  AppLocalizations l10n,
  AssessmentPianoTask task,
) {
  return switch (task.id) {
    'beginner_middle_c' => l10n.assessmentTaskMiddleCInstruction,
    'beginner_five_finger_pattern' =>
      l10n.assessmentTaskFiveFingerInstruction,
    'beginner_c_major_chord' =>
      l10n.assessmentTaskCMajorChordInstruction,
    'intermediate_c_major_scale' =>
      l10n.assessmentTaskCMajorScaleInstruction,
    'intermediate_c_major_arpeggio' =>
      l10n.assessmentTaskCMajorArpeggioInstruction,
    'intermediate_chord_progression' =>
      l10n.assessmentTaskChordProgressionInstruction,
    'advanced_two_octave_scale' =>
      l10n.assessmentTaskTwoOctaveInstruction,
    'advanced_chord_inversions' =>
      l10n.assessmentTaskChordInversionsInstruction,
    'advanced_parallel_scale' =>
      l10n.assessmentTaskParallelScaleInstruction,
    _ => task.instruction,
  };
}

String localizedPianoTaskTiming(
  AppLocalizations l10n,
  AssessmentPianoTask task,
) {
  return switch (task.id) {
    'beginner_middle_c' => l10n.assessmentTaskMiddleCTiming,
    'beginner_five_finger_pattern' ||
    'intermediate_c_major_scale' ||
    'intermediate_c_major_arpeggio' =>
      l10n.assessmentTaskNoteEveryClickTiming('C4'),
    'beginner_c_major_chord' => l10n.assessmentTaskChordGoTiming,
    'intermediate_chord_progression' ||
    'advanced_chord_inversions' =>
      l10n.assessmentTaskChordEverySecondClickTiming,
    'advanced_two_octave_scale' =>
      l10n.assessmentTaskNoteEveryClickTiming('C3'),
    'advanced_parallel_scale' => l10n.assessmentTaskParallelTiming,
    _ => task.timingInstruction,
  };
}
