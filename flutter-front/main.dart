import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'editor/editor.dart';

void main() {
  runApp(
    const MaterialApp(
      home: SoundSightLocalTest(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class SoundSightLocalTest extends StatefulWidget {
  const SoundSightLocalTest({super.key});

  @override
  State<SoundSightLocalTest> createState() => _SoundSightLocalTestState();
}

class _SoundSightLocalTestState extends State<SoundSightLocalTest> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _statusMessage = "Select, snap, or upload a sheet music PDF to begin.";

  final String backendUrl = "http://192.168.0.102:8000/process-sheet";

  /// Fallback dummy sequence generator simulating Minuet in G structures for validation testing
  // List<Note> _generateFallbackMockSequence() {
  //   return [
  //     Note(id: "1", pitch: 74, startTime: 0.0, duration: 1.0), // D5
  //     Note(id: "2", pitch: 67, startTime: 1.0, duration: 0.5), // G4
  //     Note(id: "3", pitch: 69, startTime: 1.5, duration: 0.5), // A4
  //     Note(id: "4", pitch: 71, startTime: 2.0, duration: 0.5), // B4
  //     Note(id: "5", pitch: 72, startTime: 2.5, duration: 0.5), // C5
  //     Note(id: "6", pitch: 74, startTime: 3.0, duration: 1.0), // D5
  //     Note(id: "7", pitch: 67, startTime: 4.0, duration: 1.0), // G4
  //   ];
  // }

  Future<void> _uploadFileToServer(String filePath) async {
    setState(() {
      _isProcessing = true;
      _statusMessage =
          "Uploading... Audiveris is processing (this may take a few minutes).";
    });

    try {
      var client = http.Client();
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final parsedNotes = MidiImportService.importFromMap(responseData);

        setState(() {
          _statusMessage = "OMR Analysis Successful! Opening Editor...";
        });

        if (mounted) {
          final Map<String, dynamic>? correctedMidi = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MidiEditorScreen(notes: parsedNotes),
            ),
          );

          if (correctedMidi != null) {
            setState(() {
              final count = (correctedMidi['notes'] as List?)?.length ?? 0;
              _statusMessage =
                  "Corrected $count notes. Ready for MIDI regeneration.";
            });
          }
        }
      } else {
        setState(() {
          _statusMessage =
              "Server Error ${response.statusCode}: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage =
            "Network Error: $e\n(Check if your backend is running or if Android is blocking cleartext HTTP).";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleImageAction(ImageSource source) async {
    final XFile? selectedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (selectedFile == null) return;
    await _uploadFileToServer(selectedFile.path);
  }

  Future<void> _handlePdfAction() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) return;
      await _uploadFileToServer(result.files.single.path!);
    } catch (e) {
      setState(() {
        _statusMessage = "Error opening file browser layer: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SoundSight Local MVP")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Capture Live Sheet Music"),
                onPressed: () => _handleImageAction(ImageSource.camera),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text("Upload from Phone Gallery"),
                onPressed: () => _handleImageAction(ImageSource.gallery),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Upload Sheet Music PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade50,
                  foregroundColor: Colors.indigo,
                ),
                onPressed: _handlePdfAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
