import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/assessment_attempt.dart';
import '../models/assessment_notation_question.dart';
import '../models/assessment_piano_task.dart';
import '../models/assessment_questionnaire.dart';

/// Creates, loads, and resumes the user's one allowed assessment attempt.
///
/// The service deliberately uses one fixed document:
/// `users/{userId}/assessment/current`.
/// Once that document expires, it stays expired and the user cannot create or
/// restart another attempt from the phone application.
class AssessmentAttemptService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The document name is fixed so each user can have only one assessment.
  static const String _currentDocumentId = 'current';

  /// The assessment version currently understood by the application.
  static const int _currentAssessmentVersion = 1;

  /// The level assigned when an unfinished assessment reaches its deadline.
  static const String _expiredSkillLevel = 'beginner';

  /// A notation tier is passed by answering at least four of its six items.
  static const int _notationCorrectAnswersRequired = 4;

  /// A piano tier is passed with at least seventy-percent correct note groups.
  static const int _pianoAccuracyRequired = 70;

  /// Starts the first assessment or returns the user's existing assessment.
  ///
  /// An expired assessment is finalized as expired and returned. This method
  /// never creates a replacement for an existing assessment document.
  Future<AssessmentAttempt> startOrResumeAttempt() async {
    final user = _requireCurrentUser();
    final reference = _currentAttemptReference(user.uid);

    var document = await reference.get(const GetOptions(source: Source.server));

    // No document means this user has never started an assessment.
    if (!document.exists) {
      document = await _createFirstAttempt(reference, user.uid);
    } else {
      // Finalized attempts are permanent and no longer need a time refresh.
      if (_isFinalizedDocument(document)) {
        return _attemptFromDocument(document);
      }

      // Recover safely if the app closed between the two initialization writes.
      document = await _ensureExpirationTime(document);
    }

    // This write/read round trip gives us a current, authoritative server time.
    document = await _refreshServerTime(document);

    return _finalizeExpirationIfNeeded(document: document, userId: user.uid);
  }

  /// Loads the current attempt without creating a new one.
  ///
  /// Returns null when the user has never started. If the attempt expired, this
  /// method permanently marks it expired and assigns Beginner skill level.
  Future<AssessmentAttempt?> loadCurrentAttempt() async {
    final user = _requireCurrentUser();
    final reference = _currentAttemptReference(user.uid);

    var document = await reference.get(const GetOptions(source: Source.server));

    if (!document.exists) {
      return null;
    }

    // Completion and expiration are permanent, so their documents stay
    // unchanged whenever the app loads them again.
    if (_isFinalizedDocument(document)) {
      return _attemptFromDocument(document);
    }

    document = await _ensureExpirationTime(document);
    document = await _refreshServerTime(document);

    return _finalizeExpirationIfNeeded(document: document, userId: user.uid);
  }

  /// Moves an active assessment to the requested next section.
  ///
  /// The service performs a local transition check for a readable error, while
  /// Firestore Security Rules independently enforce the same section order.
  Future<AssessmentAttempt> advanceToSection(
    AssessmentSection nextSection,
  ) async {
    // Reload first so status, section, and deadline use current server data.
    final currentAttempt = await loadCurrentAttempt();

    if (currentAttempt == null) {
      throw StateError(
        'The assessment must be started before saving progress.',
      );
    }

    if (!currentAttempt.canContinue) {
      throw StateError('The assessment is no longer available.');
    }

    if (!_isAllowedSectionTransition(
      currentSection: currentAttempt.currentSection,
      nextSection: nextSection,
    )) {
      throw StateError(
        'The assessment cannot move from '
        '${currentAttempt.currentSection.name} to ${nextSection.name}.',
      );
    }

    final reference = _currentAttemptReference(currentAttempt.userId);

    await reference.update({
      'currentSection': nextSection.name,
      'serverCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updatedDocument = await reference.get(
      const GetOptions(source: Source.server),
    );

    return _attemptFromDocument(updatedDocument);
  }

  // Validates and saves the completed questionnaire.
  //
  // The answers and section change are saved together. This prevents the
  // assessment from advancing without also saving the questionnaire.
  Future<AssessmentAttempt> submitQuestionnaire(
    Map<String, String> answers,
  ) async {
    final userId = _requireCurrentUser().uid;

    // Validate every answer before sending anything to Firestore.
    final validatedAnswers = _validateQuestionnaireAnswers(answers);

    // Refresh the server time and retrieve the latest attempt state.
    final currentAttempt = await loadCurrentAttempt();

    if (currentAttempt == null) {
      throw StateError('No assessment attempt exists.');
    }

    // An expired or completed assessment cannot accept new answers.
    if (currentAttempt.effectiveStatus != AssessmentAttemptStatus.inProgress) {
      throw StateError('This assessment can no longer be changed.');
    }

    // The questionnaire may only be submitted from its own section.
    if (currentAttempt.currentSection != AssessmentSection.questionnaire) {
      throw StateError(
        'The assessment is not currently on the questionnaire section.',
      );
    }

    final attemptReference = _currentAttemptReference(userId);

    // Save the answers and move to notation reading in one operation.
    await attemptReference.update({
      'questionnaireAnswers': validatedAnswers,
      'currentSection': AssessmentSection.notationReading.name,

      // These timestamps are generated by Firestore, not the phone.
      'serverCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Load the document again so the returned model contains
    // the final server timestamps and saved answers.
    final updatedAttempt = await loadCurrentAttempt();

    if (updatedAttempt == null) {
      throw StateError(
        'The assessment disappeared after submitting the questionnaire.',
      );
    }

    return updatedAttempt;
  }

  /// Completes the assessment as Beginner when the user directly reports that
  /// either piano playing or sheet-music reading is entirely new to them.
  Future<AssessmentAttempt> completeQuestionnaireAsBeginner(
    Map<String, String> answers,
  ) async {
    final userId = _requireCurrentUser().uid;
    final validatedAnswers = _validateQuestionnaireAnswers(answers);

    // This path is only valid for the two explicit Beginner declarations.
    if (!shouldAssignBeginnerFromBackgroundAnswers(validatedAnswers)) {
      throw StateError(
        'These background answers do not qualify for Beginner placement.',
      );
    }

    // Refresh server time before checking the permanent assessment deadline.
    final currentAttempt = await loadCurrentAttempt();

    if (currentAttempt == null) {
      throw StateError('No assessment attempt exists.');
    }

    if (currentAttempt.effectiveStatus !=
        AssessmentAttemptStatus.inProgress) {
      throw StateError('This assessment can no longer be changed.');
    }

    if (currentAttempt.currentSection != AssessmentSection.questionnaire) {
      throw StateError(
        'The assessment is not currently on the questionnaire section.',
      );
    }

    final attemptReference = _currentAttemptReference(userId);
    // Save the permanent assessment result before the review screen opens.
    // The profile level is applied only when the user presses Done there.
    await attemptReference.update({
      'questionnaireAnswers': validatedAnswers,
      'placementMethod':
          AssessmentPlacementMethod.selfReportedBeginner.name,
      'finalSkillLevel': AssessmentSkillLevel.beginner.name,
      'status': AssessmentAttemptStatus.completed.name,
      'currentSection': AssessmentSection.results.name,
      'completedAt': FieldValue.serverTimestamp(),
      'serverCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updatedDocument = await attemptReference.get(
      const GetOptions(source: Source.server),
    );

    return _attemptFromDocument(updatedDocument);
  }

  /// Validates, scores, and saves the completed notation-reading section.
  ///
  /// Answers, scores, and the transition to piano execution are written
  /// together so the section cannot advance without its complete result.
  Future<AssessmentAttempt> submitNotationReading(
    Map<String, String> answers,
  ) async {
    final userId = _requireCurrentUser().uid;

    // Reject missing, extra, or unknown answers before calculating a score.
    final validatedAnswers = _validateNotationReadingAnswers(answers);
    final score = _calculateNotationReadingScore(validatedAnswers);

    // Refresh server time before checking the current lifecycle and section.
    final currentAttempt = await loadCurrentAttempt();

    if (currentAttempt == null) {
      throw StateError('No assessment attempt exists.');
    }

    if (currentAttempt.effectiveStatus !=
        AssessmentAttemptStatus.inProgress) {
      throw StateError('This assessment can no longer be changed.');
    }

    if (currentAttempt.currentSection !=
        AssessmentSection.notationReading) {
      throw StateError(
        'The assessment is not currently on the notation-reading section.',
      );
    }

    final attemptReference = _currentAttemptReference(userId);

    // Save the complete notation result and advance in one operation.
    await attemptReference.update({
      'notationReadingAnswers': validatedAnswers,
      'notationReadingScore': {
        'beginnerCorrect': score.beginnerCorrect,
        'intermediateCorrect': score.intermediateCorrect,
        'advancedCorrect': score.advancedCorrect,
        'totalCorrect': score.totalCorrect,
      },
      'currentSection': AssessmentSection.pianoExecution.name,

      // Firestore generates these timestamps instead of trusting the phone.
      'serverCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Reload the final server values for the next assessment screen.
    final updatedAttempt = await loadCurrentAttempt();

    if (updatedAttempt == null) {
      throw StateError(
        'The assessment disappeared after submitting notation reading.',
      );
    }

    return updatedAttempt;
  }

  /// Validates, scores, and saves the completed piano-execution section.
  ///
  /// All nine task results, section levels, final level, and completion state
  /// are saved before the review screen opens.
  Future<AssessmentAttempt> submitPianoExecution(
    List<AssessmentPianoTaskResult> results,
  ) async {
    final userId = _requireCurrentUser().uid;

    final validatedResults = _validatePianoTaskResults(results);
    final score = _calculatePianoExecutionScore(validatedResults);

    // Refresh server time before checking the current lifecycle and section.
    final currentAttempt = await loadCurrentAttempt();

    if (currentAttempt == null) {
      throw StateError('No assessment attempt exists.');
    }

    if (currentAttempt.effectiveStatus !=
        AssessmentAttemptStatus.inProgress) {
      throw StateError('This assessment can no longer be changed.');
    }

    if (currentAttempt.currentSection != AssessmentSection.pianoExecution) {
      throw StateError(
        'The assessment is not currently on the piano-execution section.',
      );
    }

    final notationScore = currentAttempt.notationReadingScore;

    if (notationScore == null) {
      throw StateError(
        'Notation reading must be completed before piano execution.',
      );
    }

    // Each required ability receives its own level before the weaker one is
    // selected as the final SoundSight placement.
    final notationLevel = _calculateNotationReadingLevel(notationScore);
    final pianoLevel = _calculatePianoExecutionLevel(score);
    final finalLevel = _lowerSkillLevel(notationLevel, pianoLevel);

    final attemptReference = _currentAttemptReference(userId);
    final serializedResults = <String, Map<String, dynamic>>{};

    for (final entry in validatedResults.entries) {
      serializedResults[entry.key] = entry.value.toMap();
    }

    // Complete the assessment first so a USB disconnect or app restart cannot
    // force the user to repeat the piano section.
    await attemptReference.update({
      'pianoTaskResults': serializedResults,
      'pianoExecutionScore': {
        'beginnerCorrectGroups': score.beginnerCorrectGroups,
        'beginnerTotalGroups': score.beginnerTotalGroups,
        'intermediateCorrectGroups': score.intermediateCorrectGroups,
        'intermediateTotalGroups': score.intermediateTotalGroups,
        'advancedCorrectGroups': score.advancedCorrectGroups,
        'advancedTotalGroups': score.advancedTotalGroups,
        'totalCorrectGroups': score.totalCorrectGroups,
        'totalGroups': score.totalGroups,
        'wrongGroups': score.wrongGroups,
        'missedGroups': score.missedGroups,
        'timingMistakes': score.timingMistakes,
      },
      'notationReadingLevel': notationLevel.name,
      'pianoExecutionLevel': pianoLevel.name,
      'finalSkillLevel': finalLevel.name,
      'placementMethod': AssessmentPlacementMethod.fullAssessment.name,
      'status': AssessmentAttemptStatus.completed.name,
      'currentSection': AssessmentSection.results.name,
      'completedAt': FieldValue.serverTimestamp(),

      // Firestore generates these timestamps instead of trusting the phone.
      'serverCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updatedDocument = await attemptReference.get(
      const GetOptions(source: Source.server),
    );

    return _attemptFromDocument(updatedDocument);
  }

  /// Applies a completed assessment's saved level to the main user profile.
  ///
  /// This runs when the user presses Done on the review screen. Because the
  /// assessment was already saved, a failed profile update can be retried
  /// without repeating any assessment section.
  Future<void> applyCompletedSkillLevel() async {
    final userId = _requireCurrentUser().uid;
    final attemptReference = _currentAttemptReference(userId);
    final attemptDocument = await attemptReference.get(
      const GetOptions(source: Source.server),
    );

    if (!attemptDocument.exists) {
      throw StateError('No completed assessment exists.');
    }

    final attempt = _attemptFromDocument(attemptDocument);
    final finalLevel = attempt.finalSkillLevel;

    if (attempt.status != AssessmentAttemptStatus.completed ||
        attempt.currentSection != AssessmentSection.results ||
        finalLevel == null) {
      throw StateError('The assessment result is not ready to be applied.');
    }

    // Firestore Rules verify that this value exactly matches the permanent
    // finalSkillLevel stored in the completed assessment document.
    await _firestore.collection('users').doc(userId).set({
      'skillLevel': finalLevel.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Creates the fixed `current` document for a first-time user.
  Future<DocumentSnapshot<Map<String, dynamic>>> _createFirstAttempt(
    DocumentReference<Map<String, dynamic>> reference,
    String userId,
  ) async {
    await reference.set({
      'userId': userId,
      'status': AssessmentAttemptStatus.inProgress.name,
      'currentSection': AssessmentSection.introduction.name,
      'assessmentVersion': _currentAssessmentVersion,
      'startedAt': FieldValue.serverTimestamp(),
      'expiresAt': null,
      'completedAt': null,
      'serverCheckedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final createdDocument = await reference.get(
      const GetOptions(source: Source.server),
    );

    return _ensureExpirationTime(createdDocument);
  }

  /// Adds the exact 72-hour deadline after Firestore resolves `startedAt`.
  ///
  /// This is intentionally a separate write because a server-timestamp
  /// placeholder cannot perform timestamp arithmetic on the Flutter client.
  Future<DocumentSnapshot<Map<String, dynamic>>> _ensureExpirationTime(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = _requireDocumentData(document);

    if (data['expiresAt'] is Timestamp) {
      return document;
    }

    final startedAt = _requiredDateTime(data: data, fieldName: 'startedAt');
    final expiresAt = startedAt.add(AssessmentAttempt.completionWindow);

    await document.reference.update({
      'expiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.reference.get(const GetOptions(source: Source.server));
  }

  /// Refreshes `serverCheckedAt` so lifecycle decisions never use phone time.
  Future<DocumentSnapshot<Map<String, dynamic>>> _refreshServerTime(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    await document.reference.update({
      'serverCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.reference.get(const GetOptions(source: Source.server));
  }

  /// Permanently expires an unfinished attempt and assigns Beginner level.
  ///
  /// Both documents are written in one atomic batch: either the assessment and
  /// user profile both change, or neither changes. Firestore rules independently
  /// check that the server deadline has passed before accepting the batch.
  Future<AssessmentAttempt> _finalizeExpirationIfNeeded({
    required DocumentSnapshot<Map<String, dynamic>> document,
    required String userId,
  }) async {
    final attempt = _attemptFromDocument(document);

    // Completed assessments keep their calculated result permanently.
    if (attempt.effectiveStatus == AssessmentAttemptStatus.completed) {
      return attempt;
    }

    // An already-finalized expired assessment needs no additional write.
    if (attempt.status == AssessmentAttemptStatus.expired) {
      return attempt;
    }

    // A still-active assessment remains available for the user to continue.
    if (attempt.effectiveStatus != AssessmentAttemptStatus.expired) {
      return attempt;
    }

    final userReference = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch();

    batch.update(document.reference, {
      'status': AssessmentAttemptStatus.expired.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(userReference, {
      'skillLevel': _expiredSkillLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    final expiredDocument = await document.reference.get(
      const GetOptions(source: Source.server),
    );

    return _attemptFromDocument(expiredDocument);
  }

  /// Checks that every questionnaire question has one valid answer.
  Map<String, String> _validateQuestionnaireAnswers(
    Map<String, String> answers,
  ) {
    final expectedQuestionIds = assessmentQuestionnaireQuestions
        .map((question) => question.id)
        .toSet();

    // Extra or missing answers are not accepted.
    if (answers.length != expectedQuestionIds.length ||
        !answers.keys.toSet().containsAll(expectedQuestionIds)) {
      throw StateError('Every questionnaire question must be answered.');
    }

    final validatedAnswers = <String, String>{};

    for (final question in assessmentQuestionnaireQuestions) {
      final selectedOptionId = answers[question.id];

      final isValidOption = question.options.any(
        (option) => option.id == selectedOptionId,
      );

      if (selectedOptionId == null || !isValidOption) {
        throw StateError('An invalid answer was provided for ${question.id}.');
      }

      validatedAnswers[question.id] = selectedOptionId;
    }

    // Return a separate map so the caller cannot change the values
    // while Firestore is saving them.
    return Map<String, String>.unmodifiable(validatedAnswers);
  }

  /// Checks that every notation question has one known option ID.
  Map<String, String> _validateNotationReadingAnswers(
    Map<String, String> answers,
  ) {
    final expectedQuestionIds = assessmentNotationQuestions
        .map((question) => question.id)
        .toSet();

    // Missing questions and unknown extra fields are both rejected.
    if (answers.length != expectedQuestionIds.length ||
        !answers.keys.toSet().containsAll(expectedQuestionIds)) {
      throw StateError('Every notation-reading question must be answered.');
    }

    final validatedAnswers = <String, String>{};

    for (final question in assessmentNotationQuestions) {
      final selectedOptionId = answers[question.id];

      final isKnownOption = question.options.any(
        (option) => option.id == selectedOptionId,
      );

      if (selectedOptionId == null || !isKnownOption) {
        throw StateError(
          'An invalid notation answer was provided for ${question.id}.',
        );
      }

      validatedAnswers[question.id] = selectedOptionId;
    }

    return Map<String, String>.unmodifiable(validatedAnswers);
  }

  /// Calculates notation results without changing the submitted answers.
  AssessmentNotationScore _calculateNotationReadingScore(
    Map<String, String> validatedAnswers,
  ) {
    var beginnerCorrect = 0;
    var intermediateCorrect = 0;
    var advancedCorrect = 0;

    for (final question in assessmentNotationQuestions) {
      final isCorrect =
          validatedAnswers[question.id] == question.correctOptionId;

      if (!isCorrect) {
        continue;
      }

      switch (question.difficulty) {
        case AssessmentNotationDifficulty.beginner:
          beginnerCorrect++;
          break;

        case AssessmentNotationDifficulty.intermediate:
          intermediateCorrect++;
          break;

        case AssessmentNotationDifficulty.advanced:
          advancedCorrect++;
          break;
      }
    }

    return AssessmentNotationScore(
      beginnerCorrect: beginnerCorrect,
      intermediateCorrect: intermediateCorrect,
      advancedCorrect: advancedCorrect,
      totalCorrect:
          beginnerCorrect + intermediateCorrect + advancedCorrect,
    );
  }

  /// Validates one finalized result for every required piano task.
  Map<String, AssessmentPianoTaskResult> _validatePianoTaskResults(
    List<AssessmentPianoTaskResult> results,
  ) {
    if (results.length != assessmentPianoTasks.length) {
      throw StateError('Every piano task must be completed.');
    }

    final resultsByTaskId = <String, AssessmentPianoTaskResult>{};

    for (final result in results) {
      if (resultsByTaskId.containsKey(result.taskId)) {
        throw StateError('A piano task result was submitted more than once.');
      }

      final matchingTasks = assessmentPianoTasks.where(
        (task) => task.id == result.taskId,
      );

      if (matchingTasks.length != 1) {
        throw StateError('An unknown piano task result was submitted.');
      }

      final task = matchingTasks.single;
      final countsAreValid = result.totalGroupCount == task.noteGroups.length &&
          result.correctGroupCount >= 0 &&
          result.wrongGroupCount >= 0 &&
          result.missedGroupCount >= 0 &&
          result.timingMistakeCount >= 0 &&
          result.timingMistakeCount <= result.wrongGroupCount &&
          result.correctGroupCount +
                  result.wrongGroupCount +
                  result.missedGroupCount ==
              result.totalGroupCount;

      if (result.difficulty != task.difficulty || !countsAreValid) {
        throw StateError('A piano task result contains invalid totals.');
      }

      resultsByTaskId[result.taskId] = result;
    }

    return Map<String, AssessmentPianoTaskResult>.unmodifiable(
      resultsByTaskId,
    );
  }

  /// Combines all piano task results without allowing larger tiers to hide
  /// weaker beginner or intermediate performance.
  AssessmentPianoScore _calculatePianoExecutionScore(
    Map<String, AssessmentPianoTaskResult> resultsByTaskId,
  ) {
    var beginnerCorrectGroups = 0;
    var beginnerTotalGroups = 0;
    var intermediateCorrectGroups = 0;
    var intermediateTotalGroups = 0;
    var advancedCorrectGroups = 0;
    var advancedTotalGroups = 0;
    var totalCorrectGroups = 0;
    var totalGroups = 0;
    var wrongGroups = 0;
    var missedGroups = 0;
    var timingMistakes = 0;

    for (final task in assessmentPianoTasks) {
      final result = resultsByTaskId[task.id];

      if (result == null) {
        throw StateError('A required piano task result is missing.');
      }

      switch (task.difficulty) {
        case AssessmentPianoDifficulty.beginner:
          beginnerCorrectGroups += result.correctGroupCount;
          beginnerTotalGroups += result.totalGroupCount;
          break;

        case AssessmentPianoDifficulty.intermediate:
          intermediateCorrectGroups += result.correctGroupCount;
          intermediateTotalGroups += result.totalGroupCount;
          break;

        case AssessmentPianoDifficulty.advanced:
          advancedCorrectGroups += result.correctGroupCount;
          advancedTotalGroups += result.totalGroupCount;
          break;
      }

      totalCorrectGroups += result.correctGroupCount;
      totalGroups += result.totalGroupCount;
      wrongGroups += result.wrongGroupCount;
      missedGroups += result.missedGroupCount;
      timingMistakes += result.timingMistakeCount;
    }

    return AssessmentPianoScore(
      beginnerCorrectGroups: beginnerCorrectGroups,
      beginnerTotalGroups: beginnerTotalGroups,
      intermediateCorrectGroups: intermediateCorrectGroups,
      intermediateTotalGroups: intermediateTotalGroups,
      advancedCorrectGroups: advancedCorrectGroups,
      advancedTotalGroups: advancedTotalGroups,
      totalCorrectGroups: totalCorrectGroups,
      totalGroups: totalGroups,
      wrongGroups: wrongGroups,
      missedGroups: missedGroups,
      timingMistakes: timingMistakes,
    );
  }

  /// Calculates a cumulative notation level using four correct answers as the
  /// passing requirement for each six-question difficulty group.
  AssessmentSkillLevel _calculateNotationReadingLevel(
    AssessmentNotationScore score,
  ) {
    final passedBeginner =
        score.beginnerCorrect >= _notationCorrectAnswersRequired;
    final passedIntermediate =
        score.intermediateCorrect >= _notationCorrectAnswersRequired;
    final passedAdvanced =
        score.advancedCorrect >= _notationCorrectAnswersRequired;

    if (passedBeginner && passedIntermediate && passedAdvanced) {
      return AssessmentSkillLevel.advanced;
    }

    if (passedBeginner && passedIntermediate) {
      return AssessmentSkillLevel.intermediate;
    }

    return AssessmentSkillLevel.beginner;
  }

  /// Calculates a cumulative piano level. A higher tier is available only
  /// when the user also passes every easier tier at seventy percent.
  AssessmentSkillLevel _calculatePianoExecutionLevel(
    AssessmentPianoScore score,
  ) {
    bool passedTier(int correctGroups, int totalGroups) {
      return totalGroups > 0 &&
          correctGroups * 100 >= totalGroups * _pianoAccuracyRequired;
    }

    final passedBeginner = passedTier(
      score.beginnerCorrectGroups,
      score.beginnerTotalGroups,
    );
    final passedIntermediate = passedTier(
      score.intermediateCorrectGroups,
      score.intermediateTotalGroups,
    );
    final passedAdvanced = passedTier(
      score.advancedCorrectGroups,
      score.advancedTotalGroups,
    );

    if (passedBeginner && passedIntermediate && passedAdvanced) {
      return AssessmentSkillLevel.advanced;
    }

    if (passedBeginner && passedIntermediate) {
      return AssessmentSkillLevel.intermediate;
    }

    return AssessmentSkillLevel.beginner;
  }

  /// Prevents strength in one required ability from hiding weakness in the
  /// other by always returning the lower of the two calculated levels.
  AssessmentSkillLevel _lowerSkillLevel(
    AssessmentSkillLevel notationLevel,
    AssessmentSkillLevel pianoLevel,
  ) {
    if (notationLevel.index <= pianoLevel.index) {
      return notationLevel;
    }

    return pianoLevel;
  }

  /// Allows only the introduction-to-questionnaire generic transition.
  ///
  /// Every later section will have a dedicated submission method so its
  /// required assessment data cannot be skipped.
  bool _isAllowedSectionTransition({
    required AssessmentSection currentSection,
    required AssessmentSection nextSection,
  }) {
    return currentSection == AssessmentSection.introduction &&
        nextSection == AssessmentSection.questionnaire;
  }

  /// Converts a Firestore document into the immutable Dart model.
  AssessmentAttempt _attemptFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = _requireDocumentData(document);
    final pianoTaskResults = _pianoTaskResultsFromData(data);

    return AssessmentAttempt(
      id: document.id,
      userId: data['userId'] as String,
      status: AssessmentAttemptStatus.values.byName(data['status'] as String),
      currentSection: AssessmentSection.values.byName(
        data['currentSection'] as String,
      ),
      startedAt: _requiredDateTime(data: data, fieldName: 'startedAt'),
      expiresAt: _requiredDateTime(data: data, fieldName: 'expiresAt'),
      serverCheckedAt: _requiredDateTime(
        data: data,
        fieldName: 'serverCheckedAt',
      ),
      assessmentVersion: data['assessmentVersion'] as int,

      // Restores any questionnaire answers previously saved in Firestore.
      questionnaireAnswers: _questionnaireAnswersFromData(data),

      // Restores notation progress after this section has been submitted.
      notationReadingAnswers: _notationReadingAnswersFromData(data),
      notationReadingScore: _notationReadingScoreFromData(data),

      // Restores finalized piano tasks and their grouped score.
      pianoTaskResults: pianoTaskResults,
      pianoExecutionScore: _pianoExecutionScoreFromData(
        data,
        pianoTaskResults,
      ),
      notationReadingLevel: _optionalSkillLevelFromData(
        data: data,
        fieldName: 'notationReadingLevel',
      ),
      pianoExecutionLevel: _optionalSkillLevelFromData(
        data: data,
        fieldName: 'pianoExecutionLevel',
      ),
      finalSkillLevel: _optionalSkillLevelFromData(
        data: data,
        fieldName: 'finalSkillLevel',
      ),
      placementMethod: _optionalPlacementMethodFromData(data),
      completedAt: _optionalDateTime(data: data, fieldName: 'completedAt'),
    );
  }

  // Safely converts the questionnaireAnswers Firestore field into
  // a Map<String, String> used by the AssessmentAttempt model.
  Map<String, String> _questionnaireAnswersFromData(Map<String, dynamic> data) {
    final rawAnswers = data['questionnaireAnswers'];

    // Older attempts may not have questionnaire answers yet.
    if (rawAnswers is! Map) {
      return const {};
    }

    final answers = <String, String>{};

    // Only accept entries containing both a String key and String value.
    // Invalid Firestore values are ignored instead of crashing the app.
    for (final entry in rawAnswers.entries) {
      final questionId = entry.key;
      final optionId = entry.value;

      if (questionId is String && optionId is String) {
        answers[questionId] = optionId;
      }
    }

    // Prevent other parts of the app from accidentally changing
    // the answers stored inside the assessment model.
    return Map<String, String>.unmodifiable(answers);
  }

  /// Safely restores notation-reading answer IDs from Firestore.
  Map<String, String> _notationReadingAnswersFromData(
    Map<String, dynamic> data,
  ) {
    final rawAnswers = data['notationReadingAnswers'];

    // Attempts that have not submitted notation reading have no answer map.
    if (rawAnswers is! Map) {
      return const {};
    }

    final answers = <String, String>{};

    for (final entry in rawAnswers.entries) {
      final questionId = entry.key;
      final optionId = entry.value;

      if (questionId is String && optionId is String) {
        answers[questionId] = optionId;
      }
    }

    return Map<String, String>.unmodifiable(answers);
  }

  /// Restores and verifies the structured notation score from Firestore.
  AssessmentNotationScore? _notationReadingScoreFromData(
    Map<String, dynamic> data,
  ) {
    final rawScore = data['notationReadingScore'];

    // A null score means notation reading has not been submitted yet.
    if (rawScore == null) {
      return null;
    }

    if (rawScore is! Map) {
      throw StateError(
        'The assessment field "notationReadingScore" is invalid.',
      );
    }

    int readScore(String fieldName) {
      final value = rawScore[fieldName];

      if (value is! int) {
        throw StateError(
          'The notation score field "$fieldName" is invalid.',
        );
      }

      return value;
    }

    final beginnerCorrect = readScore('beginnerCorrect');
    final intermediateCorrect = readScore('intermediateCorrect');
    final advancedCorrect = readScore('advancedCorrect');
    final totalCorrect = readScore('totalCorrect');

    final validGroupScores = beginnerCorrect >= 0 &&
        beginnerCorrect <= AssessmentNotationScore.questionsPerDifficulty &&
        intermediateCorrect >= 0 &&
        intermediateCorrect <=
            AssessmentNotationScore.questionsPerDifficulty &&
        advancedCorrect >= 0 &&
        advancedCorrect <= AssessmentNotationScore.questionsPerDifficulty;

    final validTotal = totalCorrect >= 0 &&
        totalCorrect <= AssessmentNotationScore.totalQuestions &&
        totalCorrect ==
            beginnerCorrect + intermediateCorrect + advancedCorrect;

    if (!validGroupScores || !validTotal) {
      throw StateError('The saved notation-reading score is inconsistent.');
    }

    return AssessmentNotationScore(
      beginnerCorrect: beginnerCorrect,
      intermediateCorrect: intermediateCorrect,
      advancedCorrect: advancedCorrect,
      totalCorrect: totalCorrect,
    );
  }

  /// Restores and validates every finalized piano task result.
  Map<String, AssessmentPianoTaskResult> _pianoTaskResultsFromData(
    Map<String, dynamic> data,
  ) {
    final rawResults = data['pianoTaskResults'];

    // An absent field means piano execution has not been submitted yet.
    if (rawResults == null) {
      return const {};
    }

    if (rawResults is! Map) {
      throw StateError('The assessment field "pianoTaskResults" is invalid.');
    }

    final parsedResults = <AssessmentPianoTaskResult>[];

    for (final entry in rawResults.entries) {
      final taskId = entry.key;
      final rawResult = entry.value;

      if (taskId is! String || rawResult is! Map) {
        throw StateError('A saved piano task result is invalid.');
      }

      String readString(String fieldName) {
        final value = rawResult[fieldName];

        if (value is! String) {
          throw StateError(
            'The piano result field "$fieldName" is invalid.',
          );
        }

        return value;
      }

      int readInteger(String fieldName) {
        final value = rawResult[fieldName];

        if (value is! int) {
          throw StateError(
            'The piano result field "$fieldName" is invalid.',
          );
        }

        return value;
      }

      final savedTaskId = readString('taskId');
      final difficultyName = readString('difficulty');

      if (savedTaskId != taskId) {
        throw StateError('A saved piano task ID is inconsistent.');
      }

      late final AssessmentPianoDifficulty difficulty;

      try {
        difficulty = AssessmentPianoDifficulty.values.byName(difficultyName);
      } on ArgumentError {
        throw StateError('A saved piano task difficulty is invalid.');
      }

      final result = AssessmentPianoTaskResult(
        taskId: taskId,
        difficulty: difficulty,
        totalGroupCount: readInteger('totalGroupCount'),
        correctGroupCount: readInteger('correctGroupCount'),
        wrongGroupCount: readInteger('wrongGroupCount'),
        missedGroupCount: readInteger('missedGroupCount'),
        timingMistakeCount: readInteger('timingMistakeCount'),
      );

      parsedResults.add(result);
    }

    return _validatePianoTaskResults(parsedResults);
  }

  /// Restores and verifies the aggregate piano-execution score.
  AssessmentPianoScore? _pianoExecutionScoreFromData(
    Map<String, dynamic> data,
    Map<String, AssessmentPianoTaskResult> taskResults,
  ) {
    final rawScore = data['pianoExecutionScore'];

    if (rawScore == null) {
      if (taskResults.isNotEmpty) {
        throw StateError('Saved piano task results have no aggregate score.');
      }

      return null;
    }

    if (rawScore is! Map) {
      throw StateError(
        'The assessment field "pianoExecutionScore" is invalid.',
      );
    }

    int readScore(String fieldName) {
      final value = rawScore[fieldName];

      if (value is! int) {
        throw StateError(
          'The piano score field "$fieldName" is invalid.',
        );
      }

      return value;
    }

    final restoredScore = AssessmentPianoScore(
      beginnerCorrectGroups: readScore('beginnerCorrectGroups'),
      beginnerTotalGroups: readScore('beginnerTotalGroups'),
      intermediateCorrectGroups: readScore('intermediateCorrectGroups'),
      intermediateTotalGroups: readScore('intermediateTotalGroups'),
      advancedCorrectGroups: readScore('advancedCorrectGroups'),
      advancedTotalGroups: readScore('advancedTotalGroups'),
      totalCorrectGroups: readScore('totalCorrectGroups'),
      totalGroups: readScore('totalGroups'),
      wrongGroups: readScore('wrongGroups'),
      missedGroups: readScore('missedGroups'),
      timingMistakes: readScore('timingMistakes'),
    );

    final calculatedScore = _calculatePianoExecutionScore(taskResults);

    final scoreMatchesResults =
        restoredScore.beginnerCorrectGroups ==
            calculatedScore.beginnerCorrectGroups &&
        restoredScore.beginnerTotalGroups ==
            calculatedScore.beginnerTotalGroups &&
        restoredScore.intermediateCorrectGroups ==
            calculatedScore.intermediateCorrectGroups &&
        restoredScore.intermediateTotalGroups ==
            calculatedScore.intermediateTotalGroups &&
        restoredScore.advancedCorrectGroups ==
            calculatedScore.advancedCorrectGroups &&
        restoredScore.advancedTotalGroups ==
            calculatedScore.advancedTotalGroups &&
        restoredScore.totalCorrectGroups ==
            calculatedScore.totalCorrectGroups &&
        restoredScore.totalGroups == calculatedScore.totalGroups &&
        restoredScore.wrongGroups == calculatedScore.wrongGroups &&
        restoredScore.missedGroups == calculatedScore.missedGroups &&
        restoredScore.timingMistakes == calculatedScore.timingMistakes;

    if (!scoreMatchesResults) {
      throw StateError('The saved piano-execution score is inconsistent.');
    }

    return restoredScore;
  }

  /// Reads one optional saved placement level and rejects unknown values.
  AssessmentSkillLevel? _optionalSkillLevelFromData({
    required Map<String, dynamic> data,
    required String fieldName,
  }) {
    final value = data[fieldName];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw StateError(
        'The assessment field "$fieldName" is not a valid skill level.',
      );
    }

    try {
      return AssessmentSkillLevel.values.byName(value);
    } on ArgumentError {
      throw StateError(
        'The assessment field "$fieldName" contains an unknown skill level.',
      );
    }
  }

  /// Reads the optional method used to produce a completed placement.
  AssessmentPlacementMethod? _optionalPlacementMethodFromData(
    Map<String, dynamic> data,
  ) {
    final value = data['placementMethod'];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw StateError(
        'The assessment field "placementMethod" is invalid.',
      );
    }

    try {
      return AssessmentPlacementMethod.values.byName(value);
    } on ArgumentError {
      throw StateError(
        'The assessment contains an unknown placement method.',
      );
    }
  }

  /// Finalized documents never need another server-time refresh or write.
  bool _isFinalizedDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final status = document.data()?['status'];

    return status == AssessmentAttemptStatus.completed.name ||
        status == AssessmentAttemptStatus.expired.name;
  }

  /// Returns document data or throws a clear error for a missing document.
  Map<String, dynamic> _requireDocumentData(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('The current assessment document does not exist.');
    }

    return data;
  }

  /// Reads a required Firestore timestamp and normalizes it to UTC.
  DateTime _requiredDateTime({
    required Map<String, dynamic> data,
    required String fieldName,
  }) {
    final value = data[fieldName];

    if (value is! Timestamp) {
      throw StateError(
        'The assessment field "$fieldName" is not a valid timestamp.',
      );
    }

    return value.toDate().toUtc();
  }

  /// Reads an optional timestamp; unfinished attempts have no `completedAt`.
  DateTime? _optionalDateTime({
    required Map<String, dynamic> data,
    required String fieldName,
  }) {
    final value = data[fieldName];

    if (value == null) {
      return null;
    }

    if (value is! Timestamp) {
      throw StateError(
        'The assessment field "$fieldName" is not a valid timestamp.',
      );
    }

    return value.toDate().toUtc();
  }

  /// Builds the only assessment document path used by this service.
  DocumentReference<Map<String, dynamic>> _currentAttemptReference(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('assessment')
        .doc(_currentDocumentId);
  }

  /// Ensures assessment operations always belong to a logged-in user.
  User _requireCurrentUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('A user must be logged in to access an assessment.');
    }

    return user;
  }
}
