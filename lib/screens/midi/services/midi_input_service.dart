import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'dart:async';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';
import 'package:soundsight/screens/midi/models/midi_note_event.dart';

class MidiInputService {
  final MidiCommand midiCommand = MidiCommand();

  StreamSubscription<MidiDataReceivedEvent>? midiSubscription;
  StreamSubscription<MidiSetupChange>? setupSubscription;
  StreamSubscription<MidiConnectionState>? connectionSubscription;

  MidiDevice? connectedMidiDevice;
  bool isDisposed = false;

  final Set<int> activeMidiNoteNumbers = {};

  final StreamController<Set<int>> activeNotesController =
      StreamController<Set<int>>.broadcast();

  final StreamController<int> noteOnController =
      StreamController<int>.broadcast();

  final StreamController<bool> connectionController =
      StreamController<bool>.broadcast();

  final StreamController<MidiNoteEvent> noteEventController =
      StreamController<MidiNoteEvent>.broadcast();

  MidiInputService() {
    // USB appearance and removal are reported by the platform MIDI plugin.
    setupSubscription = midiCommand.onMidiSetupChanged?.listen(
      _handleMidiSetupChange,
    );
  }

  Set<int> get activeMidiNotes => Set<int>.unmodifiable(activeMidiNoteNumbers);

  Stream<Set<int>> get activeNotesStream => activeNotesController.stream;

  Stream<int> get noteOnStream => noteOnController.stream;

  /// Notifies screens when the currently used MIDI device connects or leaves.
  Stream<bool> get connectionStream => connectionController.stream;

  /// The device currently owned by this screen-level service.
  MidiDevice? get connectedDevice => connectedMidiDevice;

  /// Whether the current device still reports a usable connection.
  bool get isConnected => connectedMidiDevice?.connected ?? false;

  Stream<MidiNoteEvent> get noteEventStream {
    return noteEventController.stream;
  }

  Future<List<MidiDevice>> getDevices() async {
    return await midiCommand.devices ?? [];
  }

  Future<void> connectToDevice(MidiDevice device) async {
    if (isDisposed) {
      throw StateError('This MIDI input service has already been disposed.');
    }

    await midiSubscription?.cancel();
    await connectionSubscription?.cancel();

    final previousDevice = connectedMidiDevice;

    // Close a previous route-owned connection before opening another one.
    if (previousDevice != null &&
        previousDevice.id != device.id &&
        previousDevice.connected) {
      midiCommand.disconnectDevice(previousDevice);
    }

    connectedMidiDevice = device;

    // Subscribe before connecting so a fast connection or disconnection event
    // cannot occur between the native call and the Dart listener.
    connectionSubscription = device.onConnectionStateChanged.listen(
      _handleConnectionState,
    );

    try {
      await midiCommand.connectToDevice(device);
    } catch (_) {
      await connectionSubscription?.cancel();
      connectionSubscription = null;
      connectedMidiDevice = null;
      _emitConnection(false);
      rethrow;
    }

    if (isDisposed) {
      if (device.connected) {
        midiCommand.disconnectDevice(device);
      }

      return;
    }

    midiSubscription = midiCommand.onMidiDataReceived?.listen(_handleMidiEvent);

    _emitConnection(true);
  }

  Future<void> disconnect() async {
    if (isDisposed) {
      return;
    }

    final device = connectedMidiDevice;
    connectedMidiDevice = null;

    await midiSubscription?.cancel();
    midiSubscription = null;
    await connectionSubscription?.cancel();
    connectionSubscription = null;

    if (activeMidiNoteNumbers.isNotEmpty) {
      activeMidiNoteNumbers.clear();
      activeNotesController.add(const <int>{});
    }

    if (device != null && device.connected) {
      midiCommand.disconnectDevice(device);
    }

    _emitConnection(false);
  }

  void _handleMidiEvent(MidiDataReceivedEvent event) {
    if (isDisposed || event.device.id != connectedMidiDevice?.id) {
      return;
    }

    final message = event.message;

    bool notesChanged = false;

    if (message is NoteOnMessage) {
      if (message.velocity > 0) {
        noteEventController.add(
          MidiNoteEvent(
            type: MidiNoteEventType.noteOn,
            noteNumber: message.note,
            velocity: message.velocity,
          ),
        );
        notesChanged = activeMidiNoteNumbers.add(message.note);

        noteOnController.add(message.note);
      } else {
        noteEventController.add(
          MidiNoteEvent(
            type: MidiNoteEventType.noteOff,
            noteNumber: message.note,
            velocity: 0,
          ),
        );
        notesChanged = activeMidiNoteNumbers.remove(message.note);
      }
    } else if (message is NoteOffMessage) {
      noteEventController.add(
        MidiNoteEvent(
          type: MidiNoteEventType.noteOff,
          noteNumber: message.note,
          velocity: 0,
        ),
      );
      notesChanged = activeMidiNoteNumbers.remove(message.note);
    }

    if (!notesChanged) {
      return;
    }

    activeNotesController.add(Set<int>.unmodifiable(activeMidiNoteNumbers));
  }

  /// Reacts to the selected device's native connection state.
  void _handleConnectionState(MidiConnectionState state) {
    if (isDisposed) {
      return;
    }

    switch (state) {
      case MidiConnectionState.connected:
        _emitConnection(true);
        return;

      case MidiConnectionState.disconnected:
        _handleDisconnectedDevice();
        return;

      case MidiConnectionState.connecting:
      case MidiConnectionState.disconnecting:
        return;
    }
  }

  /// Uses global setup changes as a fallback for physical USB removal.
  void _handleMidiSetupChange(MidiSetupChange change) {
    if (isDisposed || connectedMidiDevice == null) {
      return;
    }

    if (change == MidiSetupChange.deviceDisconnected ||
        change == MidiSetupChange.deviceDisappeared) {
      unawaited(_confirmConnectedDeviceStillExists());
    }
  }

  /// Refreshes the device snapshot after Android reports a topology change.
  Future<void> _confirmConnectedDeviceStillExists() async {
    final selectedDevice = connectedMidiDevice;

    if (selectedDevice == null || isDisposed) {
      return;
    }

    try {
      final devices = await getDevices();
      final deviceStillExists = devices.any(
        (device) => device.id == selectedDevice.id,
      );

      if (!deviceStillExists && !isDisposed) {
        _handleDisconnectedDevice();
      }
    } catch (_) {
      // The direct connection-state stream remains the primary signal.
    }
  }

  /// Clears stale held notes and tells every listener that MIDI was removed.
  void _handleDisconnectedDevice() {
    connectedMidiDevice = null;

    if (activeMidiNoteNumbers.isNotEmpty) {
      activeMidiNoteNumbers.clear();
      activeNotesController.add(const <int>{});
    }

    _emitConnection(false);
  }

  /// Avoids adding connection events after the service has been disposed.
  void _emitConnection(bool connected) {
    if (!isDisposed && !connectionController.isClosed) {
      connectionController.add(connected);
    }
  }

  Future<void> dispose() async {
    if (isDisposed) {
      return;
    }

    final device = connectedMidiDevice;
    connectedMidiDevice = null;

    isDisposed = true;

    // Disconnect while the cable is still present when a MIDI screen closes.
    // This prevents native ports from leaking into the next MIDI feature.
    if (device != null && device.connected) {
      midiCommand.disconnectDevice(device);
    }
    await noteEventController.close();
    await midiSubscription?.cancel();
    await connectionSubscription?.cancel();
    await setupSubscription?.cancel();
    await activeNotesController.close();
    await noteOnController.close();
    await connectionController.close();
  }
}
