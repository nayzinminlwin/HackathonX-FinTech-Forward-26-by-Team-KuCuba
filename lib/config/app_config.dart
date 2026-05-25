class AppConfig {
  static const String appSecretHeaderName = 'x-app-secret';
  static const String appSecret = 'my_custom_project_key_123';

  /// Backend base URL.
  ///
  /// Default is Android emulator → host machine. For a physical device, pass
  /// `--dart-define=API_BASE_URL=https://<your-production-backend>`.
  static const String backendBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String analyzeEndpoint = '/analyze';
}
