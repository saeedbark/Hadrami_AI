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

  IconData _confidenceIcon(String confidence) {
    switch (confidence) {
      case 'exact':
        return Icons.check_circle_rounded;
      case 'partial':
        return Icons.info_outline_rounded;
      case 'not_found':
        return Icons.search_off_rounded;
      default:
        return Icons.error_outline_rounded;
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
              Icon(Icons.search_off_rounded,
                  color: colorScheme.onErrorContainer),
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
      elevation: 2,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_confidenceIcon(result.confidence),
                          size: 14, color: confidenceColor),
                      const SizedBox(width: 4),
                      Text(
                        _confidenceLabel(result.confidence),
                        style: TextStyle(
                            color: confidenceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                      key: ValueKey(isFav),
                      color: isFav ? Colors.amber : colorScheme.outline,
                    ),
                  ),
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(entry),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'نسخ',
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الكلمة الحضرمية',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colorScheme.outline)),
                      const SizedBox(height: 2),
                      Text(result.hadramiWord,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: colorScheme.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الفصحى',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colorScheme.outline)),
                      const SizedBox(height: 2),
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
