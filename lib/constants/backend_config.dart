import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class BackendUnavailableException implements Exception {
  const BackendUnavailableException();
}

class BackendConfig {
  // An explicit build argument still supports local Wi-Fi development.
  // Distributed APKs omit it and discover the address from Firebase instead.
  static const String _override = String.fromEnvironment(
    'SOUNDSIGHT_BACKEND_URL',
  );
  static const _cacheLifetime = Duration(minutes: 2);
  static String? _cachedUrl;
  static DateTime? _loadedAt;
  static Future<String>? _loading;

  static String _validateUrl(String value, {required bool remote}) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (remote &&
            (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(uri.host) ||
                uri.port != 443)) ||
        (remote
            ? uri.scheme != 'https'
            : uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const BackendUnavailableException();
    }
    return uri.replace(path: '').toString();
  }

  static Future<String> resolveBaseUrl({bool refresh = false}) async {
    if (_override.isNotEmpty) return _validateUrl(_override, remote: false);
    final cached = _cachedUrl;
    if (!refresh &&
        cached != null &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < _cacheLifetime) {
      return cached;
    }
    return _loading ??= _loadUrl().whenComplete(() => _loading = null);
  }

  static Future<String> _loadUrl() async {
    try {
      final document = await FirebaseFirestore.instance
          .doc('appConfig/backend')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      final value = document.data()?['baseUrl'];
      if (!document.exists || value is! String) {
        throw const BackendUnavailableException();
      }
      final url = _validateUrl(value, remote: true);
      _cachedUrl = url;
      _loadedAt = DateTime.now();
      return url;
    } catch (_) {
      // Never fall back to a private LAN address in a distributed APK.
      throw const BackendUnavailableException();
    }
  }

  static Future<void> refresh() async {
    try {
      await resolveBaseUrl(refresh: true);
    } catch (_) {
      // A request will show the normal service-unavailable message if needed.
    }
  }

  /// Refresh stale tunnel addresses without blindly repeating publication.
  /// Replays are enabled only for reads or idempotent job/device requests.
  static Future<http.Response> request(
    String path, {
    required Future<http.Response> Function(Uri uri) send,
    bool retryOnAddressChange = false,
  }) async {
    final baseUrl = await resolveBaseUrl();
    var refreshed = false;
    Future<http.Response?> refreshAndRetry() async {
      if (refreshed) return null;
      refreshed = true;
      try {
        final updatedUrl = await resolveBaseUrl(refresh: true);
        if (retryOnAddressChange && updatedUrl != baseUrl) {
          return await send(Uri.parse('$updatedUrl$path'));
        }
      } on BackendUnavailableException {
        // Preserve the original failed request if discovery is also offline.
      }
      return null;
    }

    try {
      final response = await send(Uri.parse('$baseUrl$path'));
      if (const [404, 502, 503, 504, 530].contains(response.statusCode)) {
        final retried = await refreshAndRetry();
        if (retried != null) return retried;
        if (response.statusCode == 404 &&
            !(response.headers['content-type'] ?? '').contains(
              'application/json',
            )) {
          throw const BackendUnavailableException();
        }
      }
      return response;
    } on http.ClientException {
      final retry = await refreshAndRetry();
      if (retry != null) return retry;
      rethrow;
    } on TimeoutException {
      final retry = await refreshAndRetry();
      if (retry != null) return retry;
      rethrow;
    }
  }
}
