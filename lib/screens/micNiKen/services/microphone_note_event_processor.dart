import 'dart:async';

import '../models/microphone_input_state.dart';
import '../models/microphone_note_event.dart';

/// Converts accepted microphone detections into stable note and state streams.
///
/// Audio capture and pitch recognition will feed this service in later steps.
/// It does not depend on the MIDI feature or modify MIDI behavior.
class MicrophoneNoteEventProcessor {
  final Set<int> _activeNotes = <int>{};
  final StreamController<MicrophoneNoteEvent> _noteEvents =
      StreamController<MicrophoneNoteEvent>.broadcast();
  final StreamController<int> _noteAttacks = StreamController<int>.broadcast();
  final StreamController<Set<int>> _activeNoteSnapshots =
      StreamController<Set<int>>.broadcast();
  final StreamController<MicrophoneInputState> _states =
      StreamController<MicrophoneInputState>.broadcast();
  final StreamController<MicrophoneSignalQuality> _signalQualities =
      StreamController<MicrophoneSignalQuality>.broadcast();

  MicrophoneInputState _state = MicrophoneInputState.stopped;
  MicrophoneSignalQuality _signalQuality = MicrophoneSignalQuality.unknown;
  bool _isDisposed = false;

  /// Returns a detached, immutable snapshot of acoustically active pitches.
  Set<int> get activeNotes => Set<int>.unmodifiable(_activeNotes);

  /// Returns the most recently reported microphone lifecycle state.
  MicrophoneInputState get state => _state;

  /// Returns the most recently reported audio quality classification.
  MicrophoneSignalQuality get signalQuality => _signalQuality;

  /// Publishes accepted microphone note attacks and releases.
  Stream<MicrophoneNoteEvent> get noteEventStream => _noteEvents.stream;

  /// Publishes the MIDI number for each accepted acoustic attack.
  Stream<int> get noteOnStream => _noteAttacks.stream;

  /// Publishes the complete acoustically active note set after each change.
  Stream<Set<int>> get activeNotesStream => _activeNoteSnapshots.stream;

  /// Publishes microphone lifecycle changes for the screen and exercises.
  Stream<MicrophoneInputState> get stateStream => _states.stream;

  /// Publishes audio quality changes for calibration and user guidance.
  Stream<MicrophoneSignalQuality> get signalQualityStream =>
      _signalQualities.stream;

  /// Accepts one recognized note attack and adds it to the active-note layer.
  void acceptNoteOn({
    required int noteNumber,
    required int estimatedVelocity,
    required double confidence,
    required Duration capturedAt,
  }) {
    if (_isDisposed) return;

    final event = MicrophoneNoteEvent(
      type: MicrophoneNoteEventType.noteOn,
      noteNumber: noteNumber,
      estimatedVelocity: estimatedVelocity.clamp(1, 127).toInt(),
      confidence: confidence.clamp(0, 1).toDouble(),
      capturedAt: capturedAt,
    );
    _noteEvents.add(event);
    _noteAttacks.add(noteNumber);

    if (_activeNotes.add(noteNumber)) {
      _emitActiveNotes();
    }
  }

  /// Accepts one recognized release and removes it from the active-note layer.
  void acceptNoteOff({
    required int noteNumber,
    required double confidence,
    required Duration capturedAt,
  }) {
    if (_isDisposed) return;

    _noteEvents.add(
      MicrophoneNoteEvent(
        type: MicrophoneNoteEventType.noteOff,
        noteNumber: noteNumber,
        estimatedVelocity: 0,
        confidence: confidence.clamp(0, 1).toDouble(),
        capturedAt: capturedAt,
      ),
    );

    if (_activeNotes.remove(noteNumber)) {
      _emitActiveNotes();
    }
  }

  /// Updates lifecycle state and clears notes when microphone input is unusable.
  void updateState(MicrophoneInputState value) {
    if (_isDisposed || value == _state) return;
    _state = value;

    if (value == MicrophoneInputState.stopped ||
        value == MicrophoneInputState.interrupted ||
        value == MicrophoneInputState.failed) {
      clearActiveNotes();
    }

    _states.add(value);
  }

  /// Publishes a signal-quality change without duplicating unchanged values.
  void updateSignalQuality(MicrophoneSignalQuality value) {
    if (_isDisposed || value == _signalQuality) return;
    _signalQuality = value;
    _signalQualities.add(value);
  }

  /// Clears all acoustically active pitches and publishes one empty snapshot.
  void clearActiveNotes() {
    if (_isDisposed || _activeNotes.isEmpty) return;
    _activeNotes.clear();
    _emitActiveNotes();
  }

  /// Publishes a detached active-note snapshot for chord and layer consumers.
  void _emitActiveNotes() {
    _activeNoteSnapshots.add(activeNotes);
  }

  /// Stops accepting detections and closes every microphone output stream.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _activeNotes.clear();
    await _noteEvents.close();
    await _noteAttacks.close();
    await _activeNoteSnapshots.close();
    await _states.close();
    await _signalQualities.close();
  }
}
