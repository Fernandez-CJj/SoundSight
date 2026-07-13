import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class MusicSheetUploadService {
  static const int maxSheetPages = 20;
  static const int maxImageFileSize = 5 * 1024 * 1024;
  static const int maxPdfFileSize = 20 * 1024 * 1024;

  Future<String> saveSheet({
    required String ownerId,
    required String title,
    required List<PlatformFile> files,
    required int? pdfPageCount,
    required void Function(double progress) onProgress,
  }) async {
    _validateFiles(files, pdfPageCount);

    final sheetDocument = FirebaseFirestore.instance
        .collection('musicSheets')
        .doc();
    final uploadedReferences = <Reference>[];
    final uploadedFiles = <Map<String, dynamic>>[];
    final totalBytes = files.fold<int>(
      0,
      (total, file) => total + file.bytes!.length,
    );
    var completedBytes = 0;

    try {
      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        final bytes = file.bytes!;
        final isPdf = file.extension?.toLowerCase() == 'pdf';
        final extension = _getSafeFileExtension(file);
        final contentType = _getContentType(extension);
        final storageFileName = isPdf
            ? 'sheet.pdf'
            : 'page_${(index + 1).toString().padLeft(2, '0')}.$extension';
        final storageReference = FirebaseStorage.instance.ref(
          'musicSheets/$ownerId/${sheetDocument.id}/$storageFileName',
        );

        uploadedReferences.add(storageReference);

        final uploadTask = storageReference.putData(
          bytes,
          SettableMetadata(
            contentType: contentType,
            customMetadata: {
              'ownerId': ownerId,
              'sheetId': sheetDocument.id,
              'originalName': file.name,
            },
          ),
        );

        await for (final snapshot in uploadTask.snapshotEvents) {
          if (totalBytes == 0) continue;

          final progress =
              (completedBytes + snapshot.bytesTransferred) / totalBytes;
          onProgress(progress.clamp(0.0, 1.0).toDouble());
        }

        completedBytes += bytes.length;
        uploadedFiles.add({
          'name': file.name,
          'storagePath': storageReference.fullPath,
          'sizeBytes': bytes.length,
          'contentType': contentType,
          'pageNumber': isPdf ? null : index + 1,
        });
      }

      final isPdf = files.length == 1 &&
          files.first.extension?.toLowerCase() == 'pdf';

      await sheetDocument.set({
        'ownerId': ownerId,
        'title': title,
        'type': isPdf ? 'pdf' : 'images',
        'pageCount': isPdf ? pdfPageCount : files.length,
        'files': uploadedFiles,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return sheetDocument.id;
    } catch (error, stackTrace) {
      debugPrint('Unable to save music sheet: $error');
      debugPrintStack(stackTrace: stackTrace);

      for (final reference in uploadedReferences) {
        try {
          await reference.delete();
        } catch (_) {}
      }

      try {
        await sheetDocument.delete();
      } catch (_) {}

      rethrow;
    }
  }

  void _validateFiles(List<PlatformFile> files, int? pdfPageCount) {
    if (files.isEmpty || files.length > maxSheetPages) {
      throw StateError('Invalid number of selected files.');
    }

    final pdfFiles = files.where((file) {
      return file.extension?.toLowerCase() == 'pdf';
    }).toList();

    if (pdfFiles.isNotEmpty) {
      if (files.length != 1 || pdfPageCount == null) {
        throw StateError('A PDF must be uploaded by itself.');
      }

      if (pdfPageCount < 1 || pdfPageCount > maxSheetPages) {
        throw StateError('Invalid PDF page count.');
      }
    }

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('A selected file could not be read.');
      }

      final isPdf = file.extension?.toLowerCase() == 'pdf';
      final maxFileSize = isPdf ? maxPdfFileSize : maxImageFileSize;

      if (bytes.length > maxFileSize) {
        throw StateError('A selected file exceeds the size limit.');
      }
    }
  }

  String _getSafeFileExtension(PlatformFile file) {
    final extension = file.extension?.toLowerCase();

    if (extension == 'pdf' ||
        extension == 'png' ||
        extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'heic' ||
        extension == 'webp') {
      return extension!;
    }

    return 'jpg';
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
