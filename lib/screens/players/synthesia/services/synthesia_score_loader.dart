import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/composition_note.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';

import '../../ar/models/ar_note_event.dart';
import '../../ar/models/ar_score_timeline.dart';
import '../../ar/services/midi_timeline_parser.dart';
import '../models/synthesia_score.dart';
import '../models/synthesia_score_source.dart';

class SynthesiaScoreLoader {
  SynthesiaScoreLoader({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    http.Client? httpClient,
    PublishedCompositionService? publishedCompositionService,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance,
       httpClient = httpClient ?? http.Client(),
       ownsHttpClient = httpClient == null,
       publishedCompositionService =
           publishedCompositionService ?? PublishedCompositionService();

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final http.Client httpClient;
  final bool ownsHttpClient;
  final PublishedCompositionService publishedCompositionService;
  final MidiTimelineParser midiTimelineParser = const MidiTimelineParser();

  Future<SynthesiaScore> load(SynthesiaScoreSource source) async {
    switch (source) {
      case SynthesiaCompositionSource():
        final audioUrl = await _resolveAudioUrl(
          storagePath: source.composition.mp3StoragePath,
        );
        return _fromComposition(source.composition, audioUrl: audioUrl);
      case SynthesiaPublishedCompositionSource():
        return _fromPublishedComposition(source);
      case SynthesiaDocumentSource():
        return _fromDocument(source);
    }
  }

  Future<SynthesiaScore> _fromPublishedComposition(
    SynthesiaPublishedCompositionSource source,
  ) async {
    final composition = await publishedCompositionService
        .loadPlayableComposition(source.composition);

    if (composition == null) {
      throw const SynthesiaScoreLoadException(
        'This published version has no playable note data.',
      );
    }

    final audioUrl = await _resolveAudioUrl(
      storagePath: source.composition.mp3StoragePath,
    );
    return _fromComposition(
      composition.copyWith(title: source.composition.title),
      audioUrl: audioUrl,
    );
  }

  SynthesiaScore _fromComposition(
    Composition composition, {
    String? audioUrl,
  }) {
    if (!composition.hasPlayableContent) {
      throw const SynthesiaScoreLoadException(
        'This composition does not contain any playable notes.',
      );
    }
    if (composition.tempo <= 0 || composition.beatUnit <= 0) {
      throw const SynthesiaScoreLoadException(
        'This composition has invalid playback timing.',
      );
    }

    final events = <ArNoteEvent>[];

    if (composition.usesPerformanceRecording) {
      for (final note in composition.performanceNotes) {
        if (note.durationUs <= 0) continue;
        events.add(
          ArNoteEvent(
            midiNote: note.midiNumber,
            startTime: Duration(microseconds: note.startTimeUs),
            duration: Duration(microseconds: note.durationUs),
          ),
        );
      }
    } else {
      final microsecondsPerBeat =
          (60000000 / composition.tempo) * (4 / composition.beatUnit);

      for (final span in _buildCompositionSpans(composition)) {
        events.add(
          ArNoteEvent(
            midiNote: span.midiNumber,
            startTime: Duration(
              microseconds: (span.startBeat * microsecondsPerBeat).round(),
            ),
            duration: Duration(
              microseconds:
                  ((span.endBeat - span.startBeat) * microsecondsPerBeat)
                      .round(),
            ),
          ),
        );
      }
    }

    return _scoreFromEvents(
      composition.title,
      events,
      audioUrl: audioUrl,
    );
  }

  List<_CompositionSpan> _buildCompositionSpans(Composition composition) {
    final notes = composition.notes.where((note) {
      return note.durationBeats > 0;
    }).toList()
      ..sort((first, second) {
        final startComparison = _absoluteBeat(
          first,
          composition,
        ).compareTo(_absoluteBeat(second, composition));
        if (startComparison != 0) return startComparison;
        return first.midiNumber.compareTo(second.midiNumber);
      });
    final consumedIds = <String>{};
    final spans = <_CompositionSpan>[];

    for (final note in notes) {
      if (consumedIds.contains(note.id)) continue;

      final startBeat = _absoluteBeat(note, composition);
      var endBeat = startBeat + note.durationBeats;
      var current = note;

      while (current.tieToNext) {
        CompositionNote? continuation;

        for (final candidate in notes) {
          if (candidate.id == current.id ||
              consumedIds.contains(candidate.id) ||
              candidate.midiNumber != current.midiNumber) {
            continue;
          }

          if ((_absoluteBeat(candidate, composition) - endBeat).abs() <
              CompositionNote.timingEpsilon) {
            continuation = candidate;
            break;
          }
        }

        if (continuation == null) break;
        consumedIds.add(continuation.id);
        current = continuation;
        endBeat =
            _absoluteBeat(continuation, composition) +
            continuation.durationBeats;
      }

      spans.add(
        _CompositionSpan(
          midiNumber: note.midiNumber,
          startBeat: startBeat,
          endBeat: endBeat,
        ),
      );
    }

    return spans;
  }

  double _absoluteBeat(CompositionNote note, Composition composition) {
    return (note.measureIndex * composition.beatsPerMeasure) + note.startBeat;
  }

  Future<SynthesiaScore> _fromDocument(
    SynthesiaDocumentSource source,
  ) async {
    final snapshot = await firestore.doc(source.documentPath).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      throw const SynthesiaScoreLoadException(
        'The selected music sheet no longer exists.',
      );
    }

    if (data['omrStatus'] != 'completed') {
      throw const SynthesiaScoreLoadException(
        'Translate the music sheet before starting Synthesia.',
      );
    }

    final midiBytes = await _loadMidiBytes(
      directUrl: data['midiUrl'],
      storagePath: data['midiStoragePath'],
    );
    final loadedTitle = data['title'];
    final title = loadedTitle is String && loadedTitle.trim().isNotEmpty
        ? loadedTitle.trim()
        : source.fallbackTitle;
    final audioUrl = await _resolveAudioUrl(
      directUrl: data['mp3Url'] ?? data['previewAudioUrl'],
      storagePath:
          data['previewAudioStoragePath'] ?? data['mp3StoragePath'],
    );

    try {
      final timeline = midiTimelineParser.parse(midiBytes);
      if (timeline.isEmpty) {
        throw const SynthesiaScoreLoadException(
          'The translated MIDI file contains no playable notes.',
        );
      }
      return SynthesiaScore(
        title: title,
        timeline: timeline,
        audioUrl: audioUrl,
      );
    } on FormatException catch (error) {
      throw SynthesiaScoreLoadException(error.message.toString());
    }
  }

  Future<Uint8List> _loadMidiBytes({
    required Object? directUrl,
    required Object? storagePath,
  }) async {
    String? url;

    if (directUrl is String && directUrl.trim().isNotEmpty) {
      url = directUrl.trim();
    } else if (storagePath is String && storagePath.trim().isNotEmpty) {
      url = await storage.ref(storagePath.trim()).getDownloadURL();
    }

    if (url == null) {
      throw const SynthesiaScoreLoadException(
        'The translated MIDI file is missing.',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const SynthesiaScoreLoadException(
        'The translated MIDI address is invalid.',
      );
    }

    final response = await httpClient.get(uri);
    if (response.statusCode != 200) {
      throw SynthesiaScoreLoadException(
        'The MIDI download failed with status ${response.statusCode}.',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw const SynthesiaScoreLoadException(
        'The translated MIDI file is empty.',
      );
    }
    return response.bodyBytes;
  }

  Future<String?> _resolveAudioUrl({
    Object? directUrl,
    Object? storagePath,
  }) async {
    if (directUrl is String && directUrl.trim().isNotEmpty) {
      return directUrl.trim();
    }
    if (storagePath is! String || storagePath.trim().isEmpty) {
      return null;
    }

    try {
      return await storage.ref(storagePath.trim()).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  SynthesiaScore _scoreFromEvents(
    String title,
    List<ArNoteEvent> events, {
    String? audioUrl,
  }) {
    if (events.isEmpty) {
      throw const SynthesiaScoreLoadException(
        'This score does not contain any playable notes.',
      );
    }
    if (events.any((event) => event.midiNote < 21 || event.midiNote > 108)) {
      throw const SynthesiaScoreLoadException(
        'This score contains notes outside the supported 88-key piano range.',
      );
    }

    events.sort((first, second) {
      final startComparison = first.startTime.compareTo(second.startTime);
      if (startComparison != 0) return startComparison;
      return first.midiNote.compareTo(second.midiNote);
    });
    var totalDuration = Duration.zero;
    for (final event in events) {
      if (event.endTime > totalDuration) totalDuration = event.endTime;
    }

    return SynthesiaScore(
      title: title,
      timeline: ArScoreTimeline(
        noteEvents: events,
        totalDuration: totalDuration,
      ),
      audioUrl: audioUrl,
    );
  }

  void dispose() {
    if (ownsHttpClient) httpClient.close();
  }
}

class SynthesiaScoreLoadException implements Exception {
  const SynthesiaScoreLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _CompositionSpan {
  const _CompositionSpan({
    required this.midiNumber,
    required this.startBeat,
    required this.endBeat,
  });

  final int midiNumber;
  final double startBeat;
  final double endBeat;
}
