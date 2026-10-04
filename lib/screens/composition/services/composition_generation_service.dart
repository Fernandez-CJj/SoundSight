import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';

class CompositionGenerationService {
  static const String backendUrl = 'http://192.168.0.104:8000';

  final CompositionService compositionService = CompositionService();

  Future<Map<String, dynamic>> generateCompositionFiles(
    Composition composition,
  ) async {
    if (composition.id.isEmpty) {
      throw StateError('Save the composition before generating its files.');
    }

    await compositionService.markGenerationPending(composition.id);

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
          Uri.parse('$backendUrl/compositions/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'File generation failed with status '
        '${response.statusCode}.',
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return responseData;
  }
}
