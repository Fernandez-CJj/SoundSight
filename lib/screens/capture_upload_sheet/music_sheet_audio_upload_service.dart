import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_audio_file.dart';

class MusicSheetAudioUploadService {
  Future<String> saveAudio({
    required String title,
    required SelectedAudioFile file,
    required void Function(double) onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not-signed-in');

    final sheetDocument = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('musicSheets')
        .doc();
    final storageReference = FirebaseStorage.instance.ref(
      'musicSheets/${user.uid}/${sheetDocument.id}/source.mp3',
    );

    try {
      final uploadTask = storageReference.putFile(
        File(file.path),
        SettableMetadata(contentType: 'audio/mpeg'),
      );
      await for (final snapshot in uploadTask.snapshotEvents) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      }
      await uploadTask;

      await sheetDocument.set({
        'ownerId': user.uid,
        'title': title,
        'type': 'audio',
        'pageCount': 0,
        'durationMs': file.duration.inMilliseconds,
        'files': [
          {
            'name': file.name,
            'storagePath': storageReference.fullPath,
            'sizeBytes': file.sizeBytes,
            'contentType': 'audio/mpeg',
            'pageNumber': null,
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return sheetDocument.id;
    } catch (_) {
      try {
        await storageReference.delete();
      } catch (_) {}
      rethrow;
    }
  }
}
