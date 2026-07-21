class CompositionNote {
  CompositionNote({
    required this.id,
    required this.pitch,
    required this.octave,
    required this.midiNumber,
    required this.measureIndex,
    required num startBeat,
    required num durationBeats,
    num velocity = 0.8,
    this.tieToNext = false,
  }) : startBeat = normalizeTiming(startBeat),
       durationBeats = normalizeTiming(durationBeats),
       velocity = normalizeVelocity(velocity);

  static const double timingStep = 1 / 12;

  final String id;
  final String pitch;
  final int octave;
  final int midiNumber;
  final int measureIndex;
  final double startBeat;
  final double durationBeats;
  final double velocity;
  final bool tieToNext;

  static double normalizeTiming(num value) {
    final normalized = (value.toDouble() / timingStep).round() * timingStep;

    if (normalized.abs() < 0.0000001) {
      return 0;
    }

    return double.parse(normalized.toStringAsFixed(10));
  }

  static double normalizeVelocity(num value) {
    return value.toDouble().clamp(0.0, 1.0).toDouble();
  }

  CompositionNote copyWith({
    String? id,
    String? pitch,
    int? octave,
    int? midiNumber,
    int? measureIndex,
    num? startBeat,
    num? durationBeats,
    num? velocity,
    bool? tieToNext,
  }) {
    return CompositionNote(
      id: id ?? this.id,
      pitch: pitch ?? this.pitch,
      octave: octave ?? this.octave,
      midiNumber: midiNumber ?? this.midiNumber,
      measureIndex: measureIndex ?? this.measureIndex,
      startBeat: startBeat ?? this.startBeat,
      durationBeats: durationBeats ?? this.durationBeats,
      velocity: velocity ?? this.velocity,
      tieToNext: tieToNext ?? this.tieToNext,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': id,
      'pitch': pitch,
      'octave': octave,
      'midiNumber': midiNumber,
      'measureIndex': measureIndex,
      'startBeat': startBeat,
      'durationBeats': durationBeats,
      'velocity': velocity,
      'tieToNext': tieToNext,
    };
  }

  static CompositionNote fromMap(Map<String, dynamic> map) {
    return CompositionNote(
      id: map['noteId'] as String? ?? '',
      pitch: map['pitch'] as String? ?? '',
      octave: (map['octave'] as num?)?.toInt() ?? 4,
      midiNumber: (map['midiNumber'] as num?)?.toInt() ?? 60,
      measureIndex: (map['measureIndex'] as num?)?.toInt() ?? 0,
      startBeat: map['startBeat'] as num? ?? 0,
      durationBeats: map['durationBeats'] as num? ?? 1,
      velocity: map['velocity'] as num? ?? 0.8,
      tieToNext: map['tieToNext'] as bool? ?? false,
    );
  }
}
