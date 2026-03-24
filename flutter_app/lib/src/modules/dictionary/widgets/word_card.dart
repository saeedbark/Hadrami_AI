import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/modules/dictionary/widgets/word_detail_sheet.dart';
import 'package:hadrami_nlp/src/modules/favorites/providers/favorites_provider.dart';

class WordCard extends ConsumerWidget {
  const WordCard({
    super.key,
    required this.entry,
    this.highlight = false,
  });

  final WordEntry entry;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = ref.watch(favoritesProvider.select(
        (list) => list.any((e) => e.hadramiWord == entry.hadramiWord)));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight ? colorScheme.secondaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => WordDetailSheet(entry: entry),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.id}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.hadramiWord,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    if (entry.arabicFus7a.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.arabicFus7a,
                        style:
                            TextStyle(fontSize: 14, color: colorScheme.primary),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      entry.fullDefinition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.amber : colorScheme.outline,
                ),
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggle(entry),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
