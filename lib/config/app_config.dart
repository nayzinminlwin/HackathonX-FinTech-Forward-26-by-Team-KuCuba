class AppConfig {
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
