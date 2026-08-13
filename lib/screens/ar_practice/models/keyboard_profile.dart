// Stores the information for one physical keyboard.
// Note names are shown to the user, while MIDI numbers identify the exact keys
// that belong to the keyboard range.
class KeyboardProfile {
  const KeyboardProfile({
    required this.name,
    required this.keyCount,
    required this.firstNote,
    required this.lastNote,
    required this.firstMidiNumber,
    required this.lastMidiNumber,
  });

  final String name;
  final int keyCount;
  final String firstNote;
  final String lastNote;
  final int firstMidiNumber;
  final int lastMidiNumber;

  // Provides the four supported standard keyboard profiles.
  // Keeping them here prevents repeated ranges in different screens and avoids
  // giving a standard keyboard the wrong notes or MIDI numbers.
  static const KeyboardProfile keys49 = KeyboardProfile(
    name: '49 Keys',
    keyCount: 49,
    firstNote: 'C2',
    lastNote: 'C6',
    firstMidiNumber: 36,
    lastMidiNumber: 84,
  );

  static const KeyboardProfile keys61 = KeyboardProfile(
    name: '61 Keys',
    keyCount: 61,
    firstNote: 'C2',
    lastNote: 'C7',
    firstMidiNumber: 36,
    lastMidiNumber: 96,
  );

  static const KeyboardProfile keys76 = KeyboardProfile(
    name: '76 Keys',
    keyCount: 76,
    firstNote: 'E1',
    lastNote: 'G7',
    firstMidiNumber: 28,
    lastMidiNumber: 103,
  );

  static const KeyboardProfile keys88 = KeyboardProfile(
    name: '88 Keys',
    keyCount: 88,
    firstNote: 'A0',
    lastNote: 'C8',
    firstMidiNumber: 21,
    lastMidiNumber: 108,
  );

  // Creates a readable range for the setup screen.
  // For example, the 88-key profile returns the text "A0 - C8".
  String getNoteRange() {
    String range = '$firstNote - $lastNote';
    return range;
  }

  // Makes sure the profile contains valid information.
  // Checks the MIDI limits, endpoint order, and whether the MIDI
  // range contains the same number of keys as keyCount.
  bool isRangeValid() {
    if (name.trim().isEmpty) {
      return false;
    }

    if (firstNote.trim().isEmpty || lastNote.trim().isEmpty) {
      return false;
    }

    if (firstMidiNumber < 0 || firstMidiNumber > 127) {
      return false;
    }

    if (lastMidiNumber < 0 || lastMidiNumber > 127) {
      return false;
    }

    if (firstMidiNumber > lastMidiNumber) {
      return false;
    }

    int rangeKeyCount = lastMidiNumber - firstMidiNumber + 1;

    if (rangeKeyCount != keyCount) {
      return false;
    }

    return true;
  }
}
