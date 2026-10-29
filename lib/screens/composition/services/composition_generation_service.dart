import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:soundsight/constants/backend_config.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/services/composition_service.dart';

class CompositionGenerationService {
  static const String backendUrl = BackendConfig.baseUrl;

  final CompositionService compositionService = CompositionService();

  Future<Map<String, dynamic>> generateCompositionFiles(
    Composition composition,
  ) async {
    if (composition.id.isEmpty) {
      throw StateError('Save the composition before generating its files.');
    }

    await compositionService.markGenerationPending(
      composition.ownerId,
      composition.id,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before generating composition files.');
    }
    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Your sign-in session could not be verified.');
    }
    final response = await http
        .post(
          Uri.parse('$backendUrl/compositions/${composition.id}/generate'),
          headers: {'Authorization': 'Bearer $idToken'},
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
