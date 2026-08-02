/// Backend route paths, kept in one place so they match `backend/app/main.py`
/// exactly and don't drift when a route is renamed.
class ApiEndpoints {
  ApiEndpoints._();

  static const String search = '/search';
  static const String words = '/words';
  static const String word = '/word';
  static const String stats = '/stats';
  static const String sections = '/sections';
  static const String random = '/random';
  static const String chat = '/chat';
  static const String feedback = '/feedback';
  static const String semanticSearch = '/semantic-search';
}
