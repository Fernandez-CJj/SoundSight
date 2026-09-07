import 'package:flutter/material.dart';
import 'package:soundsight/screens/practice/screens/challenges/synthesia/synthesia_screen.dart';

import '../challenges/ar/ar_practice_screen.dart';
import '../challenges/sight_reading/music_sheet_reading_screen.dart';
import '../music_sheet_pdf_screen.dart';

class FundamentalExerciseScreen extends StatelessWidget {
  const FundamentalExerciseScreen({
    super.key,
    required this.title,
    required this.scoreDocumentPath,
    required this.pdfUrl,
    required this.pdfFileName,
  });

  final String title;
  final String scoreDocumentPath;
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArPracticeScreen(
                        scoreDocumentPath: scoreDocumentPath,
                      ),
                    ),
                  ),
                  child: const Text('AR Practice'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MusicSheetReadingScreen(
                        scoreDocumentPath: scoreDocumentPath,
                      ),
                    ),
                  ),
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
                if (pdfUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MusicSheetPdfScreen(
                          title: title,
                          pdfUrl: pdfUrl,
                          pdfFileName: pdfFileName,
                        ),
                      ),
                    ),
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
