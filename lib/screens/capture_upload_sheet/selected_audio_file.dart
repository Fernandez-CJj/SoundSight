import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

enum AudioSelectionFailure { unsupported, empty, tooLarge, tooLong, unreadable }

class AudioSelectionException implements Exception {
  const AudioSelectionException(this.failure);
  final AudioSelectionFailure failure;
}

class SelectedAudioFile {
  const SelectedAudioFile({
    required this.name,
    required this.path,
    required this.extension,
    required this.sizeBytes,
    required this.duration,
    this.temporaryDirectory,
  });

  static const maxBytes = 95_000_000;
  static const maxDuration = Duration(minutes: 5);

  final String name;
  final String path;
  final String extension;
  final int sizeBytes;
  final Duration duration;
  final Directory? temporaryDirectory;

  static Future<SelectedAudioFile> fromPickedFile(PlatformFile picked) async {
    final extension = picked.name.split('.').last.toLowerCase();
    if (extension != 'mp3') {
      throw const AudioSelectionException(AudioSelectionFailure.unsupported);
    }
    var size = await picked.length();
    if (size != null && size > maxBytes) {
      throw const AudioSelectionException(AudioSelectionFailure.tooLarge);
    }

    Directory? temporaryDirectory;
    String? path = picked.path;
    try {
      if (path == null || !await File(path).exists()) {
        temporaryDirectory = await Directory.systemTemp.createTemp(
          'soundsight-audio-',
        );
        path =
            '${temporaryDirectory.path}${Platform.pathSeparator}source.$extension';
        final sink = File(path).openWrite();
        var copied = 0;
        try {
          await for (final chunk in picked.readAsByteStream()) {
            copied += chunk.length;
            if (copied > maxBytes) {
              throw const AudioSelectionException(
                AudioSelectionFailure.tooLarge,
              );
            }
            sink.add(chunk);
          }
        } finally {
          await sink.close();
        }
        if (copied == 0) {
          throw const AudioSelectionException(AudioSelectionFailure.empty);
        }
        size = copied;
      } else {
        size = await File(path).length();
      }
      final actualSize = size;
      if (actualSize == 0) {
        throw const AudioSelectionException(AudioSelectionFailure.empty);
      }
      if (actualSize > maxBytes) {
        throw const AudioSelectionException(AudioSelectionFailure.tooLarge);
      }

      Duration? duration;
      final player = AudioPlayer();
      try {
        await player.setSource(DeviceFileSource(path)); 
        duration = await player.getDuration();
        for (var attempt = 0; duration == null && attempt < 20; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          duration = await player.getDuration();
        }
      } finally {
        await player.dispose();
      }
      final selectedDuration = duration;
      if (selectedDuration == null || selectedDuration <= Duration.zero) {
        throw const AudioSelectionException(AudioSelectionFailure.unreadable);
      }
      if (selectedDuration > maxDuration) {
        throw const AudioSelectionException(AudioSelectionFailure.tooLong);
      }
      return SelectedAudioFile(
        name: picked.name,
        path: path,
        extension: extension,
        sizeBytes: actualSize,
        duration: selectedDuration,
        temporaryDirectory: temporaryDirectory,
      );
    } on AudioSelectionException {
      if (temporaryDirectory != null) {
        await temporaryDirectory.delete(recursive: true);
      }
      rethrow;
    } catch (_) {
      if (temporaryDirectory != null) {
        await temporaryDirectory.delete(recursive: true);
      }
      throw const AudioSelectionException(AudioSelectionFailure.unreadable);
    }
  }

  Future<void> cleanUp() async {
    final directory = temporaryDirectory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
