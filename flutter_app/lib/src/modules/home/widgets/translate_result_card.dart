import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/modules/favorites/providers/favorites_provider.dart';

class TranslateResultCard extends ConsumerWidget {
  const TranslateResultCard({super.key, required this.result});

  final TranslateResult result;

  Color _confidenceColor(BuildContext context, String confidence) {
    switch (confidence) {
      case 'exact':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'not_found':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _confidenceLabel(String confidence) {
    switch (confidence) {
      case 'exact':
        return 'تطابق تام';
      case 'partial':
        return 'تطابق جزئي';
      case 'not_found':
        return 'غير موجود';
      case 'error':
        return 'خطأ في الاتصال';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final confidenceColor = _confidenceColor(context, result.confidence);

    if (!result.found) {
      return Card(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search_off, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.fullDefinition,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entry = WordEntry(
      id: 0,
      hadramiWord: result.hadramiWord,
      arabicFus7a: result.arabicFus7a,
      fullDefinition: result.fullDefinition,
    );
    final isFav = ref.watch(favoritesProvider.select(
        (list) => list.any((e) => e.hadramiWord == entry.hadramiWord)));

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: confidenceColor),
                  ),
                  child: Text(
                    _confidenceLabel(result.confidence),
                    style: TextStyle(
                        color: confidenceColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.amber : colorScheme.outline,
                  ),
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(entry),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            '${result.hadramiWord} = ${result.arabicFus7a}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم النسخ!')));
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الكلمة الحضرمية',
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(result.hadramiWord,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: colorScheme.outline, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الفصحى',
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(
                        result.arabicFus7a.isNotEmpty
                            ? result.arabicFus7a
                            : '—',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (result.fullDefinition.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                result.fullDefinition,
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
