/// Backend base URL without trailing slash.
///
/// Local: default `http://localhost:8000`.
/// Deployed: pass `--dart-define=API_BASE_URL=https://your-api.vercel.app`,
/// or set `API_BASE_URL` in the Vercel project (used by `vercel_build.sh`).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Default HTTP timeout for typical GETs (stats, list, search).
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Longer timeout for /ask and /translate-phrase.
  static const Duration longTimeout = Duration(seconds: 120);

  /// Matches backend `DEFAULT_PAGE_SIZE` (20).
  static const int defaultPageSize = 20;
}
