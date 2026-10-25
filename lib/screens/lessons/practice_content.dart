import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/players/sight_reading/music_sheet_reading_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import 'lesson_localization.dart';
import 'models/practice_stage.dart';
import 'video_lesson_screen.dart';

/// Opens a stage's primary activity directly, falling back to its file list.
Future<bool> openPracticeStage(
  BuildContext context,
  PracticeStage stage,
  AppThemeColors colors,
) async {
  // A video is the primary activity when the stage contains one.
  final videoPaths = stage.assets
      .where((path) => path.toLowerCase().endsWith('.mp4'))
      .toList();
  if (videoPaths.isNotEmpty) {
    final quizPaths = stage.assets
        .where((path) => path.toLowerCase().endsWith('.txt'))
        .toList();
    final englishQuizPath = quizPaths.elementAtOrNull(0);
    final quizPath = englishQuizPath == null
        ? null
        : localizedQuizAssetPath(context, englishQuizPath);
    final pdfPath = stage.assets
        .where((path) => path.toLowerCase().endsWith('.pdf'))
        .firstOrNull;
    final videoPath = videoPaths.first;
    final videoName = localizedPracticeStageTitle(
      context.l10n,
      stage.number,
    );

    final passed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VideoLessonScreen(
          title: videoName,
          videoAssetPath: videoPath,
          restoreOrientations: const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          onViewPdf: pdfPath == null
              ? null
              : () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AssetContentScreen(
                        path: pdfPath,
                        title: context.l10n.lessonChordCheatSheet,
                        colors: colors,
                      ),
                    ),
                  );
                },
          onStartQuiz: quizPath == null
              ? null
              : () async {
                  final quizResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => AssetContentScreen(
                        path: quizPath,
                        title: context.l10n.lessonStageQuizTitle(stage.number),
                        colors: colors,
                      ),
                    ),
                  );
                  if (context.mounted && quizResult != null) {
                    Navigator.of(context).pop(quizResult);
                  }
                },
        ),
      ),
    );

    return passed == true;
  }

  // A MIDI and MusicXML pair opens the interactive sight-reading challenge.
  final midiPath = stage.assets
      .where(
        (path) => RegExp(r'\.(mid|midi)$', caseSensitive: false).hasMatch(path),
      )
      .firstOrNull;
  final scorePath = stage.assets
      .where(
        (path) => RegExp(
          r'\.(mxl|musicxml|xml)$',
          caseSensitive: false,
        ).hasMatch(path),
      )
      .firstOrNull;
  if (midiPath != null && scorePath != null) {
    final pdfPath = stage.assets
        .where((path) => path.toLowerCase().endsWith('.pdf'))
        .firstOrNull;
    final passed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MusicSheetReadingScreen.lesson(
          lesson: SightReadingLessonAssets(
            stageNumber: stage.number,
            title: stage.title,
            displayTitle: localizedPracticeStageTitle(
              context.l10n,
              stage.number,
            ),
            scoreAssetPath: scorePath,
            midiAssetPath: midiPath,
            pdfAssetPath: pdfPath,
          ),
          colors: colors,
          restoreOrientations: const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        ),
      ),
    );
    return passed == true;
  }

  // Stages without a recognized primary activity keep the regular contents view.
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StageContentsScreen(stage: stage, colors: colors),
    ),
  );
  return false;
}

enum PracticeStageStatus { completed, current, locked }

/// A stage in the lesson path, with progress read from the saved profile.
class PracticeStageCard extends StatelessWidget {
  const PracticeStageCard({
    super.key,
    required this.stage,
    required this.status,
    required this.horizontal,
    this.compact = false,
    required this.colors,
    required this.onTap,
  });

  final PracticeStage stage;
  final PracticeStageStatus status;
  final bool horizontal;
  final bool compact;
  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = status == PracticeStageStatus.current;
    final isLocked = status == PracticeStageStatus.locked;
    final isCompleted = status == PracticeStageStatus.completed;
    final foreground = isCurrent
        ? (colors.isDarkMode ? Colors.black : Colors.white)
        : isLocked
        ? colors.secondaryTextColor
        : colors.primaryColor;
    final statusColor = isCompleted ? colors.completedStageColor : foreground;
    final title = localizedPracticeStageShortTitle(context.l10n, stage.number);
    final activityType = practiceStageActivity(stage);
    final activity = localizedPracticeStageActivity(
      context.l10n,
      activityType,
    );
    final activityIcon = activityType == PracticeStageActivity.videoQuiz
        ? Icons.play_circle_outline_rounded
        : Icons.piano_rounded;
    final statusIcon = switch (status) {
      PracticeStageStatus.completed => Icons.check_circle_rounded,
      PracticeStageStatus.current => Icons.arrow_forward_rounded,
      PracticeStageStatus.locked => Icons.lock_rounded,
    };
    final statusText = switch (status) {
      PracticeStageStatus.completed => context.l10n.lessonCompleted,
      PracticeStageStatus.current => context.l10n.lessonCurrent,
      PracticeStageStatus.locked => context.l10n.lessonLocked,
    };
    final statusLabel = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor.withValues(alpha: .9),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final numberBadge = Container(
      width: compact ? 30 : 38,
      height: compact ? 30 : 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? foreground.withValues(alpha: .16)
            : isCompleted
            ? colors.completedStageColor.withValues(alpha: .13)
            : colors.primaryColor.withValues(alpha: isLocked ? .05 : .09),
      ),
      child: Text(
        '${stage.number}',
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 14 : 16,
        ),
      ),
    );
    final activityRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          activityIcon,
          size: 17,
          color: isCompleted
              ? colors.completedStageColor
              : foreground.withValues(alpha: .78),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              activity,
              style: TextStyle(
                color: foreground.withValues(alpha: .78),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
    final titleText = Text(
      title,
      style: TextStyle(
        color: foreground,
        fontSize: horizontal ? 15 : 16,
        fontWeight: FontWeight.w700,
        height: horizontal ? 1.1 : null,
      ),
    );

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: context.l10n.lessonStageSemantics(
        stage.number,
        title,
        activity,
        statusText,
      ),
      onTap: onTap,
      child: Material(
        color: isCurrent
            ? colors.primaryColor
            : isCompleted
            ? colors.completedStageSurfaceColor
            : colors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isCurrent
                ? colors.primaryColor
                : isCompleted
                ? colors.completedStageColor.withValues(alpha: .55)
                : colors.borderColor,
            width: isCurrent ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          excludeFromSemantics: true,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: horizontal ? (compact ? 118 : 140) : 112,
            ),
            child: SizedBox(
              width: horizontal ? 250 : null,
              height: horizontal ? (compact ? 118 : 140) : null,
              child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: compact ? 8 : horizontal ? 12 : 16,
              ),
                child: horizontal
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            numberBadge,
                            const Spacer(),
                            statusLabel,
                            const SizedBox(width: 5),
                            Icon(statusIcon, color: statusColor, size: 22),
                          ],
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: titleText,
                          ),
                        ),
                        SizedBox(height: compact ? 3 : 5),
                        activityRow,
                      ],
                    )
                  : Row(
                      children: [
                        numberBadge,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              titleText,
                              const SizedBox(height: 6),
                              activityRow,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 22),
                            const SizedBox(height: 2),
                            statusLabel,
                          ],
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lists a stage's files and combines MIDI, score, and optional PDF into one challenge.
class StageContentsScreen extends StatelessWidget {
  const StageContentsScreen({
    super.key,
    required this.stage,
    required this.colors,
  });

  final PracticeStage stage;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    // Find related sight-reading assets by extension, independent of filename casing.
    final midiPath = stage.assets
        .where(
          (path) =>
              RegExp(r'\.(mid|midi)$', caseSensitive: false).hasMatch(path),
        )
        .firstOrNull;
    final scorePath = stage.assets
        .where(
          (path) => RegExp(
            r'\.(mxl|musicxml|xml)$',
            caseSensitive: false,
          ).hasMatch(path),
        )
        .firstOrNull;
    final pdfPath = stage.assets
        .where((path) => path.toLowerCase().endsWith('.pdf'))
        .firstOrNull;
    // Pair quizzes with videos by their order in this stage's asset list.
    final videoPaths = stage.assets
        .where((path) => path.toLowerCase().endsWith('.mp4'))
        .toList();
    final quizPaths = stage.assets
        .where((path) => path.toLowerCase().endsWith('.txt'))
        .toList();
    final hasSightReadingBundle = midiPath != null && scorePath != null;
    final individualAssets = stage.assets.where((path) {
      // Quiz files are launched only from their matching video's Start Quiz button.
      if (path.toLowerCase().endsWith('.txt')) return false;
      if (hasSightReadingBundle &&
          (path == midiPath || path == scorePath || path == pdfPath)) {
        return false;
      }
      return true;
    });

    // Keep loose lesson files as individual tiles, but reserve a matched bundle for one challenge tile.
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.lessonStageLabel(stage.number)),
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            localizedPracticeStageTitle(context.l10n, stage.number),
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (hasSightReadingBundle)
            _SightReadingTile(
              stageNumber: stage.number,
              title: stage.title,
              displayTitle: localizedPracticeStageTitle(
                context.l10n,
                stage.number,
              ),
              midiPath: midiPath,
              scorePath: scorePath,
              pdfPath: pdfPath,
              colors: colors,
            ),
          ...individualAssets.map(
            (path) => _AssetTile(
              path: path,
              colors: colors,
              quizPath: videoPaths.contains(path)
                  ? quizPaths.elementAtOrNull(videoPaths.indexOf(path))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the existing sight-reading experience with this stage's local files.
class _SightReadingTile extends StatelessWidget {
  const _SightReadingTile({
    required this.stageNumber,
    required this.title,
    required this.displayTitle,
    required this.midiPath,
    required this.scorePath,
    required this.pdfPath,
    required this.colors,
  });

  final int stageNumber;
  final String title;
  final String displayTitle;
  final String midiPath;
  final String scorePath;
  final String? pdfPath;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    // Open the shared sight-reading player with the stage's bundled score.
    return Card(
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.piano, color: colors.primaryColor),
        title: Text(
          context.l10n.lessonSightReadingChallenge,
          style: TextStyle(color: colors.primaryColor),
        ),
        subtitle: Text(
          context.l10n.lessonSightReadingChallengeDescription,
          style: TextStyle(color: colors.secondaryTextColor),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.primaryColor),
        onTap: () => Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => MusicSheetReadingScreen.lesson(
              lesson: SightReadingLessonAssets(
                stageNumber: stageNumber,
                title: title,
                displayTitle: displayTitle,
                scoreAssetPath: scorePath,
                midiAssetPath: midiPath,
                pdfAssetPath: pdfPath,
              ),
              colors: colors,
              restoreOrientations: const [
                DeviceOrientation.portraitUp,
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents one non-bundled lesson asset and routes it to the matching viewer.
class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.path, required this.colors, this.quizPath});

  final String path;
  final AppThemeColors colors;
  final String? quizPath;

  @override
  Widget build(BuildContext context) {
    // Pick a recognizable icon and description based on the file extension.
    final fileName = path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    // Use the extension to identify the viewer, but keep it out of the UI label.
    final name = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final (icon, label) = switch (extension) {
      'mp4' => (Icons.play_circle, context.l10n.lessonVideoLesson),
      'txt' => (Icons.quiz_outlined, context.l10n.lessonQuestions),
      'pdf' => (Icons.picture_as_pdf_outlined, context.l10n.lessonSheetMusic),
      'mxl' => (
        Icons.music_note,
        context.l10n.lessonCompressedMusicXmlScore,
      ),
      'mid' ||
      'midi' ||
      'xml' ||
      'musicxml' => (Icons.music_note, context.l10n.lessonSightReadingScore),
      _ => (Icons.insert_drive_file_outlined, context.l10n.lessonFile),
    };

    return Card(
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: colors.primaryColor),
        title: Text(name, style: TextStyle(color: colors.primaryColor)),
        subtitle: Text(
          label,
          style: TextStyle(color: colors.secondaryTextColor),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.primaryColor),
        onTap: () => _openAsset(context, name),
      ),
    );
  }

  Future<void> _openAsset(BuildContext context, String name) async {
    // Videos use the app's existing player; restore stage orientation after it closes.
    if (path.toLowerCase().endsWith('.mp4')) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoLessonScreen(
            title: name,
            videoAssetPath: path,
            restoreOrientations: const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            onStartQuiz: quizPath == null
                ? null
                : () async {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => AssetContentScreen(
                          path: localizedQuizAssetPath(context, quizPath!),
                          title: context.l10n.lessonQuiz,
                          colors: colors,
                        ),
                      ),
                    );
                  },
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AssetContentScreen(path: path, title: name, colors: colors),
      ),
    );
  }
}

/// Loads and displays a local quiz or PDF lesson file.
class AssetContentScreen extends StatefulWidget {
  const AssetContentScreen({
    super.key,
    required this.path,
    required this.title,
    required this.colors,
  });

  final String path;
  final String title;
  final AppThemeColors colors;

  @override
  State<AssetContentScreen> createState() => _AssetContentScreenState();
}

/// Caches the asset loading futures so rebuilds do not restart file reads.
class _AssetContentScreenState extends State<AssetContentScreen> {
  late final Future<Uint8List> _bytes = rootBundle
      .load(widget.path)
      .then((data) => data.buffer.asUint8List());
  late final Future<String> _text = rootBundle.loadString(widget.path);

  @override
  Widget build(BuildContext context) {
    // Choose a viewer from the asset's extension and show loading/errors inline.
    final extension = widget.path.split('.').last.toLowerCase();
    return Scaffold(
      backgroundColor: widget.colors.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.colors.backgroundColor,
        foregroundColor: widget.colors.primaryColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: switch (extension) {
        'mp4' => _message(context.l10n.lessonOpenFromVideoPlayer),
        'txt' => FutureBuilder<String>(
          future: _text,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _message(context.l10n.lessonQuizLoadFailed);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return LessonQuizScreen(
              text: snapshot.data!,
              colors: widget.colors,
            );
          },
        ),
        'pdf' => FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _message(context.l10n.lessonPdfLoadFailed);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return PdfViewer.data(snapshot.data!, sourceName: widget.title);
          },
        ),
        _ => _message(
          context.l10n.lessonSightReadingFilesRequired,
        ),
      },
    );
  }

  // Uses a consistent centered message for unsupported or unreadable assets.
  Widget _message(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: widget.colors.primaryColor),
      ),
    ),
  );

}

/// Displays one question at a time from a stage's plain-text quiz file.
class LessonQuizScreen extends StatefulWidget {
  const LessonQuizScreen({
    super.key,
    required this.text,
    required this.colors,
  });

  final String text;
  final AppThemeColors colors;

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

/// Keeps answers hidden until the final quiz result is shown.
class _LessonQuizScreenState extends State<LessonQuizScreen> {
  int _questionIndex = 0;
  final Map<int, int> _answers = <int, int>{};

  late final List<_Question> questions = _parseQuestions(widget.text);

  @override
  Widget build(BuildContext context) {
    // Empty quiz files show a helpful message instead of a blank quiz card.
    if (questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.text.trim().isEmpty
                ? context.l10n.lessonFileEmpty
                : widget.text,
            style: TextStyle(color: widget.colors.primaryColor),
          ),
        ),
      );
    }
    // Render the active question and keep tall content scrollable on small screens.
    final question = questions[_questionIndex];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Card(
          color: widget.colors.surfaceColor,
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.lessonQuestionProgress(
                      _questionIndex + 1,
                      questions.length,
                    ),
                    style: TextStyle(color: widget.colors.secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.prompt,
                    style: TextStyle(
                      color: widget.colors.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Selection is neutral until the quiz is finished.
                  ...List.generate(question.options.length, (index) {
                    final selected = _answers[_questionIndex] == index;
                    return Card(
                      color: selected
                          ? widget.colors.backgroundColor
                          : widget.colors.surfaceColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: selected
                              ? widget.colors.primaryColor
                              : widget.colors.borderColor,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: widget.colors.primaryColor,
                        ),
                        title: Text(
                          question.options[index],
                          style: TextStyle(color: widget.colors.primaryColor),
                        ),
                        onTap: () => setState(
                          () => _answers[_questionIndex] = index,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final previousButton = OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.colors.primaryColor,
                          backgroundColor: widget.colors.surfaceColor,
                          side: BorderSide(
                            color: widget.colors.primaryColor.withValues(
                              alpha: 0.45,
                            ),
                          ),
                          minimumSize: const Size(0, 48),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => setState(() => _questionIndex--),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(context.l10n.previous),
                      );
                      final nextButton = FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.colors.primaryColor,
                          foregroundColor: widget.colors.isDarkMode
                              ? Colors.black
                              : Colors.white,
                          disabledBackgroundColor: widget.colors.borderColor,
                          disabledForegroundColor:
                              widget.colors.secondaryTextColor,
                          minimumSize: const Size(0, 48),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _answers.containsKey(_questionIndex)
                            ? _handleAnswerButton
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _questionIndex == questions.length - 1
                                  ? context.l10n.finish
                                  : context.l10n.next,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _questionIndex == questions.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      );

                      if (constraints.maxWidth < 320) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_questionIndex > 0) ...[
                              previousButton,
                              const SizedBox(height: 10),
                            ],
                            nextButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          if (_questionIndex > 0) ...[
                            Expanded(child: previousButton),
                            const SizedBox(width: 12),
                          ],
                          Expanded(child: nextButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Advance without feedback; reveal the score only after the last answer.
  Future<void> _handleAnswerButton() async {
    if (_questionIndex < questions.length - 1) {
      setState(() => _questionIndex++);
      return;
    }

    final correctAnswers = List<int>.generate(questions.length, (index) => index)
        .where((index) => _answers[index] == questions[index].answer)
        .length;
    final passed = correctAnswers == questions.length;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        backgroundColor: widget.colors.surfaceColor,
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Text(
          context.l10n.lessonQuizComplete,
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.lessonQuizScore(
                correctAnswers,
                questions.length,
              ),
              style: TextStyle(
                color: widget.colors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              passed
                  ? context.l10n.lessonQuizPerfect
                  : context.l10n.lessonQuizRetryGuidance,
              style: TextStyle(color: widget.colors.secondaryTextColor),
            ),
            const Divider(),
            ...List<Widget>.generate(questions.length, _buildResultItem),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.retry,
              style: TextStyle(color: widget.colors.primaryColor),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.colors.primaryColor,
              foregroundColor: widget.colors.isDarkMode
                  ? Colors.black
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              passed ? context.l10n.finish : context.l10n.lessonBackToStages,
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (retry == true) {
      setState(() {
        _shuffleQuestionsForRetry();
        _questionIndex = 0;
        _answers.clear();
      });
    } else if (retry == false) {
      Navigator.of(context).pop(passed);
    }
  }

  void _shuffleQuestionsForRetry() {
    if (questions.length < 2) return;
    final previousOrder = List<_Question>.of(questions);
    questions.shuffle();
    final sameOrder = List<int>.generate(questions.length, (index) => index)
        .every((index) => identical(questions[index], previousOrder[index]));
    if (sameOrder) {
      questions.add(questions.removeAt(0));
    }
  }

  Widget _buildResultItem(int index) {
    final question = questions[index];
    final selected = _answers[index];
    final correct = selected == question.answer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.prompt}',
            style: TextStyle(
              color: widget.colors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            context.l10n.lessonYourAnswer(
              selected == null
                  ? context.l10n.lessonNoAnswer
                  : question.options[selected],
            ),
            style: TextStyle(color: correct ? Colors.green : Colors.red),
          ),
          if (!correct)
            Text(
              context.l10n.lessonCorrectAnswer(
                question.options[question.answer],
              ),
              style: const TextStyle(color: Colors.green),
            ),
        ],
      ),
    );
  }
}

/// Parsed question data: prompt, answer choices, and the correct choice index.
class _Question {
  const _Question(this.prompt, this.options, this.answer);
  final String prompt;
  final List<String> options;
  final int answer;
}

/// Parses a text quiz with question lines, A-D choices, and marked answers.
List<_Question> _parseQuestions(String source) {
  final result = <_Question>[];
  String? prompt;
  final options = <String>[];
  int? answer;
  var questionStarted = false;
  var invalid = false;

  // Save a complete question and reset the parser for the next one.
  void finish() {
    if (questionStarted) {
      if (prompt == null ||
          prompt!.isEmpty ||
          options.length < 2 ||
          answer == null ||
          answer! >= options.length) {
        invalid = true;
      } else {
        result.add(_Question(prompt!, List<String>.from(options), answer!));
      }
    }
    prompt = null;
    options.clear();
    answer = null;
    questionStarted = false;
  }

  // Accepts `Q1:`, `?`, `A)`, `A:`, `*A)` and `Answer: B` style lines.
  for (final raw in source.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    final questionMatch = RegExp(
      r'^(?:Q(?:uestion)?\s*\d*\s*[:.)-]|\?)\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (questionMatch != null) {
      finish();
      questionStarted = true;
      prompt = questionMatch.group(1)!.trim();
      continue;
    }
    final optionMatch = RegExp(
      r'^(\*\s*)?([A-D])\s*[).:-]\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (optionMatch != null) {
      if (!questionStarted) {
        invalid = true;
        continue;
      }
      options.add(optionMatch.group(3)!.trim());
      if (optionMatch.group(1) != null) answer = options.length - 1;
      continue;
    }
    final answerMatch = RegExp(
      r'^(?:Answer|Correct)\s*:\s*([A-D])',
      caseSensitive: false,
    ).firstMatch(line);
    if (answerMatch != null) {
      answer = answerMatch.group(1)!.toUpperCase().codeUnitAt(0) - 65;
      continue;
    }
    prompt ??= line;
  }
  finish();
  return invalid ? const [] : result;
}

