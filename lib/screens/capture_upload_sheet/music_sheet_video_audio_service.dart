import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_audio_file.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_video_file.dart';

class MusicSheetVideoAudioService {
  Future<SelectedAudioFile> prepareAudio(SelectedVideoFile video) async {
    final directory = await Directory.systemTemp.createTemp(
      'soundsight-video-audio-',
    );
    final output = File('${directory.path}${Platform.pathSeparator}source.mp3');

    try {
      final session = await FFmpegKit.executeWithArguments([
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-i',
        video.path,
        '-map',
        '0:a:0',
        '-vn',
        '-t',
        '299.5',
        '-c:a',
        'libmp3lame',
        '-b:a',
        '192k',
        '-ar',
        '44100',
        '-ac',
        '2',
        output.path,
      ]);
      if (!ReturnCode.isSuccess(await session.getReturnCode()) ||
          !await output.exists()) {
        throw StateError('video-audio-extraction-failed');
      }

      final size = await output.length();
      if (size == 0 || size > SelectedAudioFile.maxBytes) {
        throw StateError('video-audio-size-invalid');
      }

      final audioSession = await FFprobeKit.getMediaInformation(output.path);
      final info = audioSession.getMediaInformation();
      if (info == null ||
          !info.getStreams().any((stream) => stream.getType() == 'audio')) {
        throw StateError('video-audio-unreadable');
      }
      final seconds = double.tryParse(info.getDuration() ?? '');
      if (seconds == null || !seconds.isFinite || seconds <= 0) {
        throw StateError('video-audio-duration-invalid');
      }
      final duration = Duration(milliseconds: (seconds * 1000).ceil());
      if (duration > SelectedAudioFile.maxDuration) {
        throw StateError('video-audio-too-long');
      }

      return SelectedAudioFile(
        name: '${video.name.substring(0, video.name.length - 4)}.mp3',
        path: output.path,
        extension: 'mp3',
        sizeBytes: size,
        duration: duration,
        temporaryDirectory: directory,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }
}
