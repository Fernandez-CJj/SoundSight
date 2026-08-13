import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soundsight/screens/music_sheet/models/omr_conversion_result.dart';

class MusicSheetOmrService {
  static const String backendUrl = 'http://127.0.0.1:8000';

  Future<OmrConversionResult> recognizeMusicSheet({
    required String sheetId,
    required String ownerId,
  }) async {
    if (sheetId.isEmpty) {
      throw Exception('The music sheet ID is missing.');
    }

    if (ownerId.isEmpty) {
      throw Exception('The owner ID is missing.');
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
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'ownerId': ownerId,
            }),
          )
          .timeout(const Duration(minutes: 15));
    } on TimeoutException {
      throw Exception(
        'Translation took too long. Check the backend and try again.',
      );
    } on http.ClientException {
      throw Exception(
        'SoundSight could not connect to the translation backend. '
        'Make sure the backend is running and reconnect the Android device.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var errorMessage =
          'Recognition failed with status ${response.statusCode}.';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map && errorData['detail'] is String) {
          errorMessage = errorData['detail'];
        }
      } catch (_) {}

      throw Exception(errorMessage);
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('The backend returned an invalid response.');
    }

    return OmrConversionResult(
      message: responseData['message'] as String? ?? '',
      sheetId: responseData['sheetId'] as String? ?? sheetId,
      title: responseData['title'] as String? ?? 'Untitled Sheet',
      omrStatus: responseData['omrStatus'] as String? ?? '',
      partCount: (responseData['partCount'] as num?)?.toInt() ?? 0,
      noteCount: (responseData['noteCount'] as num?)?.toInt() ?? 0,
      musicXmlStoragePath:
          responseData['musicXmlStoragePath'] as String? ?? '',
      previewAudioStoragePath:
          responseData['previewAudioStoragePath'] as String? ?? '',
    );
  }
}
