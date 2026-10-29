class BackendConfig {
  static const String baseUrl = String.fromEnvironment(
    'SOUNDSIGHT_BACKEND_URL',
    defaultValue: 'http://192.168.0.104:8000',
  );
}
