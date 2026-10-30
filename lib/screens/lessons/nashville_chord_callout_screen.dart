import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/screens/midi/services/midi_input_service.dart';
import 'package:soundsight/screens/midi/utils/midi_note_converter.dart';
import 'package:soundsight/screens/players/sight_reading/midi_file_duration_calculator.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Checks the user's piano chord against each ordered Nashville callout.
class NashvilleChordCalloutScreen extends StatefulWidget {
  const NashvilleChordCalloutScreen({
    super.key,
    required this.title,
    required this.midiAssetPath,
    required this.calloutAssetPath,
    required this.colors,
  });

  final String title;
  final String midiAssetPath;
  final String calloutAssetPath;
  final AppThemeColors colors;

  @override
  State<NashvilleChordCalloutScreen> createState() =>
      _NashvilleChordCalloutScreenState();
}

class _NashvilleChordCalloutScreenState
    extends State<NashvilleChordCalloutScreen> {
  final _midiInput = MidiInputService();
  StreamSubscription<Set<int>>? _notesSubscription;
  late final Future<void> _loadFuture;

  List<_ChordCallout> _callouts = const [];
  List<Set<int>> _midiChords = const [];
  Set<int> _activeNotes = const {};
  int _currentIndex = 0;
  String _connectionStatus = 'Connect your piano';
  String _feedback = 'Loading chord sequence…';
  String? _loadError;
  bool _currentChordMatched = false;
  bool _completed = false;
  bool _resultDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _notesSubscription = _midiInput.activeNotesStream.listen(_onNotesChanged);
    _loadFuture = _loadSequence();
  }

  Future<void> _loadSequence() async {
    try {
      final text = await rootBundle.loadString(widget.calloutAssetPath);
      final midiData = await rootBundle.load(widget.midiAssetPath);
      final midiResult = MidiFileDurationCalculator.calculate(
        midiData.buffer.asUint8List(),
      );
      if (midiResult.unavailableReason != null) {
        throw FormatException(midiResult.unavailableReason!);
      }

      final callouts = _parseCallouts(text);
      final chords = midiResult.timelineEvents
          .map((event) => event.midiNotes)
          .toList(growable: false);
      if (callouts.length != chords.length) {
        throw FormatException(
          'The text has ${callouts.length} callouts, but the MIDI has '
          '${chords.length} chord events. Each callout must match one MIDI chord.',
        );
      }
      if (!mounted) return;
      setState(() {
        _callouts = callouts;
        _midiChords = chords;
        _feedback = 'Connect your piano, then play the first chord.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load the chord test: $error');
    }
  }

  List<_ChordCallout> _parseCallouts(String text) {
    final callouts = <_ChordCallout>[];
    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = RegExp(r'^(\d+)\)\s*(.+)$').firstMatch(line);
      if (match == null) {
        throw FormatException('Invalid chord callout line: "$line"');
      }
      final index = int.parse(match.group(1)!);
      if (index != callouts.length) {
        throw FormatException(
          'Expected callout ${callouts.length}, but found $index.',
        );
      }
      callouts.add(_ChordCallout(index, match.group(2)!.trim()));
    }
    if (callouts.isEmpty) {
      throw const FormatException('The chord callout text file is empty.');
    }
    return callouts;
  }

  void _onNotesChanged(Set<int> notes) {
    if (!mounted || _completed || _loadError != null || _midiChords.isEmpty) {
      return;
    }
    final active = Set<int>.from(notes);
    if (_currentChordMatched) {
      if (active.isEmpty) _advanceCallout();
      setState(() => _activeNotes = active);
      return;
    }

    final expected = _midiChords[_currentIndex];
    final matches =
        active.length == expected.length && active.containsAll(expected);
    setState(() {
      _activeNotes = active;
      if (matches) {
        _currentChordMatched = true;
        _feedback = 'Correct. Release the keys for the next callout.';
      } else if (active.isNotEmpty &&
          (active.length >= expected.length ||
              active.any((note) => !expected.contains(note)))) {
        _feedback = 'That chord does not match. Try again.';
      } else {
        _feedback = 'Play the called-out chord.';
      }
    });
  }

  void _advanceCallout() {
    if (_currentIndex == _callouts.length - 1) {
      setState(() {
        _completed = true;
        _feedback = 'Chord sequence complete';
      });
      unawaited(_showResultDialog());
      return;
    }
    setState(() {
      _currentIndex++;
      _currentChordMatched = false;
      _feedback = 'Next chord';
    });
  }

  Future<void> _connectPiano() async {
    setState(() => _connectionStatus = 'Searching for a piano…');
    try {
      final devices = await _midiInput.getDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() => _connectionStatus = 'No MIDI piano found');
        return;
      }
      await _midiInput.connectToDevice(devices.first);
      if (mounted) {
        setState(() => _connectionStatus = 'Connected: ${devices.first.name}');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _connectionStatus = 'Connection failed: $error');
      }
    }
  }

  Future<void> _showResultDialog() async {
    if (!mounted || _resultDialogShowing) return;
    _resultDialogShowing = true;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          'Chord test complete',
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Text(
          'Chords played: ${_callouts.length}/${_callouts.length}',
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
      setState(() {
        _currentIndex = 0;
        _currentChordMatched = false;
        _completed = false;
        _activeNotes = const {};
        _feedback = 'Play the first chord.';
      });
    } else if (retry == false) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _midiInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final playedNotes = _activeNotes.isEmpty
        ? 'None'
        : (_activeNotes.toList()..sort()).map(midiToNoteName).join(' + ');

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.primaryColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: colors.primaryColor),
            );
          }
          if (_loadError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.primaryColor),
                ),
              ),
            );
          }

          final callout = _callouts[_currentIndex];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Chord ${callout.index} of ${_callouts.length - 1}',
                  style: TextStyle(color: colors.secondaryTextColor),
                ),
                const SizedBox(height: 14),
                Card(
                  color: colors.surfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: Text(
                      callout.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _feedback,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.secondaryTextColor),
                ),
                const SizedBox(height: 24),
                Text(
                  'Piano: $_connectionStatus\nPlayed: $playedNotes',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.primaryColor),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _connectPiano,
                  icon: const Icon(Icons.usb),
                  label: const Text('Connect Piano'),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value:
                      (_currentIndex + (_currentChordMatched ? 1 : 0)) /
                      _callouts.length,
                  color: colors.primaryColor,
                  backgroundColor: colors.borderColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChordCallout {
  const _ChordCallout(this.index, this.label);

  final int index;
  final String label;
}
