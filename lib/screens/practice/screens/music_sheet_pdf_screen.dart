import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';

class MusicSheetPdfScreen extends StatefulWidget {
  const MusicSheetPdfScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.pdfFileName,
  });

  final String title;
  final String pdfUrl;
  final String pdfFileName;

  @override
  State<MusicSheetPdfScreen> createState() => _MusicSheetPdfScreenState();
}

class _MusicSheetPdfScreenState extends State<MusicSheetPdfScreen> {
  late Future<Uint8List> pdfFuture = downloadPdf();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pdfFileName.isEmpty ? widget.title : widget.pdfFileName,
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    pdfFuture = downloadPdf();
                  });
                },
                child: const Text('Unable to load music sheet. Retry'),
              ),
            );
          }

          return PdfViewer.data(snapshot.data!, sourceName: widget.title);
        },
      ),
    );
  }

  Future<Uint8List> downloadPdf() async {
    final response = await http.get(Uri.parse(widget.pdfUrl));

    if (response.statusCode != 200) {
      throw Exception('Music sheet download failed.');
    }

    return response.bodyBytes;
  }
}
