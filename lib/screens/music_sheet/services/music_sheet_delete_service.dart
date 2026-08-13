import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MusicSheetDeleteService {
  Future<void> deleteMusicSheet({
    required DocumentReference<Map<String, dynamic>> sheetReference,
    required Map<String, dynamic> sheetData,
  }) async {
    final storagePaths = <String>{};
    final files = sheetData['files'];

    if (files is List) {
      for (final file in files.whereType<Map>()) {
        final storagePath = file['storagePath'];

        if (storagePath is String && storagePath.isNotEmpty) {
          storagePaths.add(storagePath);
        }
      }
    }

    addStoragePath(
      storagePaths,
      sheetData['musicXmlStoragePath'],
    );

    addStoragePath(
      storagePaths,
      sheetData['previewAudioStoragePath'],
    );

    final ownerId = sheetData['ownerId'] as String? ?? '';

    if (ownerId.isNotEmpty) {
      final sheetFolder =
          'musicSheets/$ownerId/${sheetReference.id}';

      storagePaths.add('$sheetFolder/recognized.mxl');
      storagePaths.add('$sheetFolder/preview.mp3');
    }

    for (final storagePath in storagePaths) {
      try {
        await FirebaseStorage.instance.ref(storagePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }

    await sheetReference.delete();
  }

  void addStoragePath(
    Set<String> storagePaths,
    dynamic storagePath,
  ) {
    if (storagePath is String && storagePath.isNotEmpty) {
      storagePaths.add(storagePath);
    }
  }
}
