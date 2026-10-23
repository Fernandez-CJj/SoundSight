import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../models/ar_score_timeline.dart';
import 'midi_timeline_parser.dart';

/// Loads a challenge's MIDI URL from Firestore and parses its downloaded bytes.
///
/// Firestore and HTTP dependencies can be injected for isolated tests. When the
/// loader creates its own HTTP client, [dispose] closes it.
class ArScoreTimelineLoader {
  ArScoreTimelineLoader({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    http.Client? httpClient,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance,
       httpClient = httpClient ?? http.Client(),
       ownsHttpClient = httpClient == null;

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final http.Client httpClient;
  final bool ownsHttpClient;

  final MidiTimelineParser midiTimelineParser = const MidiTimelineParser();

  /// Fetches, validates, downloads, and parses the selected score timeline.
  ///
  /// User-readable [ArScoreTimelineLoadException] messages distinguish missing
  /// documents/fields, download failures, empty files, and malformed MIDI.
  Future<ArScoreTimeline> load({required String scoreDocumentPath}) async {
    String cleanDocumentPath = scoreDocumentPath.trim();

    if (cleanDocumentPath.isEmpty) {
      throw const ArScoreTimelineLoadException(
        'The score document path is missing.',
      );
    }

    DocumentSnapshot<Map<String, dynamic>> scoreSnapshot;

    try {
      scoreSnapshot = await firestore.doc(cleanDocumentPath).get();
    } on FirebaseException catch (error) {
      throw ArScoreTimelineLoadException(
        'The score document could not be loaded: ${error.message ?? error.code}',
      );
    }

    if (!scoreSnapshot.exists) {
      throw const ArScoreTimelineLoadException(
        'The selected score does not exist in Firestore.',
      );
    }

    Map<String, dynamic>? scoreData = scoreSnapshot.data();
    Object? midiUrlValue = scoreData?['midiUrl'];
    Object? midiStoragePathValue = scoreData?['midiStoragePath'];
    String? midiUrl;

    if (midiUrlValue is String && midiUrlValue.trim().isNotEmpty) {
      midiUrl = midiUrlValue.trim();
    } else if (midiStoragePathValue is String &&
        midiStoragePathValue.trim().isNotEmpty) {
      try {
        midiUrl = await storage
            .ref(midiStoragePathValue.trim())
            .getDownloadURL();
      } on FirebaseException catch (error) {
        throw ArScoreTimelineLoadException(
          'The MIDI score could not be opened: ${error.message ?? error.code}',
        );
      }
    }

    if (midiUrl == null) {
      throw const ArScoreTimelineLoadException(
        'The selected score does not contain a MIDI file.',
      );
    }

    Uri? midiUri = Uri.tryParse(midiUrl);

    if (midiUri == null || !midiUri.hasScheme) {
      throw const ArScoreTimelineLoadException(
        'The selected score contains an invalid MIDI file address.',
      );
    }

    http.Response midiResponse;

    try {
      midiResponse = await httpClient.get(midiUri);
    } on Exception catch (error) {
      throw ArScoreTimelineLoadException(
        'The MIDI score could not be downloaded: $error',
      );
    }

    if (midiResponse.statusCode != 200) {
      throw ArScoreTimelineLoadException(
        'The MIDI download failed with status ${midiResponse.statusCode}.',
      );
    }

    if (midiResponse.bodyBytes.isEmpty) {
      throw const ArScoreTimelineLoadException(
        'The downloaded MIDI score is empty.',
      );
    }

    try {
      ArScoreTimeline parsedTimeline = midiTimelineParser.parse(
        midiResponse.bodyBytes,
      );
      Object? titleValue = scoreData?['title'];
      String pieceTitle = titleValue is String && titleValue.trim().isNotEmpty
          ? titleValue.trim()
          : 'Untitled score';

      return ArScoreTimeline(
        noteEvents: parsedTimeline.noteEvents,
        totalDuration: parsedTimeline.totalDuration,
        pieceTitle: pieceTitle,
      );
    } on FormatException catch (error) {
      throw ArScoreTimelineLoadException(error.message.toString());
    }
  }

  /// Closes only an internally created HTTP client.
  void dispose() {
    if (ownsHttpClient) {
      httpClient.close();
    }
  }
}

/// Expected score-loading failure suitable for display in the AR picker UI.
class ArScoreTimelineLoadException implements Exception {
  const ArScoreTimelineLoadException(this.message);

  /// User-readable explanation of the failed loading stage.
  final String message;

  @override
  /// Returns [message] when the exception is logged or interpolated.
  String toString() {
    return message;
  }
}
