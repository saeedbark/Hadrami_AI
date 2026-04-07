/// Backend base URL without trailing slash.
///
/// Local: default `http://localhost:8000`.
/// Vercel / CI: pass `--dart-define=API_BASE_URL=https://your-api.vercel.app`,
/// or set `API_BASE_URL` in the Vercel project (used by `vercel_build.sh`).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'hadrami-4zrbzb73s-saeedbarks-projects.vercel.app',
  );
}
