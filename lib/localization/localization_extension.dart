import 'package:flutter/widgets.dart';
import 'package:soundsight/translations/generated/app_localizations.dart';

extension LocalizationBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
