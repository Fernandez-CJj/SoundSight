class RecordedPerformanceNote {
  const RecordedPerformanceNote({
    required this.midiNumber,
    required this.velocity,
    required this.startTimeUs,
    required this.durationUs,
  });

  final int midiNumber;
  final int velocity;
  final int startTimeUs;
  final int durationUs;

  int get endTimeUs => startTimeUs + durationUs;

  Map<String, dynamic> toMap() {
    return {
      'midiNumber': midiNumber,
      'velocity': velocity,
      'startTimeUs': startTimeUs,
      'durationUs': durationUs,
    };
  }

  static RecordedPerformanceNote fromMap(Map<String, dynamic> map) {
    return RecordedPerformanceNote(
      midiNumber: (map['midiNumber'] as num?)?.toInt() ?? 0,
      velocity: (map['velocity'] as num?)?.toInt() ?? 0,
      startTimeUs: (map['startTimeUs'] as num?)?.toInt() ?? 0,
      durationUs: (map['durationUs'] as num?)?.toInt() ?? 0,
    );
  }
}
