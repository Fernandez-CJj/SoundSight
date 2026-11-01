import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

enum VideoSelectionFailure { unsupported, empty, tooLarge, tooLong, noAudio, unreadable }

class VideoSelectionException implements Exception {
  const VideoSelectionException(this.failure);
  final VideoSelectionFailure failure;
}

class SelectedVideoFile {
  const SelectedVideoFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.duration,
    this.temporaryDirectory,
  });

  static const maxBytes = 150_000_000;
  static const maxDuration = Duration(minutes: 5);

  final String name;
  final String path;
  final int sizeBytes;
  final Duration duration;
  final Directory? temporaryDirectory;

  static Future<SelectedVideoFile> fromPickedFile(PlatformFile picked) async {
    if (!picked.name.toLowerCase().endsWith('.mp4')) {
      throw const VideoSelectionException(VideoSelectionFailure.unsupported);
    }

    Directory? temporaryDirectory;
    try {
      var size = await picked.length();
      if (size != null && size > maxBytes) {
        throw const VideoSelectionException(VideoSelectionFailure.tooLarge);
      }

      var path = picked.path;
      if (path == null || !await File(path).exists()) {
        temporaryDirectory = await Directory.systemTemp.createTemp(
          'soundsight-video-',
        );
        path = '${temporaryDirectory.path}${Platform.pathSeparator}source.mp4';
        final output = await File(path).open(mode: FileMode.write);
        var copied = 0;
        try {
          await for (final chunk in picked.readAsByteStream()) {
            copied += chunk.length;
            if (copied > maxBytes) {
              throw const VideoSelectionException(VideoSelectionFailure.tooLarge);
            }
            await output.writeFrom(chunk);
          }
        } finally {
          await output.close();
        }
        size = copied;
      } else {
        size = await File(path).length();
      }

      if (size == 0) {
        throw const VideoSelectionException(VideoSelectionFailure.empty);
      }
      if (size > maxBytes) {
        throw const VideoSelectionException(VideoSelectionFailure.tooLarge);
      }

      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info == null ||
          !info.getStreams().any((stream) => stream.getType() == 'video')) {
        throw const VideoSelectionException(VideoSelectionFailure.unreadable);
      }
      if (!info.getStreams().any((stream) => stream.getType() == 'audio')) {
        throw const VideoSelectionException(VideoSelectionFailure.noAudio);
      }

      final player = VideoPlayerController.file(File(path));
      late Duration duration;
      try {
        await player.initialize();
        if (player.value.duration <= Duration.zero) {
          throw const VideoSelectionException(VideoSelectionFailure.unreadable);
        }
        duration = player.value.duration;
      } finally {
        await player.dispose();
      }

      final seconds = double.tryParse(info.getDuration() ?? '');
      if (seconds != null && seconds.isFinite && seconds > 0) {
        final probedDuration = Duration(
          milliseconds: (seconds * 1000).ceil(),
        );
        if (probedDuration > duration) duration = probedDuration;
      }
      if (duration > maxDuration) {
        throw const VideoSelectionException(VideoSelectionFailure.tooLong);
      }

      return SelectedVideoFile(
        name: picked.name,
        path: path,
        sizeBytes: size,
        duration: duration,
        temporaryDirectory: temporaryDirectory,
      );
    } on VideoSelectionException {
      if (temporaryDirectory != null) {
        await temporaryDirectory.delete(recursive: true);
      }
      rethrow;
    } catch (_) {
      if (temporaryDirectory != null) {
        await temporaryDirectory.delete(recursive: true);
      }
      throw const VideoSelectionException(VideoSelectionFailure.unreadable);
    }
  }

  Future<void> cleanUp() async {
    final directory = temporaryDirectory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
