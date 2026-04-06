import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/modules/favorites/providers/favorites_provider.dart';

class WordDetailSheet extends HookConsumerWidget {
  const WordDetailSheet({super.key, required this.entry});

  final WordEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = ref.watch(favoritesProvider.select(
        (list) => list.any((e) => e.hadramiWord == entry.hadramiWord)));

    final showFeedback = useState(false);
    final feedbackController = useTextEditingController();
    final isSubmitting = useState(false);

    Future<void> submitFeedback() async {
      final text = feedbackController.text.trim();
      if (text.isEmpty) return;
      isSubmitting.value = true;

      final success = await ref.read(apiServiceProvider).submitFeedback(
            wordId: entry.id,
            hadramiWord: entry.hadramiWord,
            suggestedFus7a: text,
          );

      isSubmitting.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'شكراً على مساهمتك!' : 'حدث خطأ'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        showFeedback.value = false;
        feedbackController.clear();
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.hadramiWord,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        if (entry.fus7aShort != null &&
                            entry.fus7aShort!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              entry.fus7aShort!,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.outline,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (entry.arabicFus7a.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              entry.arabicFus7a,
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFav ? Colors.amber : colorScheme.outline,
                          size: 28,
                        ),
                        onPressed: () =>
                            ref.read(favoritesProvider.notifier).toggle(entry),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 22),
                        tooltip: 'نسخ',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  '${entry.hadramiWord} = ${entry.arabicFus7a}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم النسخ!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              if (entry.aliases != null && entry.aliases!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'أشكال أخرى',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.aliases!
                      .map((alias) => Chip(
                            label: Text(alias),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 16, color: colorScheme.outline),
                        const SizedBox(width: 6),
                        Text(
                          'الشرح من القاموس',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      entry.fullDefinition,
                      style: const TextStyle(fontSize: 15, height: 1.7),
                    ),
                  ],
                ),
              ),

              if (entry.examples != null && entry.examples!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.format_quote_rounded,
                        size: 16, color: colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'أمثلة',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entry.examples!.map((ex) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          right: BorderSide(
                            color: colorScheme.secondary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ex.hadrami.isNotEmpty)
                            Text(
                              ex.hadrami,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          if (ex.fusha.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              ex.fusha,
                              style: TextStyle(
                                  fontSize: 14, color: colorScheme.outline),
                            ),
                          ],
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 16),
              Text(
                'رقم الكلمة في القاموس: ${entry.id}',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    showFeedback.value = !showFeedback.value,
                icon: Icon(showFeedback.value
                    ? Icons.close_rounded
                    : Icons.edit_note_rounded),
                label: Text(showFeedback.value ? 'إلغاء' : 'اقتراح تصحيح'),
              ),
              if (showFeedback.value) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'الترجمة الصحيحة للفصحى...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: isSubmitting.value ? null : submitFeedback,
                  icon: isSubmitting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(isSubmitting.value ? 'جاري الإرسال...' : 'إرسال'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
