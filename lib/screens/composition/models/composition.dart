import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';

class Composition {
  const Composition({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.tempo,
    required this.measureCount,
    required this.notes,
    this.keySignature = 'C Major',
    this.beatsPerMeasure = 4,
    this.beatUnit = 4,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final int tempo;
  final int measureCount;
  final List<CompositionNote> notes;

  final String keySignature;
  final int beatsPerMeasure;
  final int beatUnit;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'key': keySignature,
      'tempo': tempo,
      'beatsPerMeasure': beatsPerMeasure,
      'beatUnit': beatUnit,
      'measureCount': measureCount,
      'notes': notes.map((note) => note.toMap()).toList(),
    };
  }

  static Composition fromMap(String id, Map<String, dynamic> map) {
    final notes = <CompositionNote>[];
    final notesData = map['notes'];

    if (notesData is List) {
      for (final noteData in notesData) {
        if (noteData is Map) {
          final noteMap = Map<String, dynamic>.from(noteData);
          final note = CompositionNote.fromMap(noteMap);

          notes.add(note);
        }
      }
    }

    final createdAtData = map['createdAt'];
    final updatedAtData = map['updatedAt'];

    return Composition(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Composition',
      tempo: (map['tempo'] as num?)?.toInt() ?? 80,
      measureCount: (map['measureCount'] as num?)?.toInt() ?? 1,
      notes: notes,
      keySignature: map['key'] as String? ?? 'C Major',
      beatsPerMeasure: (map['beatsPerMeasure'] as num?)?.toInt() ?? 4,
      beatUnit: (map['beatUnit'] as num?)?.toInt() ?? 4,
      createdAt: createdAtData is Timestamp ? createdAtData.toDate() : null,
      updatedAt: updatedAtData is Timestamp ? updatedAtData.toDate() : null,
    );
  }
}
