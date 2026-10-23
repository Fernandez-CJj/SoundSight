import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/screens/challenges/sight_reading/midi_file_duration_calculator.dart';
import 'package:soundsight/screens/challenges/sight_reading/midi_score_playback_service.dart';
import 'package:soundsight/screens/challenges/sight_reading/music_sheet_web_view.dart';
import 'package:soundsight/screens/challenges/sight_reading/sight_reading_note_matcher.dart';
import 'package:soundsight/screens/challenges/sight_reading/sight_reading_performance_tracker.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/screens/midi/utils/midi_note_converter.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Adapts bundled stage files to the existing sight-reading challenge services.
class LocalSightReadingScreen extends StatefulWidget {
  const LocalSightReadingScreen({
    super.key,
    required this.scoreAssetPath,
    required this.midiAssetPath,
    this.pdfAssetPath,
    required this.colors,
    this.onFinish,
    this.performanceMode = false,
  });

  final String scoreAssetPath;
  final String midiAssetPath;
  final String? pdfAssetPath;
  final AppThemeColors colors;
  final VoidCallback? onFinish;
  final bool performanceMode;

  @override
  State<LocalSightReadingScreen> createState() =>
      _LocalSightReadingScreenState();
}

/// Owns local score loading, MIDI input, playback, and score display state.
class _LocalSightReadingScreenState extends State<LocalSightReadingScreen> {
  final _midiInput = MidiInputService();
  final _noteMatcher = SightReadingNoteMatcher();
  final _performanceTracker = SightReadingPerformanceTracker();
  final _playback = MidiScorePlaybackService();
  final _performanceStopwatch = Stopwatch();
  StreamSubscription<Set<int>>? _activeNotesSubscription;
  StreamSubscription<int>? _noteOnSubscription;
  Timer? _performanceCountdownTimer;
  Timer? _performanceTicker;
  late final MusicSheetWebViewController _sheetController;
  late final Future<Uint8List?> _pdfBytes;
  List<MidiTimelineEvent> _timeline = const [];
  String? _loadedScoreText;
  Set<int> _activeNotes = const {};
  String _midiStatus = 'Connect your piano';
  String _message = 'Loading the score…';
  String? _scoreError;
  int _totalPositions = 0;
  bool _loading = true;
  bool _showPdf = false;
  bool _listening = false;
  bool _performanceRunning = false;
  bool _performanceCountdownActive = false;
  bool _resultDialogShowing = false;
  int _countdownValue = 3;
  int _performanceRunId = 0;
  Future<void> _cursorQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    // Sight reading uses landscape; keep the score and piano controls side by side.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Connect challenge callbacks to this screen's progress and error messages.
    _sheetController = MusicSheetWebViewController(
      onExpectedNotesChanged: (notes) {
        if (!mounted) return;
        setState(() => _noteMatcher.updateExpectedNotes(notes));
      },
      onTotalPositionsChanged: (total) {
        if (mounted) setState(() => _totalPositions = total);
      },
      onScoreRendered: () {
        if (mounted) setState(() => _loading = false);
      },
      onScoreRenderFailed: (error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _scoreError = error;
        });
      },
      onScoreCompleted: () {
        // Only finish after the user has played every playable score position.
        if (mounted &&
            _totalPositions > 0 &&
            !widget.performanceMode &&
            _noteMatcher.completedPositionCount >= _totalPositions) {
          unawaited(_showResultDialog());
        }
      },
    );
    // Load a PDF only when the stage includes one; XML remains the interactive view.
    _pdfBytes = widget.pdfAssetPath == null
        ? Future<Uint8List?>.value(null)
        : rootBundle
              .load(widget.pdfAssetPath!)
              .then<Uint8List?>((data) => data.buffer.asUint8List());
    // Listen for held notes and note-on events from the USB MIDI input service.
    _activeNotesSubscription = _midiInput.activeNotesStream.listen(
      _onActiveNotesChanged,
    );
    _noteOnSubscription = _midiInput.noteOnStream.listen(_onNoteOn);
    unawaited(_loadScoreAndMidi());
  }

  Future<void> _loadScoreAndMidi() async {
    // Read MusicXML and MIDI together, then supply the score to the existing renderer.
    try {
      final scoreText = await _loadMusicXml(widget.scoreAssetPath);
      _loadedScoreText = scoreText;
      final midiData = await rootBundle.load(widget.midiAssetPath);
      final durationResult = MidiFileDurationCalculator.calculate(
        midiData.buffer.asUint8List(),
      );
      if (!mounted) return;
      setState(() {
        _timeline = durationResult.timelineEvents;
        if (widget.performanceMode) {
          _performanceTracker.loadTimeline(_timeline);
        }
        _message = durationResult.unavailableReason == null
            ? 'Sheet ready · MIDI playback available'
            : 'Sheet ready · MIDI timeline unavailable';
      });
      await _sheetController.loadScore(scoreText);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _scoreError = 'Unable to load stage score: $error';
      });
    }
  }

  // Performance tests assess MIDI note-on events against their scheduled times.
  void _onNoteOn(int note) {
    if (!widget.performanceMode) {
      _noteMatcher.recordNoteOn(note);
      return;
    }
    if (!_performanceRunning) return;
    _performanceTracker.recordNoteOn(
      note,
      _performanceStopwatch.elapsedMilliseconds,
    );
    if (!mounted) return;
    setState(() => _message = _performanceTracker.resultText);
    unawaited(
      _sheetController.setCursorWrong(_performanceTracker.cursorIsWrong),
    );
  }

  // Starts a short countdown, then runs the imported MIDI event timeline.
  void _startPerformanceTest() {
    if (!widget.performanceMode ||
        !_midiStatus.startsWith('Connected:') ||
        _timeline.isEmpty ||
        _performanceRunning ||
        _performanceCountdownActive) {
      return;
    }
    _cancelPerformanceTimers();
    _performanceTracker.resetAttempt();
    _performanceStopwatch
      ..stop()
      ..reset();
    setState(() {
      _countdownValue = 3;
      _performanceCountdownActive = true;
      _message = 'Get ready';
    });
    _performanceCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
        return;
      }
      timer.cancel();
      _performanceCountdownTimer = null;
      _beginPerformanceTimeline();
    });
  }

  void _beginPerformanceTimeline() {
    if (!mounted || !widget.performanceMode) return;
    _performanceRunId++;
    setState(() {
      _performanceCountdownActive = false;
      _performanceRunning = true;
      _message = 'Play on time';
    });
    _performanceStopwatch.start();
    _performanceTicker = Timer.periodic(const Duration(milliseconds: 20), (_) {
      _updatePerformanceTimeline();
    });
  }

  void _updatePerformanceTimeline() {
    if (!mounted || !_performanceRunning) return;
    final update = _performanceTracker.updateElapsedTime(
      _performanceStopwatch.elapsedMilliseconds,
    );
    if (update.cursorAdvances > 0) {
      _queueCursorAdvances(update.cursorAdvances);
    }
    if (update.stateChanged) {
      setState(() => _message = _performanceTracker.resultText);
      unawaited(
        _sheetController.setCursorWrong(_performanceTracker.cursorIsWrong),
      );
    }
    if (update.finished) unawaited(_finishPerformanceTest());
  }

  // Serialize WebView cursor moves so closely spaced MIDI events stay ordered.
  void _queueCursorAdvances(int count) {
    final runId = _performanceRunId;
    _cursorQueue = _cursorQueue.then((_) async {
      for (var step = 0; step < count; step++) {
        if (runId != _performanceRunId || !_performanceRunning) return;
        await _sheetController.advanceCursor();
      }
    });
  }

  Future<void> _finishPerformanceTest() async {
    if (!_performanceRunning) return;
    _performanceRunning = false;
    _performanceRunId++;
    _performanceTicker?.cancel();
    _performanceTicker = null;
    _performanceStopwatch.stop();
    if (mounted) setState(() => _message = 'Performance complete');
    await _sheetController.hideCursor();
    await _showPerformanceResultDialog();
  }

  Future<void> _showPerformanceResultDialog() async {
    if (!mounted || _resultDialogShowing) return;
    _resultDialogShowing = true;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          'Performance complete',
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          'Timing accuracy: ${_performanceTracker.timingAccuracyPercentage}%\n'
          'Correct on time: ${_performanceTracker.correctEventCount}/${_performanceTracker.totalEventCount}\n'
          'Wrong: ${_performanceTracker.wrongEventCount} · Missed: ${_performanceTracker.missedEventCount}',
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Retry',
              style: TextStyle(color: widget.colors.primaryColor),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.isDarkMode
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    _resultDialogShowing = false;
    if (!mounted) return;
    if (retry == true) {
      _performanceTracker.resetAttempt();
      _performanceStopwatch.reset();
      setState(() => _message = 'Ready to retry');
      final scoreText = _loadedScoreText;
      if (scoreText != null) await _sheetController.loadScore(scoreText);
    } else if (retry == false) {
      widget.onFinish?.call();
      Navigator.of(context).pop();
    }
  }

  void _cancelPerformanceTimers() {
    _performanceRunId++;
    _performanceCountdownTimer?.cancel();
    _performanceCountdownTimer = null;
    _performanceTicker?.cancel();
    _performanceTicker = null;
    _performanceCountdownActive = false;
    _performanceRunning = false;
  }

  // Shows the same Retry/Finish choice as a completed lesson quiz.
  Future<void> _showResultDialog() async {
    if (!mounted || _resultDialogShowing) return;
    _resultDialogShowing = true;
    final accuracy = _totalPositions == 0
        ? 0
        : (_noteMatcher.firstTryCorrectCount * 100 / _totalPositions).round();
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          'Sight reading complete',
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          'Accuracy: $accuracy%\n'
          'Mistakes: ${_noteMatcher.totalMistakes}',
          style: TextStyle(color: widget.colors.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Retry',
              style: TextStyle(color: widget.colors.primaryColor),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.isDarkMode
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    _resultDialogShowing = false;
    if (!mounted) return;
    if (retry == true) {
      _noteMatcher.resetExercise();
      setState(() {
        _activeNotes = const {};
        _message = 'Ready to retry';
      });
      final scoreText = _loadedScoreText;
      if (scoreText != null) await _sheetController.loadScore(scoreText);
    } else if (retry == false) {
      widget.onFinish?.call();
      Navigator.of(context).pop();
    }
  }

  Future<String> _loadMusicXml(String path) async {
    // MXL files are ZIP archives; plain XML files can be loaded as text directly.
    if (path.toLowerCase().endsWith('.mxl')) {
      final data = await rootBundle.load(path);
      final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
      final score = archive.files
          .where(
            (file) =>
                file.isFile &&
                file.name.toLowerCase().endsWith('.xml') &&
                !file.name.toLowerCase().endsWith('meta-inf/container.xml'),
          )
          .firstOrNull;
      if (score == null) {
        throw const FormatException('The MXL file contains no MusicXML score.');
      }
      return utf8.decode(score.content as List<int>);
    }
    return rootBundle.loadString(path);
  }

  void _onActiveNotesChanged(Set<int> notes) {
    // Ignore live matching while the user is listening to the MIDI preview.
    if (!mounted || _listening) return;
    if (widget.performanceMode) {
      setState(() {
        _activeNotes = Set<int>.from(notes);
        _message = _performanceTracker.resultText;
      });
      return;
    }
    final matched = _noteMatcher.updateActiveNotes(notes);
    setState(() {
      _activeNotes = Set<int>.from(notes);
      if (matched && _totalPositions > 0) {
        _message =
            'Correct · ${_noteMatcher.completedPositionCount}/$_totalPositions';
      } else {
        _message = _noteMatcher.resultText;
      }
    });
    unawaited(_sheetController.setCursorWrong(_noteMatcher.cursorIsWrong));
    if (matched) unawaited(_sheetController.advanceCursor());
  }

  Future<void> _connectPiano() async {
    // Find available MIDI devices and connect to the first detected piano.
    setState(() => _midiStatus = 'Searching for a piano…');
    try {
      final devices = await _midiInput.getDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() => _midiStatus = 'No MIDI piano found');
        return;
      }
      await _midiInput.connectToDevice(devices.first);
      if (mounted) {
        setState(() => _midiStatus = 'Connected: ${devices.first.name}');
      }
    } catch (error) {
      if (mounted) setState(() => _midiStatus = 'Connection failed: $error');
    }
  }

  Future<void> _listenToScore() async {
    // Toggle playback of the loaded MIDI timeline for a listening preview.
    if (_listening) {
      await _playback.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (_timeline.isEmpty) {
      setState(() => _message = 'This MIDI file has no playable notes');
      return;
    }
    setState(() {
      _listening = true;
      _message = 'Playing MIDI preview';
    });
    await _playback.play(
      timelineEvents: _timeline,
      onStarted: () {},
      onFinished: () {
        if (mounted) {
          setState(() {
            _listening = false;
            _message = 'Preview finished';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _listening = false;
            _message = 'MIDI preview unavailable: $error';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    // Stop subscriptions and services when leaving the local challenge screen.
    _cancelPerformanceTimers();
    _performanceStopwatch.stop();
    _activeNotesSubscription?.cancel();
    _noteOnSubscription?.cancel();
    _midiInput.dispose();
    unawaited(_playback.dispose());
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show played notes and status beside the score, with an optional PDF toggle.
    final colors = widget.colors;
    final played = _activeNotes.isEmpty
        ? 'None'
        : (_activeNotes.toList()..sort()).map(midiToNoteName).join(' + ');
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: const Text('Sight Reading'),
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.pdfAssetPath != null)
            IconButton(
              tooltip: _showPdf ? 'Show interactive score' : 'View PDF sheet',
              onPressed: () => setState(() => _showPdf = !_showPdf),
              icon: Icon(_showPdf ? Icons.music_note : Icons.picture_as_pdf),
            ),
        ],
      ),
      // The score fills the screen; the bottom strip holds device and playback actions.
      body: Column(
        children: [
          Expanded(
            child: _scoreError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _scoreError!,
                        style: TextStyle(color: colors.primaryColor),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      Offstage(
                        offstage: _showPdf,
                        child: MusicSheetWebView(controller: _sheetController),
                      ),
                      if (_showPdf)
                        FutureBuilder<Uint8List?>(
                          future: _pdfBytes,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Could not load PDF: ${snapshot.error}',
                                  style: TextStyle(color: colors.primaryColor),
                                ),
                              );
                            }
                            if (snapshot.data == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return PdfViewer.data(
                              snapshot.data!,
                              sourceName: 'Sight reading sheet',
                            );
                          },
                        ),
                      if (_loading && !_showPdf)
                        const Center(child: CircularProgressIndicator()),
                      if (_performanceCountdownActive)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black38,
                            child: Center(
                              child: Text(
                                '$_countdownValue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 84,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Container(
            color: colors.surfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Piano: $_midiStatus\nPlayed: $played · $_message',
                    style: TextStyle(color: colors.primaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _connectPiano,
                  icon: const Icon(Icons.usb),
                  label: const Text('Connect Piano'),
                ),
                const SizedBox(width: 8),
                if (widget.performanceMode)
                  FilledButton.icon(
                    onPressed:
                        _midiStatus.startsWith('Connected:') &&
                            _timeline.isNotEmpty &&
                            !_performanceRunning &&
                            !_performanceCountdownActive
                        ? _startPerformanceTest
                        : null,
                    icon: Icon(
                      _performanceRunning || _performanceCountdownActive
                          ? Icons.timer
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      _performanceCountdownActive
                          ? 'Starting…'
                          : _performanceRunning
                          ? 'Playing…'
                          : 'Start Test',
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: _listenToScore,
                    icon: Icon(_listening ? Icons.stop : Icons.volume_up),
                    label: Text(_listening ? 'Stop' : 'Listen'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
