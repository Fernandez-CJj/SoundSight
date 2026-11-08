import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A feature can span several routes without saving separate completion flags.
class FeatureTourJourney {
  FeatureTourJourney._({
    required this.featureId,
    required this.screens,
    required this.navigator,
    required this.userId,
    required this.progress,
    required this.completedSteps,
  });

  static final List<FeatureTourJourney> _pending = [];
  final String featureId;
  final Set<String> screens;
  final NavigatorState navigator;
  final String? userId;
  final FeatureTourJourneyProgress progress;
  final int completedSteps;
  bool _claimed = false;

  void release() {
    if (!progress.finished) _claimed = false;
  }

  static FeatureTourJourney? claim(String screen, NavigatorState navigator) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    for (final journey in _pending.reversed) {
      if (!journey._claimed && journey.userId == userId &&
          identical(journey.navigator, navigator) && journey.screens.contains(screen)) {
        journey._claimed = true;
        return journey;
      }
    }
    return null;
  }

  /// Returns true when the parent should show its last step again.
  static Future<bool> open({
    required BuildContext context,
    required String featureId,
    required Set<String> screens,
    required Future<Object?> Function() openScreen,
    FeatureTourJourneyProgress? progress,
    int completedSteps = 0,
  }) async {
    final journey = FeatureTourJourney._(
      featureId: featureId,
      screens: screens,
      navigator: Navigator.of(context),
      userId: FirebaseAuth.instance.currentUser?.uid,
      progress: progress ?? FeatureTourJourneyProgress(),
      completedSteps: completedSteps,
    );
    _pending.add(journey);
    try {
      await openScreen();
      return !journey.progress.finished;
    } finally {
      _pending.remove(journey);
    }
  }
}

class FeatureTourJourneyProgress {
  bool finished = false;
  bool _countPrepared = false;
  int? totalSteps;

  void prepareCount(int completedAndCurrentSteps, int? remainingSteps, {
    bool restart = false,
  }) {
    if (restart) finished = false;
    if (_countPrepared && !restart) {
      // Keep an unknown total unknown for the whole journey. A loaded page
      // may have fewer steps if its file is missing or could not be opened.
      if (totalSteps != null && remainingSteps != null) {
        totalSteps = completedAndCurrentSteps + remainingSteps;
      }
      return;
    }
    _countPrepared = true;
    totalSteps = remainingSteps == null
        ? null : completedAndCurrentSteps + remainingSteps;
  }
}

const featureTourParents = <String, String>{
  'music_sheet_viewer': 'music_sheets',
  'library_piece': 'music_library',
  'composition_details': 'my_compositions',
  'manual_composition': 'my_compositions',
  'recording_composition': 'my_compositions',
  'published_details': 'published_compositions',
  'practice_result_details': 'practice_results',
  'lesson_content': 'lessons',
  'assessment_instructions': 'assessment',
  'assessment_questions': 'assessment',
  'assessment_notation': 'assessment',
  'assessment_piano': 'assessment',
  'assessment_results': 'assessment',
};
