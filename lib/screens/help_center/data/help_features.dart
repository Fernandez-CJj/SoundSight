import 'package:flutter/material.dart';
import 'package:soundsight/screens/help_center/models/help_feature.dart';
import 'package:soundsight/screens/onboarding/tours/feature_tour_catalog.dart';
import 'package:soundsight/translations/generated/app_localizations.dart';

// Caption order matches the numbered screenshots, including tours spanning
// more than one screen. Reuse the tour copy in the selected language.
List<(String, String)> _tourCaptions(
  AppLocalizations l10n,
  String tourId, {
  List<String>? steps,
}) {
  final hints = featureTourCatalog[tourId]!;
  final selected = steps == null
      ? hints
      : [for (final id in steps) hints.firstWhere((hint) => hint.id == id)];
  final filipino = l10n.localeName.split('_').first == 'fil';
  return [
    for (final hint in selected)
      (filipino ? hint.filipinoTitle : hint.title,
       filipino ? hint.filipinoBody : hint.body),
  ];
}

List<HelpGuideStep> _screenshots(String folder, List<(String, String)> captions) => [
  for (var index = 0; index < captions.length; index++)
    HelpGuideStep(
      title: captions[index].$1,
      description: captions[index].$2,
      imageAsset: 'assets/help_assets/$folder/${index + 1}.jpg',
    ),
];

List<HelpFeature> buildHelpFeatures(AppLocalizations l10n) => <HelpFeature>[
  HelpFeature(
    id: 'home',
    title: l10n.helpHomeTitle,
    description: l10n.helpHomeDescription,
    category: HelpCategory.gettingStarted,
    icon: Icons.home_outlined,
    steps: _screenshots('homescreen', [
      (l10n.searchMusic, l10n.featureTourSearchBody),
      (l10n.quickActions, l10n.featureTourQuickActionsBody),
      (l10n.communityCompositions, l10n.featureTourCommunityBody),
      (l10n.featureTourMenuTitle, l10n.featureTourMenuBody),
      (l10n.featureTourNavigationTitle, l10n.featureTourNavigationBody),
      (l10n.featureTourPreferencesTitle, l10n.featureTourPreferencesBody),
      (l10n.helpCenterTitle, l10n.featureTourReplayBody),
    ]),
  ),
  HelpFeature(
    id: 'music_library',
    title: l10n.helpMusicLibraryTitle,
    description: l10n.helpMusicLibraryDescription,
    category: HelpCategory.gettingStarted,
    icon: Icons.search_rounded,
    steps: _screenshots('music_library', [
      ..._tourCaptions(l10n, 'music_library'),
      ..._tourCaptions(l10n, 'library_piece'),
    ]),
  ),
  HelpFeature(
    id: 'upload',
    title: l10n.helpUploadTitle,
    description: l10n.helpUploadDescription,
    category: HelpCategory.musicSheets,
    icon: Icons.add_photo_alternate_outlined,
    steps: _screenshots('upload', [
      (l10n.uploadPdf, l10n.featureTourUploadPdfBody),
      (l10n.capturePages, l10n.featureTourUploadCaptureBody),
      (l10n.featureTourUploadRecordingTitle, l10n.featureTourUploadRecordingBody),
      (l10n.captureTips, l10n.featureTourUploadTipsBody),
      (l10n.featureTourUploadPreviewTitle, l10n.featureTourUploadPreviewBody),
      (l10n.featureTourUploadSaveTitle, l10n.featureTourUploadSaveBody),
    ]),
  ),
  HelpFeature(
    id: 'music_sheets',
    title: l10n.helpMusicSheetsTitle,
    description: l10n.helpMusicSheetsDescription,
    category: HelpCategory.musicSheets,
    icon: Icons.library_music_outlined,
    steps: _screenshots('music_sheet', [
      (l10n.addMusicSheet, l10n.featureTourSheetsAddBody),
      (l10n.yourLibrary, l10n.featureTourSheetsLibraryBody),
      (l10n.featureTourSheetsOpenTitle, l10n.featureTourSheetsOpenBody),
      ..._tourCaptions(l10n, 'music_sheet_viewer', steps: ['expand', 'process', 'practice']),
    ]),
  ),
  HelpFeature(
    id: 'lessons',
    title: l10n.helpLessonsTitle,
    description: l10n.helpLessonsDescription,
    category: HelpCategory.practice,
    icon: Icons.school_outlined,
    steps: _screenshots('practice', [
      ..._tourCaptions(l10n, 'lessons'),
      ..._tourCaptions(l10n, 'lesson_content'),
    ]),
  ),
  HelpFeature(
    id: 'assessment',
    title: l10n.helpAssessmentTitle,
    description: l10n.helpAssessmentDescription,
    category: HelpCategory.practice,
    icon: Icons.assignment_outlined,
    steps: _screenshots('assessment', _tourCaptions(l10n, 'assessment')),
  ),
  HelpFeature(
    id: 'sight_reading',
    title: l10n.helpSightReadingTitle,
    description: l10n.helpSightReadingDescription,
    category: HelpCategory.practice,
    icon: Icons.music_note_outlined,
    steps: _screenshots('sight_reading', [
      ..._tourCaptions(l10n, 'sight_reading_player'),
      ..._tourCaptions(l10n, 'sight_reading_controls'),
    ]),
  ),
  HelpFeature(
    id: 'synthesia',
    title: l10n.helpSynthesiaTitle,
    description: l10n.helpSynthesiaDescription,
    category: HelpCategory.practice,
    icon: Icons.piano_outlined,
    steps: _screenshots('synthesia', [
      ..._tourCaptions(l10n, 'synthesia_player'),
      ..._tourCaptions(l10n, 'synthesia_controls'),
    ]),
  ),
  HelpFeature(
    id: 'ar',
    title: l10n.helpArTitle,
    description: l10n.helpArDescription,
    category: HelpCategory.practice,
    icon: Icons.camera_alt_outlined,
    steps: _screenshots('calibration', [
      ..._tourCaptions(l10n, 'ar_setup', steps: ['create', 'list']),
      ..._tourCaptions(l10n, 'ar_calibration', steps: ['camera', 'instructions']),
      ..._tourCaptions(l10n, 'ar_calibration_review'),
    ]),
  ),
  HelpFeature(
    id: 'ar_player',
    title: l10n.helpArPlayerTitle,
    description: l10n.helpArPlayerDescription,
    category: HelpCategory.practice,
    icon: Icons.view_in_ar_rounded,
    steps: _screenshots('ar_player', [
      ..._tourCaptions(l10n, 'ar_player'),
      ..._tourCaptions(l10n, 'ar_player_controls'),
    ]),
  ),
  HelpFeature(
    id: 'practice_results',
    title: l10n.helpPracticeResultsTitle,
    description: l10n.helpPracticeResultsDescription,
    category: HelpCategory.practice,
    icon: Icons.insights_outlined,
    steps: _screenshots('practice_results', [
      ..._tourCaptions(l10n, 'practice_results', steps: ['filters', 'card_info']),
      ..._tourCaptions(l10n, 'practice_result_details'),
    ]),
  ),
  HelpFeature(
    id: 'compositions',
    title: l10n.helpCompositionsTitle,
    description: l10n.helpCompositionsDescription,
    category: HelpCategory.compositions,
    icon: Icons.library_music_rounded,
    steps: _screenshots('my_compositions', [
      ..._tourCaptions(l10n, 'my_compositions', steps: ['create', 'list', 'card_info']),
      ..._tourCaptions(l10n, 'composition_details'),
    ]),
  ),
  HelpFeature(
    id: 'manual_composition',
    title: l10n.helpManualCompositionTitle,
    description: l10n.helpManualCompositionDescription,
    category: HelpCategory.compositions,
    icon: Icons.edit_note_rounded,
    steps: _screenshots('manual_composition', _tourCaptions(l10n, 'manual_composition')),
  ),
  HelpFeature(
    id: 'recording_composition',
    title: l10n.helpRecordingCompositionTitle,
    description: l10n.helpRecordingCompositionDescription,
    category: HelpCategory.compositions,
    icon: Icons.videocam_outlined,
    steps: _screenshots('recording_composition', _tourCaptions(l10n, 'recording_composition')),
  ),
  HelpFeature(
    id: 'published',
    title: l10n.helpPublishedTitle,
    description: l10n.helpPublishedDescription,
    category: HelpCategory.compositions,
    icon: Icons.public_rounded,
    steps: _screenshots('published_compositions', [
      ..._tourCaptions(l10n, 'published_compositions', steps: ['sort', 'card_info', 'social', 'play']),
      ..._tourCaptions(l10n, 'published_details'),
    ]),
  ),
  HelpFeature(
    id: 'saved',
    title: l10n.helpSavedTitle,
    description: l10n.helpSavedDescription,
    category: HelpCategory.compositions,
    icon: Icons.bookmark_border_rounded,
    steps: _screenshots('saved_composition', [
      ..._tourCaptions(l10n, 'saved_compositions', steps: ['card_info', 'social', 'play']),
      ..._tourCaptions(l10n, 'published_details'),
    ]),
  ),
  HelpFeature(
    id: 'profile',
    title: l10n.helpProfileTitle,
    description: l10n.helpProfileDescription,
    category: HelpCategory.account,
    icon: Icons.person_outline_rounded,
    steps: _screenshots('profile', _tourCaptions(l10n, 'profile')),
  ),
];
