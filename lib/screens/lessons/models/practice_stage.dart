import 'package:flutter/material.dart';

/// The content and label for one stage on the lesson map.
class PracticeStage {
  const PracticeStage({
    required this.number,
    required this.title,
    required this.description,
    required this.assets,
    this.circleText,
    this.circleContent,
  });

  final int number;
  final String title;
  final String description;
  final List<String> assets;
  final String? circleText;
  final Widget? circleContent;
}
