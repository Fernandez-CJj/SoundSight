import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/screens/midi/utils/midi_note_converter.dart';

import 'music_sheet_web_view.dart';
import 'midi_file_duration_calculator.dart';
import 'midi_score_playback_service.dart';
import 'sight_reading_note_matcher.dart';
import 'sight_reading_performance_tracker.dart';

class MusicSheetReadingScreen extends StatefulWidget {
  const MusicSheetReadingScreen({
    super.key,
    required this.scoreDocumentPath,
  });

  final String scoreDocumentPath;

  @override
  State<MusicSheetReadingScreen> createState() =>
      _MusicSheetReadingScreenState();
}

class _MusicSheetReadingScreenState extends State<MusicSheetReadingScreen> {
  final MidiInputService midiInputService = MidiInputService();
  final SightReadingNoteMatcher noteMatcher = SightReadingNoteMatcher();
  final SightReadingPerformanceTracker performanceTracker =
      SightReadingPerformanceTracker();
  final MidiScorePlaybackService scorePlaybackService =
      MidiScorePlaybackService();

  late final MusicSheetWebViewController musicSheetController;

  StreamSubscription<Set<int>>? activeNotesSubscription;
  StreamSubscription<int>? noteOnSubscription;

  String midiStatus = 'Not connected';
  bool scoreCompleted = false;
  int totalPositionCount = 0;
  bool performanceModeEnabled = true;
  final Stopwatch playingStopwatch = Stopwatch();
  Timer? timerRefresh;
  Timer? performanceTicker;
  Timer? countdownTimer;
  int targetDurationSeconds = 0;
  bool targetDurationCalculated = false;
  String? targetDurationUnavailableReason;
  bool performanceRunning = false;
  bool performanceCountdownActive = false;
  bool scorePreviewPreparing = false;
  bool scorePreviewPlaying = false;
  int countdownValue = 3;
  int performanceRunId = 0;
  int performanceCursorTargetIndex = 0;
  Set<int> activeMidiNotes = <int>{};
  Future<void> cursorAdvanceQueue = Future<void>.value();

  String? loadedMusicXml;
  bool scoreIsLoading = false;
  BuildContext? scoreLoadingDialogContext;

  @override
  void initState() {
    super.initState();

    musicSheetController = MusicSheetWebViewController(
      onExpectedNotesChanged: (notes) {
        if (!mounted) {
          return;
        }

        setState(() {
          noteMatcher.updateExpectedNotes(notes);
        });

        debugPrint('Expected MIDI notes: ${noteMatcher.expectedMidiNotes}');
      },

      onTotalPositionsChanged: (totalPositions) {
        if (!mounted) {
          return;
        }

        setState(() {
          totalPositionCount = totalPositions;
        });
      },

      onScoreRendered: () {
        hideScoreLoadingDialog();
      },

      onScoreRenderFailed: (message) {
        hideScoreLoadingDialog();
        showScoreLoadingError(message);
      },

      onScoreCompleted: () {
        if (performanceModeEnabled) {
          return;
        }

        if (!mounted || scoreCompleted) {
          return;
        }

        stopPlayingTimer();

        setState(() {
          scoreCompleted = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          showCompletionDialog();
        });
      },
    );

    activeNotesSubscription = midiInputService.activeNotesStream.listen((
      notes,
    ) {
      if (!mounted) {
        return;
      }

      if (scorePreviewPreparing || scorePreviewPlaying) {
        return;
      }

      if (performanceModeEnabled) {
        setState(() {
          activeMidiNotes = Set<int>.from(notes);
        });

        return;
      }

      late final bool notesMatch;
      late final bool cursorIsWrong;

      setState(() {
        activeMidiNotes = Set<int>.from(notes);
        notesMatch = noteMatcher.updateActiveNotes(notes);
        cursorIsWrong = noteMatcher.cursorIsWrong;
      });

      unawaited(musicSheetController.setCursorWrong(cursorIsWrong));

      if (notesMatch) {
        unawaited(advanceSheet());
      }

      debugPrint('Active MIDI notes: ${noteMatcher.activeMidiNotes}');
    });

    noteOnSubscription = midiInputService.noteOnStream.listen((note) {
      if (!mounted) {
        return;
      }

      if (scorePreviewPreparing || scorePreviewPlaying) {
        return;
      }

      if (performanceModeEnabled) {
        if (performanceRunning) {
          performanceTracker.recordNoteOn(
            note,
            playingStopwatch.elapsedMilliseconds,
          );

          setState(() {});

          unawaited(
            musicSheetController.setCursorWrong(
              performanceTracker.cursorIsWrong,
            ),
          );
        }

        return;
      }

      noteMatcher.recordNoteOn(note);
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    unawaited(loadPerformanceDifficulty());
    loadPieceSource();
  }

  @override
  Widget build(BuildContext context) {
    final expectedMidiNotes = performanceModeEnabled
        ? performanceTracker.currentExpectedNotes
        : noteMatcher.expectedMidiNotes;
    final sortedExpectedNotes = expectedMidiNotes.toList()..sort();
    final sortedActiveNotes = activeMidiNotes.toList()..sort();

    final activeNotesText = sortedActiveNotes.isEmpty
        ? 'None'
        : sortedActiveNotes.map(midiToNoteName).join(' + ');

    final expectedNotesText = sortedExpectedNotes.isEmpty
        ? 'Waiting...'
        : sortedExpectedNotes.map(midiToNoteName).join(' + ');

    final showExpectedHint =
        !performanceModeEnabled && noteMatcher.showExpectedHint;

    final resultText = performanceModeEnabled
        ? performanceTracker.resultText
        : noteMatcher.resultText;

    final canStartPerformance =
        performanceModeEnabled &&
        performanceTracker.hasTimeline &&
        midiStatus.startsWith('Connected:') &&
        !performanceRunning &&
        !performanceCountdownActive &&
        !scorePreviewPreparing &&
        !scorePreviewPlaying &&
        !scoreCompleted;

    final canToggleScorePreview =
        scorePreviewPreparing ||
        scorePreviewPlaying ||
        (performanceTracker.hasTimeline &&
            !performanceRunning &&
            !performanceCountdownActive);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Sheet Reading'),
        actions: [
          IconButton(
            tooltip: performanceModeEnabled
                ? 'Switch to Wait Mode'
                : 'Switch to Performance Mode',
            icon: Icon(
              performanceModeEnabled ? Icons.timer : Icons.hourglass_empty,
            ),
            onPressed: () {
              setState(() {
                performanceModeEnabled = !performanceModeEnabled;
              });

              unawaited(retryExercise());
            },
          ),

          _buildProgressIndicator(),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: MusicSheetWebView(controller: musicSheetController),
                  ),
                  if (performanceCountdownActive)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black38,
                        child: Center(
                          child: Text(
                            '$countdownValue',
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!scoreCompleted && showExpectedHint)
                          Text(
                            'Hint: $expectedNotesText',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          'Played: $activeNotesText',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'MIDI: $midiStatus',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Result: ${scoreCompleted ? 'Completed' : resultText}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        buildTimeStatus(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (performanceModeEnabled) ...[
                    ElevatedButton.icon(
                      onPressed: canStartPerformance
                          ? startPerformanceCountdown
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        performanceRunning
                            ? 'Playing'
                            : performanceCountdownActive
                            ? 'Starting'
                            : 'Start',
                      ),
                    ),
                    const Gap(8),
                  ],
                  OutlinedButton.icon(
                    onPressed: canToggleScorePreview
                        ? () {
                            unawaited(toggleScorePreview());
                          }
                        : null,
                    icon: scorePreviewPreparing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            scorePreviewPlaying
                                ? Icons.stop
                                : Icons.volume_up,
                          ),
                    label: Text(
                      scorePreviewPreparing
                          ? 'Loading'
                          : scorePreviewPlaying
                          ? 'Stop'
                          : 'Listen',
                    ),
                  ),
                  const Gap(8),
                  ElevatedButton(
                    onPressed:
                        performanceRunning ||
                            scorePreviewPreparing ||
                            scorePreviewPlaying
                        ? null
                        : connectToMidi,
                    child: const Text('Connect MIDI'),
                  ),
                  Gap(8),

                  OutlinedButton.icon(
                    onPressed: loadedMusicXml == null
                        ? null
                        : () {
                            unawaited(retryExercise());
                          },
                    icon: const Icon(Icons.replay),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> connectToMidi() async {
    setState(() {
      midiStatus = 'Searching...';
    });

    try {
      final devices = await midiInputService.getDevices();

      if (!mounted) {
        return;
      }

      if (devices.isEmpty) {
        setState(() {
          midiStatus = 'No device detected';
        });

        return;
      }

      final device = devices.first;

      setState(() {
        midiStatus = 'Connecting...';
      });

      await midiInputService.connectToDevice(device);

      if (!mounted) {
        return;
      }

      setState(() {
        midiStatus = 'Connected: ${device.name}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        midiStatus = 'Connection failed';
      });
    }
  }

  Future<void> toggleScorePreview() async {
    if (scorePreviewPreparing || scorePreviewPlaying) {
      await stopScorePreview();
      return;
    }

    if (performanceRunning || performanceCountdownActive) {
      return;
    }

    setState(() {
      scorePreviewPreparing = true;
      activeMidiNotes = <int>{};
    });

    await scorePlaybackService.play(
      timelineEvents: performanceTracker.timelineEvents,
      onStarted: () {
        if (!mounted) {
          return;
        }

        setState(() {
          scorePreviewPreparing = false;
          scorePreviewPlaying = true;
        });
      },
      onFinished: () {
        if (!mounted) {
          return;
        }

        setState(() {
          scorePreviewPreparing = false;
          scorePreviewPlaying = false;
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          scorePreviewPreparing = false;
          scorePreviewPlaying = false;
        });

        final messenger = ScaffoldMessenger.of(context);

        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('Score playback failed: $error')),
        );
      },
    );
  }

  Future<void> stopScorePreview() async {
    await scorePlaybackService.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      scorePreviewPreparing = false;
      scorePreviewPlaying = false;
    });
  }

  Future<void> loadPerformanceDifficulty() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      performanceTracker.applySkillLevel('beginner');
      return;
    }

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final skillLevel =
          userDocument.data()?['skillLevel'] as String? ?? 'beginner';

      performanceTracker.applySkillLevel(skillLevel.toLowerCase());
    } catch (error) {
      performanceTracker.applySkillLevel('beginner');
    }
  }

  Widget _buildProgressIndicator() {
    final completedPositions = performanceModeEnabled
        ? performanceTracker.evaluatedEventCount
        : noteMatcher.completedPositionCount;
    final positionTotal = performanceModeEnabled
        ? performanceTracker.totalEventCount
        : totalPositionCount;
    final hasTotal = positionTotal > 0;
    final progress = hasTotal
        ? (completedPositions / positionTotal).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 210,
        height: 26,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (context, animatedProgress, child) {
            final percentage = (animatedProgress * 100).round();

            return ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: animatedProgress,
                      heightFactor: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF66BB6A)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> advanceSheet() {
    return musicSheetController.advanceCursor();
  }

  void showScoreLoadingDialog() {
    scoreIsLoading = true;

    WidgetsBinding.instance.addPostFrameCallback((value) {
      if (!mounted ||
          !scoreIsLoading ||
          scoreLoadingDialogContext != null) {
        return;
      }

      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            scoreLoadingDialogContext = dialogContext;

            return const PopScope(
              canPop: false,
              child: AlertDialog(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text(
                      'Loading score...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ).whenComplete(() {
          scoreLoadingDialogContext = null;
        }),
      );
    });
  }

  void hideScoreLoadingDialog() {
    scoreIsLoading = false;
    final dialogContext = scoreLoadingDialogContext;

    if (dialogContext == null) {
      return;
    }

    scoreLoadingDialogContext = null;
    Navigator.of(dialogContext).pop();
  }

  void showScoreLoadingError(String message) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((value) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Score rendering failed: $message')),
      );
    });
  }

  Future<void> loadPieceSource() async {
    showScoreLoadingDialog();

    try {
      final piece = await FirebaseFirestore.instance
          .doc(widget.scoreDocumentPath)
          .get();

      final data = piece.data();
      final musicXmlUrl = data?['musicXmlUrl'] as String?;
      final midiUrl = data?['midiUrl'] as String?;

      debugPrint('MusicXML URL found: ${musicXmlUrl != null}');
      debugPrint('MIDI URL found: ${midiUrl != null}');

      if (musicXmlUrl == null) {
        hideScoreLoadingDialog();
        await musicSheetController.showMessage('MusicXML URL is missing');

        return;
      }

      final musicXmlResponse = await http.get(Uri.parse(musicXmlUrl));

      debugPrint('MusicXML download status: ${musicXmlResponse.statusCode}');

      if (musicXmlResponse.statusCode != 200) {
        hideScoreLoadingDialog();
        await musicSheetController.showMessage(
          'MusicXML download failed: ${musicXmlResponse.statusCode}',
        );

        return;
      }

      final musicXml = musicXmlResponse.body;

      debugPrint(
        'MusicXML downloaded: '
        '${musicXml.length} characters',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        loadedMusicXml = musicXml;
      });

      await musicSheetController.loadScore(musicXml);
      await loadMidiTargetDuration(midiUrl);
    } catch (error) {
      hideScoreLoadingDialog();

      if (!mounted) {
        return;
      }

      await musicSheetController.showMessage('Score loading failed: $error');
    }
  }

  Future<void> loadMidiTargetDuration(String? midiUrl) async {
    if (midiUrl == null || midiUrl.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        performanceTracker.loadTimeline(const []);
        targetDurationCalculated = true;
        targetDurationUnavailableReason = 'The challenge has no MIDI file.';
      });

      return;
    }

    try {
      final midiResponse = await http.get(Uri.parse(midiUrl));

      debugPrint('MIDI download status: ${midiResponse.statusCode}');

      if (!mounted) {
        return;
      }

      if (midiResponse.statusCode != 200) {
        setState(() {
          performanceTracker.loadTimeline(const []);
          targetDurationCalculated = true;
          targetDurationUnavailableReason =
              'MIDI download failed: ${midiResponse.statusCode}.';
        });

        return;
      }

      final durationResult = MidiFileDurationCalculator.calculate(
        midiResponse.bodyBytes,
      );

      setState(() {
        performanceTracker.loadTimeline(durationResult.timelineEvents);
        targetDurationSeconds = durationResult.seconds;
        targetDurationCalculated = true;
        targetDurationUnavailableReason = durationResult.unavailableReason;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        performanceTracker.loadTimeline(const []);
        targetDurationCalculated = true;
        targetDurationUnavailableReason = 'MIDI loading failed: $error';
      });
    }
  }

  Future<void> showCompletionDialog() async {
    final totalMistakes = performanceModeEnabled
        ? performanceTracker.totalMistakes
        : noteMatcher.totalMistakes;

    final hintWasShown =
        !performanceModeEnabled && noteMatcher.hintWasShownDuringExercise;

    final elapsedSeconds = playingStopwatch.elapsed.inSeconds;
    final hasTargetDuration = targetDurationSeconds > 0;
    final retryIsRequired = hintWasShown;

    final isPerfect = totalMistakes == 0 && !retryIsRequired;
    final scoreText = performanceModeEnabled
        ? performanceTracker.scoreText
        : noteMatcher.scoreText;

    late final String title;
    late final String message;
    late final Color accentColor;
    late final Color backgroundColor;
    late final IconData icon;

    if (retryIsRequired) {
      title = 'Retry Required';
      message =
          'A hint was shown during this attempt. '
          'Please retry and complete the score without '
          'reaching five consecutive mistakes.';

      accentColor = Colors.red.shade700;
      backgroundColor = Colors.red.shade50;
      icon = Icons.replay_circle_filled;
    } else if (isPerfect) {
      title = 'Perfect!';
      message =
          'You completed the score without any '
          'mistakes or hints.';

      accentColor = Colors.green.shade700;
      backgroundColor = Colors.green.shade50;
      icon = Icons.check_circle;
    } else {
      final mistakeWord = totalMistakes == 1 ? 'mistake' : 'mistakes';

      title = 'Exercise Completed';
      message =
          'You completed the score with '
          '$totalMistakes $mistakeWord, '
          'but you did not need a hint.';

      accentColor = Colors.amber.shade800;
      backgroundColor = Colors.amber.shade50;
      icon = Icons.warning_amber_rounded;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          iconPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          titlePadding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          backgroundColor: backgroundColor,
          icon: Icon(icon, color: accentColor, size: 42),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Score',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scoreText,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (performanceModeEnabled) ...[
                const SizedBox(height: 8),
                Text(
                  'Correct on time: ${performanceTracker.correctEventCount}/${performanceTracker.totalEventCount}\n'
                  'Wrong: ${performanceTracker.wrongEventCount}\n'
                  'Missed: ${performanceTracker.missedEventCount}\n'
                  'Timing accuracy: ${performanceTracker.timingAccuracyPercentage}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              buildDialogTimeResult(
                elapsedSeconds: elapsedSeconds,
                hasTargetDuration: hasTargetDuration,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                unawaited(retryExercise());
              },
              icon: const Icon(Icons.replay),
              label: const Text('Retry'),
            ),

            if (!retryIsRequired)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: accentColor),
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
          ],
        );
      },
    );
  }

  Future<void> retryExercise() async {
    await stopScorePreview();
    cancelPerformanceTimers();
    resetPlayingTimer();
    final musicXml = loadedMusicXml;

    if (musicXml == null || !mounted) {
      return;
    }

    setState(() {
      scoreCompleted = false;
      totalPositionCount = 0;
      noteMatcher.resetExercise();
      performanceTracker.resetAttempt();
      performanceCursorTargetIndex = 0;
      activeMidiNotes = <int>{};
    });

    showScoreLoadingDialog();
    await musicSheetController.loadScore(musicXml);
  }

  void startPlayingTimer() {
    if (!performanceModeEnabled) {
      return;
    }

    if (playingStopwatch.isRunning) {
      return;
    }

    playingStopwatch.start();

    timerRefresh = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void stopPlayingTimer() {
    playingStopwatch.stop();
    timerRefresh?.cancel();
    timerRefresh = null;
  }

  void resetPlayingTimer() {
    playingStopwatch.stop();
    playingStopwatch.reset();

    timerRefresh?.cancel();
    timerRefresh = null;

    if (mounted) {
      setState(() {});
    }
  }

  void startPerformanceCountdown() {
    if (!performanceModeEnabled ||
        !performanceTracker.hasTimeline ||
        performanceRunning ||
        performanceCountdownActive ||
        scorePreviewPreparing ||
        scorePreviewPlaying ||
        scoreCompleted) {
      return;
    }

    cancelPerformanceTimers();
    resetPlayingTimer();
    performanceTracker.resetAttempt();

    setState(() {
      countdownValue = 3;
      performanceCountdownActive = true;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (countdownValue > 1) {
        setState(() {
          countdownValue--;
        });

        return;
      }

      timer.cancel();
      countdownTimer = null;
      beginPerformanceTimeline();
    });
  }

  void beginPerformanceTimeline() {
    if (!mounted || !performanceModeEnabled) {
      return;
    }

    performanceRunId++;

    setState(() {
      performanceCountdownActive = false;
      performanceRunning = true;
      performanceCursorTargetIndex = 0;
      performanceTracker.resultText = 'Play on time';
    });

    startPlayingTimer();
    queueNextPerformanceCursorSlide();

    performanceTicker = Timer.periodic(
      const Duration(milliseconds: 20),
      (timer) {
        updatePerformanceTimeline();
      },
    );
  }

  void updatePerformanceTimeline() {
    if (!mounted || !performanceRunning) {
      return;
    }

    final timelineUpdate = performanceTracker.updateElapsedTime(
      playingStopwatch.elapsedMilliseconds,
    );

    if (timelineUpdate.cursorAdvances > 0) {
      queueNextPerformanceCursorSlide();
    } else if (timelineUpdate.stateChanged) {
      unawaited(
        musicSheetController.setCursorWrong(
          performanceTracker.cursorIsWrong,
        ),
      );
    }

    if (timelineUpdate.stateChanged) {
      setState(() {});
    }

    if (timelineUpdate.finished) {
      finishPerformanceTimeline();
    }
  }

  void queueNextPerformanceCursorSlide() {
    final scheduledRunId = performanceRunId;

    cursorAdvanceQueue = cursorAdvanceQueue.then((value) async {
      if (scheduledRunId != performanceRunId || !performanceRunning) {
        return;
      }

      final timelineEvents = performanceTracker.timelineEvents;
      final currentEventIndex = performanceTracker.cursorEventIndex;

      while (performanceCursorTargetIndex < currentEventIndex) {
        await musicSheetController.advanceCursor();
        performanceCursorTargetIndex++;

        if (scheduledRunId != performanceRunId || !performanceRunning) {
          return;
        }
      }

      final nextEventIndex = currentEventIndex + 1;

      if (performanceCursorTargetIndex == currentEventIndex &&
          nextEventIndex < timelineEvents.length) {
        final nextEventTime =
            timelineEvents[nextEventIndex].scheduledTime.inMilliseconds;
        final remainingMilliseconds =
            nextEventTime - playingStopwatch.elapsedMilliseconds;
        final slideMilliseconds = remainingMilliseconds > 0
            ? remainingMilliseconds
            : 0;

        await musicSheetController.slideCursorToNextNote(
          Duration(milliseconds: slideMilliseconds),
        );

        performanceCursorTargetIndex = nextEventIndex;
      }

      if (scheduledRunId == performanceRunId && performanceRunning) {
        await musicSheetController.setCursorWrong(
          performanceTracker.cursorIsWrong,
        );
      }
    });
  }

  void finishPerformanceTimeline() {
    if (!mounted || !performanceRunning) {
      return;
    }

    performanceRunning = false;
    performanceRunId++;
    performanceTicker?.cancel();
    performanceTicker = null;
    stopPlayingTimer();

    setState(() {
      scoreCompleted = true;
    });

    unawaited(musicSheetController.hideCursor());

    WidgetsBinding.instance.addPostFrameCallback((value) {
      if (mounted) {
        showCompletionDialog();
      }
    });
  }

  void cancelPerformanceTimers() {
    performanceRunId++;
    countdownTimer?.cancel();
    countdownTimer = null;
    performanceTicker?.cancel();
    performanceTicker = null;
    performanceCountdownActive = false;
    performanceRunning = false;
    countdownValue = 3;
  }

  Widget buildTimeStatus() {
    const textStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    if (!performanceModeEnabled) {
      return const Text('Mode: Wait (timer disabled)', style: textStyle);
    }

    if (!targetDurationCalculated) {
      return const Text(
        'Performance Mode: Reading MIDI timeline...',
        style: textStyle,
      );
    }

    if (targetDurationSeconds <= 0) {
      final reason =
          targetDurationUnavailableReason ?? 'Unknown MIDI file problem.';

      return Text('Performance Mode: Unavailable - $reason', style: textStyle);
    }

    final elapsedText = formatDuration(playingStopwatch.elapsed.inSeconds);
    final targetText = formatDuration(targetDurationSeconds);

    if (performanceCountdownActive) {
      return Text(
        'Performance Mode: Starting in $countdownValue',
        style: textStyle,
      );
    }

    if (!performanceRunning && !scoreCompleted) {
      return Text(
        'Performance Mode: Ready - $targetText timeline',
        style: textStyle,
      );
    }

    return Text(
      'Performance Mode: $elapsedText / $targetText',
      style: textStyle,
    );
  }

  Widget buildDialogTimeResult({
    required int elapsedSeconds,
    required bool hasTargetDuration,
    required Color accentColor,
  }) {
    if (!performanceModeEnabled) {
      return const Text(
        'Wait Mode\nNo time target',
        textAlign: TextAlign.center,
      );
    }

    final elapsedText = formatDuration(elapsedSeconds);

    if (!hasTargetDuration) {
      final reason =
          targetDurationUnavailableReason ?? 'Unknown MIDI file problem.';

      return Text(
        'Time: $elapsedText\nTimeline unavailable\n$reason',
        textAlign: TextAlign.center,
      );
    }

    final targetText = formatDuration(targetDurationSeconds);

    return Text(
      'Performance Mode\n'
      'MIDI timeline: $targetText',
      textAlign: TextAlign.center,
      style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
    );
  }

  String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final paddedSeconds = seconds.toString().padLeft(2, '0');

    return '$minutes:$paddedSeconds';
  }

  @override
  void dispose() {
    activeNotesSubscription?.cancel();
    noteOnSubscription?.cancel();
    midiInputService.dispose();
    timerRefresh?.cancel();
    countdownTimer?.cancel();
    performanceTicker?.cancel();
    playingStopwatch.stop();
    unawaited(scorePlaybackService.dispose());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }
}
