import 'package:flutter/widgets.dart';
import 'package:soundsight/l10n/generated/app_localizations.dart';

import 'models/practice_stage.dart';

enum PracticeStageActivity { videoQuiz, pianoPerformance }

PracticeStageActivity practiceStageActivity(PracticeStage stage) {
  return stage.assets.any((path) => path.toLowerCase().endsWith('.mp4'))
      ? PracticeStageActivity.videoQuiz
      : PracticeStageActivity.pianoPerformance;
}

String localizedPracticeStageActivity(
  AppLocalizations l10n,
  PracticeStageActivity activity,
) {
  return switch (activity) {
    PracticeStageActivity.videoQuiz => l10n.lessonVideoAndQuiz,
    PracticeStageActivity.pianoPerformance => l10n.lessonPianoPerformance,
  };
}

String localizedPracticeStageShortTitle(
  AppLocalizations l10n,
  int stageNumber,
) {
  return switch (stageNumber) {
    1 => l10n.lessonStage1ShortTitle,
    2 => l10n.lessonStage2ShortTitle,
    3 => l10n.lessonStage3ShortTitle,
    4 => l10n.lessonStage4ShortTitle,
    5 => l10n.lessonStage5ShortTitle,
    6 => l10n.lessonStage6ShortTitle,
    7 => l10n.lessonStage7ShortTitle,
    8 => l10n.lessonStage8ShortTitle,
    9 => l10n.lessonStage9ShortTitle,
    10 => l10n.lessonStage10ShortTitle,
    11 => l10n.lessonStage11ShortTitle,
    12 => l10n.lessonStage12ShortTitle,
    13 => l10n.lessonStage13ShortTitle,
    14 => l10n.lessonStage14ShortTitle,
    15 => l10n.lessonStage15ShortTitle,
    16 => l10n.lessonStage16ShortTitle,
    _ => l10n.lessonStageLabel(stageNumber),
  };
}

String localizedPracticeStageTitle(AppLocalizations l10n, int stageNumber) {
  final shortTitle = localizedPracticeStageShortTitle(l10n, stageNumber);
  final lessonNumber = switch (stageNumber) {
    1 => 1,
    2 => 2,
    3 => 3,
    5 => 4,
    7 => 5,
    8 => 6,
    10 => 7,
    12 => 8,
    13 => 9,
    15 => 10,
    _ => null,
  };
  if (lessonNumber != null) {
    return l10n.lessonNumberTitle(lessonNumber, shortTitle);
  }
  if (stageNumber == 11) {
    return l10n.lessonStage11Title;
  }
  return shortTitle;
}

String localizedPracticeStageDescription(
  AppLocalizations l10n,
  int stageNumber,
) {
  return switch (stageNumber) {
    1 || 2 || 3 || 13 || 15 => l10n.lessonWatchThenQuiz,
    4 || 6 || 9 => l10n.lessonOpenScoreAndPlay,
    5 || 7 || 8 || 10 => l10n.lessonWatchTopicVideo(
      localizedPracticeStageShortTitle(l10n, stageNumber),
    ),
    11 => l10n.lessonPlayWithMovingCursor,
    12 => l10n.lessonWatchViewPdfAndQuiz,
    14 || 16 => l10n.lessonConnectAndPlayScore,
    _ => '',
  };
}

String localizedLessonResultTitle(
  AppLocalizations l10n,
  String scoreDocumentPath,
  String fallback,
) {
  final match = RegExp(r'^lessons/stage_(\d+)$').firstMatch(scoreDocumentPath);
  final stageNumber = int.tryParse(match?.group(1) ?? '');
  if (stageNumber == null || stageNumber < 1 || stageNumber > 16) {
    return fallback;
  }
  return localizedPracticeStageTitle(l10n, stageNumber);
}

String localizedQuizAssetPath(BuildContext context, String englishPath) {
  if (Localizations.localeOf(context).languageCode != 'fil') {
    return englishPath;
  }
  final extensionIndex = englishPath.toLowerCase().lastIndexOf('.txt');
  if (extensionIndex < 0) return englishPath;
  return '${englishPath.substring(0, extensionIndex)}_fil.txt';
}
