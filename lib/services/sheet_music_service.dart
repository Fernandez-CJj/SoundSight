import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SheetMusicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> saveSheetMusic({
    required File file,
    required String originalFileName,
    required String fileType,
    required String sourceType,
  }) async {
    final docRef = _firestore.collection('sheet_music').doc();

    final fileExtension = fileType == 'pdf' ? 'pdf' : 'jpg';

    final storagePath = 'sheet_music/${docRef.id}/original.$fileExtension';

    final storageRef = _storage.ref().child(storagePath);

    await storageRef.putFile(file);

    final downloadUrl = await storageRef.getDownloadURL();

    await docRef.set({
      'originalFileName': originalFileName,
      'fileType': fileType,
      'sourceType': sourceType,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'status': 'pending_omr',
      'translationResult': {'notes': [], 'chords': [], 'synthesiaEvents': []},
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }
}
