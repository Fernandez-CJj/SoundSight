import 'dart:math' as math;
import 'dart:typed_data';

class MidiFileDurationCalculator {
  static MidiDurationResult calculate(Uint8List midiBytes) {
    try {
      final reader = MidiByteReader(midiBytes);

      if (reader.readText(4) != 'MThd') {
        return const MidiDurationResult.unavailable(
          'The downloaded file is not a standard MIDI file.',
        );
      }

      final headerLength = reader.readUint32();

      if (headerLength < 6) {
        return const MidiDurationResult.unavailable(
          'The MIDI header is incomplete.',
        );
      }

      final format = reader.readUint16();
      final trackCount = reader.readUint16();
      final timeDivision = reader.readUint16();

      if (format > 2 || trackCount == 0) {
        return const MidiDurationResult.unavailable(
          'The MIDI header contains unsupported values.',
        );
      }

      reader.skip(headerLength - 6);

      final noteOnEvents = <RawMidiNoteOn>[];
      final tempoEvents = <MidiTempoEvent>[];
      var tempoOrder = 0;
      var maximumTrackTick = 0;
      var maximumNoteOffTick = 0;

      for (var trackIndex = 0; trackIndex < trackCount; trackIndex++) {
        if (reader.readText(4) != 'MTrk') {
          return const MidiDurationResult.unavailable(
            'A MIDI track is missing its MTrk header.',
          );
        }

        final trackLength = reader.readUint32();
        final trackEnd = reader.position + trackLength;

        if (trackEnd > reader.length) {
          return const MidiDurationResult.unavailable(
            'A MIDI track is incomplete.',
          );
        }

        var absoluteTick = 0;
        int? runningStatus;
        final activeNoteOns = <int, List<RawMidiNoteOn>>{};

        while (reader.position < trackEnd) {
          absoluteTick += reader.readVariableLength(trackEnd);

          if (absoluteTick > maximumTrackTick) {
            maximumTrackTick = absoluteTick;
          }

          final nextByte = reader.peekByte(trackEnd);
          late final int status;
          int? firstDataByte;

          if (nextByte < 0x80) {
            if (runningStatus == null) {
              throw const FormatException(
                'A MIDI event uses running status before a status byte.',
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
            final metaType = reader.readByte(trackEnd);
            final metaLength = reader.readVariableLength(trackEnd);

            if (metaType == 0x51 && metaLength == 3) {
              final microsecondsPerQuarter = reader.readUint24(trackEnd);

              if (microsecondsPerQuarter > 0) {
                tempoEvents.add(
                  MidiTempoEvent(
                    tick: absoluteTick,
                    microsecondsPerQuarter: microsecondsPerQuarter,
                    order: tempoOrder,
                  ),
                );

                tempoOrder++;
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
            final systemExclusiveLength = reader.readVariableLength(trackEnd);
            reader.skipWithinTrack(systemExclusiveLength, trackEnd);
            continue;
          }

          if (status >= 0xF0) {
            runningStatus = null;
            final dataLength = systemMessageDataLength(status);
            reader.skipWithinTrack(dataLength, trackEnd);
            continue;
          }

          final messageType = status & 0xF0;
          final dataLength = messageType == 0xC0 || messageType == 0xD0 ? 1 : 2;
          final firstData = firstDataByte ?? reader.readByte(trackEnd);
          final secondData = dataLength == 2 ? reader.readByte(trackEnd) : 0;

          final channel = status & 0x0F;

          if (messageType == 0x90 && secondData > 0 && channel != 9) {
            final noteOn = RawMidiNoteOn(
              tick: absoluteTick,
              midiNote: firstData,
              channel: channel,
            );
            noteOnEvents.add(noteOn);
            final noteKey = channel * 128 + firstData;
            activeNoteOns.putIfAbsent(noteKey, () => <RawMidiNoteOn>[]);
            activeNoteOns[noteKey]!.add(noteOn);
          }

          final isNoteOff =
              messageType == 0x80 || (messageType == 0x90 && secondData == 0);

          if (isNoteOff && channel != 9 && absoluteTick > maximumNoteOffTick) {
            maximumNoteOffTick = absoluteTick;
          }

          if (isNoteOff && channel != 9) {
            final noteKey = channel * 128 + firstData;
            final activeNotes = activeNoteOns[noteKey];

            if (activeNotes != null && activeNotes.isNotEmpty) {
              activeNotes.removeAt(0).endTick = absoluteTick;
            }
          }

          if (firstData > 0x7F || secondData > 0x7F) {
            throw const FormatException(
              'A MIDI event contains an invalid data byte.',
            );
          }
        }

        for (final activeNotes in activeNoteOns.values) {
          for (final activeNote in activeNotes) {
            activeNote.endTick = absoluteTick;
          }
        }

        reader.position = trackEnd;
      }

      if (noteOnEvents.isEmpty) {
        return const MidiDurationResult.unavailable(
          'The MIDI file contains no playable Note On events.',
        );
      }

      final notesByTick = <int, Set<int>>{};
      final noteEndTicksByTick = <int, Map<int, int>>{};

      for (final noteEvent in noteOnEvents) {
        notesByTick.putIfAbsent(noteEvent.tick, () => <int>{});
        notesByTick[noteEvent.tick]!.add(noteEvent.midiNote);
        noteEndTicksByTick.putIfAbsent(noteEvent.tick, () => <int, int>{});

        final endTick = noteEvent.endTick ?? maximumTrackTick;
        final storedEndTick =
            noteEndTicksByTick[noteEvent.tick]![noteEvent.midiNote];
        if (storedEndTick == null || endTick > storedEndTick) {
          noteEndTicksByTick[noteEvent.tick]![noteEvent.midiNote] = endTick;
        }
      }

      final eventTicks = notesByTick.keys.toList()..sort();

      tempoEvents.sort((firstEvent, secondEvent) {
        final tickComparison = firstEvent.tick.compareTo(secondEvent.tick);

        if (tickComparison != 0) {
          return tickComparison;
        }

        return firstEvent.order.compareTo(secondEvent.order);
      });

      final timelineEvents = <MidiTimelineEvent>[];

      for (final eventTick in eventTicks) {
        final eventTimeInSeconds = calculateTimeBetweenTicks(
          firstTick: 0,
          finalTick: eventTick,
          timeDivision: timeDivision,
          tempoEvents: tempoEvents,
        );

        if (eventTimeInSeconds == null) {
          return const MidiDurationResult.unavailable(
            'The MIDI time division is invalid.',
          );
        }

        final noteDurations = <int, Duration>{};
        for (final entry in noteEndTicksByTick[eventTick]!.entries) {
          final noteDurationInSeconds = calculateTimeBetweenTicks(
            firstTick: eventTick,
            finalTick: math.max(eventTick, entry.value),
            timeDivision: timeDivision,
            tempoEvents: tempoEvents,
          );

          if (noteDurationInSeconds == null) {
            return const MidiDurationResult.unavailable(
              'The MIDI note duration is invalid.',
            );
          }

          noteDurations[entry.key] = Duration(
            microseconds: math.max(
              0,
              (noteDurationInSeconds * Duration.microsecondsPerSecond).round(),
            ),
          );
        }

        timelineEvents.add(
          MidiTimelineEvent(
            scheduledTime: Duration(
              milliseconds: math.max(0, (eventTimeInSeconds * 1000).round()),
            ),
            midiNotes: Set<int>.unmodifiable(notesByTick[eventTick]!),
            noteDurations: Map<int, Duration>.unmodifiable(noteDurations),
          ),
        );
      }

      if (timelineEvents.isEmpty) {
        return const MidiDurationResult.unavailable(
          'The MIDI file contains no playable timeline events.',
        );
      }

      final finalTick = math.max(maximumTrackTick, maximumNoteOffTick);
      final durationInSeconds = calculateTimeBetweenTicks(
        firstTick: 0,
        finalTick: finalTick,
        timeDivision: timeDivision,
        tempoEvents: tempoEvents,
      );

      if (durationInSeconds == null) {
        return const MidiDurationResult.unavailable(
          'The MIDI time division is invalid.',
        );
      }

      final totalDuration = Duration(
        microseconds: math.max(
          0,
          (durationInSeconds * Duration.microsecondsPerSecond).round(),
        ),
      );

      return MidiDurationResult.available(totalDuration, timelineEvents);
    } on FormatException catch (error) {
      return MidiDurationResult.unavailable(error.message.toString());
    } catch (error) {
      return MidiDurationResult.unavailable(
        'MIDI duration calculation failed: $error',
      );
    }
  }

  static double? calculateTimeBetweenTicks({
    required int firstTick,
    required int finalTick,
    required int timeDivision,
    required List<MidiTempoEvent> tempoEvents,
  }) {
    if ((timeDivision & 0x8000) != 0) {
      final encodedFrames = (timeDivision >> 8) & 0xFF;
      final signedFrames = encodedFrames >= 0x80
          ? encodedFrames - 0x100
          : encodedFrames;
      final framesPerSecondCode = -signedFrames;
      final ticksPerFrame = timeDivision & 0xFF;

      if (framesPerSecondCode <= 0 || ticksPerFrame <= 0) {
        return null;
      }

      final framesPerSecond = framesPerSecondCode == 29
          ? 29.97
          : framesPerSecondCode.toDouble();

      return (finalTick - firstTick) / (framesPerSecond * ticksPerFrame);
    }

    final ticksPerQuarter = timeDivision & 0x7FFF;

    if (ticksPerQuarter <= 0) {
      return null;
    }

    var currentTick = firstTick;
    var microsecondsPerQuarter = 500000;
    var elapsedMicroseconds = 0.0;

    for (final tempoEvent in tempoEvents) {
      if (tempoEvent.tick <= firstTick) {
        microsecondsPerQuarter = tempoEvent.microsecondsPerQuarter;
        continue;
      }

      if (tempoEvent.tick >= finalTick) {
        break;
      }

      elapsedMicroseconds +=
          (tempoEvent.tick - currentTick) *
          microsecondsPerQuarter /
          ticksPerQuarter;
      currentTick = tempoEvent.tick;
      microsecondsPerQuarter = tempoEvent.microsecondsPerQuarter;
    }

    elapsedMicroseconds +=
        (finalTick - currentTick) * microsecondsPerQuarter / ticksPerQuarter;

    return elapsedMicroseconds / 1000000;
  }

  static int systemMessageDataLength(int status) {
    if (status == 0xF1 || status == 0xF3) {
      return 1;
    }

    if (status == 0xF2) {
      return 2;
    }

    return 0;
  }
}

class MidiDurationResult {
  const MidiDurationResult.available(this.totalDuration, this.timelineEvents)
    : unavailableReason = null;

  const MidiDurationResult.unavailable(this.unavailableReason)
    : totalDuration = Duration.zero,
      timelineEvents = const [];

  final Duration totalDuration;
  final String? unavailableReason;
  final List<MidiTimelineEvent> timelineEvents;
}

class MidiTimelineEvent {
  const MidiTimelineEvent({
    required this.scheduledTime,
    required this.midiNotes,
    required this.noteDurations,
  });

  final Duration scheduledTime;
  final Set<int> midiNotes;
  final Map<int, Duration> noteDurations;

  Duration get longestNoteDuration {
    var longest = Duration.zero;

    for (final duration in noteDurations.values) {
      if (duration > longest) {
        longest = duration;
      }
    }

    return longest;
  }
}

class RawMidiNoteOn {
  RawMidiNoteOn({
    required this.tick,
    required this.midiNote,
    required this.channel,
  });

  final int tick;
  final int midiNote;
  final int channel;
  int? endTick;
}

class MidiTempoEvent {
  const MidiTempoEvent({
    required this.tick,
    required this.microsecondsPerQuarter,
    required this.order,
  });

  final int tick;
  final int microsecondsPerQuarter;
  final int order;
}

class MidiByteReader {
  MidiByteReader(this.bytes);

  final Uint8List bytes;
  int position = 0;

  int get length => bytes.length;

  int readByte([int? limit]) {
    final readLimit = limit ?? bytes.length;

    if (position >= readLimit || position >= bytes.length) {
      throw const FormatException('The MIDI file ended unexpectedly.');
    }

    return bytes[position++];
  }

  int peekByte([int? limit]) {
    final readLimit = limit ?? bytes.length;

    if (position >= readLimit || position >= bytes.length) {
      throw const FormatException('The MIDI file ended unexpectedly.');
    }

    return bytes[position];
  }

  int readUint16() {
    return (readByte() << 8) | readByte();
  }

  int readUint24(int limit) {
    return (readByte(limit) << 16) | (readByte(limit) << 8) | readByte(limit);
  }

  int readUint32() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  int readVariableLength(int limit) {
    var value = 0;

    for (var byteIndex = 0; byteIndex < 4; byteIndex++) {
      final byte = readByte(limit);
      value = (value << 7) | (byte & 0x7F);

      if ((byte & 0x80) == 0) {
        return value;
      }
    }

    throw const FormatException('A MIDI variable-length value is invalid.');
  }

  String readText(int characterCount) {
    final characters = <int>[];

    for (var index = 0; index < characterCount; index++) {
      characters.add(readByte());
    }

    return String.fromCharCodes(characters);
  }

  void skip(int byteCount) {
    final newPosition = position + byteCount;

    if (byteCount < 0 || newPosition > bytes.length) {
      throw const FormatException('The MIDI file ended unexpectedly.');
    }

    position = newPosition;
  }

  void skipWithinTrack(int byteCount, int trackEnd) {
    final newPosition = position + byteCount;

    if (byteCount < 0 || newPosition > trackEnd || newPosition > bytes.length) {
      throw const FormatException('A MIDI event is incomplete.');
    }

    position = newPosition;
  }
}
