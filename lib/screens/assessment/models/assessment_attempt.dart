import 'assessment_piano_task.dart';

/// The lifecycle states an assessment can have.
///
/// All three values can be stored. Before expiration is permanently saved,
/// [expired] can also be derived from the last trusted Firestore server time.
enum AssessmentAttemptStatus { inProgress, completed, expired }

/// The ordered sections that make up the assessment experience.
///
/// Saving the current section lets a user close the app and resume later.
enum AssessmentSection {
  introduction,
  questionnaire,
  notationReading,
  pianoExecution,
  results,
}

/// The three placement levels that the assessment can assign.
///
/// Their order is intentional because the scoring service compares their
/// indexes to select the weaker required skill.
enum AssessmentSkillLevel { beginner, intermediate, advanced }

/// Records how the user's permanent assessment placement was produced.
enum AssessmentPlacementMethod {
  fullAssessment,
  selfReportedBeginner,
}

/// Stores the score produced by the notation-reading section.
class AssessmentNotationScore {
  const AssessmentNotationScore({
    required this.beginnerCorrect,
    required this.intermediateCorrect,
    required this.advancedCorrect,
    required this.totalCorrect,
  });

  /// The notation assessment currently contains six questions per group.
  static const int questionsPerDifficulty = 6;

  /// The total number of notation questions in assessment version 1.
  static const int totalQuestions = 18;

  /// Correct answers from the beginner notation group.
  final int beginnerCorrect;

  /// Correct answers from the intermediate notation group.
  final int intermediateCorrect;

  /// Correct answers from the advanced notation group.
  final int advancedCorrect;

  /// Correct answers across the complete notation section.
  final int totalCorrect;

  /// Returns a value from zero to one for later placement calculations.
  double get accuracy {
    return totalCorrect / totalQuestions;
  }
}

/// An immutable, in-memory representation of the user's current assessment.
///
/// Firestore is the source of truth for all timestamps. The phone clock is not
/// used to decide whether this attempt may be resumed or restarted.
class AssessmentAttempt {
  const AssessmentAttempt({
    required this.id,
    required this.userId,
    required this.status,
    required this.currentSection,
    required this.startedAt,
    required this.expiresAt,
    required this.serverCheckedAt,
    required this.assessmentVersion,
    // An empty map means the questionnaire has not been submitted yet.
    this.questionnaireAnswers = const {},

    // An empty map means notation reading has not been submitted yet.
    this.notationReadingAnswers = const {},

    // The score stays null until notation reading is submitted.
    this.notationReadingScore,

    // An empty map means piano execution has not been submitted yet.
    this.pianoTaskResults = const {},

    // The score stays null until every piano task is submitted.
    this.pianoExecutionScore,

    // Placement levels stay null until the assessment is completed.
    this.notationReadingLevel,
    this.pianoExecutionLevel,
    this.finalSkillLevel,

    // The method is saved when the assessment receives a permanent result.
    this.placementMethod,

    this.completedAt,
  });

  /// Every unfinished attempt has exactly 72 hours to be completed.
  static const Duration completionWindow = Duration(days: 3);

  /// The fixed Firestore document ID. It is currently always `current`.
  final String id;

  /// The Firebase Authentication UID that owns this attempt.
  final String userId;

  /// The lifecycle status saved for this attempt.
  final AssessmentAttemptStatus status;

  /// The section the user should see when the assessment resumes.
  final AssessmentSection currentSection;

  /// The Firestore server time at which this attempt began.
  final DateTime startedAt;

  /// The exact deadline: [startedAt] plus [completionWindow].
  final DateTime expiresAt;

  /// A recently refreshed Firestore server time used for lifecycle decisions.
  final DateTime serverCheckedAt;

  /// Identifies which questions, excerpts, and scoring rules were used.
  final int assessmentVersion;

  // Stores the option selected for each questionnaire question.
  //
  // Example:
  // {
  //   'piano_experience': 'under_one_year',
  //   'sheet_music_experience': 'basic_familiarity',
  // }
  final Map<String, String> questionnaireAnswers;

  /// Stores the selected option ID for every notation-reading question.
  final Map<String, String> notationReadingAnswers;

  /// Remains null until every notation-reading answer is submitted.
  final AssessmentNotationScore? notationReadingScore;

  /// Stores finalized piano results by their permanent task ID.
  final Map<String, AssessmentPianoTaskResult> pianoTaskResults;

  /// Remains null until all nine piano tasks are submitted.
  final AssessmentPianoScore? pianoExecutionScore;

  /// The placement calculated from the three notation difficulty groups.
  final AssessmentSkillLevel? notationReadingLevel;

  /// The placement calculated from the three piano difficulty groups.
  final AssessmentSkillLevel? pianoExecutionLevel;

  /// The lower of [notationReadingLevel] and [pianoExecutionLevel].
  final AssessmentSkillLevel? finalSkillLevel;

  /// Distinguishes a full performance result from the Beginner shortcut.
  final AssessmentPlacementMethod? placementMethod;

  /// The Firestore server time at which the assessment was completed.
  /// It remains null while the assessment is unfinished.
  final DateTime? completedAt;

  /// Returns the trustworthy status based on the last Firestore server check.
  AssessmentAttemptStatus get effectiveStatus {
    // A completed result stays completed even after its former deadline.
    if (status == AssessmentAttemptStatus.completed) {
      return AssessmentAttemptStatus.completed;
    }

    // Equality counts as expired, so the attempt ends exactly at the deadline.
    if (!serverCheckedAt.isBefore(expiresAt)) {
      return AssessmentAttemptStatus.expired;
    }

    return status;
  }

  /// Whether Firestore's last server check says the attempt may continue.
  bool get canContinue {
    return effectiveStatus == AssessmentAttemptStatus.inProgress;
  }

  /// Time remaining at the moment represented by [serverCheckedAt].
  ///
  /// A future screen can count down locally from this duration for display,
  /// but it must refresh the server time before a protected write or submit.
  Duration get remainingTime {
    if (!canContinue) {
      return Duration.zero;
    }

    return expiresAt.difference(serverCheckedAt);
  }
}
