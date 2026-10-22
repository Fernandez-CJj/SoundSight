import 'package:flutter/material.dart';

enum AppLanguage {
  english('en', Locale('en')),
  filipino('fil', Locale('fil'));

  const AppLanguage(this.code, this.locale);

  final String code;
  final Locale locale;

  static AppLanguage fromCode(Object? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

