import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/screens/challenges/sight_reading/music_sheet_html.dart';
import 'package:soundsight/screens/practice/screens/video_lesson_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'local_sight_reading_screen.dart';

/// Data for one stage; definitions live in `stages/stage_#.dart` files.
class PracticeStage {
  const PracticeStage({
    required this.number,
    required this.title,
    required this.description,
    required this.assets,
    this.unlockedForTesting = false,
    this.performanceMode = false,
    this.circleText,
    this.circleContent,
  });

  final int number;
  final String title;
  final String description;
  final List<String> assets;

  /// Set true in this stage file to bypass progression while testing it.
  final bool unlockedForTesting;

  /// Run local sight reading against the MIDI timeline when this is enabled.
  final bool performanceMode;

  /// Text shown inside the stage circle. Defaults to `Stage <number>`.
  final String? circleText;

  /// Optional custom widget shown instead of [circleText].
  final Widget? circleContent;
}

/// Opens a stage's primary activity directly, falling back to its file list.
Future<void> openPracticeStage(
  BuildContext context,
  PracticeStage stage,
  AppThemeColors colors, {
  required VoidCallback onFinished,
}) async {
  // A video is the primary activity when the stage contains one.
  final videoPaths = stage.assets
      .where((path) => path.toLowerCase().endsWith('.mp4'))
      .toList();
  if (videoPaths.isNotEmpty) {
    // Keep a handle to this stage map so Finish can return past the video route.
    final stageMapRoute = ModalRoute.of(context);
    final quizPaths = stage.assets
        .where((path) => path.toLowerCase().endsWith('.txt'))
        .toList();
    final quizPath = quizPaths.elementAtOrNull(0);
    final pdfPath = stage.assets
        .where((path) => path.toLowerCase().endsWith('.pdf'))
        .firstOrNull;
    final videoPath = videoPaths.first;
    final videoName = _assetNameWithoutExtension(videoPath);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoLessonScreen(
          title: videoName,
          videoAssetPath: videoPath,
          onViewPdf: pdfPath == null
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AssetContentScreen(
                        path: pdfPath,
                        title: _assetNameWithoutExtension(pdfPath),
                        colors: colors,
                      ),
                    ),
                  );
                },
          onStartQuiz: quizPath == null
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AssetContentScreen(
                        path: quizPath,
                        title: _assetNameWithoutExtension(quizPath),
                        colors: colors,
                        onFinish: () {
                          onFinished();
                          final navigator = Navigator.of(context);
                          if (stageMapRoute == null) {
                            navigator.pop();
                          } else {
                            navigator.popUntil(
                              (route) => identical(route, stageMapRoute),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
        ),
      ),
    );

    // The existing video route requests portrait when it is disposed.
    const landscape = <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
    for (final delay in <int>[0, 200, 500, 900]) {
      if (delay > 0) {
        await Future<void>.delayed(Duration(milliseconds: delay));
      }
      await SystemChrome.setPreferredOrientations(landscape);
    }
    return;
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalSightReadingScreen(
          scoreAssetPath: scorePath,
          midiAssetPath: midiPath,
          pdfAssetPath: pdfPath,
          colors: colors,
          onFinish: onFinished,
          performanceMode: stage.performanceMode,
        ),
      ),
    );
    return;
  }

  // Stages without a recognized primary activity keep the regular contents view.
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StageContentsScreen(stage: stage, colors: colors),
    ),
  );
}

// Removes the file extension for video and quiz screen titles.
String _assetNameWithoutExtension(String path) {
  final name = path.split('/').last;
  final extensionIndex = name.lastIndexOf('.');
  return extensionIndex < 0 ? name : name.substring(0, extensionIndex);
}

/// Draws a selectable stage circle and its custom text or widget.
class StageCircle extends StatelessWidget {
  const StageCircle({
    super.key,
    required this.stage,
    required this.diameter,
    required this.selected,
    this.locked = false,
    required this.colors,
    required this.onTap,
  });

  final PracticeStage stage;
  final double diameter;
  final bool selected;
  final bool locked;
  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected circles use the theme's primary color; other circles use its surface.
    final isSelected = selected && !locked;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        label: locked
            ? 'Stage ${stage.number}, locked'
            : 'Stage ${stage.number}${isSelected ? ', selected' : ''}',
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: locked
                ? Color.lerp(
                    colors.surfaceColor,
                    colors.isDarkMode ? Colors.black : Colors.grey,
                    colors.isDarkMode ? .40 : .48,
                  )
                : isSelected
                ? colors.primaryColor
                : colors.surfaceColor,
            border: Border.all(
              color: locked
                  ? colors.borderColor.withValues(alpha: .85)
                  : isSelected
                  ? colors.primaryColor
                  : colors.borderColor,
              width: locked
                  ? 1.5
                  : isSelected
                  ? 2
                  : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primaryColor.withValues(alpha: .12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(color: _foregroundColor),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: _foregroundColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: locked ? 8 : 0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child:
                              stage.circleContent ??
                              Text(stage.circleText ?? 'Stage ${stage.number}'),
                        ),
                      ),
                    ),
                  ),
                  if (locked)
                    Icon(
                      Icons.lock_rounded,
                      size: diameter * .38,
                      color: colors.isDarkMode
                          ? Colors.white70.withValues(alpha: .78)
                          : Colors.black54.withValues(alpha: .78),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _foregroundColor => locked
      ? colors.secondaryTextColor.withValues(alpha: .46)
      : selected
      ? (colors.isDarkMode ? Colors.black : Colors.white)
      : colors.primaryColor;
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
        title: Text('Stage ${stage.number}'),
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            stage.title,
            style: TextStyle(
              color: colors.primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (hasSightReadingBundle)
            _SightReadingTile(
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
    required this.midiPath,
    required this.scorePath,
    required this.pdfPath,
    required this.colors,
  });

  final String midiPath;
  final String scorePath;
  final String? pdfPath;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    // The local adapter reuses the challenge's piano connection and note matching.
    return Card(
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.piano, color: colors.primaryColor),
        title: Text(
          'Sight Reading Challenge',
          style: TextStyle(color: colors.primaryColor),
        ),
        subtitle: Text(
          'Connect your piano and play the score',
          style: TextStyle(color: colors.secondaryTextColor),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.primaryColor),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LocalSightReadingScreen(
              scoreAssetPath: scorePath,
              midiAssetPath: midiPath,
              pdfAssetPath: pdfPath,
              colors: colors,
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
      'mp4' => (Icons.play_circle, 'Video lesson'),
      'txt' => (Icons.quiz_outlined, 'Lesson questions'),
      'pdf' => (Icons.picture_as_pdf_outlined, 'Sheet music'),
      'mxl' => (Icons.music_note, 'Compressed MusicXML score'),
      'mid' ||
      'midi' ||
      'xml' ||
      'musicxml' => (Icons.music_note, 'Sight reading score'),
      _ => (Icons.insert_drive_file_outlined, 'Lesson file'),
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
            onStartQuiz: quizPath == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AssetContentScreen(
                          path: quizPath!,
                          title: quizPath!.split('/').last.split('.').first,
                          colors: colors,
                        ),
                      ),
                    );
                  },
          ),
        ),
      );
      // The existing video screen requests portrait while disposing. Reapply
      // landscape as its route finishes closing so that request cannot leave
      // the practice screen in portrait.
      const landscape = <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
      for (final delay in <int>[0, 200, 500, 900]) {
        if (delay > 0) {
          await Future<void>.delayed(Duration(milliseconds: delay));
        }
        await SystemChrome.setPreferredOrientations(landscape);
      }
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

/// Loads and displays a local quiz, PDF, or MusicXML lesson file.
class AssetContentScreen extends StatefulWidget {
  const AssetContentScreen({
    super.key,
    required this.path,
    required this.title,
    required this.colors,
    this.onFinish,
  });

  final String path;
  final String title;
  final AppThemeColors colors;
  final VoidCallback? onFinish;

  @override
  State<AssetContentScreen> createState() => _AssetContentScreenState();
}

/// Caches the asset loading futures so rebuilds do not restart file reads.
class _AssetContentScreenState extends State<AssetContentScreen> {
  late final Future<Uint8List> _bytes = rootBundle
      .load(widget.path)
      .then((data) => data.buffer.asUint8List());
  late final Future<String> _text = rootBundle.loadString(widget.path);
  late final Future<String> _mxlXml = _loadMxl(widget.path);
  late final Future<String> _midiScore = _loadMxl(
    widget.path.replaceFirst(
      RegExp(r'\.(mid|midi)$', caseSensitive: false),
      '.mxl',
    ),
  );

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
        'mp4' => _message('Open this lesson from the video player.'),
        'txt' => FutureBuilder<String>(
          future: _text,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _message('Could not load this test: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return LessonQuizScreen(
              text: snapshot.data!,
              colors: widget.colors,
              onFinish: widget.onFinish,
            );
          },
        ),
        'pdf' => FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _message('Could not load this PDF: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return PdfViewer.data(snapshot.data!, sourceName: widget.title);
          },
        ),
        'xml' || 'musicxml' => FutureBuilder<String>(
          future: _text,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _message('Could not load this score: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return MusicXmlView(xml: snapshot.data!);
          },
        ),
        'mxl' => _scoreBody(_mxlXml),
        'mid' || 'midi' => _scoreBody(_midiScore),
        _ => _message(
          'This file type is not supported in the practice viewer.',
        ),
      },
    );
  }

  // Displays MusicXML extracted from either an MXL archive or a paired MIDI asset.
  Widget _scoreBody(Future<String> xmlFuture) => FutureBuilder<String>(
    future: xmlFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _message(
          'Could not find a MusicXML score for this file. Add a matching .mxl file or PDF to the stage folder.',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return MusicXmlView(xml: snapshot.data!);
    },
  );

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

  Future<String> _loadMxl(String path) async {
    // MXL is a ZIP container; extract its score XML while skipping container metadata.
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
      throw const FormatException('No MusicXML document in MXL file.');
    }
    return utf8.decode(scoreFile.content as List<int>);
  }
}

/// Displays one question at a time from a stage's plain-text quiz file.
class LessonQuizScreen extends StatefulWidget {
  const LessonQuizScreen({
    super.key,
    required this.text,
    required this.colors,
    this.onFinish,
  });

  final String text;
  final AppThemeColors colors;
  final VoidCallback? onFinish;

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

/// Tracks the current question, chosen option, and submitted feedback state.
class _LessonQuizScreenState extends State<LessonQuizScreen> {
  int _questionIndex = 0;
  int? _selected;
  int _correctAnswers = 0;
  bool _submitted = false;

  List<_Question> get questions => _parseQuestions(widget.text);

  @override
  Widget build(BuildContext context) {
    // Empty quiz files show a helpful message instead of a blank quiz card.
    if (questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.text.trim().isEmpty
                ? 'This lesson file is empty.'
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
                    'Question ${_questionIndex + 1} of ${questions.length}',
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
                  // After checking, highlight both the correct option and a wrong selection.
                  ...List.generate(question.options.length, (index) {
                    final selected = _selected == index;
                    final isCorrect = index == question.answer;
                    final showCorrect = _submitted && isCorrect;
                    final showWrong = _submitted && selected && !isCorrect;
                    final resultColor = showCorrect
                        ? Colors.green
                        : showWrong
                        ? Colors.red
                        : widget.colors.borderColor;
                    return Card(
                      color: showCorrect
                          ? Colors.green.withValues(alpha: .12)
                          : showWrong
                          ? Colors.red.withValues(alpha: .12)
                          : selected
                          ? widget.colors.backgroundColor
                          : widget.colors.surfaceColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: showCorrect || showWrong
                              ? resultColor
                              : widget.colors.borderColor,
                          width: showCorrect || showWrong ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        enabled: !_submitted,
                        leading: Icon(
                          showCorrect
                              ? Icons.check_circle
                              : showWrong
                              ? Icons.cancel
                              : selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: showCorrect || showWrong
                              ? resultColor
                              : widget.colors.primaryColor,
                        ),
                        title: Text(
                          question.options[index],
                          style: TextStyle(color: widget.colors.primaryColor),
                        ),
                        onTap: _submitted
                            ? null
                            : () => setState(() => _selected = index),
                      ),
                    );
                  }),
                  // Feedback includes the right answer when the submitted choice is wrong.
                  if (_submitted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _selected == question.answer
                            ? 'Correct!'
                            : 'Incorrect. The correct answer is '
                                  '${question.options[question.answer]}',
                        style: TextStyle(
                          color: _selected == question.answer
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Check submits an answer; Next advances or shows the final score.
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.colors.primaryColor,
                        foregroundColor: widget.colors.surfaceColor,
                      ),
                      onPressed: _selected == null ? null : _handleAnswerButton,
                      child: Text(_submitted ? 'Next' : 'Check'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Records the answer, moves to the next question, or shows the final score.
  Future<void> _handleAnswerButton() async {
    if (!_submitted) {
      setState(() {
        _submitted = true;
        if (_selected == questions[_questionIndex].answer) {
          _correctAnswers++;
        }
      });
      return;
    }

    if (_questionIndex < questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selected = null;
        _submitted = false;
      });
      return;
    }

    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          'Quiz complete',
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          'Your score: $_correctAnswers/${questions.length}',
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

    if (!mounted) return;
    if (retry == true) {
      setState(() {
        _questionIndex = 0;
        _selected = null;
        _correctAnswers = 0;
        _submitted = false;
      });
    } else if (retry == false) {
      if (widget.onFinish != null) {
        widget.onFinish!();
      } else {
        Navigator.of(context).pop();
      }
    }
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
  var answer = 0;

  // Save a complete question and reset the parser for the next one.
  void finish() {
    if (prompt != null && options.isNotEmpty) {
      result.add(
        _Question(
          prompt!,
          List<String>.from(options),
          answer.clamp(0, options.length - 1),
        ),
      );
    }
    prompt = null;
    options.clear();
    answer = 0;
  }

  // Accepts `Q1:`, `?`, `A)`, `A:`, `*A)` and `Answer: B` style lines.
  for (final raw in source.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final questionMatch = RegExp(
      r'^(?:Q(?:uestion)?\s*\d*\s*[:.)-]|\?)\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (questionMatch != null) {
      finish();
      prompt = questionMatch.group(1)!.trim();
      continue;
    }
    final optionMatch = RegExp(
      r'^(\*\s*)?([A-D])\s*[).:-]\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (optionMatch != null) {
      prompt ??= 'Choose the correct answer';
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
  return result;
}

/// Displays MusicXML through the same sheet-rendering HTML used by challenges.
class MusicXmlView extends StatefulWidget {
  const MusicXmlView({super.key, required this.xml});

  final String xml;

  @override
  State<MusicXmlView> createState() => _MusicXmlViewState();
}

/// Holds the WebView controller for the rendered score.
class _MusicXmlViewState extends State<MusicXmlView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(buildMusicSheetHtml(widget.xml));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
