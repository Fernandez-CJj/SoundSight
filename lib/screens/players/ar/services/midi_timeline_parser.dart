import 'dart:math' as math;
import 'dart:typed_data';

import '../models/ar_note_event.dart';
import '../models/ar_score_timeline.dart';

/// Parses Standard MIDI File bytes into the timing model used by AR practice.
///
/// Both metrical (ticks per quarter note) and SMPTE divisions are supported.
/// The parser intentionally ignores percussion channel events.
class MidiTimelineParser {
  const MidiTimelineParser();

  /// Validates MIDI headers/tracks and converts note ticks into microseconds.
  ///
  /// Timeline zero is shifted to the first playable note so leading file silence
  /// does not add an unexpected delay after the app's own four-second lead-in.
  /// Duplicate note signatures are removed before the immutable result is built.
  ArScoreTimeline parse(Uint8List midiBytes) {
    _MidiByteReader reader = _MidiByteReader(midiBytes);

    if (reader.readText(4) != 'MThd') {
      throw const FormatException(
        'The downloaded file is not a standard MIDI file.',
      );
    }

    int headerLength = reader.readUint32();

    if (headerLength < 6) {
      throw const FormatException('The MIDI header is incomplete.');
    }

    int format = reader.readUint16();
    int trackCount = reader.readUint16();
    int timeDivision = reader.readUint16();

    if (format > 1) {
      throw const FormatException(
        'This MIDI file uses an unsupported sequence format.',
      );
    }

    if (trackCount <= 0) {
      throw const FormatException('The MIDI file contains no tracks.');
    }

    if (timeDivision == 0) {
      throw const FormatException('The MIDI time division is invalid.');
    }

    reader.skip(headerLength - 6);

    List<_RawMidiNote> rawNotes = [];
    List<_MidiTempoChange> tempoChanges = [];

    for (int trackIndex = 0; trackIndex < trackCount; trackIndex++) {
      _parseTrack(
        reader: reader,
        rawNotes: rawNotes,
        tempoChanges: tempoChanges,
      );
    }

    if (rawNotes.isEmpty) {
      throw const FormatException(
        'The MIDI file contains no playable piano notes.',
      );
    }

    tempoChanges.sort((_MidiTempoChange first, _MidiTempoChange second) {
      int tickComparison = first.tick.compareTo(second.tick);

      if (tickComparison != 0) {
        return tickComparison;
      }

      return first.order.compareTo(second.order);
    });

    rawNotes.sort((_RawMidiNote first, _RawMidiNote second) {
      int startComparison = first.startTick.compareTo(second.startTick);

      if (startComparison != 0) {
        return startComparison;
      }

      return first.midiNote.compareTo(second.midiNote);
    });

    int firstNoteTick = rawNotes.first.startTick;

    double firstNoteMicroseconds = _microsecondsAtTick(
      tick: firstNoteTick,
      timeDivision: timeDivision,
      tempoChanges: tempoChanges,
    );

    List<ArNoteEvent> noteEvents = [];
    Set<(int, int, int)> addedNotes = {};
    int totalMicroseconds = 0;

    for (_RawMidiNote rawNote in rawNotes) {
      double absoluteStartMicroseconds = _microsecondsAtTick(
        tick: rawNote.startTick,
        timeDivision: timeDivision,
        tempoChanges: tempoChanges,
      );

      double absoluteEndMicroseconds = _microsecondsAtTick(
        tick: rawNote.endTick,
        timeDivision: timeDivision,
        tempoChanges: tempoChanges,
      );

      int startMicroseconds = math.max(
        0,
        (absoluteStartMicroseconds - firstNoteMicroseconds).round(),
      );

      int durationMicroseconds = math.max(
        80000,
        (absoluteEndMicroseconds - absoluteStartMicroseconds).round(),
      );

      int endMicroseconds = startMicroseconds + durationMicroseconds;

      (int, int, int) signature = (
        rawNote.midiNote,
        startMicroseconds,
        endMicroseconds,
      );

      if (!addedNotes.add(signature)) {
        continue;
      }

      noteEvents.add(
        ArNoteEvent(
          midiNote: rawNote.midiNote,
          startTime: Duration(microseconds: startMicroseconds),
          duration: Duration(microseconds: durationMicroseconds),
        ),
      );

      totalMicroseconds = math.max(totalMicroseconds, endMicroseconds);
    }

    if (noteEvents.isEmpty) {
      throw const FormatException(
        'The MIDI file contains no usable note events.',
      );
    }

    return ArScoreTimeline(
      noteEvents: noteEvents,
      totalDuration: Duration(microseconds: totalMicroseconds),
    );
  }

  /// Reads one `MTrk` chunk and collects note spans plus tempo changes.
  ///
  /// Running status, meta events, SysEx/system messages, normal note-off, and
  /// zero-velocity note-on are handled without crossing the declared track end.
  void _parseTrack({
    required _MidiByteReader reader,
    required List<_RawMidiNote> rawNotes,
    required List<_MidiTempoChange> tempoChanges,
  }) {
    if (reader.readText(4) != 'MTrk') {
      throw const FormatException('A MIDI track is missing its MTrk header.');
    }

    int trackLength = reader.readUint32();
    int trackEnd = reader.position + trackLength;

    if (trackEnd > reader.length) {
      throw const FormatException('A MIDI track is incomplete.');
    }

    int absoluteTick = 0;
    int trackLastTick = 0;
    int? runningStatus;

    Map<(int, int), List<int>> activeNotes = {};

    // Pairs the oldest unmatched note-on for this channel/pitch with note-off.
    void closeNote({
      required int channel,
      required int midiNote,
      required int endTick,
    }) {
      (int, int) noteKey = (channel, midiNote);
      List<int>? startTicks = activeNotes[noteKey];

      if (startTicks == null || startTicks.isEmpty) {
        return;
      }

      int startTick = startTicks.removeAt(0);

      if (startTicks.isEmpty) {
        activeNotes.remove(noteKey);
      }

      rawNotes.add(
        _RawMidiNote(
          midiNote: midiNote,
          startTick: startTick,
          endTick: math.max(startTick + 1, endTick),
        ),
      );
    }

    while (reader.position < trackEnd) {
      absoluteTick += reader.readVariableLength(trackEnd);
      trackLastTick = math.max(trackLastTick, absoluteTick);

      int nextByte = reader.peekByte(trackEnd);
      late int status;
      int? firstDataByte;

      if (nextByte < 0x80) {
        if (runningStatus == null) {
          throw const FormatException(
            'A MIDI event uses running status without a previous status byte.',
          );
        }

        status = runningStatus;
        firstDataByte = reader.readByte(trackEnd);
      } else {
        status = reader.readByte(trackEnd);

        if (status < 0xF0) {
          runningStatus = status;
        }
      }

      if (status == 0xFF) {
        runningStatus = null;

        int metaType = reader.readByte(trackEnd);
        int metaLength = reader.readVariableLength(trackEnd);

        if (metaType == 0x51 && metaLength == 3) {
          int microsecondsPerQuarter = reader.readUint24(trackEnd);

          if (microsecondsPerQuarter > 0) {
            tempoChanges.add(
              _MidiTempoChange(
                tick: absoluteTick,
                microsecondsPerQuarter: microsecondsPerQuarter,
                order: tempoChanges.length,
              ),
            );
          }
        } else {
          reader.skipWithinTrack(metaLength, trackEnd);
        }

        if (metaType == 0x2F) {
          reader.position = trackEnd;
        }

        continue;
      }

      if (status == 0xF0 || status == 0xF7) {
        runningStatus = null;

        int messageLength = reader.readVariableLength(trackEnd);
        reader.skipWithinTrack(messageLength, trackEnd);
        continue;
      }

      if (status >= 0xF0) {
        runningStatus = null;

        int dataLength = _systemMessageDataLength(status);
        reader.skipWithinTrack(dataLength, trackEnd);
        continue;
      }

      int messageType = status & 0xF0;
      int channel = status & 0x0F;

      int dataLength = messageType == 0xC0 || messageType == 0xD0 ? 1 : 2;

      int firstData = firstDataByte ?? reader.readByte(trackEnd);

      int secondData = dataLength == 2 ? reader.readByte(trackEnd) : 0;

      if (firstData > 0x7F || secondData > 0x7F) {
        throw const FormatException(
          'A MIDI event contains an invalid data byte.',
        );
      }

      // MIDI channel 10, represented by index 9, is normally percussion.
      // Percussion notes should not become falling piano notes.
      if (channel == 9) {
        continue;
      }

      if (messageType == 0x90 && secondData > 0) {
        (int, int) noteKey = (channel, firstData);

        activeNotes.putIfAbsent(noteKey, () => <int>[]);
        activeNotes[noteKey]!.add(absoluteTick);
        continue;
      }

      bool isRegularNoteOff = messageType == 0x80;
      bool isZeroVelocityNoteOff = messageType == 0x90 && secondData == 0;

      if (isRegularNoteOff || isZeroVelocityNoteOff) {
        closeNote(channel: channel, midiNote: firstData, endTick: absoluteTick);
      }
    }

    for (MapEntry<(int, int), List<int>> entry in activeNotes.entries) {
      for (int startTick in entry.value) {
        rawNotes.add(
          _RawMidiNote(
            midiNote: entry.key.$2,
            startTick: startTick,
            endTick: math.max(startTick + 1, trackLastTick),
          ),
        );
      }
    }

    reader.position = trackEnd;
  }

  /// Converts an absolute tick into elapsed microseconds using tempo history.
  ///
  /// MIDI's default 120 BPM tempo is used until the first tempo meta event.
  double _microsecondsAtTick({
    required int tick,
    required int timeDivision,
    required List<_MidiTempoChange> tempoChanges,
  }) {
    bool usesSmpteTiming = (timeDivision & 0x8000) != 0;

    if (usesSmpteTiming) {
      int encodedFramesPerSecond = (timeDivision >> 8) & 0xFF;

      int signedFramesPerSecond = encodedFramesPerSecond >= 0x80
          ? encodedFramesPerSecond - 0x100
          : encodedFramesPerSecond;

      int framesPerSecondCode = -signedFramesPerSecond;
      int ticksPerFrame = timeDivision & 0xFF;

      if (framesPerSecondCode <= 0 || ticksPerFrame <= 0) {
        throw const FormatException('The MIDI SMPTE timing is invalid.');
      }

      double framesPerSecond = framesPerSecondCode == 29
          ? 29.97
          : framesPerSecondCode.toDouble();

      return tick * 1000000 / (framesPerSecond * ticksPerFrame);
    }

    int ticksPerQuarterNote = timeDivision & 0x7FFF;

    if (ticksPerQuarterNote <= 0) {
      throw const FormatException(
        'The MIDI ticks-per-quarter value is invalid.',
      );
    }

    int currentTick = 0;
    int microsecondsPerQuarter = 500000;
    double elapsedMicroseconds = 0;

    for (_MidiTempoChange tempoChange in tempoChanges) {
      if (tempoChange.tick > tick) {
        break;
      }

      if (tempoChange.tick > currentTick) {
        elapsedMicroseconds +=
            (tempoChange.tick - currentTick) *
            microsecondsPerQuarter /
            ticksPerQuarterNote;

        currentTick = tempoChange.tick;
      }

      microsecondsPerQuarter = tempoChange.microsecondsPerQuarter;
    }

    elapsedMicroseconds +=
        (tick - currentTick) * microsecondsPerQuarter / ticksPerQuarterNote;

    return elapsedMicroseconds;
  }

  /// Returns fixed data length for supported system-common status bytes.
  int _systemMessageDataLength(int status) {
    if (status == 0xF1 || status == 0xF3) {
      return 1;
    }

    if (status == 0xF2) {
      return 2;
    }

    return 0;
  }
}

/// Temporary tick-based note span collected before tempo conversion.
class _RawMidiNote {
  const _RawMidiNote({
    required this.midiNote,
    required this.startTick,
    required this.endTick,
  });

  /// MIDI pitch byte.
  final int midiNote;
  /// Absolute note-on tick.
  final int startTick;
  /// Absolute note-off tick.
  final int endTick;
}

/// Tempo meta event used while converting metrical ticks to time.
class _MidiTempoChange {
  const _MidiTempoChange({
    required this.tick,
    required this.microsecondsPerQuarter,
    required this.order,
  });

  /// Absolute tick at which the tempo takes effect.
  final int tick;
  /// MIDI tempo value from meta event `0x51`.
  final int microsecondsPerQuarter;
  /// File encounter order used to stabilize equal-tick tempo events.
  final int order;
}

/// Bounds-checked cursor for MIDI's big-endian binary fields.
class _MidiByteReader {
  _MidiByteReader(this.bytes);

  final Uint8List bytes;
  int position = 0;

  /// Total number of available bytes.
  int get length {
    return bytes.length;
  }

  /// Reads one byte without crossing [limit] or the file end.
  int readByte([int? limit]) {
    int readLimit = limit ?? bytes.length;

    if (position >= readLimit || position >= bytes.length) {
      throw const FormatException('The MIDI file ended unexpectedly.');
    }

    return bytes[position++];
  }

  /// Reads the next byte without moving [position].
  int peekByte([int? limit]) {
    int readLimit = limit ?? bytes.length;

    if (position >= readLimit || position >= bytes.length) {
      throw const FormatException('The MIDI file ended unexpectedly.');
    }

    return bytes[position];
  }

  /// Reads an unsigned 16-bit big-endian integer.
  int readUint16() {
    return (readByte() << 8) | readByte();
  }

  /// Reads an unsigned 24-bit big-endian value inside a track boundary.
  int readUint24(int limit) {
    return (readByte(limit) << 16) | (readByte(limit) << 8) | readByte(limit);
  }

  /// Reads an unsigned 32-bit big-endian integer.
  int readUint32() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  /// Decodes MIDI's one-to-four-byte variable-length quantity.
  int readVariableLength(int limit) {
    int value = 0;

    for (int byteIndex = 0; byteIndex < 4; byteIndex++) {
      int byte = readByte(limit);

      value = (value << 7) | (byte & 0x7F);

      if ((byte & 0x80) == 0) {
        return value;
      }
    }

    throw const FormatException('A MIDI variable-length value is invalid.');
  }

  /// Reads an ASCII-like fixed-length chunk identifier such as `MThd`.
  String readText(int characterCount) {
    List<int> characters = [];

    for (int index = 0; index < characterCount; index++) {
      characters.add(readByte());
    }

    return String.fromCharCodes(characters);
  }

  /// Advances within the full file after validating the requested count.
  void skip(int byteCount) {
    int newPosition = position + byteCount;

    if (byteCount < 0 || newPosition > bytes.length) {
      throw const FormatException('The MIDI file ended unexpectedly.');
    }

    position = newPosition;
  }

  /// Advances without crossing either the current track or the file boundary.
  void skipWithinTrack(int byteCount, int trackEnd) {
    int newPosition = position + byteCount;

    if (byteCount < 0 || newPosition > trackEnd || newPosition > bytes.length) {
      throw const FormatException('A MIDI event is incomplete.');
    }

    position = newPosition;
  }
}
