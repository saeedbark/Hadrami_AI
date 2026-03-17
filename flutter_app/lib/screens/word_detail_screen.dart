import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/word_entry.dart';
import '../services/app_provider.dart';

class WordDetailScreen extends StatefulWidget {
  final WordEntry entry;
  const WordDetailScreen({super.key, required this.entry});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  bool _showFeedback = false;
  final _feedbackController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);

    final ok = await context.read<AppProvider>().submitFeedback(
          wordId: widget.entry.id,
          hadramiWord: widget.entry.hadramiWord,
          suggestedFus7a: text,
        );

    if (mounted) {
      setState(() {
        _submitting = false;
        _showFeedback = false;
      });
      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ شكراً على مساهمتك!' : '❌ حدث خطأ'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();
    final isFav = provider.isFavorite(widget.entry);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry.hadramiWord,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : Colors.white,
            ),
            onPressed: () => provider.toggleFavorite(widget.entry),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final text =
                  '${widget.entry.hadramiWord} = ${widget.entry.arabicFus7a}\n${widget.entry.fullDefinition}';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 تم نسخ الكلمة!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Main card ───────────────────────────────────────────────
            Card(
              elevation: 0,
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      widget.entry.hadramiWord,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Icon(Icons.arrow_downward, size: 20),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.entry.arabicFus7a.isNotEmpty
                            ? widget.entry.arabicFus7a
                            : 'لم تُترجم بعد',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Definition ───────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book, color: cs.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الشرح من القاموس الحضرمي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.entry.fullDefinition.isNotEmpty
                          ? widget.entry.fullDefinition
                          : 'لا يوجد شرح',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Meta info ────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetaChip(
                        icon: Icons.tag,
                        label: 'رقم ${widget.entry.id}',
                        color: cs.tertiary),
                    _MetaChip(
                        icon: Icons.translate,
                        label: widget.entry.arabicFus7a.isNotEmpty
                            ? 'مترجمة'
                            : 'غير مترجمة',
                        color: widget.entry.arabicFus7a.isNotEmpty
                            ? Colors.green
                            : Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Actions ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text:
                            '${widget.entry.hadramiWord} = ${widget.entry.arabicFus7a}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم النسخ!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        setState(() => _showFeedback = !_showFeedback),
                    icon: Icon(_showFeedback ? Icons.close : Icons.edit),
                    label: Text(_showFeedback ? 'إلغاء' : 'اقتراح تصحيح'),
                  ),
                ),
              ],
            ),

            // ── Feedback form ────────────────────────────────────────────
            if (_showFeedback) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'اقتراح ترجمة أفضل',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: cs.primary),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submitFeedback,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label:
                            Text(_submitting ? 'جاري الإرسال...' : 'إرسال'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
