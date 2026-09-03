import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';

import '../challenges/ar/ar_practice_screen.dart';
import '../challenges/sight_reading/music_sheet_reading_screen.dart';

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
                if (pdfUrl.isNotEmpty)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FundamentalPdfScreen(
                          title: title,
                          pdfUrl: pdfUrl,
                          pdfFileName: pdfFileName,
                        ),
                      ),
                    ),
                    child: const Text('View PDF'),
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

class FundamentalPdfScreen extends StatefulWidget {
  const FundamentalPdfScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.pdfFileName,
  });

  final String title;
  final String pdfUrl;
  final String pdfFileName;

  @override
  State<FundamentalPdfScreen> createState() => _FundamentalPdfScreenState();
}

class _FundamentalPdfScreenState extends State<FundamentalPdfScreen> {
  late Future<Uint8List> _pdfFuture = _downloadPdf();

  Future<Uint8List> _downloadPdf() async {
    final response = await http.get(Uri.parse(widget.pdfUrl));
    if (response.statusCode != 200) {
      throw Exception('PDF download failed (${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pdfFileName.isEmpty ? widget.title : widget.pdfFileName,
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _pdfFuture = _downloadPdf()),
                child: const Text('Unable to load PDF. Retry'),
              ),
            );
          }
          return PdfViewer.data(snapshot.data!, sourceName: widget.title);
        },
      ),
    );
  }
}
