import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'music_sheet_html.dart';

class MusicSheetWebViewController {
  MusicSheetWebViewController({
    required ValueChanged<Set<int>> onExpectedNotesChanged,
    required ValueChanged<int> onTotalPositionsChanged,
    required VoidCallback onScoreRendered,
    required ValueChanged<String> onScoreRenderFailed,
    required VoidCallback onScoreCompleted,
  }) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ExpectedNotes',
        onMessageReceived: (message) {
          final decodedNotes = jsonDecode(message.message) as List<dynamic>;
          final midiNotes = <int>{};

          for (final note in decodedNotes) {
            final noteData = note as Map<String, dynamic>;
            midiNotes.add(noteData['midi'] as int);
          }

          onExpectedNotesChanged(midiNotes);
        },
      )
      ..addJavaScriptChannel(
        'ScoreTotal',
        onMessageReceived: (message) {
          final totalPositions = int.tryParse(message.message);

          if (totalPositions != null) {
            onTotalPositionsChanged(totalPositions);
          }
        },
      )
      ..addJavaScriptChannel(
        'ScoreRendered',
        onMessageReceived: (_) {
          onScoreRendered();
        },
      )
      ..addJavaScriptChannel(
        'ScoreRenderFailed',
        onMessageReceived: (message) {
          onScoreRenderFailed(message.message);
        },
      )
      ..addJavaScriptChannel(
        'ScoreCompleted',
        onMessageReceived: (_) {
          onScoreCompleted();
        },
      )
      ..loadHtmlString(buildOsmdLoadingHtml());
  }

  late final WebViewController _webViewController;

  WebViewController get webViewController => _webViewController;

  Future<void> loadScore(String musicXml) {
    return _webViewController.loadHtmlString(buildMusicSheetHtml(musicXml));
  }

  Future<void> showMessage(String message) {
    final escapedMessage = const HtmlEscape(
      HtmlEscapeMode.element,
    ).convert(message);

    return _webViewController.loadHtmlString('<h2>$escapedMessage</h2>');
  }

  Future<void> advanceCursor() {
    return _webViewController.runJavaScript('advanceCursor();');
  }

  Future<void> slideCursorToNextNote(Duration duration) {
    final durationMilliseconds = duration.inMilliseconds;

    return _webViewController.runJavaScript(
      'slideCursorToNextNote($durationMilliseconds);',
    );
  }

  Future<void> hideCursor() {
    return _webViewController.runJavaScript('hideCursorForCompletion();');
  }

  Future<void> setCursorWrong(bool isWrong) {
    final color = isWrong ? '#e53935' : '#33e02f';
    final encodedColor = jsonEncode(color);

    return _webViewController.runJavaScript('''
      if (typeof setCursorColor === "function") {
        setCursorColor($encodedColor);
      }
    ''');
  }
}

class MusicSheetWebView extends StatelessWidget {
  const MusicSheetWebView({super.key, required this.controller});

  final MusicSheetWebViewController controller;

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller.webViewController);
  }
}
