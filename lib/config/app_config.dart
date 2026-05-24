class AppConfig {
  /// Toggle to true to use mock responses (no backend needed).
  static const bool useMockApi = true;

  /// Backend base URL.
  ///
  /// Default is Android emulator → host machine. For a physical device, pass
  /// `--dart-define=API_BASE_URL=http://<computer-lan-ip>:8080`.
  static const String backendBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String analyzeEndpoint = '/analyze';
}
