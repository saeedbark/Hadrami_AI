import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/word_entry.dart';
import '../services/app_provider.dart';

class WordDetailSheet extends StatefulWidget {
  final WordEntry entry;
  const WordDetailSheet({super.key, required this.entry});

  @override
  State<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<WordDetailSheet> {
  bool _showFeedback = false;
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    final success = await context.read<AppProvider>().submitFeedback(
          wordId: widget.entry.id,
          hadramiWord: widget.entry.hadramiWord,
          suggestedFus7a: text,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'شكراً على مساهمتك! ✅' : 'حدث خطأ'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() => _showFeedback = false);
      _feedbackController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();
    final isFav = provider.isFavorite(widget.entry);

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
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.hadramiWord,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.entry.arabicFus7a.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.entry.arabicFus7a,
                              style: TextStyle(
                                fontSize: 16,
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : cs.outline,
                      size: 30,
                    ),
                    onPressed: () =>
                        provider.toggleFavorite(widget.entry),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 24),
                    tooltip: 'نسخ',
                    onPressed: () {
                      final text =
                          '${widget.entry.hadramiWord} = ${widget.entry.arabicFus7a}';
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم النسخ!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Definition ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الشرح من القاموس',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.entry.fullDefinition,
                      style: const TextStyle(fontSize: 15, height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── ID Info ───────────────────────────────────────────────
              Text(
                'رقم الكلمة في القاموس: ${widget.entry.id}',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
              const SizedBox(height: 20),

              // ── Suggest Correction ────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _showFeedback = !_showFeedback),
                icon: const Icon(Icons.edit_note),
                label:
                    Text(_showFeedback ? 'إلغاء' : 'اقتراح تصحيح'),
              ),

              if (_showFeedback) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _feedbackController,
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
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send),
                  label: const Text('إرسال'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
