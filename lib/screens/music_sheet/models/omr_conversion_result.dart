class OmrConversionResult {
  const OmrConversionResult({
    required this.message,
    required this.sheetId,
    required this.title,
    required this.omrStatus,
    required this.partCount,
    required this.noteCount,
    required this.musicXmlStoragePath,
    required this.midiStoragePath,
    required this.recognizedPdfStoragePath,
    required this.previewAudioStoragePath,
  });

  final String message;
  final String sheetId;
  final String title;
  final String omrStatus;
  final int partCount;
  final int noteCount;
  final String musicXmlStoragePath;
  final String midiStoragePath;
  final String recognizedPdfStoragePath;
  final String previewAudioStoragePath;
}
