import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/models/dictionary_labels.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/modules/favorites/providers/favorites_provider.dart';
import 'package:hadrami_nlp/src/widgets/text_input.dart';

class WordDetailSheet extends HookConsumerWidget {
  const WordDetailSheet({super.key, required this.entry});

  final WordEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = ref.watch(favoritesProvider.select(
        (list) => list.any((e) => e.wordVocalized == entry.wordVocalized)));

    final showFeedback = useState(false);
    final feedbackController = useTextEditingController();
    final isSubmitting = useState(false);

    Future<void> submitFeedback() async {
      final text = feedbackController.text.trim();
      if (text.isEmpty) return;
      isSubmitting.value = true;

      final success = await ref.read(apiServiceProvider).submitFeedback(
            wordId: entry.id,
            wordVocalized: entry.wordVocalized,
            suggestedFusha: text,
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
                          entry.wordVocalized,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        if (entry.root != null && entry.root!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'الجذر: ${entry.root}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.outline,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (entry.fushaEquivalent != null &&
                            entry.fushaEquivalent!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              entry.fushaEquivalent!,
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
                                  '${entry.wordVocalized} = ${entry.fushaEquivalent ?? ""}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم النسخ!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (entry.pos != null && entry.pos!.isNotEmpty)
                    _PosChip(rawPos: entry.pos!),
                  if (entry.region != 'General' && entry.region.isNotEmpty)
                    _TagChip(
                      label: WordRegion.arabicLabelFor(entry.region),
                      icon: Icons.place_rounded,
                    ),
                  if (entry.tags != null)
                    ...entry.tags!.map((tag) => _TagChip(
                          label: tagArabicLabel(tag),
                          icon: Icons.label_rounded,
                        )),
                ],
              ),

              if (entry.phoneticVariants != null &&
                  entry.phoneticVariants!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.phoneticVariants!
                      .map((note) => Chip(
                            avatar: const Icon(Icons.record_voice_over_rounded,
                                size: 13),
                            label: Text(note, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],

              if (entry.synonyms != null && entry.synonyms!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'مرادفات',
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
                  children: entry.synonyms!
                      .map((synonym) => Chip(
                            label: Text(synonym),
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
                      entry.definition ?? '',
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
                          if (ex.h.isNotEmpty)
                            Text(
                              ex.h,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          if (ex.f.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              ex.f,
                              style: TextStyle(
                                  fontSize: 14, color: colorScheme.outline),
                            ),
                          ],
                        ],
                      ),
                    )),
              ],

              if (entry.proverbs != null &&
                  entry.proverbs!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        size: 16, color: colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Text(
                      'أمثال شعبية',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entry.proverbs!.map((proverb) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          right: BorderSide(
                            color: colorScheme.tertiary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: SelectableText(
                        proverb,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
              ],

              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'ملاحظة',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        entry.note!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (entry.source != null && entry.source!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'المصدر: ${entry.source}',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ],

              const SizedBox(height: 8),
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
                AppTextField(
                  controller: feedbackController,
                  variant: AppTextFieldVariant.compact,
                  borderRadius: BorderRadius.circular(10),
                  hintText: 'الترجمة الصحيحة للفصحى...',
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

class _PosChip extends StatelessWidget {
  const _PosChip({required this.rawPos});
  final String rawPos;

  static const _posColors = {
    'Noun': Colors.indigo,
    'Verb': Colors.teal,
    'Adjective': Colors.orange,
    'Expression': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final color = _posColors[rawPos] ?? Colors.grey;
    return Chip(
      avatar: Icon(Icons.label_rounded, size: 14, color: color),
      label: Text(PartOfSpeech.arabicLabelFor(rawPos),
          style: TextStyle(fontSize: 11, color: color)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 14, color: colorScheme.secondary),
      label: Text(label,
          style: TextStyle(fontSize: 11, color: colorScheme.secondary)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.3)),
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
    );
  }
}
