import 'package:flutter/widgets.dart';
import 'package:soundsight/l10n/generated/app_localizations.dart';

extension LocalizationBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
