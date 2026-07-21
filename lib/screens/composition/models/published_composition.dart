import 'package:cloud_firestore/cloud_firestore.dart';

class PublishedComposition {
  const PublishedComposition({
    required this.id,
    required this.compositionId,
    required this.ownerId,
    required this.authorName,
    required this.authorProfileImageUrl,
    required this.currentVersion,
    required this.title,
    required this.tempo,
    required this.keySignature,
    required this.beatsPerMeasure,
    required this.beatUnit,
    required this.measureCount,
    required this.noteCount,
    required this.pdfStoragePath,
    this.publishedAt,
  });

  final String id;
  final String compositionId;
  final String ownerId;
  final String authorName;
  final String authorProfileImageUrl;
  final int currentVersion;
  final String title;
  final int tempo;
  final String keySignature;
  final int beatsPerMeasure;
  final int beatUnit;
  final int measureCount;
  final int noteCount;
  final String pdfStoragePath;
  final DateTime? publishedAt;

  static PublishedComposition fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final publishedAtData = map['publishedAt'];

    return PublishedComposition(
      id: id,
      compositionId: map['compositionId'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      authorName:
          map['authorName'] as String? ?? 'SoundSight Musician',
      authorProfileImageUrl:
          map['authorProfileImageUrl'] as String? ?? '',
      currentVersion: (map['versionNumber'] as num?)?.toInt() ??
          (map['currentVersion'] as num?)?.toInt() ??
          1,
      title: map['title'] as String? ?? 'Untitled Composition',
      tempo: (map['tempo'] as num?)?.toInt() ?? 80,
      keySignature: map['key'] as String? ?? 'C Major',
      beatsPerMeasure: (map['beatsPerMeasure'] as num?)?.toInt() ?? 4,
      beatUnit: (map['beatUnit'] as num?)?.toInt() ?? 4,
      measureCount: (map['measureCount'] as num?)?.toInt() ?? 1,
      noteCount: (map['noteCount'] as num?)?.toInt() ?? 0,
      pdfStoragePath: map['pdfStoragePath'] as String? ?? '',
      publishedAt: publishedAtData is Timestamp
          ? publishedAtData.toDate()
          : null,
    );
  }
}
