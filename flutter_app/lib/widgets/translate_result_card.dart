import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/word_entry.dart';
import '../services/app_provider.dart';

class TranslateResultCard extends StatelessWidget {
  final TranslateResult result;
  const TranslateResultCard({super.key, required this.result});

  Color _confidenceColor(BuildContext context, String confidence) {
    final cs = Theme.of(context).colorScheme;
    switch (confidence) {
      case 'exact':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'not_found':
        return cs.error;
      default:
        return cs.outline;
    }
  }

  String _confidenceLabel(String confidence) {
    switch (confidence) {
      case 'exact':
        return '✅ تطابق تام';
      case 'partial':
        return '🔶 تطابق جزئي';
      case 'not_found':
        return '❌ غير موجود';
      case 'error':
        return '⚠️ خطأ في الاتصال';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confidenceColor = _confidenceColor(context, result.confidence);
    final provider = context.watch<AppProvider>();

    if (!result.found) {
      return Card(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search_off, color: cs.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.fullDefinition,
                  style: TextStyle(color: cs.onErrorContainer),
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
    final isFav = provider.isFavorite(entry);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: confidenceColor, width: 1),
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
                    color: isFav ? Colors.amber : cs.outline,
                  ),
                  onPressed: () => provider.toggleFavorite(entry),
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

            // Main translation
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الكلمة الحضرمية',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        result.hadramiWord,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward,
                    color: cs.outline, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الفصحى',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        result.arabicFus7a.isNotEmpty
                            ? result.arabicFus7a
                            : '—',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
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
                    color: cs.onSurfaceVariant,
                    height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
