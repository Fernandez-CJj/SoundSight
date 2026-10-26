import 'package:soundsight/l10n/generated/app_localizations.dart';

enum AchievementBadge {
  firstMeasure('first_measure'),
  sheetCollector('sheet_collector'),
  firstComposer('first_composer'),
  middleC('middle_c'),
  firstMelody('first_melody'),
  growingMusician('growing_musician'),
  chordBuilder('chord_builder'),
  musicNavigator('music_navigator'),
  soundSightMaster('soundsight_master');

  const AchievementBadge(this.id);

  final String id;
  String get assetPath => 'assets/badge/$id.png';

  static AchievementBadge? fromId(String id) {
    for (final badge in values) {
      if (badge.id == id) return badge;
    }
    return null;
  }

  static AchievementBadge? forCompletedStage(int stage) => switch (stage) {
    3 => middleC,
    6 => firstMelody,
    9 => growingMusician,
    12 => chordBuilder,
    15 => musicNavigator,
    16 => soundSightMaster,
    _ => null,
  };

  String title(AppLocalizations l10n) => switch (this) {
    firstMeasure => l10n.badgeFirstMeasure,
    sheetCollector => l10n.badgeSheetCollector,
    firstComposer => l10n.badgeFirstComposer,
    middleC => l10n.badgeMiddleC,
    firstMelody => l10n.badgeFirstMelody,
    growingMusician => l10n.badgeGrowingMusician,
    chordBuilder => l10n.badgeChordBuilder,
    musicNavigator => l10n.badgeMusicNavigator,
    soundSightMaster => l10n.badgeSoundSightMaster,
  };

  String description(AppLocalizations l10n) => switch (this) {
    firstMeasure => l10n.badgeFirstMeasureDescription,
    sheetCollector => l10n.badgeSheetCollectorDescription,
    firstComposer => l10n.badgeFirstComposerDescription,
    middleC => l10n.badgeMiddleCDescription,
    firstMelody => l10n.badgeFirstMelodyDescription,
    growingMusician => l10n.badgeGrowingMusicianDescription,
    chordBuilder => l10n.badgeChordBuilderDescription,
    musicNavigator => l10n.badgeMusicNavigatorDescription,
    soundSightMaster => l10n.badgeSoundSightMasterDescription,
  };
}
