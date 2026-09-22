import 'package:flutter/material.dart';
import 'data/practice_levels.dart';
import 'package:soundsight/screens/practice/screens/video_lesson_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice'), centerTitle: true),
      body: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 24),
        itemCount: practiceLevels.length,
        itemBuilder: (context, index) {
          final level = practiceLevels[index];
          final levelNumber = level.number;

          return SizedBox(
            height: 140,
            child: Column(
              children: [
                Expanded(
                  child: index < practiceLevels.length - 1
                      ? Container(
                          width: 4,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        )
                      : const SizedBox(),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    fixedSize: const Size(72, 72),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: Text('Level $levelNumber'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),

                              const SizedBox(height: 16),
                              Text(level.description),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              child: const Text('Close'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (routeContext) {
                                      return VideoLessonScreen(
                                        title: level.title,
                                        videoAssetPath:
                                            'assets/video_lessons/level_1_video_lesson.mp4',
                                      );
                                    },
                                  ),
                                );
                              },
                              child: const Text('Proceed'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                    '$levelNumber',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: levelNumber > 1
                      ? Container(
                          width: 4,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
