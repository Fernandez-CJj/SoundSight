import '../../players/ar/utils/midi_note_utils.dart';
import '../models/middle_c_guide_result.dart';

/// Converts MIDI note presses into directions toward Middle C.
class MiddleCGuideService {
  const MiddleCGuideService();

  static const int middleCMidiNote = 60;
  static const Set<int> _whitePitchClasses = <int>{0, 2, 4, 5, 7, 9, 11};

  MiddleCGuideResult evaluate(int midiNote) {
    if (midiNote < 0 || midiNote > 127) {
      return MiddleCGuideResult(
        type: MiddleCGuideResultType.invalid,
        midiNote: midiNote,
        noteName: null,
      );
    }

    String noteName = MidiNoteUtils.nameForMidiNote(midiNote);

    if (!_isWhiteKey(midiNote)) {
      return MiddleCGuideResult(
        type: MiddleCGuideResultType.blackKey,
        midiNote: midiNote,
        noteName: noteName,
      );
    }

    if (midiNote == middleCMidiNote) {
      return MiddleCGuideResult(
        type: MiddleCGuideResultType.found,
        midiNote: midiNote,
        noteName: noteName,
      );
    }

    bool moveRight = midiNote < middleCMidiNote;

    return MiddleCGuideResult(
      type: moveRight
          ? MiddleCGuideResultType.moveRight
          : MiddleCGuideResultType.moveLeft,
      midiNote: midiNote,
      noteName: noteName,
      whiteKeyDistance: _whiteKeyDistance(midiNote, middleCMidiNote),
    );
  }

  bool _isWhiteKey(int midiNote) {
    return _whitePitchClasses.contains(midiNote % 12);
  }

  int _whiteKeyDistance(int fromMidiNote, int toMidiNote) {
    int distance = 0;
    int direction = fromMidiNote < toMidiNote ? 1 : -1;

    for (
      int note = fromMidiNote + direction;
      note != toMidiNote + direction;
      note += direction
    ) {
      if (_isWhiteKey(note)) {
        distance++;
      }
    }

    return distance;
  }
}
