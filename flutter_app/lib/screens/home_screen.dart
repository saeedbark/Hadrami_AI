import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/word_entry.dart';
import '../widgets/word_card.dart';
import '../widgets/translate_result_card.dart';
import '../widgets/drawer_trigger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadStats();
      context.read<AppProvider>().loadRandomWord();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _translate() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      context.read<AppProvider>().translate(q);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: DrawerTrigger.of(context),
        ),
        title: const Text(
          '🗺️ قاموس حضرموت',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'كلمة عشوائية',
            onPressed: () => context.read<AppProvider>().loadRandomWord(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Stats Card ───────────────────────────────────────────────
            if (provider.stats != null) _StatsCard(stats: provider.stats!),
            const SizedBox(height: 16),

            // ── Translate Input ──────────────────────────────────────────
            _TranslateInput(
              controller: _controller,
              onSubmit: _translate,
              isLoading: provider.isLoading,
            ),
            const SizedBox(height: 16),

            // ── Result ───────────────────────────────────────────────────
            if (provider.translateResult != null)
              TranslateResultCard(result: provider.translateResult!),

            // ── History ──────────────────────────────────────────────────
            if (provider.history.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السجل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<AppProvider>().clearHistory(),
                    child: const Text('مسح'),
                  ),
                ],
              ),
              ...provider.history.take(5).map((e) => WordCard(entry: e)),
            ],

            // ── Random Word ───────────────────────────────────────────────
            if (provider.randomWord != null) ...[
              const SizedBox(height: 20),
              Text(
                'كلمة اليوم 🎲',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              WordCard(entry: provider.randomWord!, highlight: true),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stats Card ────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final AppStats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat('${stats.totalWords}', 'إجمالي الكلمات', Icons.book),
            _Stat('${stats.translated}', 'مترجمة', Icons.check_circle),
            _Stat(
              '${stats.completionPercent.toStringAsFixed(0)}%',
              'الاكتمال',
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _Stat(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ── Translate Input ───────────────────────────────────────────────────────
class _TranslateInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isLoading;
  const _TranslateInput(
      {required this.controller,
      required this.onSubmit,
      required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ترجمة كلمة حضرمية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: 'أدخل الكلمة الحضرمية...',
                prefixIcon: const Icon(Icons.translate),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(isLoading ? 'جاري البحث...' : 'ترجمة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
