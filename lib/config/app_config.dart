class AppConfig {
  /// Toggle to true to use mock responses (no backend needed).
  static const bool useMockApi = true;

  /// Backend base URL (Android emulator → host machine).
  static const String backendBaseUrl = 'http://10.0.2.2:8080';

  static const String analyzeEndpoint = '/analyze';
}
