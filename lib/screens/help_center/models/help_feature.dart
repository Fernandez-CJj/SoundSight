import 'package:flutter/material.dart';

enum HelpCategory {
  all,
  gettingStarted,
  musicSheets,
  practice,
  compositions,
  account,
}

class HelpGuideStep {
  const HelpGuideStep({
    required this.title,
    required this.description,
    this.imageAsset,
    this.darkImageAsset,
  });

  final String title;
  final String description;
  // Numbered screenshots are bundled under assets/help_assets/<feature>/.
  final String? imageAsset;
  final String? darkImageAsset;

  String? imageFor(bool isDarkMode) =>
      isDarkMode ? darkImageAsset ?? imageAsset : imageAsset;
}

class HelpFeature {
  const HelpFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final HelpCategory category;
  final IconData icon;
  final List<HelpGuideStep> steps;
}
