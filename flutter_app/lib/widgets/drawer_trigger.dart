import 'package:flutter/material.dart';

/// Provides a way for child screens to open the root Scaffold's drawer.
class DrawerTrigger extends InheritedWidget {
  const DrawerTrigger({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static VoidCallback? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DrawerTrigger>()
        ?.openDrawer;
  }

  @override
  bool updateShouldNotify(DrawerTrigger oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}
