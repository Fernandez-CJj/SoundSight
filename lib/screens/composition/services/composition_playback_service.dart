import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/services/composition_audio_renderer.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/models/piano_note.dart';

class CompositionPlaybackService {
  static const int _maximumPreviewVoices = 10;
  static const int _maximumPreviewVoicesPerNote = 2;
  static const Duration _compositionReleaseDuration = Duration(
    milliseconds: 120,
  );
  static final AudioContext _previewAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );
  static final AudioContext _compositionAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );

  final CompositionAudioRenderer _renderer = CompositionAudioRenderer();
  final Map<int, Future<AudioPool>> _previewPools = {};
  final Set<int> _currentPreviewMidiNumbers = {};
  final List<_PreviewVoice> _activePreviewVoices = [];
  final Map<String, CompositionNote> _activeTimelineNotes = {};

  Future<void> _previewQueue = Future<void>.value();
  AudioPlayer? _compositionPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _playbackSession = 0;
  int _previewLoadSession = 0;
  int _previewGeneration = 0;
  int _elapsedMicroseconds = 0;
  int _totalMicroseconds = 0;
  double _volume = 1;
  bool _sustainEnabled = false;
  bool _metronomeEnabled = false;
  Completer<void>? _resumeSignal;

  void Function(CompositionNote?)? _onNoteChanged;
  void Function(Set<String>)? _onActiveNotesChanged;
  void Function(Duration position, Duration total)? _onProgressChanged;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get volume => _volume;
  bool get sustainEnabled => _sustainEnabled;
  bool get metronomeEnabled => _metronomeEnabled;

  set sustainEnabled(bool value) {
    final shouldReleasePreviewVoices = _sustainEnabled && !value;
    _sustainEnabled = value;

    if (shouldReleasePreviewVoices) {
      unawaited(_stopActivePreviewSound());
    }
  }

  set metronomeEnabled(bool value) {
    _metronomeEnabled = value;
  }

  Future<void> setVolume(double value) async {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Volume must be finite.');
    }

    _volume = value.clamp(0.0, 1.0).toDouble();

    final player = _compositionPlayer;

    if (player != null) {
      await player.setVolume(_volume);
    }
  }

  Future<void> preloadPreviewOctave(int octave) async {
    final currentLoadSession = ++_previewLoadSession;
    final safeOctave = octave.clamp(0, 8).toInt();
    final firstMidi = safeOctave == 0
        ? PianoNote.minimumMidi
        : ((safeOctave + 1) * 12).clamp(
            PianoNote.minimumMidi,
            PianoNote.maximumMidi,
          ).toInt();
    final lastMidi = safeOctave == 0
        ? 23
        : safeOctave == 8
        ? PianoNote.maximumMidi
        : firstMidi + 11;
    final requiredMidiNumbers = <int>{
      for (var midiNumber = firstMidi; midiNumber <= lastMidi; midiNumber++)
        midiNumber,
    };

    final loadedMidiNumbers = await Future.wait(
      requiredMidiNumbers.map((midiNumber) async {
        try {
          await _getPreviewPool(midiNumber);
          return midiNumber;
        } catch (_) {
          return null;
        }
      }),
    );

    if (currentLoadSession != _previewLoadSession) return;

    _currentPreviewMidiNumbers
      ..clear()
      ..addAll(loadedMidiNumbers.whereType<int>());

    await _disposeUnusedPreviewPools();
  }

  Future<void> playComposition({
    required Composition composition,
    void Function(CompositionNote?)? onNoteChanged,
    void Function(Set<String>)? onActiveNotesChanged,
    void Function(Duration position, Duration total)? onProgressChanged,
    void Function()? onPlaybackStarted,
    bool loop = false,
    double startBeat = 0,
    int? loopMeasureIndex,
  }) async {
    if (composition.notes.isEmpty) return;

    if (composition.tempo <= 0) {
      throw ArgumentError.value(
        composition.tempo,
        'tempo',
        'Tempo must be greater than zero.',
      );
    }

    if (composition.beatUnit <= 0) {
      throw ArgumentError.value(
        composition.beatUnit,
        'beatUnit',
        'Beat unit must be greater than zero.',
      );
    }

    if (!startBeat.isFinite) {
      throw ArgumentError.value(
        startBeat,
        'startBeat',
        'The playback start beat must be finite.',
      );
    }

    if (loopMeasureIndex != null &&
        (loopMeasureIndex < 0 ||
            loopMeasureIndex >= composition.measureCount)) {
      throw RangeError.range(
        loopMeasureIndex,
        0,
        composition.measureCount - 1,
        'loopMeasureIndex',
      );
    }

    final currentSession = ++_playbackSession;

    await _prepareForNewComposition();

    if (currentSession != _playbackSession) return;

    final renderResult = await _renderer.render(
      composition,
      releaseDuration: _compositionReleaseDuration,
    );

    if (currentSession != _playbackSession) return;

    final timelineNotes = _buildTimelineNotes(composition);
    final microsecondsPerBeat =
        (60000000 / composition.tempo) * (4 / composition.beatUnit);
    final renderedTotalBeats =
        renderResult.duration.inMicroseconds / microsecondsPerBeat;
    final writtenTotalBeats =
        (composition.measureCount * composition.beatsPerMeasure).toDouble();
    final playbackStartBeat = loopMeasureIndex == null
        ? startBeat.clamp(0.0, writtenTotalBeats).toDouble()
        : (loopMeasureIndex * composition.beatsPerMeasure).toDouble();
    final playbackEndBeat = loopMeasureIndex == null
        ? renderedTotalBeats
        : math.min(
            writtenTotalBeats,
            playbackStartBeat + composition.beatsPerMeasure,
          );
    final shouldLoop = loop || loopMeasureIndex != null;
    final playbackStartPosition = Duration(
      microseconds: (playbackStartBeat * microsecondsPerBeat).round(),
    );
    final boundaries = _buildTimelineBoundaries(
      timelineNotes,
      metronomeTotalBeats: writtenTotalBeats,
    );
    final player = AudioPlayer();

    try {
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setAudioContext(_compositionAudioContext);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(_volume);
      await player.setSource(DeviceFileSource(renderResult.file.path));

      if (playbackStartPosition > Duration.zero) {
        await player.seek(playbackStartPosition);
      }
    } catch (_) {
      await player.dispose();
      rethrow;
    }

    if (currentSession != _playbackSession) {
      await player.dispose();
      return;
    }

    _compositionPlayer = player;
    _isPlaying = true;
    _isPaused = false;
    _onNoteChanged = onNoteChanged;
    _onActiveNotesChanged = onActiveNotesChanged;
    _onProgressChanged = onProgressChanged;
    _totalMicroseconds = renderResult.duration.inMicroseconds;
    _elapsedMicroseconds = playbackStartPosition.inMicroseconds.clamp(
      0,
      _totalMicroseconds,
    );
    _notifyProgress();

    try {
      await player.resume();

      if (!_isCurrentSession(currentSession)) return;

      onPlaybackStarted?.call();

      do {
        final completed = await _playRenderedTimeline(
          boundaries: boundaries,
          timelineNotes: timelineNotes,
          startBeat: playbackStartBeat,
          endBeat: playbackEndBeat,
          tempo: composition.tempo,
          beatUnit: composition.beatUnit,
          session: currentSession,
        );

        if (!completed || !shouldLoop) break;

        _activeTimelineNotes.clear();
        _onNoteChanged?.call(null);
        _onActiveNotesChanged?.call(const <String>{});
        _elapsedMicroseconds = playbackStartPosition.inMicroseconds.clamp(
          0,
          _totalMicroseconds,
        );
        _notifyProgress();

        await player.pause();

        if (!_isCurrentSession(currentSession)) return;

        await player.seek(playbackStartPosition);
        await player.setVolume(_volume);
        await player.resume();
      } while (_isCurrentSession(currentSession));
    } finally {
      if (_isCurrentSession(currentSession)) {
        _elapsedMicroseconds = _totalMicroseconds;
        _notifyProgress();
        await _finishCompositionPlayback();
      }
    }
  }

  Future<void> playPreview(
    int midiNumber, {
    bool allowOverlap = false,
    double velocity = 1,
  }) {
    if (_isPlaying) return Future<void>.value();

    final generation = allowOverlap
        ? _previewGeneration
        : ++_previewGeneration;

    return _enqueuePreview(() async {
      if (_isPlaying || generation != _previewGeneration) return;

      if (!allowOverlap && !_sustainEnabled) {
        await _clearActivePreviewSound();
      }

      if (_isPlaying || generation != _previewGeneration) return;

      while (_activePreviewVoices.where((voice) {
            return voice.midiNumber == midiNumber;
          }).length >=
          _maximumPreviewVoicesPerNote) {
        final oldestMatchingVoice = _activePreviewVoices.firstWhere((voice) {
          return voice.midiNumber == midiNumber;
        });
        await _finishPreviewVoice(oldestMatchingVoice);
      }

      while (_activePreviewVoices.length >= _maximumPreviewVoices) {
        await _finishPreviewVoice(_activePreviewVoices.first);
      }

      if (_isPlaying || generation != _previewGeneration) return;

      final pool = await _getPreviewPool(midiNumber);

      if (_isPlaying || generation != _previewGeneration) return;

      final previewVolume = (_volume * velocity).clamp(0.0, 1.0).toDouble();
      final stopSound = await pool.start(volume: previewVolume);
      final voice = _PreviewVoice(
        midiNumber: midiNumber,
        stopSound: stopSound,
      );

      if (_isPlaying || generation != _previewGeneration) {
        await _stopPreviewVoiceSafely(voice);
        return;
      }

      _activePreviewVoices.add(voice);
      voice.timer = Timer(
        Duration(seconds: _sustainEnabled ? 8 : 4),
        () async {
          await _finishPreviewVoice(voice);
        },
      );
    });
  }

  Future<void> pause() async {
    if (!_isPlaying || _isPaused) return;

    _isPaused = true;
    _resumeSignal ??= Completer<void>();

    final player = _compositionPlayer;

    if (player != null) {
      await player.pause();
    }
  }

  Future<void> resume() async {
    if (!_isPlaying || !_isPaused) return;

    final player = _compositionPlayer;

    try {
      if (player != null) {
        await player.resume();
      }
    } finally {
      _isPaused = false;
      _completeResumeSignal();
    }
  }

  Future<void> stop() async {
    _playbackSession++;
    _isPlaying = false;
    _isPaused = false;
    _completeResumeSignal();
    _clearPlaybackCallbacks();
    _elapsedMicroseconds = 0;
    _notifyProgress();
    _onProgressChanged = null;
    _activeTimelineNotes.clear();

    await _stopActivePreviewSound();
    await _disposeCompositionPlayer();
  }

  Future<void> _prepareForNewComposition() async {
    _isPlaying = false;
    _isPaused = false;
    _completeResumeSignal();
    _clearPlaybackCallbacks();
    _elapsedMicroseconds = 0;
    _totalMicroseconds = 0;
    _activeTimelineNotes.clear();

    await _stopActivePreviewSound();
    await _disposeCompositionPlayer();
  }

  Future<void> _finishCompositionPlayback() async {
    _isPlaying = false;
    _isPaused = false;
    _completeResumeSignal();
    _activeTimelineNotes.clear();
    _onNoteChanged?.call(null);
    _onActiveNotesChanged?.call(const <String>{});
    _clearPlaybackCallbacks();
    _onProgressChanged = null;
    await _disposeCompositionPlayer();
  }

  void _clearPlaybackCallbacks() {
    _onNoteChanged?.call(null);
    _onActiveNotesChanged?.call(const <String>{});
    _onNoteChanged = null;
    _onActiveNotesChanged = null;
  }

  List<_TimelineNote> _buildTimelineNotes(Composition composition) {
    final timelineNotes = <_TimelineNote>[];

    for (final note in composition.notes) {
      if (note.durationBeats <= 0) continue;

      final startBeat =
          (note.measureIndex * composition.beatsPerMeasure) + note.startBeat;

      timelineNotes.add(
        _TimelineNote(
          note: note,
          startBeat: startBeat,
          endBeat: startBeat + note.durationBeats,
        ),
      );
    }

    timelineNotes.sort((first, second) {
      final startComparison = first.startBeat.compareTo(second.startBeat);

      if (startComparison != 0) return startComparison;

      return first.note.midiNumber.compareTo(second.note.midiNumber);
    });

    return timelineNotes;
  }

  List<_TimelineBoundary> _buildTimelineBoundaries(
    List<_TimelineNote> notes, {
    required double metronomeTotalBeats,
  }) {
    final boundariesByBeat = <double, _TimelineBoundary>{};

    for (final note in notes) {
      boundariesByBeat
          .putIfAbsent(
            note.startBeat,
            () => _TimelineBoundary(note.startBeat),
          )
          .startingNotes
          .add(note);
      boundariesByBeat
          .putIfAbsent(
            note.endBeat,
            () => _TimelineBoundary(note.endBeat),
          )
          .endingNotes
          .add(note);
    }

    for (var beat = 0; beat < metronomeTotalBeats; beat++) {
      boundariesByBeat
          .putIfAbsent(
            beat.toDouble(),
            () => _TimelineBoundary(beat.toDouble()),
          )
          .isMetronomeBeat = true;
    }

    final boundaries = boundariesByBeat.values.toList();
    boundaries.sort((first, second) => first.beat.compareTo(second.beat));
    return boundaries;
  }

  Future<bool> _playRenderedTimeline({
    required List<_TimelineBoundary> boundaries,
    required List<_TimelineNote> timelineNotes,
    required double startBeat,
    required double endBeat,
    required int tempo,
    required int beatUnit,
    required int session,
  }) async {
    const timingTolerance = 0.0000001;
    var currentBeat = startBeat;

    _activeTimelineNotes.clear();

    for (final timelineNote in timelineNotes) {
      if (timelineNote.startBeat < startBeat - timingTolerance &&
          timelineNote.endBeat > startBeat + timingTolerance) {
        _activeTimelineNotes[timelineNote.note.id] = timelineNote.note;
      }
    }

    if (_activeTimelineNotes.isNotEmpty) {
      _notifyTimelineNotes(const <_TimelineNote>[]);
    }

    for (final boundary in boundaries) {
      if (!_isCurrentSession(session)) return false;

      if (boundary.beat < startBeat - timingTolerance) continue;
      if (boundary.beat >= endBeat - timingTolerance) break;

      final waitBeats = boundary.beat - currentBeat;

      if (waitBeats > 0) {
        final completedWait = await _waitForBeats(
          beats: waitBeats,
          tempo: tempo,
          beatUnit: beatUnit,
          session: session,
        );

        if (!completedWait) return false;
      }

      if (_metronomeEnabled && boundary.isMetronomeBeat) {
        unawaited(_playMetronomeClick());
      }

      for (final endingNote in boundary.endingNotes) {
        _activeTimelineNotes.remove(endingNote.note.id);
      }

      for (final startingNote in boundary.startingNotes) {
        _activeTimelineNotes[startingNote.note.id] = startingNote.note;
      }

      if (boundary.startingNotes.isNotEmpty ||
          boundary.endingNotes.isNotEmpty) {
        _notifyTimelineNotes(boundary.startingNotes);
      }

      currentBeat = boundary.beat;
    }

    final remainingBeats = endBeat - currentBeat;

    if (remainingBeats > 0) {
      final completed = await _waitForBeats(
        beats: remainingBeats,
        tempo: tempo,
        beatUnit: beatUnit,
        session: session,
      );

      if (!completed) return false;
    }

    _activeTimelineNotes.clear();
    _onNoteChanged?.call(null);
    _onActiveNotesChanged?.call(const <String>{});
    return _isCurrentSession(session);
  }

  void _notifyTimelineNotes(List<_TimelineNote> newlyStartedNotes) {
    _onActiveNotesChanged?.call(_activeTimelineNotes.keys.toSet());

    if (newlyStartedNotes.isNotEmpty) {
      _onNoteChanged?.call(newlyStartedNotes.first.note);
    } else if (_activeTimelineNotes.isEmpty) {
      _onNoteChanged?.call(null);
    } else {
      _onNoteChanged?.call(_activeTimelineNotes.values.first);
    }
  }

  Future<bool> _waitForBeats({
    required double beats,
    required int tempo,
    required int beatUnit,
    required int session,
  }) async {
    final microsecondsPerBeat = (60000000 / tempo) * (4 / beatUnit);
    var remainingMicroseconds = (microsecondsPerBeat * beats).round();

    while (remainingMicroseconds > 0) {
      if (!_isCurrentSession(session)) return false;

      if (_isPaused) {
        final resumed = await _waitUntilResumed(session);

        if (!resumed) return false;
        continue;
      }

      final requestedMicroseconds = math.min(16000, remainingMicroseconds);
      final stopwatch = Stopwatch()..start();

      await Future<void>.delayed(
        Duration(microseconds: requestedMicroseconds),
      );

      stopwatch.stop();

      if (!_isCurrentSession(session)) return false;
      if (_isPaused) continue;

      final elapsedMicroseconds = math.min(
        remainingMicroseconds,
        math.max(1, stopwatch.elapsedMicroseconds),
      );

      remainingMicroseconds -= elapsedMicroseconds;
      _elapsedMicroseconds += elapsedMicroseconds;

      if (_elapsedMicroseconds > _totalMicroseconds) {
        _elapsedMicroseconds = _totalMicroseconds;
      }

      _notifyProgress();
    }

    return true;
  }

  Future<bool> _waitUntilResumed(int session) async {
    while (_isPaused) {
      if (!_isCurrentSession(session)) return false;

      final signal = _resumeSignal ??= Completer<void>();
      await signal.future;
    }

    return _isCurrentSession(session);
  }

  Future<AudioPool> _getPreviewPool(int midiNumber) {
    final existingPool = _previewPools[midiNumber];

    if (existingPool != null) return existingPool;

    late final Future<AudioPool> poolFuture;

    poolFuture = () async {
      try {
        return await AudioPool.create(
          source: AssetSource(_getAudioPath(midiNumber)),
          minPlayers: 1,
          maxPlayers: 2,
          playerMode: PlayerMode.lowLatency,
          audioContext: _previewAudioContext,
        );
      } catch (_) {
        if (identical(_previewPools[midiNumber], poolFuture)) {
          _previewPools.remove(midiNumber);
        }

        rethrow;
      }
    }();

    _previewPools[midiNumber] = poolFuture;
    return poolFuture;
  }

  Future<void> _enqueuePreview(Future<void> Function() action) {
    final completer = Completer<void>();

    _previewQueue = _previewQueue.then((_) async {
      try {
        await action();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  Future<void> _stopActivePreviewSound() async {
    _previewGeneration++;
    await _clearActivePreviewSound();
  }

  Future<void> _clearActivePreviewSound() async {
    final activeVoices = List<_PreviewVoice>.from(_activePreviewVoices);
    _activePreviewVoices.clear();

    for (final voice in activeVoices) {
      voice.timer?.cancel();
    }

    await Future.wait(activeVoices.map(_stopPreviewVoiceSafely));
    await _disposeUnusedPreviewPools();
  }

  Future<void> _finishPreviewVoice(_PreviewVoice voice) async {
    if (!_activePreviewVoices.remove(voice)) return;

    voice.timer?.cancel();
    await _stopPreviewVoiceSafely(voice);
    await _disposePreviewPoolIfUnused(voice.midiNumber);
  }

  Future<void> _stopPreviewVoiceSafely(_PreviewVoice voice) async {
    try {
      await voice.stopSound();
    } catch (_) {
      // Continue cleaning up the remaining voices.
    }
  }

  Future<void> _disposeUnusedPreviewPools() async {
    final activeMidiNumbers = _activePreviewVoices.map((voice) {
      return voice.midiNumber;
    }).toSet();
    final unusedMidiNumbers = _previewPools.keys.where((midiNumber) {
      return !_currentPreviewMidiNumbers.contains(midiNumber) &&
          !activeMidiNumbers.contains(midiNumber);
    }).toList();

    for (final midiNumber in unusedMidiNumbers) {
      final poolFuture = _previewPools.remove(midiNumber);

      if (poolFuture != null) {
        await _disposePreviewPoolFuture(poolFuture);
      }
    }
  }

  Future<void> _disposePreviewPoolIfUnused(int midiNumber) async {
    if (_currentPreviewMidiNumbers.contains(midiNumber)) return;

    final isStillActive = _activePreviewVoices.any((voice) {
      return voice.midiNumber == midiNumber;
    });

    if (isStillActive) return;

    final poolFuture = _previewPools.remove(midiNumber);

    if (poolFuture != null) {
      await _disposePreviewPoolFuture(poolFuture);
    }
  }

  Future<void> _disposePreviewPoolFuture(
    Future<AudioPool> poolFuture,
  ) async {
    try {
      final pool = await poolFuture;
      await pool.dispose();
    } catch (_) {
      // A pool that failed to load has nothing to dispose.
    }
  }

  Future<void> _disposeCompositionPlayer() async {
    final player = _compositionPlayer;
    _compositionPlayer = null;

    if (player == null) return;

    try {
      await player.dispose();
    } catch (_) {
      // The native player may already have released itself.
    }
  }

  Future<void> _playMetronomeClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Some platforms do not provide a system click sound.
    }
  }

  void _completeResumeSignal() {
    final signal = _resumeSignal;
    _resumeSignal = null;

    if (signal != null && !signal.isCompleted) {
      signal.complete();
    }
  }

  bool _isCurrentSession(int session) {
    return _isPlaying && session == _playbackSession;
  }

  void _notifyProgress() {
    _onProgressChanged?.call(
      Duration(microseconds: _elapsedMicroseconds),
      Duration(microseconds: _totalMicroseconds),
    );
  }

  String _getAudioPath(int midiNumber) {
    final pianoNote = PianoNote.fromMidi(midiNumber);
    final filePitch = pianoNote.pitch.replaceAll('#', 's');
    return 'audio/piano/cleaned/$filePitch${pianoNote.octave}.wav';
  }

  Future<void> dispose() async {
    await stop();
    _previewLoadSession++;
    _currentPreviewMidiNumbers.clear();

    final previewPoolFutures = _previewPools.values.toSet().toList();
    _previewPools.clear();

    await Future.wait(previewPoolFutures.map(_disposePreviewPoolFuture));
    await _renderer.dispose();
  }
}

class _PreviewVoice {
  _PreviewVoice({required this.midiNumber, required this.stopSound});

  final int midiNumber;
  final StopFunction stopSound;
  Timer? timer;
}

class _TimelineNote {
  const _TimelineNote({
    required this.note,
    required this.startBeat,
    required this.endBeat,
  });

  final CompositionNote note;
  final double startBeat;
  final double endBeat;
}

class _TimelineBoundary {
  _TimelineBoundary(this.beat);

  final double beat;
  final List<_TimelineNote> startingNotes = [];
  final List<_TimelineNote> endingNotes = [];
  bool isMetronomeBeat = false;
}
