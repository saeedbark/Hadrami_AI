import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/providers/theme_provider.dart';
import 'package:hadrami_nlp/src/core/routing/router.dart';
import 'package:hadrami_nlp/src/core/theme/theme.dart';

/// Flutter's default [MaterialScrollBehavior] only lets touch/stylus drag
/// scroll views, so on web a mouse can't click-and-drag any list (e.g. the
/// dictionary letter filter) -- add mouse/trackpad so drag-to-scroll works
/// the same as touch everywhere in the app.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class HadramiApp extends ConsumerWidget {
  const HadramiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'قاموس حضرموت',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      routerConfig: goRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
