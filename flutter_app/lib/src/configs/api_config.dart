class ApiConfig {
  /// Override at build/run time, e.g. Android emulator:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
  /// Physical device: use your PC LAN IP, e.g. `http://192.168.1.10:8000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const Duration defaultTimeout = Duration(seconds: 10);
  /// First backend /ask may be slow (cold start). Match with server-side RAG.
  static const Duration longTimeout = Duration(seconds: 120);
  static const int defaultPageSize = 30;
}
