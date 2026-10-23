import 'package:cloud_firestore/cloud_firestore.dart';

enum PracticeResultType { sightReading, synthesia, arPerformance }

extension PracticeResultTypeWireName on PracticeResultType {
  String get wireName {
    return switch (this) {
      PracticeResultType.sightReading => 'sightReading',
      PracticeResultType.synthesia => 'synthesia',
      PracticeResultType.arPerformance => 'arPerformance',
    };
  }

  String get label {
    return switch (this) {
      PracticeResultType.sightReading => 'SIGHT READING',
      PracticeResultType.synthesia => 'SYNTHESIA',
      PracticeResultType.arPerformance => 'AR PERFORMANCE',
    };
  }
}

PracticeResultType practiceResultTypeFromWireName(Object? value) {
  for (final type in PracticeResultType.values) {
    if (type.wireName == value) return type;
  }
  return PracticeResultType.sightReading;
}

enum PerformanceIssueType {
  wrongNote,
  early,
  late,
  missed,
  chordTiming,
  releasedEarly,
}

extension PerformanceIssueTypeWireName on PerformanceIssueType {
  String get wireName {
    switch (this) {
      case PerformanceIssueType.wrongNote:
        return 'wrongNote';
      case PerformanceIssueType.early:
        return 'early';
      case PerformanceIssueType.late:
        return 'late';
      case PerformanceIssueType.missed:
        return 'missed';
      case PerformanceIssueType.chordTiming:
        return 'chordTiming';
      case PerformanceIssueType.releasedEarly:
        return 'releasedEarly';
    }
  }

  String get label {
    switch (this) {
      case PerformanceIssueType.wrongNote:
        return 'Different key played';
      case PerformanceIssueType.early:
        return 'Too early';
      case PerformanceIssueType.late:
        return 'Too late';
      case PerformanceIssueType.missed:
        return 'No note played';
      case PerformanceIssueType.chordTiming:
        return 'Chord notes not together';
      case PerformanceIssueType.releasedEarly:
        return 'Released too soon';
    }
  }
}

PerformanceIssueType? performanceIssueTypeFromWireName(String value) {
  for (final issueType in PerformanceIssueType.values) {
    if (issueType.wireName == value) {
      return issueType;
    }
  }

  return null;
}

class ScorePositionMetadata {
  const ScorePositionMetadata({
    required this.positionIndex,
    required this.measureNumber,
    required this.midiNotes,
    required this.clefs,
    required this.staffNumbers,
  });

  factory ScorePositionMetadata.fromJson(Map<String, dynamic> json) {
    return ScorePositionMetadata(
      positionIndex: (json['positionIndex'] as num?)?.toInt() ?? 0,
      measureNumber: json['measureNumber'] as String?,
      midiNotes: _intList(json['midiNotes']),
      clefs: _stringList(json['clefs']),
      staffNumbers: _intList(json['staffNumbers']),
    );
  }

  final int positionIndex;
  final String? measureNumber;
  final List<int> midiNotes;
  final List<String> clefs;
  final List<int> staffNumbers;
}

class NotePerformanceBreakdown {
  const NotePerformanceBreakdown({
    required this.midiNote,
    required this.totalCount,
    required this.errorCount,
    required this.missedCount,
    required this.wrongPlayedCount,
  });

  factory NotePerformanceBreakdown.fromMap(Map<String, dynamic> map) {
    return NotePerformanceBreakdown(
      midiNote: (map['midiNote'] as num?)?.toInt() ?? 0,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      errorCount: (map['errorCount'] as num?)?.toInt() ?? 0,
      missedCount: (map['missedCount'] as num?)?.toInt() ?? 0,
      wrongPlayedCount: (map['wrongPlayedCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int midiNote;
  final int totalCount;
  final int errorCount;
  final int missedCount;
  final int wrongPlayedCount;

  double get errorRate => totalCount == 0 ? 0 : errorCount / totalCount;

  Map<String, dynamic> toMap() {
    return {
      'midiNote': midiNote,
      'totalCount': totalCount,
      'errorCount': errorCount,
      'missedCount': missedCount,
      'wrongPlayedCount': wrongPlayedCount,
    };
  }
}

class ClefPerformanceBreakdown {
  const ClefPerformanceBreakdown({
    required this.clef,
    required this.totalCount,
    required this.errorCount,
    required this.missedCount,
  });

  factory ClefPerformanceBreakdown.fromMap(Map<String, dynamic> map) {
    return ClefPerformanceBreakdown(
      clef: map['clef'] as String? ?? 'unknown',
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      errorCount: (map['errorCount'] as num?)?.toInt() ?? 0,
      missedCount: (map['missedCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String clef;
  final int totalCount;
  final int errorCount;
  final int missedCount;

  double get errorRate => totalCount == 0 ? 0 : errorCount / totalCount;

  Map<String, dynamic> toMap() {
    return {
      'clef': clef,
      'totalCount': totalCount,
      'errorCount': errorCount,
      'missedCount': missedCount,
    };
  }
}

class PracticeResultErrorEvent {
  const PracticeResultErrorEvent({
    required this.positionIndex,
    required this.measureNumber,
    required this.scheduledTimeMs,
    required this.expectedMidiNotes,
    required this.playedMidiNotes,
    required this.clefs,
    required this.staffNumbers,
    required this.issueTypes,
    required this.timingOffsetMs,
    required this.eventuallyMatched,
  });

  factory PracticeResultErrorEvent.fromMap(Map<String, dynamic> map) {
    return PracticeResultErrorEvent(
      positionIndex: (map['positionIndex'] as num?)?.toInt() ?? 0,
      measureNumber: map['measureNumber'] as String?,
      scheduledTimeMs: (map['scheduledTimeMs'] as num?)?.toInt() ?? 0,
      expectedMidiNotes: _intList(map['expectedMidiNotes']),
      playedMidiNotes: _intList(map['playedMidiNotes']),
      clefs: _stringList(map['clefs']),
      staffNumbers: _intList(map['staffNumbers']),
      issueTypes: _stringList(map['issueTypes'])
          .map(performanceIssueTypeFromWireName)
          .whereType<PerformanceIssueType>()
          .toList(growable: false),
      timingOffsetMs: (map['timingOffsetMs'] as num?)?.toInt(),
      eventuallyMatched: map['eventuallyMatched'] == true,
    );
  }

  final int positionIndex;
  final String? measureNumber;
  final int scheduledTimeMs;
  final List<int> expectedMidiNotes;
  final List<int> playedMidiNotes;
  final List<String> clefs;
  final List<int> staffNumbers;
  final List<PerformanceIssueType> issueTypes;
  final int? timingOffsetMs;
  final bool eventuallyMatched;

  Map<String, dynamic> toMap() {
    return {
      'positionIndex': positionIndex,
      'measureNumber': measureNumber,
      'scheduledTimeMs': scheduledTimeMs,
      'expectedMidiNotes': expectedMidiNotes,
      'playedMidiNotes': playedMidiNotes,
      'clefs': clefs,
      'staffNumbers': staffNumbers,
      'issueTypes': issueTypes.map((issue) => issue.wireName).toList(),
      'timingOffsetMs': timingOffsetMs,
      'eventuallyMatched': eventuallyMatched,
    };
  }
}

class PracticeResultSummary {
  const PracticeResultSummary({
    this.id,
    this.practiceType = PracticeResultType.sightReading,
    required this.ownerId,
    required this.scoreDocumentPath,
    required this.source,
    required this.pieceTitle,
    required this.completedAt,
    required this.targetDurationMs,
    required this.elapsedDurationMs,
    required this.correctCount,
    required this.wrongCount,
    required this.missedCount,
    required this.totalCount,
    required this.timingAccuracyPercentage,
    required this.noteBreakdown,
    required this.clefBreakdown,
    required this.suggestions,
    required this.errorEventCount,
    this.storageStatus = 'complete',
  });

  factory PracticeResultSummary.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final timestamp = data['completedAt'];

    return PracticeResultSummary(
      id: document.id,
      practiceType: practiceResultTypeFromWireName(data['practiceType']),
      ownerId: data['ownerId'] as String? ?? '',
      scoreDocumentPath: data['scoreDocumentPath'] as String? ?? '',
      source: data['source'] as String? ?? 'musicSheet',
      pieceTitle: data['pieceTitle'] as String? ?? 'Untitled score',
      completedAt: timestamp is Timestamp ? timestamp.toDate() : null,
      targetDurationMs: (data['targetDurationMs'] as num?)?.toInt() ?? 0,
      elapsedDurationMs: (data['elapsedDurationMs'] as num?)?.toInt() ?? 0,
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
      wrongCount: (data['wrongCount'] as num?)?.toInt() ?? 0,
      missedCount: (data['missedCount'] as num?)?.toInt() ?? 0,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      timingAccuracyPercentage:
          (data['timingAccuracyPercentage'] as num?)?.toInt() ?? 0,
      noteBreakdown: _mapList(
        data['noteBreakdown'],
      ).map(NotePerformanceBreakdown.fromMap).toList(growable: false),
      clefBreakdown: _mapList(
        data['clefBreakdown'],
      ).map(ClefPerformanceBreakdown.fromMap).toList(growable: false),
      suggestions: _stringList(data['suggestions']),
      errorEventCount: (data['errorEventCount'] as num?)?.toInt() ?? 0,
      storageStatus: data['storageStatus'] as String? ?? 'complete',
    );
  }

  final String? id;
  final PracticeResultType practiceType;
  final String ownerId;
  final String scoreDocumentPath;
  final String source;
  final String pieceTitle;
  final DateTime? completedAt;
  final int targetDurationMs;
  final int elapsedDurationMs;
  final int correctCount;
  final int wrongCount;
  final int missedCount;
  final int totalCount;
  final int timingAccuracyPercentage;
  final List<NotePerformanceBreakdown> noteBreakdown;
  final List<ClefPerformanceBreakdown> clefBreakdown;
  final List<String> suggestions;
  final int errorEventCount;
  final String storageStatus;

  String get scoreText => '$correctCount/$totalCount';

  ClefPerformanceBreakdown? get weakestClef {
    final knownClefs =
        clefBreakdown
            .where(
              (item) =>
                  item.clef != 'unknown' &&
                  item.errorCount >= 3 &&
                  item.errorRate >= 0.30,
            )
            .toList()
          ..sort((first, second) {
            final rateComparison = second.errorRate.compareTo(first.errorRate);
            return rateComparison != 0
                ? rateComparison
                : second.errorCount.compareTo(first.errorCount);
          });

    return knownClefs.isEmpty ? null : knownClefs.first;
  }

  PracticeResultSummary copyWith({
    String? id,
    DateTime? completedAt,
    String? storageStatus,
    PracticeResultType? practiceType,
  }) {
    return PracticeResultSummary(
      id: id ?? this.id,
      practiceType: practiceType ?? this.practiceType,
      ownerId: ownerId,
      scoreDocumentPath: scoreDocumentPath,
      source: source,
      pieceTitle: pieceTitle,
      completedAt: completedAt ?? this.completedAt,
      targetDurationMs: targetDurationMs,
      elapsedDurationMs: elapsedDurationMs,
      correctCount: correctCount,
      wrongCount: wrongCount,
      missedCount: missedCount,
      totalCount: totalCount,
      timingAccuracyPercentage: timingAccuracyPercentage,
      noteBreakdown: noteBreakdown,
      clefBreakdown: clefBreakdown,
      suggestions: suggestions,
      errorEventCount: errorEventCount,
      storageStatus: storageStatus ?? this.storageStatus,
    );
  }

  Map<String, dynamic> toMap({required Object completedAtValue}) {
    return {
      'schemaVersion': 2,
      'practiceType': practiceType.wireName,
      'ownerId': ownerId,
      'scoreDocumentPath': scoreDocumentPath,
      'source': source,
      'pieceTitle': pieceTitle,
      'mode': 'performance',
      'completedAt': completedAtValue,
      'targetDurationMs': targetDurationMs,
      'elapsedDurationMs': elapsedDurationMs,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'missedCount': missedCount,
      'totalCount': totalCount,
      'timingAccuracyPercentage': timingAccuracyPercentage,
      'noteBreakdown': noteBreakdown.map((item) => item.toMap()).toList(),
      'clefBreakdown': clefBreakdown.map((item) => item.toMap()).toList(),
      'suggestions': suggestions,
      'errorEventCount': errorEventCount,
      'storageStatus': storageStatus,
    };
  }
}

class SightReadingPerformanceReport {
  const SightReadingPerformanceReport({
    required this.summary,
    required this.errorEvents,
    required this.suggestions,
  });

  final PracticeResultSummary summary;
  final List<PracticeResultErrorEvent> errorEvents;
  final List<String> suggestions;
}

List<int> _intList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.whereType<num>().map((item) => item.toInt()).toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.whereType<String>().toList();
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
