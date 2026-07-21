const compositionKeySignatures = [
  'C Major',
  'G Major',
  'D Major',
  'A Major',
  'E Major',
  'B Major',
  'F# Major',
  'C# Major',
  'F Major',
  'Bb Major',
  'Eb Major',
  'Ab Major',
  'Db Major',
  'Gb Major',
  'Cb Major',
  'A Minor',
  'E Minor',
  'B Minor',
  'F# Minor',
  'C# Minor',
  'G# Minor',
  'D# Minor',
  'A# Minor',
  'D Minor',
  'G Minor',
  'C Minor',
  'F Minor',
  'Bb Minor',
  'Eb Minor',
  'Ab Minor',
];

const compositionTimeSignatures = [
  '2/4',
  '3/4',
  '4/4',
  '5/4',
  '6/4',
  '7/4',
  '3/8',
  '6/8',
  '9/8',
  '12/8',
];

int beatsFromTimeSignature(String value) {
  return int.parse(value.split('/').first);
}

int beatUnitFromTimeSignature(String value) {
  return int.parse(value.split('/').last);
}
