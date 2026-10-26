import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:soundsight/screens/music_sheet/models/omr_conversion_result.dart';

enum MusicSheetOmrFailure {
  missingSheetId,
  notSignedIn,
  emailNotVerified,
  timedOut,
  connection,
  rejected,
  invalidResponse,
}

class MusicSheetOmrException implements Exception {
  const MusicSheetOmrException(this.failure);

  final MusicSheetOmrFailure failure;
}

class MusicSheetOmrService {
  static const String backendUrl =
      'https://cindy-unsigned-quit-gerald.trycloudflare.com';

  Future<OmrConversionResult> recognizeMusicSheet({
    required String sheetId,
  }) async {
    if (sheetId.isEmpty) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.missingSheetId);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.notSignedIn);
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.notSignedIn);
    }

    final url = Uri.parse(
      '$backendUrl/music-sheets/'
      '${Uri.encodeComponent(sheetId)}/recognize',
    );

    late final http.Response response;

    try {
      response = await http
          .post(url, headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(minutes: 15));
    } on TimeoutException {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.timedOut);
    } on http.ClientException {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.connection);
    }

    if (response.statusCode == 401) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.notSignedIn);
    }

    if (response.statusCode == 403) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.emailNotVerified);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.rejected);
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.invalidResponse);
    }

    return OmrConversionResult(
      message: responseData['message'] as String? ?? '',
      sheetId: responseData['sheetId'] as String? ?? sheetId,
      title: responseData['title'] as String? ?? 'Untitled Sheet',
      omrStatus: responseData['omrStatus'] as String? ?? '',
      partCount: (responseData['partCount'] as num?)?.toInt() ?? 0,
      noteCount: (responseData['noteCount'] as num?)?.toInt() ?? 0,
      musicXmlStoragePath: responseData['musicXmlStoragePath'] as String? ?? '',
      midiStoragePath: responseData['midiStoragePath'] as String? ?? '',
      recognizedPdfStoragePath:
          responseData['recognizedPdfStoragePath'] as String? ?? '',
      previewAudioStoragePath:
          responseData['previewAudioStoragePath'] as String? ?? '',
    );
  }
}
