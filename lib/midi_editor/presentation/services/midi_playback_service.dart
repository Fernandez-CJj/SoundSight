import 'dart:typed_data';

import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class MidiPlaybackService {
  MidiPlaybackService({MidiPro? midi}) : _midi = midi ?? MidiPro();

  final MidiPro _midi;
  int? _soundfontId;
  bool _loadedMidi = false;

  Future<void> initialize() async {
    if (!_midi.isInitialized) {
      await _midi.init(sampleRate: 48000, bufferSize: 256, polyphony: 96);
    }
    _soundfontId ??= await _midi.loadSoundfontAsset(
      assetPath: 'assets/Piano.sf2',
      bank: 0,
      program: 0,
    );
  }

  Future<void> loadMidi(Uint8List bytes) async {
    await initialize();
    await _midi.loadMidiData(data: bytes, sfId: _soundfontId!);
    _loadedMidi = true;
  }

  Future<void> play() async {
    if (_loadedMidi) {
      await _midi.playMidi();
    }
  }

  Future<void> pause() async {
    if (_loadedMidi) {
      await _midi.pauseMidi();
    }
  }

  Future<void> stop() async {
    if (_loadedMidi) {
      await _midi.stopMidi();
    }
  }

  Future<void> seek(int tick) async {
    if (_loadedMidi) {
      await _midi.seekMidi(tick);
    }
  }

  Future<void> setTempoFactor(double factor) async {
    if (_loadedMidi) {
      await _midi.setMidiTempo(factor);
    }
  }

  Future<MidiPlayerState?> state() async {
    if (!_loadedMidi) {
      return null;
    }
    return _midi.getMidiPlayerState();
  }

  Future<void> dispose() async {
    await _midi.dispose();
  }
}
