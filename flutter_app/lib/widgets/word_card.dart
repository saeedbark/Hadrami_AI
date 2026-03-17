import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_entry.dart';
import '../services/app_provider.dart';
import 'word_detail_sheet.dart';

class WordCard extends StatelessWidget {
  final WordEntry entry;
  final bool highlight;
  final bool showFavorite;

  const WordCard({
    super.key,
    required this.entry,
    this.highlight = false,
    this.showFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();
    final isFav = provider.isFavorite(entry);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight ? cs.secondaryContainer : null,
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
              // ID badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.id}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Words
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.hadramiWord,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entry.arabicFus7a.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.arabicFus7a,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      entry.fullDefinition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Favorite button
              IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.amber : cs.outline,
                ),
                onPressed: () => provider.toggleFavorite(entry),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
