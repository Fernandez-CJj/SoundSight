import 'package:flutter/material.dart';
import 'package:soundsight/localization/app_language.dart';

class AppLocaleController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  void applyLanguageCode(Object? code) {
    setLanguage(AppLanguage.fromCode(code));
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  void reset() => setLanguage(AppLanguage.english);
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope is missing above this context.');
    return scope!.notifier!;
  }
}

