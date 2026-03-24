import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
        title: const Text('المفضلة'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'مسح الكل',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('مسح المفضلة؟'),
                  content: const Text('هل تريد مسح جميع الكلمات المحفوظة؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).clearAll();
                        Navigator.pop(context);
                      },
                      child: const Text('مسح'),
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
              message: 'لا توجد كلمات محفوظة',
              subtitle: 'اضغط على النجمة لحفظ أي كلمة',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (_, i) => WordCard(entry: favorites[i]),
            ),
    );
  }
}
