import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/modules/dictionary/widgets/word_card.dart';
import 'package:hadrami_nlp/src/modules/favorites/providers/favorites_provider.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/empty_state.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return AppScaffold(
      appBar: AppAppBar(
        title: const Text(AppStrings.commonFavoritesLabel),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: AppStrings.favoritesClearAllTooltip,
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text(AppStrings.favoritesClearConfirmTitle),
                  content:
                      const Text(AppStrings.favoritesClearConfirmMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(AppStrings.commonCancelLabel),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).clearAll();
                        Navigator.pop(context);
                      },
                      child: const Text(AppStrings.commonClearLabel),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              message: AppStrings.favoritesEmptyMessage,
              subtitle: AppStrings.favoritesEmptySubtitle,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (_, i) => WordCard(entry: favorites[i]),
            ),
    );
  }
}
