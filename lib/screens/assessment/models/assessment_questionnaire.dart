/// One selectable answer in a background questionnaire question.
class AssessmentQuestionnaireOption {
  const AssessmentQuestionnaireOption({required this.id, required this.label});

  /// Stable value saved to Firestore.
  final String id;

  /// Readable text displayed to the user.
  final String label;
}

/// One required background questionnaire question.
class AssessmentQuestionnaireQuestion {
  const AssessmentQuestionnaireQuestion({
    required this.id,
    required this.title,
    required this.options,
  });

  /// Stable question identifier saved with the selected answer.
  final String id;

  /// Question displayed to the user.
  final String title;

  /// Answers the user may select.
  final List<AssessmentQuestionnaireOption> options;
}

/// Version 1 background questionnaire.
///
/// Most answers provide context only. A direct statement that the user is new
/// to piano or cannot read sheet music can safely trigger Beginner placement.
const List<AssessmentQuestionnaireQuestion> assessmentQuestionnaireQuestions = [
  AssessmentQuestionnaireQuestion(
    id: 'piano_experience',
    title: 'How long have you been playing the piano or keyboard?',
    options: [
      AssessmentQuestionnaireOption(
        id: 'new_to_piano',
        label: 'I am just starting',
      ),
      AssessmentQuestionnaireOption(
        id: 'under_one_year',
        label: 'Less than one year',
      ),
      AssessmentQuestionnaireOption(
        id: 'one_to_three_years',
        label: 'One to three years',
      ),
      AssessmentQuestionnaireOption(
        id: 'more_than_three_years',
        label: 'More than three years',
      ),
    ],
  ),
  AssessmentQuestionnaireQuestion(
    id: 'sheet_music_experience',
    title: 'How familiar are you with reading sheet music?',
    options: [
      AssessmentQuestionnaireOption(
        id: 'not_familiar',
        label: 'I have not learned sheet music',
      ),
      AssessmentQuestionnaireOption(
        id: 'basic_familiarity',
        label: 'I recognize a few notes and symbols',
      ),
      AssessmentQuestionnaireOption(
        id: 'moderate_familiarity',
        label: 'I can read simple sheet music',
      ),
      AssessmentQuestionnaireOption(
        id: 'comfortable',
        label: 'I am comfortable reading sheet music',
      ),
    ],
  ),
  AssessmentQuestionnaireQuestion(
    id: 'learning_method',
    title: 'How have you mainly learned piano?',
    options: [
      AssessmentQuestionnaireOption(
        id: 'no_formal_learning',
        label: 'I have not started learning yet',
      ),
      AssessmentQuestionnaireOption(
        id: 'teacher',
        label: 'With a piano teacher',
      ),
      AssessmentQuestionnaireOption(id: 'self_taught', label: 'Self-taught'),
      AssessmentQuestionnaireOption(
        id: 'mixed_learning',
        label: 'A mixture of lessons and self-study',
      ),
    ],
  ),
  AssessmentQuestionnaireQuestion(
    id: 'primary_goal',
    title: 'What is your main goal in SoundSight?',
    options: [
      AssessmentQuestionnaireOption(
        id: 'learn_notation',
        label: 'Learn how to read music notation',
      ),
      AssessmentQuestionnaireOption(
        id: 'improve_sight_reading',
        label: 'Improve my sight-reading',
      ),
      AssessmentQuestionnaireOption(
        id: 'improve_coordination',
        label: 'Improve my piano coordination',
      ),
      AssessmentQuestionnaireOption(
        id: 'track_progress',
        label: 'Understand and track my current ability',
      ),
    ],
  ),
];

/// Returns true when either required skill is explicitly self-reported at the
/// lowest level.
///
/// The shortcut can only assign Beginner. It can never award Intermediate or
/// Advanced without completing the objective assessment sections.
bool shouldAssignBeginnerFromBackgroundAnswers(
  Map<String, String> answers,
) {
  final isNewToPiano = answers['piano_experience'] == 'new_to_piano';
  final cannotReadSheetMusic =
      answers['sheet_music_experience'] == 'not_familiar';

  return isNewToPiano || cannotReadSheetMusic;
}
