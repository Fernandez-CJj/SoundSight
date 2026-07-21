import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:soundsight/screens/composition/models/composition.dart';

class CompositionPublishService {
  static const String backendUrl = 'http://127.0.0.1:8000';

  Future<String> publishComposition(Composition composition) async {
    final requestData = composition.toMap();

    requestData['id'] = composition.id;
    requestData['notes'] = composition.notes.map((note) {
      final noteData = note.toMap();

      noteData['id'] = note.id;
      noteData.remove('noteId');

      return noteData;
    }).toList();

    final response = await http
        .post(
          Uri.parse('$backendUrl/compositions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        )
        .timeout(const Duration(minutes: 2));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Publishing failed with status '
        '${response.statusCode}.',
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return responseData['postId'] as String? ?? composition.id;
  }

  Future<void> unpublishComposition({
    required String compositionId,
    required String ownerId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$backendUrl/compositions/$compositionId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'ownerId': ownerId}),
        )
        .timeout(const Duration(minutes: 1));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Unpublishing failed with status '
        '${response.statusCode}.',
      );
    }
  }
}
