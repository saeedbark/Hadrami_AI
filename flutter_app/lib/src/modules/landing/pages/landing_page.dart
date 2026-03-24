import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/configs/app_colors.dart';
import 'package:hadrami_nlp/src/core/providers/theme_provider.dart';
import 'package:hadrami_nlp/src/core/theme/theme.dart';

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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'بحث',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'القاموس',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'اسأل',
            ),
          ],
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer,
          elevation: 4,
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
                    child: const Icon(Icons.menu_book,
                        color: Colors.white, size: 24),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(height: 8),
                    Text(
                      'قاموس حضرموت',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      ref.watch(appThemeModeProvider) == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: colorScheme.outline,
                    ),
                    onPressed: () =>
                        ref.read(appThemeModeProvider.notifier).toggle(),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: colorScheme.outline),
                    tooltip: 'الإعدادات',
                    onPressed: () => context.push('/settings'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('الرئيسية'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: Text('بحث'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('القاموس'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bookmark_outline),
                selectedIcon: Icon(Icons.bookmark),
                label: Text('المفضلة'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('اسأل'),
              ),
            ],
            indicatorColor: colorScheme.primaryContainer,
          ),
          VerticalDivider(
              thickness: 1, width: 1, color: colorScheme.outlineVariant),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
