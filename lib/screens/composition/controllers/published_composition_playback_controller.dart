import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/composition_playback_service.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';

class PublishedCompositionPlaybackController extends ChangeNotifier {
  final CompositionPlaybackService playbackService =
      CompositionPlaybackService();
  final PublishedCompositionService publishedCompositionService =
      PublishedCompositionService();

  String? playingVersionId;
  bool isBusy = false;
  int playbackRequestId = 0;
  bool isDisposed = false;

  bool isPlaying(PublishedComposition composition) {
    return playingVersionId == getVersionId(composition);
  }

  Future<String?> togglePlayback(
    PublishedComposition publishedComposition, {
    VoidCallback? onPlaybackStarted,
  }) async {
    if (isBusy || isDisposed) return null;

    final versionId = getVersionId(publishedComposition);
    final isStopping = playingVersionId == versionId;
    final currentRequestId = ++playbackRequestId;

    isBusy = true;

    if (!isStopping) {
      playingVersionId = versionId;
    }

    notifySafely();

    try {
      await playbackService.stop();

      if (isRequestInvalid(currentRequestId)) return null;

      if (isStopping) {
        return 'Playback stopped.';
      }

      final composition = await publishedCompositionService
          .loadPlayableComposition(publishedComposition);

      if (isRequestInvalid(currentRequestId)) return null;

      if (composition == null || composition.notes.isEmpty) {
        return 'This version has no playback data. Republish it first.';
      }

      await playbackService.playComposition(
        composition: composition,
        onPlaybackStarted: () {
          if (isRequestInvalid(currentRequestId)) return;

          isBusy = false;
          notifySafely();
          onPlaybackStarted?.call();
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Published composition playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      return 'The published composition could not be played.';
    } finally {
      if (!isRequestInvalid(currentRequestId)) {
        playingVersionId = null;
        isBusy = false;
        notifySafely();
      }
    }

    return null;
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
