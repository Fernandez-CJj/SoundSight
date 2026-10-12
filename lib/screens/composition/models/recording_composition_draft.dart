class RecordingCompositionDraft {
  const RecordingCompositionDraft({
    required this.ownerId,
    required this.title,
    required this.keySignature,
    required this.beatsPerMeasure,
    required this.beatUnit,
  });

  final String ownerId;
  final String title;
  final String keySignature;
  final int beatsPerMeasure;
  final int beatUnit;
}
