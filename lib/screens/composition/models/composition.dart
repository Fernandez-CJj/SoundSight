import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';

class Composition {
  static const String manualCreationMethod = 'manual';
  static const String recordingCreationMethod = 'recording';
  static const String pendingGenerationStatus = 'pending';
  static const String generatingStatus = 'generating';
  static const String completedGenerationStatus = 'completed';
  static const String failedGenerationStatus = 'failed';

  const Composition({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.tempo,
    required this.measureCount,
    required this.notes,
    this.creationMethod = manualCreationMethod,
    this.keySignature = 'C Major',
    this.beatsPerMeasure = 4,
    this.beatUnit = 4,
    this.pdfStoragePath,
    this.musicXmlStoragePath,
    this.midiStoragePath,
    this.mp3StoragePath,
    this.generationStatus,
    this.filesGeneratedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final int tempo;
  final int measureCount;
  final List<CompositionNote> notes;

  final String creationMethod;

  final String keySignature;
  final int beatsPerMeasure;
  final int beatUnit;

  final String? pdfStoragePath;
  final String? musicXmlStoragePath;
  final String? midiStoragePath;
  final String? mp3StoragePath;

  final String? generationStatus;
  final DateTime? filesGeneratedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAllGeneratedFiles {
    return pdfStoragePath?.isNotEmpty == true &&
        musicXmlStoragePath?.isNotEmpty == true &&
        midiStoragePath?.isNotEmpty == true &&
        mp3StoragePath?.isNotEmpty == true;
  }

  bool get generatedFilesAreCurrent {
    if (!hasAllGeneratedFiles) {
      return false;
    }

    if (generationStatus != null &&
        generationStatus != completedGenerationStatus) {
      return false;
    }

    if (filesGeneratedAt == null) {
      return false;
    }

    if (updatedAt != null && filesGeneratedAt!.isBefore(updatedAt!)) {
      return false;
    }

    return generationStatus == completedGenerationStatus ||
        generationStatus == null;
  }

  bool get generatedFilesAreOutOfDate {
    return hasAllGeneratedFiles && !generatedFilesAreCurrent;
  }

  Composition copyWith({
    String? id,
    String? ownerId,
    String? title,
    int? tempo,
    int? measureCount,
    List<CompositionNote>? notes,
    String? creationMethod,
    String? keySignature,
    int? beatsPerMeasure,
    int? beatUnit,
    String? pdfStoragePath,
    String? musicXmlStoragePath,
    String? midiStoragePath,
    String? mp3StoragePath,
    String? generationStatus,
    DateTime? filesGeneratedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Composition(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      tempo: tempo ?? this.tempo,
      measureCount: measureCount ?? this.measureCount,
      notes: notes ?? this.notes,
      creationMethod: creationMethod ?? this.creationMethod,
      keySignature: keySignature ?? this.keySignature,
      beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
      beatUnit: beatUnit ?? this.beatUnit,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      musicXmlStoragePath: musicXmlStoragePath ?? this.musicXmlStoragePath,
      midiStoragePath: midiStoragePath ?? this.midiStoragePath,
      mp3StoragePath: mp3StoragePath ?? this.mp3StoragePath,
      generationStatus: generationStatus ?? this.generationStatus,
      filesGeneratedAt: filesGeneratedAt ?? this.filesGeneratedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
      'creationMethod': creationMethod,
    };
  }

  /// Reads a supported stored method and identifies older generated documents
  /// as recordings when they were saved before this field existed.
  static String creationMethodFromMap(Map<String, dynamic> map) {
    final storedMethod = map['creationMethod'];

    if (storedMethod == manualCreationMethod ||
        storedMethod == recordingCreationMethod) {
      return storedMethod as String;
    }

    final hasGeneratedRecordingFiles =
        map['pdfStoragePath'] is String ||
        map['musicXmlStoragePath'] is String ||
        map['midiStoragePath'] is String ||
        map['mp3StoragePath'] is String;

    return hasGeneratedRecordingFiles
        ? recordingCreationMethod
        : manualCreationMethod;
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
    final filesGeneratedAtData = map['filesGeneratedAt'];
    return Composition(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Composition',
      tempo: (map['tempo'] as num?)?.toInt() ?? 80,
      measureCount: (map['measureCount'] as num?)?.toInt() ?? 1,
      notes: notes,
      creationMethod: creationMethodFromMap(map),
      keySignature: map['key'] as String? ?? 'C Major',
      beatsPerMeasure: (map['beatsPerMeasure'] as num?)?.toInt() ?? 4,
      beatUnit: (map['beatUnit'] as num?)?.toInt() ?? 4,
      pdfStoragePath: map['pdfStoragePath'] as String?,
      musicXmlStoragePath: map['musicXmlStoragePath'] as String?,
      midiStoragePath: map['midiStoragePath'] as String?,
      mp3StoragePath: map['mp3StoragePath'] as String?,
      generationStatus: map['generationStatus'] as String?,
      filesGeneratedAt: filesGeneratedAtData is Timestamp
          ? filesGeneratedAtData.toDate()
          : null,
      createdAt: createdAtData is Timestamp ? createdAtData.toDate() : null,
      updatedAt: updatedAtData is Timestamp ? updatedAtData.toDate() : null,
    );
  }
}
