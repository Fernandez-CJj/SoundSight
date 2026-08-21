import 'dart:async';

import 'package:soundsight/screens/composition/services/composition_playback_service.dart';

import 'midi_file_duration_calculator.dart';

class MidiScorePlaybackService {
  final CompositionPlaybackService pianoPlaybackService =
      CompositionPlaybackService();

  int playbackSession = 0;
  bool isPreparing = false;
  bool isPlaying = false;

  Future<void> play({
    required List<MidiTimelineEvent> timelineEvents,
    required void Function() onStarted,
    required void Function() onFinished,
    required void Function(Object error) onError,
  }) async {
    final currentSession = ++playbackSession;
    isPreparing = true;
    isPlaying = false;

    await pianoPlaybackService.stop();

    if (currentSession != playbackSession) {
      return;
    }

    if (timelineEvents.isEmpty) {
      isPreparing = false;
      onError(StateError('The score has no MIDI timeline to play.'));
      return;
    }

    try {
      final scoreMidiNumbers = timelineEvents
          .expand((event) => event.midiNotes)
          .toSet();
      final availableMidiNumbers = await pianoPlaybackService
          .preloadPreviewNotes(scoreMidiNumbers);

      if (currentSession != playbackSession) {
        return;
      }

      if (availableMidiNumbers.isEmpty) {
        throw StateError(
          'None of the score notes have a matching piano sample.',
        );
      }

      isPreparing = false;
      isPlaying = true;
      onStarted();

      final playbackClock = Stopwatch()..start();

      for (final event in timelineEvents) {
        final waitTime = event.scheduledTime - playbackClock.elapsed;

        if (waitTime > Duration.zero) {
          await Future<void>.delayed(waitTime);
        }

        if (currentSession != playbackSession) {
          return;
        }

        final playableNotes = event.midiNotes.where(
          availableMidiNumbers.contains,
        );

        await Future.wait(
          playableNotes.map(
            (midiNumber) => pianoPlaybackService.playPreview(
              midiNumber,
              allowOverlap: true,
            ),
          ),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (currentSession != playbackSession) {
        return;
      }

      isPlaying = false;
      await pianoPlaybackService.stop();
      onFinished();
    } catch (error) {
      if (currentSession != playbackSession) {
        return;
      }

      isPreparing = false;
      isPlaying = false;
      await pianoPlaybackService.stop();
      onError(error);
    }
  }

  Future<void> stop() async {
    playbackSession++;
    isPreparing = false;
    isPlaying = false;
    await pianoPlaybackService.stop();
  }

  Future<void> dispose() async {
    playbackSession++;
    isPreparing = false;
    isPlaying = false;
    await pianoPlaybackService.dispose();
  }
}
