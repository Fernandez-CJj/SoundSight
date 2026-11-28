import 'package:soundsight/screens/help_center/models/help_feature.dart';
import 'package:soundsight/translations/generated/app_localizations.dart';

extension HelpCategoryLocalization on HelpCategory {
  String label(AppLocalizations l10n) => switch (this) {
    HelpCategory.all => l10n.helpCategoryAll,
    HelpCategory.gettingStarted => l10n.helpCategoryGettingStarted,
    HelpCategory.musicSheets => l10n.helpCategoryMusicSheets,
    HelpCategory.practice => l10n.helpCategoryPractice,
    HelpCategory.compositions => l10n.helpCategoryCompositions,
    HelpCategory.account => l10n.helpCategoryAccount,
  };
}
