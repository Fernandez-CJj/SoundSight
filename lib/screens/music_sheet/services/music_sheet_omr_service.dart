import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soundsight/screens/music_sheet/models/omr_conversion_result.dart';

enum MusicSheetOmrFailure {
  missingSheetId,
  missingOwnerId,
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
  static const String backendUrl = 'http://192.168.0.104:8000';

  Future<OmrConversionResult> recognizeMusicSheet({
    required String sheetId,
    required String ownerId,
  }) async {
    if (sheetId.isEmpty) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.missingSheetId);
    }

    if (ownerId.isEmpty) {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.missingOwnerId);
    }

    final url = Uri.parse(
      '$backendUrl/music-sheets/'
      '${Uri.encodeComponent(sheetId)}/recognize',
    );

    late final http.Response response;

    try {
      response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ownerId': ownerId}),
          )
          .timeout(const Duration(minutes: 15));
    } on TimeoutException {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.timedOut);
    } on http.ClientException {
      throw const MusicSheetOmrException(MusicSheetOmrFailure.connection);
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
