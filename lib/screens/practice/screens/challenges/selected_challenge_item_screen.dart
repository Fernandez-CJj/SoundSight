import 'package:flutter/material.dart';
import 'package:soundsight/screens/practice/screens/challenges/ar/ar_practice_screen.dart';
import 'package:soundsight/screens/practice/screens/challenges/synthesia/synthesia_screen.dart';

import '../music_sheet_pdf_screen.dart';
import 'sight_reading/music_sheet_reading_screen.dart';

class SelectedChallengeItemScreen extends StatelessWidget {
  const SelectedChallengeItemScreen({
    super.key,
    required this.challengeItemId,
    required this.title,
    required this.pdfUrl,
    required this.pdfFileName,
  });

  final String challengeItemId;
  final String title;
  final String pdfUrl;
  final String pdfFileName;

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
                const SizedBox(height: 17),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArPracticeScreen(
                          scoreDocumentPath: 'challenge_items/$challengeItemId',
                        ),
                      ),
                    );
                  },
                  child: Text('AR Practice'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MusicSheetReadingScreen(
                          scoreDocumentPath: 'challenge_items/$challengeItemId',
                          challengeItemId: challengeItemId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Music Sheet Reading'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SynthesiaScreen()),
                    );
                  },
                  child: Text('Synthesia'),
                ),
                if (pdfUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MusicSheetPdfScreen(
                            title: title,
                            pdfUrl: pdfUrl,
                            pdfFileName: pdfFileName,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Music Sheet'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
