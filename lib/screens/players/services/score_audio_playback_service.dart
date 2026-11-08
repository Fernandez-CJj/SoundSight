import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class ScoreAudioPlaybackService {
  final AudioPlayer audioPlayer = AudioPlayer();

  StreamSubscription<void>? completionSubscription;
  int playbackSession = 0;
  bool isPreparing = false;
  bool isPlaying = false;

  Future<void> play({
    required String audioUrl,
    required void Function() onStarted,
    required void Function() onFinished,
    required void Function(Object error) onError,
  }) async {
    final currentSession = ++playbackSession;
    final cleanAudioUrl = audioUrl.trim();

    isPreparing = true;
    isPlaying = false;

    await completionSubscription?.cancel();
    completionSubscription = null;
    await audioPlayer.stop();

    if (currentSession != playbackSession) {
      return;
    }

    if (cleanAudioUrl.isEmpty) {
      isPreparing = false;
      onError(StateError('The score has no MP3 audio to play.'));
      return;
    }

    try {
      await audioPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      await audioPlayer.setReleaseMode(ReleaseMode.stop);
      await audioPlayer.setSource(UrlSource(cleanAudioUrl));

      if (currentSession != playbackSession) {
        return;
      }

      completionSubscription = audioPlayer.onPlayerComplete.listen((_) {
        if (currentSession != playbackSession) {
          return;
        }

        isPreparing = false;
        isPlaying = false;
        onFinished();
      });

      await audioPlayer.resume();

      if (currentSession != playbackSession) {
        return;
      }

      isPreparing = false;
      isPlaying = true;
      onStarted();
    } catch (error) {
      if (currentSession != playbackSession) {
        return;
      }

      await completionSubscription?.cancel();
      completionSubscription = null;
      isPreparing = false;
      isPlaying = false;
      await audioPlayer.stop();
      onError(error);
    }
  }

  Future<void> stop() async {
    playbackSession++;
    isPreparing = false;
    isPlaying = false;
    await completionSubscription?.cancel();
    completionSubscription = null;
    await audioPlayer.stop();
  }

  Future<void> dispose() async {
    playbackSession++;
    isPreparing = false;
    isPlaying = false;
    await completionSubscription?.cancel();
    completionSubscription = null;
    await audioPlayer.dispose();
  }
}
