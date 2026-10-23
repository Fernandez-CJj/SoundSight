import 'package:flutter/foundation.dart';

@immutable
class SynthesiaWaitNoteOccurrence {
  const SynthesiaWaitNoteOccurrence({
    required this.groupIndex,
    required this.groupStartMicroseconds,
    required this.midiNote,
  });

  final int groupIndex;
  final int groupStartMicroseconds;
  final int midiNote;

  @override
  bool operator ==(Object other) {
    return other is SynthesiaWaitNoteOccurrence &&
        other.groupIndex == groupIndex &&
        other.groupStartMicroseconds == groupStartMicroseconds &&
        other.midiNote == midiNote;
  }

  @override
  int get hashCode {
    return Object.hash(groupIndex, groupStartMicroseconds, midiNote);
  }
}
