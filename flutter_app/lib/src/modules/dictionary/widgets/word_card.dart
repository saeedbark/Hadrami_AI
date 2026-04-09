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
                  entry.hadramiWord.isNotEmpty
                      ? entry.hadramiWord.characters.first
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.hadramiWord,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (entry.isArchaic) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.history_rounded,
                              size: 14, color: colorScheme.error),
                        ],
                      ],
                    ),
                    if (entry.arabicFus7a.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.arabicFus7a,
                        style: TextStyle(
                            fontSize: 13, color: colorScheme.primary),
                      ),
                    ],
                    if (entry.partOfSpeech != null &&
                        entry.partOfSpeech!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MiniTag(
                            label: entry.partOfSpeech!,
                            color: _posColor(entry.partOfSpeech!),
                          ),
                          if (entry.thematicCategory != null &&
                              entry.thematicCategory!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            _MiniTag(
                              label: entry.thematicCategory!,
                              color: colorScheme.secondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (entry.fullDefinition.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.fullDefinition,
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
