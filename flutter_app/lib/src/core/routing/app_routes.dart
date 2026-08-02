/// Frontend GoRouter paths, kept in one place so navigation call sites and
/// [router.dart]'s route definitions can't drift out of sync.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String dictionary = '/dictionary';
  static const String favorites = '/favorites';
  static const String chat = '/chat';
  static const String settings = '/settings';

  // Legacy paths kept only as redirect targets in router.dart.
  static const String search = '/search';
  static const String ask = '/ask';
  static const String phraseTranslate = '/phrase-translate';
}
