import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/models/dictionary_labels.dart';
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
        (list) => list.any((e) => e.wordVocalized == entry.wordVocalized)));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => WordDetailSheet(entry: entry),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: highlight
                      ? colorScheme.secondary.withValues(alpha: 0.15)
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.wordVocalized.isNotEmpty
                      ? entry.wordVocalized.characters.first
                      : '؟',
                  style: TextStyle(
                    fontSize: 16,
                    color: highlight
                        ? colorScheme.secondary
                        : colorScheme.onPrimaryContainer,
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
                      entry.wordVocalized,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (entry.fushaEquivalent != null &&
                        entry.fushaEquivalent!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.fushaEquivalent!,
                        style: TextStyle(
                            fontSize: 13, color: colorScheme.primary),
                      ),
                    ],
                    if (entry.pos != null && entry.pos!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MiniTag(
                            label: PartOfSpeech.arabicLabelFor(entry.pos!),
                            color: _posColor(entry.pos!),
                          ),
                          if (entry.tags != null &&
                              entry.tags!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            _MiniTag(
                              label: tagArabicLabel(entry.tags!.first),
                              color: colorScheme.secondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (entry.definition != null &&
                        entry.definition!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.definition!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    key: ValueKey(isFav),
                    color: isFav ? colorScheme.secondary : colorScheme.outline,
                  ),
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

  static Color _posColor(String pos) {
    switch (pos) {
      case 'Noun':
        return Colors.indigo;
      case 'Verb':
        return Colors.teal;
      case 'Adjective':
        return Colors.orange;
      case 'Expression':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
