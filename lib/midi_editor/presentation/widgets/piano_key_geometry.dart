class PianoKeyGeometry {
  const PianoKeyGeometry._();

  static const int lowPitch = 21;
  static const int highPitch = 108;
  static const int keyCount = highPitch - lowPitch + 1;
  static const int whiteKeyCount = 52;
  static const double blackKeyWidthFactor = 0.58;
  static const double blackKeyLengthFactor = 0.64;

  static bool isBlackKey(int midi) =>
      switch (midi % 12) { 1 || 3 || 6 || 8 || 10 => true, _ => false };

  static String noteName(int midi) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return '${names[midi % 12]}${midi ~/ 12 - 1}';
  }

  static String keyLabel(int midi) {
    const naturals = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return naturals[midi % 12];
  }

  static double keyStart(int pitch, double whiteKeyWidth) {
    if (!isBlackKey(pitch)) {
      return _whiteIndex(pitch) * whiteKeyWidth;
    }
    final blackExtent = keyWidth(pitch, whiteKeyWidth);
    final previousWhite = _whiteIndex(pitch) - 1;
    return (previousWhite + 1) * whiteKeyWidth - blackExtent / 2;
  }

  static double keyWidth(int pitch, double whiteKeyWidth) {
    return isBlackKey(pitch) ? whiteKeyWidth * blackKeyWidthFactor : whiteKeyWidth;
  }

  static double keyCenter(int pitch, double whiteKeyWidth) {
    return keyStart(pitch, whiteKeyWidth) + keyWidth(pitch, whiteKeyWidth) / 2;
  }

  static int pitchFromAxis(double axisPosition, double whiteKeyWidth) {
    for (var pitch = lowPitch; pitch <= highPitch; pitch++) {
      if (!isBlackKey(pitch)) {
        continue;
      }
      final start = keyStart(pitch, whiteKeyWidth);
      final end = start + keyWidth(pitch, whiteKeyWidth);
      if (axisPosition >= start && axisPosition <= end) {
        return pitch;
      }
    }

    final whiteIndex = (axisPosition / whiteKeyWidth).floor().clamp(0, whiteKeyCount - 1);
    var index = 0;
    for (var pitch = lowPitch; pitch <= highPitch; pitch++) {
      if (isBlackKey(pitch)) {
        continue;
      }
      if (index == whiteIndex) {
        return pitch;
      }
      index++;
    }
    return highPitch;
  }

  static int _whiteIndex(int pitch) {
    var index = 0;
    for (var midi = lowPitch; midi < pitch; midi++) {
      if (!isBlackKey(midi)) {
        index++;
      }
    }
    return index;
  }
}
