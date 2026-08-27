import 'package:flutter/material.dart';

import '../challenges/sight_reading/music_sheet_reading_screen.dart';

class SelectedFundamentalLessonScreen extends StatelessWidget {
  const SelectedFundamentalLessonScreen({
    super.key,
    required this.folderId,
    required this.lessonId,
    required this.title,
  });

  final String folderId;
  final String lessonId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MusicSheetReadingScreen(
                          scoreDocumentPath:
                              'fundamentals_folders/$folderId/lessons/$lessonId',
                        ),
                      ),
                    );
                  },
                  child: const Text('Music Sheet Reading'),
                ),
                const SizedBox(height: 17),
                const ElevatedButton(
                  onPressed: null,
                  child: Text('Synthesia'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
