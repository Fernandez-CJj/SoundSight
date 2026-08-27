import 'package:flutter/material.dart';

import 'sight_reading/music_sheet_reading_screen.dart';

class SelectedChallengeItemScreen extends StatelessWidget {
  const SelectedChallengeItemScreen({
    super.key,
    required this.challengeItemId,
    required this.title,
  });

  final String challengeItemId;
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
                        builder: (_) => MusicSheetReadingScreen(
                          scoreDocumentPath:
                              'challenge_items/$challengeItemId',
                        ),
                      ),
                    );
                  },
                  child: const Text('Music Sheet Reading'),
                ),
                const SizedBox(height: 17),
                const ElevatedButton(onPressed: null, child: Text('Synthesia')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
