import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';
import 'package:soundsight/screens/players/services/score_audio_playback_service.dart';

class PublishedCompositionPlaybackController extends ChangeNotifier {
  PublishedCompositionPlaybackController({
    ScoreAudioPlaybackService? playbackService,
    PublishedCompositionService? publishedCompositionService,
  }) : playbackService = playbackService ?? ScoreAudioPlaybackService(),
       publishedCompositionService =
           publishedCompositionService ?? PublishedCompositionService();

  final ScoreAudioPlaybackService playbackService;
  final PublishedCompositionService publishedCompositionService;

  String? playingVersionId;
  bool isBusy = false;
  int playbackRequestId = 0;
  bool isDisposed = false;
  Future<void> _playbackQueue = Future<void>.value();

  bool isPlaying(PublishedComposition composition) {
    return playingVersionId == getVersionId(composition);
  }

  bool isBusyFor(PublishedComposition composition) {
    return isBusy && isPlaying(composition);
  }

  Future<String?> togglePlayback(
    PublishedComposition publishedComposition, {
    VoidCallback? onPlaybackStarted,
  }) async {
    if (isDisposed || isBusyFor(publishedComposition)) return null;

    final versionId = getVersionId(publishedComposition);
    final isStopping = playingVersionId == versionId;
    final currentRequestId = ++playbackRequestId;

    isBusy = true;

    if (!isStopping) {
      playingVersionId = versionId;
    }

    notifySafely();

    var playbackStarted = false;
    String? playbackError;
    try {
      await _queuePlaybackAction(playbackService.stop);

      if (isRequestInvalid(currentRequestId)) return null;

      if (isStopping) {
        return 'Playback stopped.';
      }

      final audioUrl = await publishedCompositionService.loadMp3Url(
        publishedComposition,
      );

      if (isRequestInvalid(currentRequestId)) return null;

      if (audioUrl == null || audioUrl.trim().isEmpty) {
        return 'This version has no playback data. Republish it first.';
      }

      await _queuePlaybackAction(() async {
        if (isRequestInvalid(currentRequestId)) return;

        await playbackService.play(
          audioUrl: audioUrl,
          onStarted: () {
            if (isRequestInvalid(currentRequestId)) return;

            playbackStarted = true;
            isBusy = false;
            notifySafely();
            onPlaybackStarted?.call();
          },
          onFinished: () => _finishPlayback(currentRequestId),
          onError: (error) {
            if (isRequestInvalid(currentRequestId)) return;

            debugPrint('Published composition MP3 playback failed: $error');
            playbackError = 'The published composition could not be played.';
            _finishPlayback(currentRequestId);
          },
        );
      });

      return playbackError;
    } catch (error, stackTrace) {
      if (isRequestInvalid(currentRequestId)) return null;

      debugPrint('Published composition playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      return 'The published composition could not be played.';
    } finally {
      if (!playbackStarted) {
        _finishPlayback(currentRequestId);
      }
    }
  }

  Future<void> stop() async {
    if (isDisposed) return;

    playbackRequestId++;
    playingVersionId = null;
    isBusy = false;
    notifySafely();
    await _queuePlaybackAction(playbackService.stop);
  }

  Future<void> _queuePlaybackAction(Future<void> Function() action) {
    _playbackQueue = _playbackQueue.catchError((Object _) {}).then((_) async {
      if (!isDisposed) await action();
    });
    return _playbackQueue;
  }

  void _finishPlayback(int requestId) {
    if (isRequestInvalid(requestId)) return;

    playingVersionId = null;
    isBusy = false;
    notifySafely();
  }

  bool isRequestInvalid(int requestId) {
    return isDisposed || requestId != playbackRequestId;
  }

  String getVersionId(PublishedComposition composition) {
    return '${composition.id}_${composition.currentVersion}';
  }

  void notifySafely() {
    if (!isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    playbackRequestId++;
    unawaited(playbackService.dispose());
    super.dispose();
  }
}
