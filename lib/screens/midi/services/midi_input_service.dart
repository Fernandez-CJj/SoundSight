import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'dart:async';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';

class MidiInputService {
  final MidiCommand _midiCommand = MidiCommand();

  StreamSubscription<MidiDataReceivedEvent>? _midiSubscription;
  StreamSubscription<MidiSetupChange>? _setupSubscription;
  StreamSubscription<MidiConnectionState>? _connectionSubscription;

  MidiDevice? _connectedDevice;
  bool _isDisposed = false;

  final Set<int> _activeMidiNotes = {};

  final StreamController<Set<int>> _activeNotesController =
      StreamController<Set<int>>.broadcast();

  final StreamController<int> _noteOnController =
      StreamController<int>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  MidiInputService() {
    // USB appearance and removal are reported by the platform MIDI plugin.
    _setupSubscription = _midiCommand.onMidiSetupChanged?.listen(
      _handleMidiSetupChange,
    );
  }

  Set<int> get activeMidiNotes => Set<int>.unmodifiable(_activeMidiNotes);

  Stream<Set<int>> get activeNotesStream => _activeNotesController.stream;

  Stream<int> get noteOnStream => _noteOnController.stream;

  /// Notifies screens when the currently used MIDI device connects or leaves.
  Stream<bool> get connectionStream => _connectionController.stream;

  /// The device currently owned by this screen-level service.
  MidiDevice? get connectedDevice => _connectedDevice;

  /// Whether the current device still reports a usable connection.
  bool get isConnected => _connectedDevice?.connected ?? false;

  Future<List<MidiDevice>> getDevices() async {
    return await _midiCommand.devices ?? [];
  }

  Future<void> connectToDevice(MidiDevice device) async {
    if (_isDisposed) {
      throw StateError('This MIDI input service has already been disposed.');
    }

    await _midiSubscription?.cancel();
    await _connectionSubscription?.cancel();

    final previousDevice = _connectedDevice;

    // Close a previous route-owned connection before opening another one.
    if (previousDevice != null &&
        previousDevice.id != device.id &&
        previousDevice.connected) {
      _midiCommand.disconnectDevice(previousDevice);
    }

    _connectedDevice = device;

    // Subscribe before connecting so a fast connection or disconnection event
    // cannot occur between the native call and the Dart listener.
    _connectionSubscription = device.onConnectionStateChanged.listen(
      _handleConnectionState,
    );

    try {
      await _midiCommand.connectToDevice(device);
    } catch (_) {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      _connectedDevice = null;
      _emitConnection(false);
      rethrow;
    }

    if (_isDisposed) {
      if (device.connected) {
        _midiCommand.disconnectDevice(device);
      }

      return;
    }

    _midiSubscription = _midiCommand.onMidiDataReceived?.listen(
      _handleMidiEvent,
    );

    _emitConnection(true);
  }

  void _handleMidiEvent(MidiDataReceivedEvent event) {
    if (_isDisposed || event.device.id != _connectedDevice?.id) {
      return;
    }

    final message = event.message;

    bool notesChanged = false;

    if (message is NoteOnMessage) {
      if (message.velocity > 0) {
        notesChanged = _activeMidiNotes.add(message.note);

        _noteOnController.add(message.note);
      } else {
        notesChanged = _activeMidiNotes.remove(message.note);
      }
    } else if (message is NoteOffMessage) {
      notesChanged = _activeMidiNotes.remove(message.note);
    }

    if (!notesChanged) {
      return;
    }

    _activeNotesController.add(Set<int>.unmodifiable(_activeMidiNotes));
  }

  /// Reacts to the selected device's native connection state.
  void _handleConnectionState(MidiConnectionState state) {
    if (_isDisposed) {
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
    if (_isDisposed || _connectedDevice == null) {
      return;
    }

    if (change == MidiSetupChange.deviceDisconnected ||
        change == MidiSetupChange.deviceDisappeared) {
      unawaited(_confirmConnectedDeviceStillExists());
    }
  }

  /// Refreshes the device snapshot after Android reports a topology change.
  Future<void> _confirmConnectedDeviceStillExists() async {
    final selectedDevice = _connectedDevice;

    if (selectedDevice == null || _isDisposed) {
      return;
    }

    try {
      final devices = await getDevices();
      final deviceStillExists = devices.any(
        (device) => device.id == selectedDevice.id,
      );

      if (!deviceStillExists && !_isDisposed) {
        _handleDisconnectedDevice();
      }
    } catch (_) {
      // The direct connection-state stream remains the primary signal.
    }
  }

  /// Clears stale held notes and tells every listener that MIDI was removed.
  void _handleDisconnectedDevice() {
    _connectedDevice = null;

    if (_activeMidiNotes.isNotEmpty) {
      _activeMidiNotes.clear();
      _activeNotesController.add(const <int>{});
    }

    _emitConnection(false);
  }

  /// Avoids adding connection events after the service has been disposed.
  void _emitConnection(bool connected) {
    if (!_isDisposed && !_connectionController.isClosed) {
      _connectionController.add(connected);
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    final device = _connectedDevice;
    _connectedDevice = null;

    // Disconnect while the cable is still present when a MIDI screen closes.
    // This prevents native ports from leaking into the next MIDI feature.
    if (device != null && device.connected) {
      _midiCommand.disconnectDevice(device);
    }

    await _midiSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _setupSubscription?.cancel();
    await _activeNotesController.close();
    await _noteOnController.close();
    await _connectionController.close();
  }
}
