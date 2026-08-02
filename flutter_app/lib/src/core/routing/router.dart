import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hadrami_nlp/src/core/routing/app_routes.dart';
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
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dictionary,
              name: 'dictionary',
              builder: (context, state) => const DictionaryPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.favorites,
              name: 'favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.chat,
              name: 'chat',
              builder: (context, state) => const ChatPage(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsPage(),
      ),
      // Merged into other destinations (nav-rail reduction) — keep old links
      // and bookmarks working instead of 404ing.
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => AppRoutes.dictionary,
      ),
      GoRoute(
        path: AppRoutes.ask,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => AppRoutes.chat,
      ),
      GoRoute(
        path: AppRoutes.phraseTranslate,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => AppRoutes.chat,
      ),
    ],
  );

  ref.onDispose(() => router.dispose());
  return router;
}
