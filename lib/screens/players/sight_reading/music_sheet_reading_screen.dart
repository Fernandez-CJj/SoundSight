import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/screens/midi/utils/midi_note_converter.dart';
import 'package:soundsight/screens/practice_result/practice_result_detail_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/practice_mode_toggle.dart';

import 'music_sheet_web_view.dart';
import 'midi_file_duration_calculator.dart';
import 'practice_result_models.dart';
import 'practice_result_service.dart';
import 'score_audio_playback_service.dart';
import 'sight_reading_note_matcher.dart';
import 'sight_reading_performance_tracker.dart';
import 'sight_reading_progress_service.dart';

enum SightReadingSource { composition, musicSheet, lesson }

class SightReadingLessonAssets {
  const SightReadingLessonAssets({
    required this.stageNumber,
    required this.title,
    required this.scoreAssetPath,
    required this.midiAssetPath,
    this.pdfAssetPath,
  });

  final int stageNumber;
  final String title;
  final String scoreAssetPath;
  final String midiAssetPath;
  final String? pdfAssetPath;
}

class MusicSheetReadingScreen extends StatefulWidget {
  const MusicSheetReadingScreen({
    super.key,
    required this.scoreDocumentPath,
    required this.source,
    required this.colors,
    this.challengeItemId,
  }) : lesson = null,
       restoreOrientations = null;

  MusicSheetReadingScreen.lesson({
    super.key,
    required SightReadingLessonAssets lesson,
    required this.colors,
    this.restoreOrientations,
  }) : scoreDocumentPath = 'lessons/stage_${lesson.stageNumber}',
       source = SightReadingSource.lesson,
       challengeItemId = null,
       lesson = lesson;

  final String scoreDocumentPath;
  final SightReadingSource source;
  final AppThemeColors colors;
  final String? challengeItemId;
  final SightReadingLessonAssets? lesson;
  final List<DeviceOrientation>? restoreOrientations;

  @override
  State<MusicSheetReadingScreen> createState() =>
      _MusicSheetReadingScreenState();
}

class _WaitHeldNoteState {
  _WaitHeldNoteState({
    required this.midiNote,
    required this.originPositionIndex,
    required this.pressedAt,
    required this.earliestReleaseAt,
    required this.expectedReleaseAt,
    required this.latestReleaseAt,
  });

  final int midiNote;
  final int originPositionIndex;
  final DateTime pressedAt;
  final DateTime earliestReleaseAt;
  final DateTime expectedReleaseAt;
  final DateTime latestReleaseAt;
  bool wasHeldTooLong = false;
}

class _MusicSheetReadingScreenState extends State<MusicSheetReadingScreen> {
  final MidiInputService midiInputService = MidiInputService();
  final SightReadingNoteMatcher noteMatcher = SightReadingNoteMatcher();
  final SightReadingPerformanceTracker performanceTracker =
      SightReadingPerformanceTracker();
  final ScoreAudioPlaybackService scoreAudioPlaybackService =
      ScoreAudioPlaybackService();

  final SightReadingProgressService progressService =
      SightReadingProgressService();
  final PracticeResultService practiceResultService = PracticeResultService();

  late final MusicSheetWebViewController musicSheetController;

  StreamSubscription<Set<int>>? activeNotesSubscription;
  StreamSubscription<int>? noteOnSubscription;
  StreamSubscription<MidiNoteEvent>? midiNoteEventSubscription;
  StreamSubscription<bool>? midiConnectionSubscription;

  String midiStatus = 'Not connected';
  bool scoreCompleted = false;
  int totalPositionCount = 0;
  bool performanceModeEnabled = true;
  final Stopwatch playingStopwatch = Stopwatch();
  Timer? timerRefresh;
  Timer? performanceTicker;
  int targetDurationSeconds = 0;
  bool targetDurationCalculated = false;
  String? targetDurationUnavailableReason;
  bool performanceRunning = false;
  bool performanceFinishing = false;
  bool performanceWaitingForFirstKey = false;
  bool scorePreviewPreparing = false;
  bool scorePreviewPlaying = false;
  int performanceRunId = 0;
  int performanceCursorTargetIndex = 0;
  Set<int> activeMidiNotes = <int>{};
  Future<void> cursorAdvanceQueue = Future<void>.value();
  int? completedElapsedSeconds;
  static const double waitMinimumHoldRatio = 0.6;
  Timer? waitHoldTicker;
  bool waitHoldInProgress = false;
  bool waitRetryRequiresRelease = false;
  bool waitCursorHasArrived = false;
  bool waitBlockedByExpiredKey = false;
  int waitHoldPositionIndex = 0;
  int waitCursorEventIndex = 0;
  DateTime? waitSegmentStartedAt;
  Duration waitCursorTravelDuration = Duration.zero;
  final Map<int, DateTime> waitNotePressedAt = <int, DateTime>{};
  final Map<int, _WaitHeldNoteState> waitHeldNotes =
      <int, _WaitHeldNoteState>{};
  final Set<int> waitCursorPassedPositions = <int>{};
  final Set<int> waitOverheldMistakePositions = <int>{};
  bool practiceControlsSheetOpen = false;
  bool midiReconnectSheetScheduled = false;
  bool midiWasConnected = false;

  String? loadedMusicXml;
  String? scoreAudioUrl;
  String pieceTitle = 'Untitled score';
  bool scoreIsLoading = true;
  String? scoreLoadingError;

  @override
  void initState() {
    super.initState();

    if (widget.lesson != null) {
      performanceModeEnabled = false;
    }

    musicSheetController = MusicSheetWebViewController(
      onExpectedNotesChanged: (notes) {
        if (!mounted) {
          return;
        }

        setState(() {
          noteMatcher.setCurrentPositionIndex(waitCursorEventIndex);
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

      onScorePositionsChanged: (positions) {
        if (!mounted) {
          return;
        }

        performanceTracker.attachScorePositions(positions);
      },

      onScoreRendered: () {
        hideScoreLoadingDialog();
      },

      onScoreRenderFailed: (message) {
        hideScoreLoadingDialog();
        showScoreLoadingError(context.l10n.sightReadingScorePreparationFailed);
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

      if (waitRetryRequiresRelease) {
        setState(() {
          activeMidiNotes = Set<int>.from(notes);

          if (notes.isEmpty) {
            waitRetryRequiresRelease = false;
            noteMatcher.prepareRetryAfterRelease();
          }
        });

        if (notes.isEmpty) {
          unawaited(musicSheetController.setCursorWrong(true));
        }

        return;
      }

      if (waitBlockedByExpiredKey) {
        setState(() {
          activeMidiNotes = Set<int>.from(notes);
        });
        return;
      }

      final sustainedNotes = waitHeldNotes.keys.toSet();
      final allowedNotes = <int>{
        ...noteMatcher.expectedMidiNotes,
        ...sustainedNotes,
      };
      final hasUnexpectedNote = notes.any(
        (note) => !allowedNotes.contains(note),
      );

      late final bool notesMatch;
      late final bool cursorIsWrong;

      setState(() {
        activeMidiNotes = Set<int>.from(notes);
        notesMatch = noteMatcher.updateActiveNotes(
          notes,
          allowedSustainedNotes: sustainedNotes,
          deferCorrectCompletion: true,
        );
        cursorIsWrong = noteMatcher.cursorIsWrong;
      });

      unawaited(musicSheetController.setCursorWrong(cursorIsWrong));

      if (waitHoldInProgress && hasUnexpectedNote) {
        unawaited(
          rewindWaitAttempt(
            positionIndex: waitHoldPositionIndex,
            preserveCurrentFeedback: true,
          ),
        );
      } else if (!waitHoldInProgress &&
          !waitBlockedByExpiredKey &&
          notesMatch) {
        unawaited(beginWaitHoldAttempt());
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
        if (performanceWaitingForFirstKey) {
          beginPerformanceTimeline();
        }

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

      if (!waitRetryRequiresRelease && !waitBlockedByExpiredKey) {
        if (waitHeldNotes.containsKey(note)) {
          final noteName = midiToNoteName(note);
          setState(() {
            noteMatcher.showDurationFeedback(
              'Release $noteName before playing it again',
              isError: true,
            );
          });
          unawaited(musicSheetController.setCursorWrong(true));
          return;
        }

        waitNotePressedAt[note] = DateTime.now();
        noteMatcher.recordNoteOn(note);
      }
    });

    midiNoteEventSubscription = midiInputService.noteEventStream.listen((
      event,
    ) {
      if (!mounted || event.type != MidiNoteEventType.noteOff) {
        return;
      }

      if (scorePreviewPreparing || scorePreviewPlaying) {
        return;
      }

      if (!performanceModeEnabled) {
        handleWaitNoteOff(event.noteNumber);

        return;
      }

      if (!performanceRunning) {
        return;
      }

      performanceTracker.recordNoteOff(
        event.noteNumber,
        playingStopwatch.elapsedMilliseconds,
      );

      setState(() {});
      unawaited(
        musicSheetController.setCursorWrong(performanceTracker.cursorIsWrong),
      );
    });

    midiConnectionSubscription = midiInputService.connectionStream.listen((
      connected,
    ) {
      if (!mounted) {
        return;
      }

      if (connected) {
        midiWasConnected = true;
        return;
      }

      final shouldShowReconnectControls =
          midiWasConnected || midiStatus.startsWith('Connected:');
      midiWasConnected = false;

      final exerciseWasActive =
          waitHoldInProgress ||
          waitHeldNotes.isNotEmpty ||
          performanceRunning ||
          performanceWaitingForFirstKey;

      setState(() {
        midiStatus = 'Not connected';
        activeMidiNotes = <int>{};
      });

      if (exerciseWasActive) {
        unawaited(retryExercise());
      }

      if (shouldShowReconnectControls) {
        scheduleMidiReconnectControls();
      }
    });

    unawaited(loadPerformanceDifficulty());
    unawaited(loadInitialPieceSource());
  }

  Future<void> loadInitialPieceSource() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await loadPieceSource();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final expectedMidiNotes = performanceModeEnabled
        ? performanceTracker.currentExpectedNotes
        : noteMatcher.expectedMidiNotes;
    final sortedExpectedNotes = expectedMidiNotes.toList()..sort();
    final sortedActiveNotes = activeMidiNotes.toList()..sort();

    final activeNotesText = sortedActiveNotes.isEmpty
        ? context.l10n.sightReadingNone
        : sortedActiveNotes.map(midiToNoteName).join(' + ');

    final expectedNotesText = sortedExpectedNotes.isEmpty
        ? context.l10n.sightReadingWaitingEllipsis
        : sortedExpectedNotes.map(midiToNoteName).join(' + ');

    final showExpectedHint =
        !performanceModeEnabled && noteMatcher.showExpectedHint;

    final resultText = performanceModeEnabled
        ? performanceTracker.resultText
        : noteMatcher.resultText;

    final canSwitchMode =
        !scoreIsLoading &&
        !performanceRunning &&
        !performanceWaitingForFirstKey &&
        !waitHoldInProgress &&
        !waitRetryRequiresRelease &&
        !waitBlockedByExpiredKey &&
        waitHeldNotes.isEmpty &&
        !scorePreviewPreparing &&
        !scorePreviewPlaying;
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          child: AppBar(
            toolbarHeight: 64,
            backgroundColor: colors.backgroundColor,
            foregroundColor: colors.primaryColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            title: buildPracticeAppBarContent(
              colors: colors,
              canSwitchMode: canSwitchMode,
              resultText: resultText,
              onOpenControls: () {
                unawaited(showCurrentPracticeControls());
              },
            ),
            actions: [
              if (widget.lesson?.pdfAssetPath != null)
                IconButton(
                  tooltip: 'View lesson PDF',
                  onPressed: () => unawaited(openLessonPdf()),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        left: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: buildScoreCard(
            colors,
            activeNotesText: activeNotesText,
            expectedNotesText: expectedNotesText,
            resultText: resultText,
            showExpectedHint: showExpectedHint,
          ),
        ),
      ),
    );
  }

  Widget buildPracticeAppBarContent({
    required AppThemeColors colors,
    required bool canSwitchMode,
    required String resultText,
    required VoidCallback onOpenControls,
  }) {
    final completedPositions = performanceModeEnabled
        ? performanceTracker.evaluatedEventCount
        : noteMatcher.completedPositionCount;
    final positionTotal = performanceModeEnabled
        ? performanceTracker.totalEventCount
        : totalPositionCount;
    final progress = positionTotal > 0
        ? (completedPositions / positionTotal).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final percentage = (progress * 100).round();
    final rawFeedbackText = scoreCompleted ? 'Completed' : resultText;
    final feedbackText = localizedFeedback(rawFeedbackText);
    final feedbackVisual = feedbackAppearance(rawFeedbackText, colors);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showTitle = screenWidth >= 700;
    final showProgress = screenWidth >= 620;

    return Row(
      children: [
        if (showTitle) SizedBox(
          width: 132,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.sightReading,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: AppTextSizes.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${pieceTitle == 'Untitled score' ? context.l10n.sightReadingUntitledScore : pieceTitle} · ${sourceLabel()}',
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showTitle) const Gap(AppSpacing.sm),
        PracticeModeToggle<bool>(
          firstValue: false,
          firstLabel: context.l10n.sightReadingWait,
          secondValue: true,
          secondLabel: context.l10n.sightReadingPerformance,
          selectedValue: performanceModeEnabled,
          colors: colors,
          onChanged: canSwitchMode
              ? (selectedMode) {
                  unawaited(confirmPracticeModeChange(selectedMode));
                }
              : null,
        ),
        const Gap(AppSpacing.sm),
        if (showProgress) Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    positionTotal > 0
                        ? '$completedPositions / $positionTotal · $percentage% · ${compactTimeStatus()}'
                        : context.l10n.sightReadingPreparingProgress,
                    maxLines: 1,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Gap(AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: colors.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ) else const Spacer(),
        const Gap(AppSpacing.sm),
        Tooltip(
          message: feedbackText,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: feedbackVisual.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              feedbackVisual.icon,
              color: feedbackVisual.color,
              size: AppIconSizes.sm,
            ),
          ),
        ),
        const Gap(AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onOpenControls,
          style: secondaryButtonStyle(colors).copyWith(
            visualDensity: VisualDensity.compact,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
          ),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: Text(context.l10n.sightReadingControls),
        ),
        const Gap(AppSpacing.sm),
      ],
    );
  }

  Future<void> confirmPracticeModeChange(bool selectedMode) async {
    if (selectedMode == performanceModeEnabled) {
      return;
    }

    final colors = widget.colors;
    final modeName = selectedMode
        ? context.l10n.sightReadingPerformanceMode
        : context.l10n.sightReadingWaitMode;
    final modeIcon = selectedMode
        ? Icons.timer_outlined
        : Icons.hourglass_empty_rounded;
    final modeDescription = selectedMode
        ? context.l10n.sightReadingPerformanceModeDescription
        : context.l10n.sightReadingWaitModeDescription;
    final modeDetails = selectedMode
        ? [
            context.l10n.sightReadingPerformanceDetailNoPause,
            context.l10n.sightReadingPerformanceDetailEvaluation,
            context.l10n.sightReadingPerformanceDetailFirstKey,
          ]
        : [
            context.l10n.sightReadingWaitDetailNoTimeLimit,
            context.l10n.sightReadingWaitDetailHoldLength,
            context.l10n.sightReadingWaitDetailContinuedNotes,
          ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          iconPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          icon: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: Icon(
              modeIcon,
              color: colors.primaryColor,
              size: AppIconSizes.md,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          title: Text(
            context.l10n.sightReadingSwitchToModeQuestion(modeName),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 155, maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  modeDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: AppTextSizes.caption,
                    height: 1.25,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: modeDetails
                        .map(
                          (detail) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: colors.primaryColor,
                                  size: 18,
                                ),
                                const Gap(AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: TextStyle(
                                      color: colors.primaryColor,
                                      fontSize: AppTextSizes.caption,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 46),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        context.l10n.cancel,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 46),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        context.l10n.sightReadingSwitchMode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      performanceModeEnabled = selectedMode;
    });
    await retryExercise();

    if (!selectedMode && mounted && !midiStatus.startsWith('Connected:')) {
      await showMidiConnectionRequiredDialog(forPerformanceMode: false);
    }
  }

  Future<void> handlePerformanceStartPressed() async {
    if (midiStatus.startsWith('Connected:')) {
      armPerformanceForFirstKey();
      return;
    }

    await showMidiConnectionRequiredDialog(forPerformanceMode: true);
  }

  Future<void> showMidiConnectionRequiredDialog({
    required bool forPerformanceMode,
  }) async {
    if (!mounted || midiStatus.startsWith('Connected:')) {
      if (forPerformanceMode && mounted) {
        armPerformanceForFirstKey();
      }
      return;
    }

    final colors = widget.colors;
    final shouldConnect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: colors.surfaceColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: Icon(
              Icons.piano_rounded,
              color: colors.primaryColor,
              size: AppIconSizes.md,
            ),
          ),
          title: Text(
            context.l10n.sightReadingConnectMidiKeyboard,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            forPerformanceMode
                ? context.l10n.sightReadingPerformanceRequiresMidi
                : context.l10n.sightReadingWaitRequiresMidi,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.body,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 46),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        context.l10n.cancel,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 46),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.usb_rounded, size: 18),
                      label: Text(
                        context.l10n.sightReadingConnectMidi,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted || shouldConnect != true) {
      return;
    }

    await connectToMidi();

    if (forPerformanceMode && mounted && midiStatus.startsWith('Connected:')) {
      armPerformanceForFirstKey();
    }
  }

  Widget buildScoreCard(
    AppThemeColors colors, {
    required String activeNotesText,
    required String expectedNotesText,
    required String resultText,
    required bool showExpectedHint,
  }) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: colors.isDarkMode ? 0.24 : 0.07,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.sm,
            ),
            child: MusicSheetWebView(controller: musicSheetController),
          ),
          if (!scoreIsLoading && scoreLoadingError == null)
            buildScoreFeedbackOverlay(
              colors: colors,
              activeNotesText: activeNotesText,
              expectedNotesText: expectedNotesText,
              resultText: resultText,
              showExpectedHint: showExpectedHint,
            ),
          if (shouldShowPerformanceStartButton())
            buildPerformanceStartButton(colors),
          if (scoreIsLoading) buildScoreLoadingOverlay(colors),
          if (scoreLoadingError != null) buildScoreErrorOverlay(colors),
          if (performanceWaitingForFirstKey) buildPerformanceReadyOverlay(),
        ],
      ),
    );
  }

  bool shouldShowPerformanceStartButton() {
    return performanceModeEnabled &&
        !scoreIsLoading &&
        scoreLoadingError == null &&
        !scoreCompleted &&
        !performanceRunning &&
        !performanceFinishing &&
        !performanceWaitingForFirstKey;
  }

  bool canStartPerformance() {
    return shouldShowPerformanceStartButton() &&
        performanceTracker.hasTimeline &&
        midiStatus != 'Searching...' &&
        midiStatus != 'Connecting...' &&
        !scorePreviewPreparing &&
        !scorePreviewPlaying;
  }

  Widget buildPerformanceStartButton(AppThemeColors colors) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: AppSpacing.sm,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 240,
            minHeight: 46,
            maxWidth: 300,
          ),
          child: FilledButton.icon(
            onPressed: canStartPerformance()
                ? () {
                    unawaited(handlePerformanceStartPressed());
                  }
                : null,
            style: primaryButtonStyle(colors).copyWith(
              elevation: const WidgetStatePropertyAll(4),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              context.l10n.sightReadingStartPerformance,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildScoreFeedbackOverlay({
    required AppThemeColors colors,
    required String activeNotesText,
    required String expectedNotesText,
    required String resultText,
    required bool showExpectedHint,
  }) {
    final rawFeedbackText = scoreCompleted ? 'Completed' : resultText;
    final feedbackText = localizedFeedback(rawFeedbackText);
    final feedbackVisual = feedbackAppearance(rawFeedbackText, colors);

    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Center(
        child: IgnorePointer(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: feedbackVisual.color.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  feedbackVisual.icon,
                  color: feedbackVisual.color,
                  size: 18,
                ),
                const Gap(AppSpacing.xs),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.sightReadingPlayedNotes(
                          feedbackText,
                          activeNotesText,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: AppTextSizes.caption,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!scoreCompleted && showExpectedHint)
                        Text(
                          context.l10n.sightReadingHintPlay(
                            expectedNotesText,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: AppTextSizes.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildScoreLoadingOverlay(AppThemeColors colors) {
    return ColoredBox(
      color: colors.surfaceColor.withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primaryColor),
            const Gap(AppSpacing.md),
            Text(
              context.l10n.sightReadingPreparingScore,
              style: TextStyle(
                color: colors.primaryColor,
                fontSize: AppTextSizes.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              context.l10n.sightReadingLoadingNotationTimingAudio,
              style: TextStyle(
                color: colors.secondaryTextColor,
                fontSize: AppTextSizes.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScoreErrorOverlay(AppThemeColors colors) {
    return ColoredBox(
      color: colors.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: AppIconSizes.lg,
              ),
              const Gap(AppSpacing.sm),
              Text(
                context.l10n.sightReadingCouldNotPrepareScore,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(AppSpacing.xs),
              Text(
                scoreLoadingError ?? context.l10n.sightReadingUnknownLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                ),
              ),
              const Gap(AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(loadPieceSource());
                },
                style: secondaryButtonStyle(colors),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.sightReadingTryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPerformanceReadyOverlay() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.piano_rounded,
                color: Colors.white,
                size: AppIconSizes.lg,
              ),
              const Gap(AppSpacing.sm),
              Text(
                context.l10n.sightReadingPressAnyMidiKey,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTextSizes.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showPracticeControlsSheet({
    required AppThemeColors colors,
    required String activeNotesText,
    required String expectedNotesText,
    required String resultText,
    required bool showExpectedHint,
  }) async {
    if (practiceControlsSheetOpen) {
      return;
    }

    practiceControlsSheetOpen = true;
    final rawFeedbackText = scoreCompleted ? 'Completed' : resultText;
    final feedbackText = localizedFeedback(rawFeedbackText);
    final feedbackVisual = feedbackAppearance(rawFeedbackText, colors);

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        enableDrag: false,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, refreshControls) {
            final sheetCanToggleScorePreview =
                scorePreviewPreparing ||
                scorePreviewPlaying ||
                (scoreAudioUrl?.isNotEmpty == true &&
                    !performanceRunning &&
                    !performanceWaitingForFirstKey &&
                    !waitHoldInProgress &&
                    !waitBlockedByExpiredKey &&
                    waitHeldNotes.isEmpty);
            final sheetCanConnectMidi =
                !scoreIsLoading &&
                !performanceRunning &&
                !performanceWaitingForFirstKey &&
                !waitHoldInProgress &&
                !waitBlockedByExpiredKey &&
                waitHeldNotes.isEmpty &&
                !scorePreviewPreparing &&
                !scorePreviewPlaying;
            final sheetCanRetry =
                loadedMusicXml != null &&
                !performanceRunning &&
                !performanceWaitingForFirstKey &&
                !waitHoldInProgress &&
                !waitBlockedByExpiredKey &&
                waitHeldNotes.isEmpty &&
                !scorePreviewPreparing &&
                !scorePreviewPlaying;

            Future<void> runAndRefresh(Future<void> Function() action) async {
              final actionFuture = action();
              if (sheetContext.mounted) {
                refreshControls(() {});
              }

              await actionFuture;

              if (sheetContext.mounted) {
                refreshControls(() {});
              }
            }

            void refreshDuringPlayback() {
              Future<void>.delayed(const Duration(milliseconds: 250), () {
                if (!sheetContext.mounted) {
                  return;
                }

                refreshControls(() {});
                if (scorePreviewPreparing || scorePreviewPlaying) {
                  refreshDuringPlayback();
                }
              });
            }

              final showMidiReconnectPrompt =
                  midiStatus == 'No device detected' ||
                  midiStatus == 'Connection failed' ||
                  midiStatus == 'Not connected';

              return SafeArea(
              child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: colors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: feedbackVisual.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            feedbackVisual.icon,
                            color: feedbackVisual.color,
                            size: AppIconSizes.sm,
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feedbackText,
                                style: TextStyle(
                                  color: colors.primaryColor,
                                  fontSize: AppTextSizes.label,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                showExpectedHint
                                    ? context.l10n.sightReadingPlayedWithHint(
                                        activeNotesText,
                                        expectedNotesText,
                                      )
                                    : context.l10n.sightReadingPlayed(
                                        activeNotesText,
                                      ),
                                style: TextStyle(
                                  color: showExpectedHint
                                      ? const Color(0xFFF59E0B)
                                      : colors.secondaryTextColor,
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        buildMidiStatusChip(colors),
                        const Gap(AppSpacing.sm),
                        IconButton(
                          tooltip: context.l10n.sightReadingCloseControls,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: colors.primaryColor,
                        ),
                      ],
                    ),
                    if (showMidiReconnectPrompt) ...[
                      const Gap(AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFF59E0B),
                              size: AppIconSizes.sm,
                            ),
                            const Gap(AppSpacing.xs),
                            Expanded(
                              child: Text(
                                context.l10n.sightReadingMidiReconnectPrompt,
                                style: TextStyle(
                                  color: colors.primaryColor,
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Gap(AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: sheetCanToggleScorePreview
                                ? () {
                                    unawaited(
                                      runAndRefresh(toggleScorePreview),
                                    );
                                    refreshDuringPlayback();
                                  }
                                : null,
                            style: secondaryButtonStyle(colors),
                            icon: scorePreviewPreparing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    scorePreviewPlaying
                                        ? Icons.stop_rounded
                                        : Icons.volume_up_rounded,
                                  ),
                            label: Text(
                              scorePreviewPreparing
                                  ? context.l10n.loading
                                  : scorePreviewPlaying
                                  ? context.l10n.stop
                                  : context.l10n.sightReadingListen,
                            ),
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: sheetCanConnectMidi
                                ? () {
                                    unawaited(runAndRefresh(connectToMidi));
                                  }
                                : null,
                            style: secondaryButtonStyle(colors),
                            icon: Icon(midiActionIcon()),
                            label: Text(midiActionLabel()),
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: sheetCanRetry
                                ? () {
                                    unawaited(runAndRefresh(retryExercise));
                                  }
                                : null,
                            style: secondaryButtonStyle(colors),
                            icon: const Icon(Icons.replay_rounded),
                            label: Text(context.l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
              );
            },
          );
        },
      );
    } finally {
      practiceControlsSheetOpen = false;
    }
  }

  Future<void> showCurrentPracticeControls() async {
    if (!mounted || practiceControlsSheetOpen) {
      return;
    }

    final sortedActiveNotes = activeMidiNotes.toList()..sort();
    final sortedExpectedNotes = noteMatcher.expectedMidiNotes.toList()..sort();
    final activeNotesText = sortedActiveNotes.isEmpty
        ? context.l10n.sightReadingNone
        : sortedActiveNotes.map(midiToNoteName).join(' + ');
    final expectedNotesText = sortedExpectedNotes.isEmpty
        ? context.l10n.sightReadingWaitingEllipsis
        : sortedExpectedNotes.map(midiToNoteName).join(' + ');

    await showPracticeControlsSheet(
      colors: widget.colors,
      activeNotesText: activeNotesText,
      expectedNotesText: expectedNotesText,
      resultText: performanceModeEnabled
          ? performanceTracker.resultText
          : noteMatcher.resultText,
      showExpectedHint:
          !performanceModeEnabled && noteMatcher.showExpectedHint,
    );
  }

  void scheduleMidiReconnectControls() {
    if (!mounted ||
        midiReconnectSheetScheduled ||
        practiceControlsSheetOpen) {
      return;
    }

    midiReconnectSheetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      midiReconnectSheetScheduled = false;

      if (!mounted ||
          practiceControlsSheetOpen ||
          midiStatus.startsWith('Connected:')) {
        return;
      }

      unawaited(showCurrentPracticeControls());
    });
  }

  Widget buildPracticeDock({
    required AppThemeColors colors,
    required String activeNotesText,
    required String expectedNotesText,
    required String resultText,
    required bool showExpectedHint,
    required bool canStartPerformance,
    required bool canToggleScorePreview,
    required bool canConnectMidi,
    required bool canRetry,
  }) {
    final rawFeedbackText = scoreCompleted ? 'Completed' : resultText;
    final feedbackText = localizedFeedback(rawFeedbackText);
    final feedbackVisual = feedbackAppearance(rawFeedbackText, colors);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: buildPanelDecoration(colors),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: feedbackVisual.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feedbackVisual.icon,
                        color: feedbackVisual.color,
                        size: AppIconSizes.sm,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: Text(
                        feedbackText,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    buildStatusChip(
                      colors: colors,
                      icon: Icons.piano_rounded,
                      label: context.l10n.sightReadingPlayed(activeNotesText),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: !performanceModeEnabled
                            ? Visibility(
                                visible: !scoreCompleted && showExpectedHint,
                                maintainState: true,
                                maintainAnimation: true,
                                maintainSize: true,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context.l10n.sightReadingHintPlay(
                                      expectedNotesText,
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: AppTextSizes.caption,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  performanceRunning
                                      ? context.l10n.sightReadingFollowCursor
                                      : context
                                            .l10n
                                            .sightReadingStartWhenMidiReady,
                                  style: TextStyle(
                                    color: colors.secondaryTextColor,
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    buildMidiStatusChip(colors),
                  ],
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  child: performanceModeEnabled
                      ? FilledButton.icon(
                          onPressed: canStartPerformance
                              ? armPerformanceForFirstKey
                              : null,
                          style: primaryButtonStyle(colors),
                          icon: Icon(
                            performanceRunning
                                ? Icons.graphic_eq_rounded
                                : performanceWaitingForFirstKey
                                ? Icons.hourglass_top_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            performanceRunning
                                ? context.l10n.sightReadingPlaying
                                : performanceWaitingForFirstKey
                                ? context.l10n.sightReadingWaiting
                                : context.l10n.sightReadingStart,
                          ),
                        )
                      : Container(
                          height: 44,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colors.backgroundColor,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note_rounded,
                                color: colors.primaryColor,
                                size: AppIconSizes.sm,
                              ),
                              const Gap(AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  context.l10n.sightReadingHoldUntilCursor,
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canToggleScorePreview
                        ? () {
                            unawaited(toggleScorePreview());
                          }
                        : null,
                    style: secondaryButtonStyle(colors),
                    icon: scorePreviewPreparing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            scorePreviewPlaying
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                          ),
                    label: Text(
                      scorePreviewPreparing
                          ? context.l10n.loading
                          : scorePreviewPlaying
                          ? context.l10n.stop
                          : context.l10n.sightReadingListen,
                    ),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canConnectMidi ? connectToMidi : null,
                    style: secondaryButtonStyle(colors),
                    icon: Icon(midiActionIcon()),
                    label: Text(midiActionLabel()),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canRetry
                        ? () {
                            unawaited(retryExercise());
                          }
                        : null,
                    style: secondaryButtonStyle(colors),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(context.l10n.retry),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration buildPanelDecoration(AppThemeColors colors) {
    return BoxDecoration(
      color: colors.surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: colors.borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: colors.isDarkMode ? 0.18 : 0.04,
          ),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  ButtonStyle primaryButtonStyle(AppThemeColors colors) {
    return FilledButton.styleFrom(
      backgroundColor: colors.primaryColor,
      foregroundColor: colors.backgroundColor,
      disabledBackgroundColor: colors.borderColor,
      disabledForegroundColor: colors.secondaryTextColor,
    );
  }

  ButtonStyle secondaryButtonStyle(AppThemeColors colors) {
    return OutlinedButton.styleFrom(
      foregroundColor: colors.primaryColor,
      disabledForegroundColor: colors.secondaryTextColor.withValues(
        alpha: 0.55,
      ),
      side: BorderSide(color: colors.borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  Widget buildStatusChip({
    required AppThemeColors colors,
    required IconData icon,
    required String label,
    Color? accentColor,
  }) {
    final foreground = accentColor ?? colors.secondaryTextColor;

    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const Gap(AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMidiStatusChip(AppThemeColors colors) {
    final isConnected = midiStatus.startsWith('Connected:');
    final isFailed = midiStatus == 'Connection failed';
    final isWorking =
        midiStatus == 'Searching...' || midiStatus == 'Connecting...';
    final color = isConnected
        ? const Color(0xFF16A34A)
        : isFailed
        ? const Color(0xFFDC2626)
        : colors.secondaryTextColor;
    final icon = isConnected
        ? Icons.usb_rounded
        : isFailed
        ? Icons.usb_off_rounded
        : isWorking
        ? Icons.sync_rounded
        : Icons.usb_off_rounded;

    return buildStatusChip(
      colors: colors,
      icon: icon,
      label: localizedMidiStatus(),
      accentColor: color,
    );
  }

  ({Color color, IconData icon}) feedbackAppearance(
    String result,
    AppThemeColors colors,
  ) {
    final normalizedResult = result.toLowerCase();

    if (normalizedResult.contains('correct') ||
        normalizedResult.contains('completed') ||
        normalizedResult.contains('duration complete')) {
      return (color: const Color(0xFF16A34A), icon: Icons.check_circle_rounded);
    }

    if (normalizedResult.contains('wrong') ||
        normalizedResult.contains('released too soon') ||
        normalizedResult.contains('held too long') ||
        normalizedResult.contains('release before playing') ||
        normalizedResult.contains('try again')) {
      return (color: const Color(0xFFDC2626), icon: Icons.cancel_rounded);
    }

    if (normalizedResult.contains('play on time') ||
        normalizedResult.contains('keep playing') ||
        normalizedResult.contains('keep holding') ||
        normalizedResult.contains('correct notes') ||
        normalizedResult.startsWith('hold ') ||
        normalizedResult.startsWith('release ') ||
        normalizedResult.startsWith('released — continue')) {
      return (color: const Color(0xFF2563EB), icon: Icons.graphic_eq_rounded);
    }

    return (
      color: colors.secondaryTextColor,
      icon: Icons.radio_button_checked_rounded,
    );
  }

  String localizedFeedback(String feedback) {
    final keepHolding = RegExp(
      r'^Keep holding (?:·|Â·) (\d+)%$',
    ).firstMatch(feedback);
    if (keepHolding != null) {
      return context.l10n.sightReadingKeepHolding(
        int.parse(keepHolding.group(1)!),
      );
    }

    final releaseBefore = RegExp(
      r'^Release (.+) before playing it again$',
    ).firstMatch(feedback);
    if (releaseBefore != null) {
      return context.l10n.sightReadingReleaseBeforePlayingAgain(
        releaseBefore.group(1)!,
      );
    }

    final releaseHeldTooLong = RegExp(
      r'^Release (.+) (?:—|â€”) held too long$',
    ).firstMatch(feedback);
    if (releaseHeldTooLong != null) {
      return context.l10n.sightReadingReleaseHeldTooLong(
        releaseHeldTooLong.group(1)!,
      );
    }

    final heldTooLong = RegExp(
      r'^(.+) was held too long$',
    ).firstMatch(feedback);
    if (heldTooLong != null) {
      return context.l10n.sightReadingNoteHeldTooLong(heldTooLong.group(1)!);
    }

    final releasedTooSoon = RegExp(
      r'^(.+) was released too soon$',
    ).firstMatch(feedback);
    if (releasedTooSoon != null) {
      return context.l10n.sightReadingNoteReleasedTooSoon(
        releasedTooSoon.group(1)!,
      );
    }

    final holdNext = RegExp(
      r'^Hold (.+) while playing the next notes$',
    ).firstMatch(feedback);
    if (holdNext != null) {
      return context.l10n.sightReadingHoldWhilePlayingNext(
        holdNext.group(1)!,
      );
    }

    final holdWhilePlaying = RegExp(
      r'^Hold (.+) while playing (.+)$',
    ).firstMatch(feedback);
    if (holdWhilePlaying != null) {
      return context.l10n.sightReadingHoldWhilePlaying(
        holdWhilePlaying.group(1)!,
        holdWhilePlaying.group(2)!,
      );
    }

    final release = RegExp(r'^Release (.+)$').firstMatch(feedback);
    if (release != null) {
      return context.l10n.sightReadingReleaseNotes(release.group(1)!);
    }

    return switch (feedback) {
      'Ready' => context.l10n.sightReadingReady,
      'Waiting' => context.l10n.sightReadingWaiting,
      'Waiting for MIDI file' => context.l10n.sightReadingWaitingForMidi,
      'Play on time' => context.l10n.sightReadingPlayOnTime,
      'Missed' => context.l10n.sightReadingMissed,
      'Wrong note' => context.l10n.sightReadingWrongNote,
      'Complete the chord' => context.l10n.sightReadingCompleteChord,
      'Chord notes were not together' =>
        context.l10n.sightReadingChordNotesNotTogether,
      'Correct after mistake' => context.l10n.sightReadingCorrectAfterMistake,
      'Correct — keep holding' || 'Correct notes — keep holding' =>
        context.l10n.sightReadingCorrectNotesKeepHolding,
      'Correct' => context.l10n.sightReadingCorrect,
      'Released too soon' => context.l10n.sightReadingReleasedTooSoon,
      'Too early' => context.l10n.sightReadingTooEarly,
      'Too late' => context.l10n.sightReadingTooLate,
      'Wrong' => context.l10n.sightReadingWrong,
      'Keep playing' => context.l10n.sightReadingKeepPlaying,
      'Duration complete' => context.l10n.sightReadingDurationComplete,
      'Released — continue with the highlighted note' =>
        context.l10n.sightReadingReleasedContinue,
      'Try again — hold until the cursor reaches the next note' =>
        context.l10n.sightReadingTryAgainHoldUntilCursor,
      'Press any MIDI key to begin' => context.l10n.sightReadingPressAnyMidiKey,
      'Completed' => context.l10n.sightReadingCompleted,
      _ => feedback,
    };
  }

  String sourceLabel() {
    return switch (widget.source) {
      SightReadingSource.composition =>
        context.l10n.sightReadingComposition,
      SightReadingSource.musicSheet => context.l10n.sightReadingMusicSheet,
      SightReadingSource.lesson => context.l10n.drawerPractice,
    };
  }

  Future<void> openLessonPdf() async {
    final lesson = widget.lesson;
    final path = lesson?.pdfAssetPath;
    if (lesson == null || path == null) return;
    final pdfBytes = rootBundle.load(path);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(lesson.title)),
          body: FutureBuilder<ByteData>(
            future: pdfBytes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Could not load PDF: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return PdfViewer.data(
                snapshot.data!.buffer.asUint8List(),
                sourceName: lesson.title,
              );
            },
          ),
        ),
      ),
    );
  }

  String compactTimeStatus() {
    if (!performanceModeEnabled) {
      return context.l10n.sightReadingNoTimeLimit;
    }

    if (!targetDurationCalculated) {
      return context.l10n.sightReadingReadingTimeline;
    }

    if (targetDurationSeconds <= 0) {
      return context.l10n.sightReadingTimelineUnavailable;
    }

    final elapsedSeconds = scoreCompleted
        ? completedElapsedSeconds ?? playingStopwatch.elapsed.inSeconds
        : playingStopwatch.elapsed.inSeconds;

    if (!performanceRunning &&
        !scoreCompleted &&
        !performanceWaitingForFirstKey) {
      return context.l10n.sightReadingTargetDuration(
        formatDuration(targetDurationSeconds),
      );
    }

    if (performanceWaitingForFirstKey) {
      return context.l10n.sightReadingPressAnyKeyToStart;
    }

    return '${formatDuration(elapsedSeconds)} / '
        '${formatDuration(targetDurationSeconds)}';
  }

  IconData midiActionIcon() {
    if (midiStatus.startsWith('Connected:')) {
      return Icons.usb_rounded;
    }

    if (midiStatus == 'Searching...' || midiStatus == 'Connecting...') {
      return Icons.sync_rounded;
    }

    return Icons.usb_off_rounded;
  }

  String midiActionLabel() {
    if (midiStatus.startsWith('Connected:')) {
      return context.l10n.sightReadingConnected;
    }

    if (midiStatus == 'Searching...') {
      return context.l10n.sightReadingSearching;
    }

    if (midiStatus == 'Connecting...') {
      return context.l10n.sightReadingConnecting;
    }

    return context.l10n.sightReadingConnectMidi;
  }

  String localizedMidiStatus() {
    if (midiStatus.startsWith('Connected:')) {
      final device = midiStatus.substring('Connected:'.length).trim();
      return context.l10n.sightReadingConnectedDevice(device);
    }

    return switch (midiStatus) {
      'Searching...' => context.l10n.sightReadingSearchingEllipsis,
      'Connecting...' => context.l10n.sightReadingConnectingEllipsis,
      'No device detected' => context.l10n.sightReadingNoDeviceDetected,
      'Connection failed' => context.l10n.sightReadingConnectionFailed,
      _ => context.l10n.sightReadingNotConnected,
    };
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

        scheduleMidiReconnectControls();

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

      if (!midiInputService.isConnected) {
        setState(() {
          midiStatus = 'Connection failed';
        });
        scheduleMidiReconnectControls();
        return;
      }

      setState(() {
        midiStatus = 'Connected: ${device.name}';
      });
      midiWasConnected = true;
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        midiStatus = 'Connection failed';
      });
      scheduleMidiReconnectControls();
    }
  }

  Future<void> toggleScorePreview() async {
    if (scorePreviewPreparing || scorePreviewPlaying) {
      await stopScorePreview();
      return;
    }

    if (performanceRunning ||
        performanceWaitingForFirstKey ||
        waitHoldInProgress ||
        waitHeldNotes.isNotEmpty) {
      return;
    }

    final audioUrl = scoreAudioUrl;

    if (audioUrl == null || audioUrl.isEmpty) {
      showThemedSnackBar(context.l10n.sightReadingNoMp3Preview, isError: true);
      return;
    }

    setState(() {
      scorePreviewPreparing = true;
      activeMidiNotes = <int>{};
    });

    await scoreAudioPlaybackService.play(
      audioUrl: audioUrl,
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

        showThemedSnackBar(
          context.l10n.sightReadingPlaybackFailed,
          isError: true,
        );
      },
    );
  }

  void showThemedSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    final colors = widget.colors;
    final backgroundColor = isError
        ? const Color(0xFFB91C1C)
        : colors.primaryColor;
    final foregroundColor = isError ? Colors.white : colors.backgroundColor;
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: foregroundColor,
              size: AppIconSizes.sm,
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Text(message, style: TextStyle(color: foregroundColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> stopScorePreview() async {
    await scoreAudioPlaybackService.stop();

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

  Future<void> advanceSheet() {
    return musicSheetController.advanceCursor();
  }

  MidiTimelineEvent? currentWaitTimelineEvent() {
    final events = performanceTracker.timelineEvents;
    final expectedNotes = noteMatcher.expectedMidiNotes;

    if (events.isEmpty || expectedNotes.isEmpty) {
      return null;
    }

    if (waitCursorEventIndex >= events.length) {
      return null;
    }

    final event = events[waitCursorEventIndex];
    final eventNotes = event.midiNotes;

    return eventNotes.length == expectedNotes.length &&
            eventNotes.containsAll(expectedNotes)
        ? event
        : null;
  }

  Future<void> beginWaitHoldAttempt() async {
    if (!mounted ||
        performanceModeEnabled ||
        waitHoldInProgress ||
        waitRetryRequiresRelease ||
        scoreCompleted) {
      return;
    }

    final timelineEvent = currentWaitTimelineEvent();

    if (timelineEvent == null) {
      final completedIndex = waitCursorEventIndex;
      setState(() {
        noteMatcher.completePosition(completedIndex);
      });
      waitCursorEventIndex++;
      noteMatcher.setCurrentPositionIndex(waitCursorEventIndex);
      await advanceSheet();
      return;
    }

    final now = DateTime.now();
    final expectedNotes = Set<int>.from(noteMatcher.expectedMidiNotes);

    for (final note in expectedNotes) {
      final noteDuration =
          timelineEvent.noteDurations[note] ??
          timelineEvent.longestNoteDuration;
      final pressedAt = waitNotePressedAt[note] ?? now;
      final minimumHoldMilliseconds =
          (noteDuration.inMilliseconds * waitMinimumHoldRatio).round();

      waitHeldNotes[note] = _WaitHeldNoteState(
        midiNote: note,
        originPositionIndex: waitCursorEventIndex,
        pressedAt: pressedAt,
        earliestReleaseAt: pressedAt.add(
          Duration(milliseconds: minimumHoldMilliseconds),
        ),
        expectedReleaseAt: pressedAt.add(noteDuration),
        latestReleaseAt: pressedAt
            .add(noteDuration)
            .add(performanceTracker.timingTolerance),
      );
    }

    waitHoldInProgress = true;
    waitCursorHasArrived = false;
    waitBlockedByExpiredKey = false;
    waitHoldPositionIndex = waitCursorEventIndex;
    waitSegmentStartedAt = now;
    waitCursorTravelDuration = waitCursorDurationForEvent(waitCursorEventIndex);

    setState(() {
      noteMatcher.showDurationFeedback('Correct notes — keep holding');
    });

    await musicSheetController.beginWaitCursorHold(
      waitCursorTravelDuration,
      positionIndex: waitHoldPositionIndex,
    );

    if (!mounted || !waitHoldInProgress) {
      return;
    }

    ensureWaitHoldTicker();
    updateWaitHoldProgress();
  }

  Duration waitCursorDurationForEvent(int eventIndex) {
    final events = performanceTracker.timelineEvents;

    if (eventIndex < 0 || eventIndex >= events.length) {
      return Duration.zero;
    }

    if (eventIndex + 1 < events.length) {
      final duration =
          events[eventIndex + 1].scheduledTime -
          events[eventIndex].scheduledTime;
      return duration.isNegative ? Duration.zero : duration;
    }

    return events[eventIndex].longestNoteDuration;
  }

  void ensureWaitHoldTicker() {
    if (waitHoldTicker != null) {
      return;
    }

    waitHoldTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      updateWaitHoldProgress();
    });
  }

  void updateWaitHoldProgress() {
    if (!mounted ||
        performanceModeEnabled ||
        (!waitHoldInProgress && waitHeldNotes.isEmpty)) {
      return;
    }

    final now = DateTime.now();
    final dueForRelease = <_WaitHeldNoteState>[];
    final overheldNotes = <_WaitHeldNoteState>[];

    for (final heldNote in waitHeldNotes.values) {
      if (!activeMidiNotes.contains(heldNote.midiNote)) {
        continue;
      }

      if (!now.isBefore(heldNote.expectedReleaseAt)) {
        dueForRelease.add(heldNote);
      }

      if (now.isAfter(heldNote.latestReleaseAt)) {
        heldNote.wasHeldTooLong = true;
        overheldNotes.add(heldNote);

        if (waitOverheldMistakePositions.add(heldNote.originPositionIndex)) {
          final noteName = midiToNoteName(heldNote.midiNote);
          noteMatcher.recordDurationMistake(
            positionIndex: heldNote.originPositionIndex,
            message: '$noteName was held too long',
          );
        }
      }
    }

    waitBlockedByExpiredKey = dueForRelease.isNotEmpty;

    final segmentStartedAt = waitSegmentStartedAt;
    if (waitHoldInProgress && segmentStartedAt != null) {
      final segmentElapsed = now.difference(segmentStartedAt);

      if (segmentElapsed >= waitCursorTravelDuration) {
        waitCursorHasArrived = true;
      }
    }

    if (overheldNotes.isNotEmpty) {
      final noteNames = formatMidiNoteNames(
        overheldNotes.map((note) => note.midiNote),
      );
      final retryPosition = overheldNotes
          .map((note) => note.originPositionIndex)
          .reduce(
            (earliest, position) =>
                position < earliest ? position : earliest,
          );
      setState(() {
        noteMatcher.showDurationFeedback(
          'Release $noteNames — held too long',
          isError: true,
        );
      });
      unawaited(musicSheetController.setCursorWrong(true));
      unawaited(
        rewindWaitAttempt(
          positionIndex: retryPosition,
          preserveCurrentFeedback: true,
        ),
      );
      return;
    } else if (dueForRelease.isNotEmpty) {
      final noteNames = formatMidiNoteNames(
        dueForRelease.map((note) => note.midiNote),
      );
      setState(() {
        noteMatcher.showDurationFeedback('Release $noteNames');
      });
    } else if (waitHoldInProgress) {
      final progress = waitSegmentProgress(now);
      final carriedNotes = waitHeldNotes.values
          .where(
            (note) =>
                note.originPositionIndex < waitHoldPositionIndex &&
                activeMidiNotes.contains(note.midiNote),
          )
          .map((note) => note.midiNote)
          .toList(growable: false);

      setState(() {
        if (carriedNotes.isNotEmpty) {
          final names = formatMidiNoteNames(carriedNotes);
          noteMatcher.showDurationFeedback(
            'Hold $names while playing the next notes',
          );
        } else {
          noteMatcher.updateHoldProgress(progress);
        }
      });
    } else if (waitHeldNotes.isNotEmpty) {
      final carriedNotes = waitHeldNotes.values
          .where((note) => activeMidiNotes.contains(note.midiNote))
          .map((note) => note.midiNote);
      final carriedNames = formatMidiNoteNames(carriedNotes);
      final expectedNames = formatMidiNoteNames(noteMatcher.expectedMidiNotes);

      if (carriedNames.isNotEmpty && expectedNames.isNotEmpty) {
        setState(() {
          noteMatcher.showDurationFeedback(
            'Hold $carriedNames while playing $expectedNames',
          );
        });
      }
    }

    final isFinalPosition =
        waitHoldPositionIndex + 1 >= performanceTracker.timelineEvents.length;
    final canFinishFinalPosition =
        !isFinalPosition || waitHeldNotes.isEmpty;

    if (waitHoldInProgress &&
        waitCursorHasArrived &&
        !waitBlockedByExpiredKey &&
        canFinishFinalPosition) {
      unawaited(completeWaitCursorHandoff());
    }
  }

  double waitSegmentProgress(DateTime now) {
    final startedAt = waitSegmentStartedAt;
    final totalMilliseconds = waitCursorTravelDuration.inMilliseconds;

    if (startedAt == null || totalMilliseconds <= 0) {
      return 1;
    }

    return (now.difference(startedAt).inMilliseconds / totalMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  String formatMidiNoteNames(Iterable<int> notes) {
    final sortedNotes = notes.toSet().toList()..sort();
    return sortedNotes.map(midiToNoteName).join(' + ');
  }

  void handleWaitNoteOff(int midiNote) {
    final heldNote = waitHeldNotes[midiNote];
    if (heldNote == null) {
      waitNotePressedAt.remove(midiNote);
      return;
    }

    final releasedAt = DateTime.now();

    if (releasedAt.isBefore(heldNote.earliestReleaseAt)) {
      final noteName = midiToNoteName(midiNote);
      noteMatcher.recordDurationMistake(
        positionIndex: heldNote.originPositionIndex,
        message: '$noteName was released too soon',
      );
      unawaited(
        rewindWaitAttempt(
          positionIndex: heldNote.originPositionIndex,
          preserveCurrentFeedback: true,
        ),
      );
      return;
    }

    waitHeldNotes.remove(midiNote);
    waitNotePressedAt.remove(midiNote);
    finalizeWaitPositionIfReleased(heldNote.originPositionIndex);

    final stillExpired = waitHeldNotes.values.any(
      (note) =>
          activeMidiNotes.contains(note.midiNote) &&
          !releasedAt.isBefore(note.expectedReleaseAt),
    );
    waitBlockedByExpiredKey = stillExpired;

    if (!stillExpired) {
      setState(() {
        noteMatcher.showDurationFeedback(
          'Released — continue with the highlighted note',
        );
      });
      unawaited(musicSheetController.setCursorWrong(false));
    }

    if (waitHeldNotes.isEmpty && !waitHoldInProgress) {
      waitHoldTicker?.cancel();
      waitHoldTicker = null;
    }

    updateWaitHoldProgress();
  }

  Future<void> completeWaitCursorHandoff() async {
    if (!waitHoldInProgress || !waitCursorHasArrived) {
      return;
    }

    final completedPositionIndex = waitHoldPositionIndex;
    waitHoldInProgress = false;
    waitCursorHasArrived = false;
    waitSegmentStartedAt = null;
    waitCursorPassedPositions.add(completedPositionIndex);
    finalizeWaitPositionIfReleased(completedPositionIndex);

    final hasNextEvent =
        completedPositionIndex + 1 < performanceTracker.timelineEvents.length;

    if (hasNextEvent) {
      waitCursorEventIndex = completedPositionIndex + 1;
      noteMatcher.setCurrentPositionIndex(waitCursorEventIndex);
    }

    waitNotePressedAt.clear();
    await musicSheetController.completeWaitCursorHold();

    if (waitHeldNotes.isEmpty) {
      waitHoldTicker?.cancel();
      waitHoldTicker = null;
    }
  }

  void finalizeWaitPositionIfReleased(int positionIndex) {
    if (!waitCursorPassedPositions.contains(positionIndex)) {
      return;
    }

    final hasOutstandingNote = waitHeldNotes.values.any(
      (note) => note.originPositionIndex == positionIndex,
    );

    if (!hasOutstandingNote) {
      setState(() {
        noteMatcher.completePosition(positionIndex);
      });
    }
  }

  Future<void> rewindWaitAttempt({
    required int positionIndex,
    required bool preserveCurrentFeedback,
  }) async {
    waitHoldInProgress = false;
    waitCursorHasArrived = false;
    waitBlockedByExpiredKey = false;
    waitSegmentStartedAt = null;
    waitHoldTicker?.cancel();
    waitHoldTicker = null;
    waitRetryRequiresRelease = activeMidiNotes.isNotEmpty;
    waitCursorEventIndex = positionIndex;
    waitHoldPositionIndex = positionIndex;
    waitCursorPassedPositions.removeWhere((index) => index >= positionIndex);
    waitOverheldMistakePositions.removeWhere((index) => index >= positionIndex);

    setState(() {
      noteMatcher.rewindToPosition(positionIndex);

      if (!preserveCurrentFeedback) {
        noteMatcher.showDurationFeedback(
          'Try again — hold until the cursor reaches the next note',
          isError: true,
        );
      }
    });

    waitNotePressedAt.clear();
    waitHeldNotes.clear();
    await musicSheetController.cancelWaitCursorHold(positionIndex);
  }

  void cancelWaitDurationTracking() {
    waitHoldTicker?.cancel();
    waitHoldTicker = null;
    waitHoldInProgress = false;
    waitRetryRequiresRelease = false;
    waitCursorHasArrived = false;
    waitBlockedByExpiredKey = false;
    waitHoldPositionIndex = 0;
    waitCursorEventIndex = 0;
    waitSegmentStartedAt = null;
    waitCursorTravelDuration = Duration.zero;
    waitNotePressedAt.clear();
    waitHeldNotes.clear();
    waitCursorPassedPositions.clear();
    waitOverheldMistakePositions.clear();
  }

  void showScoreLoadingDialog() {
    if (!mounted) {
      return;
    }

    setState(() {
      scoreIsLoading = true;
      scoreLoadingError = null;
    });
  }

  void hideScoreLoadingDialog() {
    if (!mounted) {
      return;
    }

    setState(() {
      scoreIsLoading = false;
    });
  }

  void showScoreLoadingError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      scoreIsLoading = false;
      scoreLoadingError = message;
    });
  }

  Future<String?> resolveScoreFileUrl({
    required Object? directUrlValue,
    required Object? storagePathValue,
  }) async {
    if (directUrlValue is String && directUrlValue.trim().isNotEmpty) {
      return directUrlValue.trim();
    }

    if (storagePathValue is! String || storagePathValue.trim().isEmpty) {
      return null;
    }

    return FirebaseStorage.instance
        .ref(storagePathValue.trim())
        .getDownloadURL();
  }

  Future<void> loadPieceSource() async {
    showScoreLoadingDialog();

    try {
      final lesson = widget.lesson;
      if (lesson != null) {
        await loadLessonSource(lesson);
        return;
      }

      final piece = await FirebaseFirestore.instance
          .doc(widget.scoreDocumentPath)
          .get();

      final data = piece.data();
      final loadedTitle = data?['title'];
      final musicXmlUrl = await resolveScoreFileUrl(
        directUrlValue: data?['musicXmlUrl'],
        storagePathValue: data?['musicXmlStoragePath'],
      );
      final midiUrl = await resolveScoreFileUrl(
        directUrlValue: data?['midiUrl'],
        storagePathValue: data?['midiStoragePath'],
      );
      final mp3StorageField = widget.source == SightReadingSource.composition
          ? 'mp3StoragePath'
          : 'previewAudioStoragePath';
      final mp3StoragePath = data?[mp3StorageField];
      final mp3Url = await resolveScoreFileUrl(
        directUrlValue: data?['mp3Url'],
        storagePathValue: mp3StoragePath,
      );

      debugPrint('MusicXML URL found: ${musicXmlUrl != null}');
      debugPrint('MIDI URL found: ${midiUrl != null}');
      debugPrint('MP3 URL found: ${mp3Url != null}');

      if (musicXmlUrl == null) {
        showScoreLoadingError(context.l10n.sightReadingMusicXmlMissing);

        return;
      }

      final musicXmlResponse = await http.get(Uri.parse(musicXmlUrl));

      debugPrint('MusicXML download status: ${musicXmlResponse.statusCode}');

      if (musicXmlResponse.statusCode != 200) {
        showScoreLoadingError(
          context.l10n.sightReadingMusicXmlDownloadFailed,
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
        scoreAudioUrl = mp3Url;
        pieceTitle = loadedTitle is String && loadedTitle.trim().isNotEmpty
            ? loadedTitle.trim()
            : context.l10n.sightReadingUntitledScore;
        scoreLoadingError = null;
      });

      await musicSheetController.loadScore(
        musicXml,
        preserveRestOnlyStaves: widget.source == SightReadingSource.composition,
      );
      await loadMidiTargetDuration(midiUrl);
    } catch (error) {
      if (!mounted) {
        return;
      }

      showScoreLoadingError(context.l10n.sightReadingScoreLoadFailed);
    }
  }

  Future<void> loadLessonSource(SightReadingLessonAssets lesson) async {
    final musicXml = await readLessonMusicXml(lesson.scoreAssetPath);
    final midiData = await rootBundle.load(lesson.midiAssetPath);
    final durationResult = MidiFileDurationCalculator.calculate(
      midiData.buffer.asUint8List(),
    );

    if (!mounted) return;
    setState(() {
      loadedMusicXml = musicXml;
      scoreAudioUrl = null;
      pieceTitle = lesson.title;
      scoreLoadingError = null;
      performanceTracker.loadTimeline(
        durationResult.timelineEvents,
        totalDuration: durationResult.totalDuration,
      );
      targetDurationSeconds =
          (durationResult.totalDuration.inMilliseconds /
                  Duration.millisecondsPerSecond)
              .ceil();
      targetDurationCalculated = true;
      targetDurationUnavailableReason = durationResult.unavailableReason;
    });
    await musicSheetController.loadScore(musicXml);
  }

  Future<String> readLessonMusicXml(String path) async {
    if (!path.toLowerCase().endsWith('.mxl')) {
      return rootBundle.loadString(path);
    }

    final data = await rootBundle.load(path);
    final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
    final scoreFile = archive.files
        .where(
          (file) =>
              file.isFile &&
              file.name.toLowerCase().endsWith('.xml') &&
              !file.name.toLowerCase().endsWith('meta-inf/container.xml'),
        )
        .firstOrNull;
    if (scoreFile == null) {
      throw const FormatException('No MusicXML score in lesson asset.');
    }
    return utf8.decode(scoreFile.content as List<int>);
  }

  Future<void> loadMidiTargetDuration(String? midiUrl) async {
    if (midiUrl == null || midiUrl.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        performanceTracker.loadTimeline(const [], totalDuration: Duration.zero);
        targetDurationCalculated = true;
        targetDurationUnavailableReason = context
            .l10n
            .sightReadingMidiFileMissing;
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
          performanceTracker.loadTimeline(
            const [],
            totalDuration: Duration.zero,
          );
          targetDurationCalculated = true;
          targetDurationUnavailableReason = context
              .l10n
              .sightReadingMidiTimelineUnavailable;
        });

        return;
      }

      final durationResult = MidiFileDurationCalculator.calculate(
        midiResponse.bodyBytes,
      );

      debugPrint(
        'MIDI timeline loaded: '
        '${durationResult.timelineEvents.length} events, '
        '${durationResult.totalDuration.inMilliseconds} ms total',
      );

      setState(() {
        performanceTracker.loadTimeline(
          durationResult.timelineEvents,
          totalDuration: durationResult.totalDuration,
        );
        targetDurationSeconds =
            (durationResult.totalDuration.inMilliseconds /
                    Duration.millisecondsPerSecond)
                .ceil();
        targetDurationCalculated = true;
        targetDurationUnavailableReason = durationResult.unavailableReason;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        performanceTracker.loadTimeline(const [], totalDuration: Duration.zero);
        targetDurationCalculated = true;
        targetDurationUnavailableReason = context
            .l10n
            .sightReadingMidiTimelineUnavailable;
      });
    }
  }

  Future<void> showCompletionDialog({
    SightReadingCompletionResult? completionResult,
    bool progressSaveFailed = false,
    SightReadingPerformanceReport? performanceReport,
    Future<String>? resultSaveFuture,
  }) async {
    final totalMistakes = performanceModeEnabled
        ? performanceTracker.totalMistakes
        : noteMatcher.totalMistakes;

    final hintWasShown =
        !performanceModeEnabled && noteMatcher.hintWasShownDuringExercise;

    final hasTargetDuration = targetDurationSeconds > 0;
    final retryIsRequired = hintWasShown;

    final isPerfect = totalMistakes == 0 && !retryIsRequired;
    final lessonPassed = widget.lesson != null &&
        performanceModeEnabled &&
        performanceTracker.totalEventCount > 0 &&
        performanceTracker.correctEventCount ==
            performanceTracker.totalEventCount &&
        performanceTracker.wrongEventCount == 0 &&
        performanceTracker.missedEventCount == 0;
    final scoreText = performanceModeEnabled
        ? performanceTracker.scoreText
        : noteMatcher.scoreText;

    late final String xpMessage;

    if (widget.lesson != null) {
      xpMessage = lessonPassed
          ? 'Perfect Performance run. Save your progress to unlock the next stage.'
          : performanceModeEnabled
              ? 'A perfect Performance run is required to unlock the next stage.'
              : 'Wait mode is practice. Complete a perfect Performance run to advance.';
    } else if (!performanceModeEnabled) {
      xpMessage = context.l10n.sightReadingWaitModeNoXp;
    } else if (widget.challengeItemId == null) {
      xpMessage = context.l10n.sightReadingLessonNoXp;
    } else if (!isPerfect) {
      xpMessage = context.l10n.sightReadingNoXpImperfect;
    } else if (progressSaveFailed) {
      xpMessage = context.l10n.sightReadingProgressSaveFailed;
    } else if (completionResult?.newlyCompleted == true) {
      xpMessage = '+${completionResult!.xpAwarded} XP';
    } else {
      xpMessage = context.l10n.sightReadingAlreadyCompleted;
    }

    late final String title;
    late final String message;
    late final Color accentColor;
    late final IconData icon;

    if (widget.lesson != null && !performanceModeEnabled) {
      title = 'Wait practice complete';
      message = 'Switch to Performance mode when you are ready to pass this stage.';
      accentColor = Colors.blue.shade700;
      icon = Icons.hourglass_empty_rounded;
    } else if (retryIsRequired) {
      title = context.l10n.sightReadingRetryRequired;
      message = context.l10n.sightReadingRetryRequiredDescription;

      accentColor = Colors.red.shade700;
      icon = Icons.replay_circle_filled;
    } else if (isPerfect) {
      title = context.l10n.sightReadingPerfect;
      message = context.l10n.sightReadingPerfectDescription;

      accentColor = Colors.green.shade700;
      icon = Icons.check_circle;
    } else {
      title = context.l10n.sightReadingExerciseCompleted;
      message = performanceModeEnabled
          ? context.l10n.sightReadingCompletedWithMistakes(totalMistakes)
          : context.l10n.sightReadingWaitCompletedWithMistakes(totalMistakes);

      accentColor = Colors.amber.shade800;
      icon = Icons.warning_amber_rounded;
    }

    final colors = widget.colors;
    final resultStats = performanceModeEnabled
        ? <({String label, String value})>[
            (
              label: context.l10n.sightReadingCorrectOnTime,
              value:
                  '${performanceTracker.correctEventCount}/'
                  '${performanceTracker.totalEventCount}',
            ),
            (
              label: context.l10n.sightReadingWrongNotes,
              value: '${performanceTracker.wrongEventCount}',
            ),
            (
              label: context.l10n.sightReadingNotPlayed,
              value: '${performanceTracker.missedEventCount}',
            ),
            (
              label: context.l10n.sightReadingPlayedOnTime,
              value: '${performanceTracker.timingAccuracyPercentage}%',
            ),
            (
              label: context.l10n.sightReadingMusicLength,
              value: hasTargetDuration
                  ? formatDuration(targetDurationSeconds)
                  : context.l10n.unavailable,
            ),
          ]
        : <({String label, String value})>[
            (label: context.l10n.sightReadingFirstTry, value: scoreText),
            (
              label: context.l10n.sightReadingMistakes,
              value: '$totalMistakes',
            ),
            (
              label: context.l10n.sightReadingHintUsed,
              value: hintWasShown
                  ? context.l10n.sightReadingYes
                  : context.l10n.sightReadingNo,
            ),
            (
              label: context.l10n.sightReadingTime,
              value: context.l10n.sightReadingNoLimit,
            ),
          ];

    var activeResultSaveFuture = resultSaveFuture;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              backgroundColor: colors.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                side: BorderSide(color: colors.borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: accentColor,
                              size: AppIconSizes.lg,
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.sectionTitle,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  message,
                                  style: TextStyle(
                                    color: colors.secondaryTextColor,
                                    fontSize: AppTextSizes.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Column(
                            children: [
                              Text(
                                context.l10n.sightReadingScoreLabel,
                                style: TextStyle(
                                  color: colors.secondaryTextColor,
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                scoreText,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: AppTextSizes.display,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.md),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: resultStats
                            .map(
                              (stat) => buildResultStatTile(
                                colors: colors,
                                label: stat.label,
                                value: stat.value,
                              ),
                            )
                            .toList(),
                      ),
                      if (performanceReport != null) ...[
                        const Gap(AppSpacing.md),
                        buildPerformanceInsights(
                          colors: colors,
                          report: performanceReport,
                        ),
                        const Gap(AppSpacing.md),
                        buildResultSaveStatus(
                          colors: colors,
                          saveFuture: activeResultSaveFuture!,
                          onRetrySave: () {
                            setDialogState(() {
                              activeResultSaveFuture = practiceResultService
                                  .savePerformanceResult(performanceReport);
                            });
                          },
                          onViewResult: (resultId) {
                            Navigator.of(dialogContext).pop();
                            unawaited(
                              openPracticeResultFromSightReading(
                                result: performanceReport.summary.copyWith(
                                  id: resultId,
                                  completedAt: DateTime.now(),
                                ),
                                lessonPassed: widget.lesson == null
                                    ? null
                                    : lessonPassed,
                              ),
                            );
                          },
                        ),
                      ],
                      const Gap(AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              completionResult?.newlyCompleted == true
                                  ? Icons.bolt_rounded
                                  : Icons.info_outline_rounded,
                              color: accentColor,
                              size: AppIconSizes.sm,
                            ),
                            const Gap(AppSpacing.sm),
                            Flexible(
                              child: Text(
                                xpMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: AppTextSizes.label,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      SizedBox(
                        width: retryIsRequired ? 220 : 460,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  unawaited(retryExercise());
                                },
                                style: secondaryButtonStyle(colors),
                                icon: const Icon(Icons.replay_rounded),
                                label: Text(context.l10n.retry),
                              ),
                            ),
                            if (!retryIsRequired) ...[
                              const Gap(AppSpacing.sm),
                              Expanded(
                                child: FilledButton.icon(
                                  style: primaryButtonStyle(colors),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.of(context).pop(
                                      widget.lesson == null ? null : lessonPassed,
                                    );
                                  },
                                  icon: const Icon(Icons.check_rounded),
                                  label: Text(context.l10n.done),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> openPracticeResultFromSightReading({
    required PracticeResultSummary result,
    bool? lessonPassed,
  }) async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) {
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PracticeResultDetailScreen(result: result, colors: widget.colors),
        ),
      );
    } finally {
      if (mounted) {
        await SystemChrome.setPreferredOrientations(
          widget.lesson == null
              ? const [
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]
              : widget.restoreOrientations ??
                    const [
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ],
        );

        if (mounted) {
          if (widget.lesson != null) {
            Navigator.of(context).pop(lessonPassed);
          } else {
            await retryExercise();
          }
        }
      }
    }
  }

  Widget buildPerformanceInsights({
    required AppThemeColors colors,
    required SightReadingPerformanceReport report,
  }) {
    final attentionItems = buildAttentionItems(report);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: buildInsightPanel(
            colors: colors,
            icon: Icons.troubleshoot_rounded,
            title: context.l10n.sightReadingWhatToWorkOn,
            items: attentionItems,
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: buildInsightPanel(
            colors: colors,
            icon: Icons.lightbulb_outline_rounded,
            title: context.l10n.sightReadingHowToImprove,
            items: report.suggestions,
          ),
        ),
      ],
    );
  }

  Widget buildInsightPanel({
    required AppThemeColors colors,
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primaryColor, size: AppIconSizes.sm),
              const Gap(AppSpacing.xs),
              Text(
                title,
                style: TextStyle(
                  color: colors.primaryColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xs),
          ...items.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '• $item',
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.caption,
                  height: 1.25,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<String> buildAttentionItems(SightReadingPerformanceReport report) {
    if (report.errorEvents.isEmpty) {
      return [context.l10n.sightReadingNoRepeatedProblems];
    }

    final items = <String>[];
    final weakClef = report.summary.weakestClef;

    if (weakClef != null) {
      items.add(
        context.l10n.sightReadingClefDifficulty(
          friendlyClefDescription(weakClef.clef),
          weakClef.errorCount,
          weakClef.totalCount,
        ),
      );
    }

    final difficultNotes =
        report.summary.noteBreakdown
            .where((item) => item.errorCount > 0)
            .toList()
          ..sort(
            (first, second) => second.errorCount.compareTo(first.errorCount),
          );

    if (difficultNotes.isNotEmpty) {
      final note = difficultNotes.first;
      items.add(
        context.l10n.sightReadingTroubleWithNoteTimes(
          midiToNoteName(note.midiNote),
          note.errorCount,
        ),
      );
    }

    items.add(
      context.l10n.sightReadingWrongAndMissedGroups(
        report.summary.wrongCount,
        report.summary.missedCount,
      ),
    );
    return items.take(3).toList(growable: false);
  }

  Widget buildResultSaveStatus({
    required AppThemeColors colors,
    required Future<String> saveFuture,
    required VoidCallback onRetrySave,
    required ValueChanged<String> onViewResult,
  }) {
    return FutureBuilder<String>(
      future: saveFuture,
      builder: (context, snapshot) {
        final isSaving = snapshot.connectionState == ConnectionState.waiting;
        final isSaved = snapshot.hasData;
        final color = isSaved
            ? const Color(0xFF16A34A)
            : snapshot.hasError
            ? const Color(0xFFDC2626)
            : colors.secondaryTextColor;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              if (isSaving)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(
                  isSaved
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: color,
                  size: AppIconSizes.sm,
                ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  isSaving
                      ? context.l10n.sightReadingSavingResult
                      : isSaved
                      ? context.l10n.sightReadingResultSaved
                      : context.l10n.sightReadingResultNotSaved,
                  style: TextStyle(
                    color: color,
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (snapshot.hasError)
                TextButton(
                  onPressed: onRetrySave,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                  ),
                  child: Text(context.l10n.sightReadingRetrySave),
                ),
              if (snapshot.hasData)
                TextButton.icon(
                  onPressed: () => onViewResult(snapshot.data!),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primaryColor,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(context.l10n.sightReadingViewFullResult),
                ),
            ],
          ),
        );
      },
    );
  }

  String friendlyClefDescription(String clef) {
    switch (clef.toLowerCase()) {
      case 'treble':
        return context.l10n.sightReadingTrebleClefDescription;
      case 'bass':
        return context.l10n.sightReadingBassClefDescription;
      case 'unknown':
        return context.l10n.sightReadingUnknownClefDescription;
      default:
        if (clef.isEmpty) {
          return context.l10n.sightReadingUnknownClefDescription;
        }
        final name = '${clef[0].toUpperCase()}${clef.substring(1)}';
        return context.l10n.sightReadingOtherClefDescription(name);
    }
  }

  Widget buildResultStatTile({
    required AppThemeColors colors,
    required String label,
    required String value,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> retryExercise() async {
    await stopScorePreview();
    cancelPerformanceTimers();
    cancelWaitDurationTracking();
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
    await musicSheetController.loadScore(
      musicXml,
      preserveRestOnlyStaves: widget.source == SightReadingSource.composition,
    );
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

  void armPerformanceForFirstKey() {
    if (!performanceModeEnabled ||
        !performanceTracker.hasTimeline ||
        !midiStatus.startsWith('Connected:') ||
        performanceRunning ||
        performanceWaitingForFirstKey ||
        scorePreviewPreparing ||
        scorePreviewPlaying ||
        scoreCompleted) {
      return;
    }

    cancelPerformanceTimers();
    resetPlayingTimer();
    performanceTracker.resetAttempt();

    setState(() {
      performanceWaitingForFirstKey = true;
      performanceTracker.resultText = 'Press any MIDI key to begin';
    });
  }

  void beginPerformanceTimeline() {
    if (!mounted || !performanceModeEnabled) {
      return;
    }

    performanceRunId++;

    setState(() {
      performanceWaitingForFirstKey = false;
      performanceRunning = true;
      performanceFinishing = false;
      performanceCursorTargetIndex = 0;
      completedElapsedSeconds = null;
      performanceTracker.resultText = 'Play on time';
    });

    startPlayingTimer();
    queueNextPerformanceCursorSlide();

    performanceTicker = Timer.periodic(const Duration(milliseconds: 20), (
      timer,
    ) {
      updatePerformanceTimeline();
    });
  }

  void updatePerformanceTimeline() {
    if (!mounted || !performanceRunning || performanceFinishing) {
      return;
    }

    final timelineUpdate = performanceTracker.updateElapsedTime(
      playingStopwatch.elapsedMilliseconds,
    );

    if (timelineUpdate.cursorAdvances > 0) {
      queueNextPerformanceCursorSlide();
    } else if (timelineUpdate.stateChanged) {
      unawaited(
        musicSheetController.setCursorWrong(performanceTracker.cursorIsWrong),
      );
    }

    if (timelineUpdate.stateChanged) {
      setState(() {});
    }

    if (timelineUpdate.finished) {
      unawaited(finishPerformanceTimeline());
    }
  }

  void queueNextPerformanceCursorSlide() {
    final scheduledRunId = performanceRunId;

    cursorAdvanceQueue = cursorAdvanceQueue
        .then((value) async {
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
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Sight-reading cursor update failed: $error\n$stackTrace');
        });
  }

  Future<void> finishPerformanceTimeline() async {
    if (!mounted || !performanceRunning || performanceFinishing) {
      return;
    }

    performanceFinishing = true;
    performanceTicker?.cancel();
    performanceTicker = null;

    final finishingRunId = performanceRunId;

    try {
      await cursorAdvanceQueue;

      if (!mounted ||
          !performanceRunning ||
          finishingRunId != performanceRunId) {
        return;
      }

      while (performanceCursorTargetIndex <
          performanceTracker.cursorEventIndex) {
        await musicSheetController.advanceCursor();
        performanceCursorTargetIndex++;

        if (!mounted ||
            !performanceRunning ||
            finishingRunId != performanceRunId) {
          return;
        }
      }

      await musicSheetController.completePerformanceCursor();
    } catch (error, stackTrace) {
      debugPrint(
        'Final sight-reading cursor synchronization failed: '
        '$error\n$stackTrace',
      );
    }

    if (!mounted || !performanceRunning || finishingRunId != performanceRunId) {
      return;
    }

    performanceRunning = false;
    performanceFinishing = false;
    performanceRunId++;

    stopPlayingTimer();

    completedElapsedSeconds =
        (playingStopwatch.elapsedMilliseconds / Duration.millisecondsPerSecond)
            .ceil();

    setState(() {
      scoreCompleted = true;
    });

    final isPerfectPerformance =
        performanceTracker.totalEventCount > 0 &&
        performanceTracker.correctEventCount ==
            performanceTracker.totalEventCount &&
        performanceTracker.wrongEventCount == 0 &&
        performanceTracker.missedEventCount == 0;

    final challengeItemId = widget.challengeItemId;

    SightReadingCompletionResult? completionResult;
    var progressSaveFailed = false;

    if (isPerfectPerformance && challengeItemId != null) {
      try {
        completionResult = await progressService.recordPerfectCompletion(
          challengeItemId: challengeItemId,
          correctCount: performanceTracker.correctEventCount,
          wrongCount: performanceTracker.wrongEventCount,
          missedCount: performanceTracker.missedEventCount,
          totalCount: performanceTracker.totalEventCount,
        );
      } catch (error) {
        progressSaveFailed = true;
        debugPrint('Failed to save sight-reading progress: $error');
      }
    }

    if (!mounted) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final performanceReport = performanceTracker.buildReport(
      ownerId: user?.uid ?? '',
      scoreDocumentPath: widget.scoreDocumentPath,
      source: widget.source.name,
      pieceTitle: pieceTitle,
      elapsedDurationMs: playingStopwatch.elapsedMilliseconds,
      messages: SightReadingPerformanceReportMessages(
        perfectPerformance: context.l10n.sightReadingSuggestionPerfect,
        almostPerfect: context.l10n.sightReadingSuggestionAlmostPerfect,
        bassClef: context.l10n.sightReadingSuggestionBassClef,
        trebleClef: context.l10n.sightReadingSuggestionTrebleClef,
        otherClef: context.l10n.sightReadingSuggestionOtherClef,
        difficultNote: context.l10n.sightReadingSuggestionDifficultNote,
        releasedTooSoon: context.l10n.sightReadingSuggestionReleasedTooSoon,
        missedNotes: context.l10n.sightReadingSuggestionMissedNotes,
        playedLate: context.l10n.sightReadingSuggestionPlayedLate,
        playedEarly: context.l10n.sightReadingSuggestionPlayedEarly,
        chordTiming: context.l10n.sightReadingSuggestionChordTiming,
        generalPractice: context.l10n.sightReadingSuggestionGeneralPractice,
      ),
    );
    final resultSaveFuture = practiceResultService.savePerformanceResult(
      performanceReport,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showCompletionDialog(
        completionResult: completionResult,
        progressSaveFailed: progressSaveFailed,
        performanceReport: performanceReport,
        resultSaveFuture: resultSaveFuture,
      );
    });
  }

  void cancelPerformanceTimers() {
    performanceRunId++;
    performanceTicker?.cancel();
    performanceTicker = null;
    performanceWaitingForFirstKey = false;
    performanceRunning = false;
    performanceFinishing = false;
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
    midiNoteEventSubscription?.cancel();
    midiConnectionSubscription?.cancel();
    midiInputService.dispose();
    timerRefresh?.cancel();
    performanceTicker?.cancel();
    waitHoldTicker?.cancel();
    playingStopwatch.stop();
    unawaited(scoreAudioPlaybackService.dispose());
    SystemChrome.setPreferredOrientations(
      widget.restoreOrientations ?? (widget.lesson == null
          ? [DeviceOrientation.portraitUp]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]),
    );

    super.dispose();
  }
}
