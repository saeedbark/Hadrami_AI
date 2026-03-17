import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../widgets/word_card.dart';
import '../widgets/drawer_trigger.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: DrawerTrigger.of(context),
        ),
        title: const Text('المفضلة'),
        actions: [
          if (provider.favorites.isNotEmpty)
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
                        for (final e in [...provider.favorites]) {
                          provider.toggleFavorite(e);
                        }
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
      body: provider.favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 80, color: cs.primaryContainer),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد كلمات محفوظة',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على ⭐ لحفظ أي كلمة',
                    style: TextStyle(color: cs.outline, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.favorites.length,
              itemBuilder: (_, i) =>
                  WordCard(entry: provider.favorites[i], showFavorite: true),
            ),
    );
  }
}
