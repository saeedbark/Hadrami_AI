import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hadrami_nlp/src/modules/chat/pages/chat_page.dart';
import 'package:hadrami_nlp/src/modules/dictionary/pages/dictionary_page.dart';
import 'package:hadrami_nlp/src/modules/favorites/pages/favorites_page.dart';
import 'package:hadrami_nlp/src/modules/home/pages/home_page.dart';
import 'package:hadrami_nlp/src/modules/landing/pages/landing_page.dart';
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
      // Merged into other destinations (nav-rail reduction) — keep old links
      // and bookmarks working instead of 404ing.
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/dictionary',
      ),
      GoRoute(
        path: '/ask',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/chat',
      ),
      GoRoute(
        path: '/phrase-translate',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/chat',
      ),
    ],
  );

  ref.onDispose(() => router.dispose());
  return router;
}
