import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hadrami_nlp/src/modules/ask/pages/ask_page.dart';
import 'package:hadrami_nlp/src/modules/chat/pages/chat_page.dart';
import 'package:hadrami_nlp/src/modules/phrase/pages/phrase_translate_page.dart';
import 'package:hadrami_nlp/src/modules/dictionary/pages/dictionary_page.dart';
import 'package:hadrami_nlp/src/modules/favorites/pages/favorites_page.dart';
import 'package:hadrami_nlp/src/modules/home/pages/home_page.dart';
import 'package:hadrami_nlp/src/modules/landing/pages/landing_page.dart';
import 'package:hadrami_nlp/src/modules/search/pages/search_page.dart';
import 'package:hadrami_nlp/src/modules/settings/pages/settings_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(RouterRef ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            LandingPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              builder: (context, state) => const SearchPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dictionary',
              name: 'dictionary',
              builder: (context, state) => const DictionaryPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              name: 'favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ask',
              name: 'ask',
              builder: (context, state) => const AskPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/phrase-translate',
              name: 'phrase_translate',
              builder: (context, state) => const PhraseTranslatePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chat',
              name: 'chat',
              builder: (context, state) => const ChatPage(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );

  ref.onDispose(() => router.dispose());
  return router;
}
