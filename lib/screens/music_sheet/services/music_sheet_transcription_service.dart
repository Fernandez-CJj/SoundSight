import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:soundsight/constants/backend_config.dart';

enum MusicSheetTranscriptionFailure {
  notSignedIn,
  emailNotVerified,
  timedOut,
  connection,
  rejected,
  invalidResponse,
}

class MusicSheetTranscriptionException implements Exception {
  const MusicSheetTranscriptionException(this.failure);
  final MusicSheetTranscriptionFailure failure;
}

class MusicSheetTranscriptionService {
  Future<int> transcribeAudio({required String sheetId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.notSignedIn,
      );
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.notSignedIn,
      );
    }

    final url = Uri.parse(
      '${BackendConfig.baseUrl}/music-sheets/'
      '${Uri.encodeComponent(sheetId)}/transcribe-audio',
    );
    late final http.Response response;
    try {
      response = await http
          .post(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(minutes: 40));
    } on TimeoutException {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.timedOut,
      );
    } on http.ClientException {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.connection,
      );
    }

    if (response.statusCode == 401) {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.notSignedIn,
      );
    }
    if (response.statusCode == 403) {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.emailNotVerified,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.rejected,
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> ||
        data['transcriptionStatus'] != 'completed' ||
        data['midiStoragePath'] is! String ||
        (data['midiStoragePath'] as String).isEmpty ||
        data['musicXmlStoragePath'] is! String ||
        (data['musicXmlStoragePath'] as String).isEmpty ||
        data['recognizedPdfStoragePath'] is! String ||
        (data['recognizedPdfStoragePath'] as String).isEmpty ||
        data['previewAudioStoragePath'] is! String ||
        (data['previewAudioStoragePath'] as String).isEmpty ||
        data['noteCount'] is! num) {
      throw const MusicSheetTranscriptionException(
        MusicSheetTranscriptionFailure.invalidResponse,
      );
    }
    return (data['noteCount'] as num).toInt();
  }
}
