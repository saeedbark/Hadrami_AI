import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/configs/app_colors.dart';
import 'package:hadrami_nlp/src/core/providers/theme_provider.dart';
import 'package:hadrami_nlp/src/core/routing/app_routes.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/core/theme/theme.dart';

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

const _destinations = [
  _NavItem(Icons.home_outlined, Icons.home_rounded,
      AppStrings.landingNavHomeLabel),
  _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded,
      AppStrings.landingNavDictionaryLabel),
  _NavItem(Icons.bookmark_outline_rounded, Icons.bookmark_rounded,
      AppStrings.commonFavoritesLabel),
  _NavItem(Icons.smart_toy_outlined, Icons.smart_toy_rounded,
      AppStrings.landingNavChatLabel),
];

class LandingPage extends HookConsumerWidget {
  const LandingPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = context.isMobile;
    final isDesktop = context.isDesktop;

    void onDestinationSelected(int index) {
      navigationShell.goBranch(index,
          initialLocation: index == navigationShell.currentIndex);
    }

    if (isMobile) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer,
          elevation: 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          animationDuration: const Duration(milliseconds: 500),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: onDestinationSelected,
            extended: isDesktop,
            minWidth: 72,
            minExtendedWidth: 200,
            backgroundColor: colorScheme.surface,
            leading: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 16, horizontal: isDesktop ? 16 : 8),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 24),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                ],
              ),
            ),
            trailing: !isMobile
                ? Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                RotationTransition(
                              turns: Tween<double>(begin: 0.6, end: 1.0)
                                  .animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            ),
                            child: Icon(
                              ref.watch(appThemeModeProvider) == ThemeMode.dark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              key: ValueKey(ref.watch(appThemeModeProvider)),
                              color: colorScheme.outline,
                            ),
                          ),
                          onPressed: () =>
                              ref.read(appThemeModeProvider.notifier).toggle(),
                          tooltip: AppStrings.landingThemeToggleTooltip,
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_rounded,
                              color: colorScheme.outline),
                          tooltip: AppStrings.commonSettingsLabel,
                          onPressed: () => context.push(AppRoutes.settings),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                : null,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
            indicatorColor: colorScheme.primaryContainer,
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: colorScheme.outline.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.08 : 0.14,
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
