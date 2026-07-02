import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:soundsight/services/sheet_music_service.dart';

void main() {
  runApp(const SoundSightApp());
}

class SoundSightApp extends StatelessWidget {
  const SoundSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SoundSight',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _imagePicker = ImagePicker();
  final SheetMusicService _sheetMusicService = SheetMusicService();
  bool isSaving = false;

  Future<void> pickPdfSheetMusic() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      return;
    }

    final pickedFile = result.files.single;

    if (pickedFile.path == null) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final documentId = await _sheetMusicService.saveSheetMusic(
        file: File(pickedFile.path!),
        originalFileName: pickedFile.name,
        fileType: 'pdf',
        sourceType: 'pdf_upload',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to Firebase. ID: $documentId')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> scanPhysicalSheetMusic() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final documentId = await _sheetMusicService.saveSheetMusic(
        file: File(image.path),
        originalFileName: image.name,
        fileType: 'image',
        sourceType: 'camera_scan',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned sheet saved to Firebase. ID: $documentId'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save scanned sheet: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              const Text(
                'SoundSight',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2B2B),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Scan piano sheet music and prepare it for AR piano guidance.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5F5F5F),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 50),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF5),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.piano, size: 72, color: Color(0xFF3A3A3A)),

                    const SizedBox(height: 18),

                    const Text(
                      'Start with Sheet Music',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Choose a PDF file or capture a physical piano sheet using your camera.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : pickPdfSheetMusic,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Upload PDF Sheet Music'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F2F2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: isSaving ? null : scanPhysicalSheetMusic,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Scan Physical Sheet Music'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2F2F2F),
                          side: const BorderSide(
                            color: Color(0xFF2F2F2F),
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              const Center(
                child: Text(
                  'Piano-inspired soft black and warm white theme',
                  style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
