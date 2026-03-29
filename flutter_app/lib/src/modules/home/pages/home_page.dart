import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/configs/app_colors.dart';
import 'package:hadrami_nlp/src/configs/app_radius.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/providers/theme_provider.dart';
import 'package:hadrami_nlp/src/modules/dictionary/widgets/word_card.dart';
import 'package:hadrami_nlp/src/modules/home/providers/home_provider.dart';
import 'package:hadrami_nlp/src/modules/home/widgets/translate_result_card.dart';
import 'package:hadrami_nlp/src/widgets/loading_widget.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final translateState = ref.watch(translateProvider);
    final statsAsync = ref.watch(statsProvider);
    final randomAsync = ref.watch(randomWordProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final heroColors = useMemoized(
      () => [
        AppColors.primaryLight,
        AppColors.primaryLight.withValues(alpha: .85),
        AppColors.accent,
      ],
      const [],
    );

    void doTranslate() {
      final q = controller.text.trim();
      if (q.isNotEmpty) {
        ref.read(translateProvider.notifier).translate(q);
        FocusScope.of(context).unfocus();
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: heroColors,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(Icons.menu_book,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'قاموس حضرموت',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ]),
                        Row(children: [
                          IconButton(
                            icon: Icon(
                              ref.watch(appThemeModeProvider) == ThemeMode.dark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: Colors.white70,
                            ),
                            onPressed: () => ref
                                .read(appThemeModeProvider.notifier)
                                .toggle(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings,
                                color: Colors.white70),
                            onPressed: () => context.push('/settings'),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ترجم أي كلمة حضرمية',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    _TranslateInput(
                      controller: controller,
                      onSubmit: doTranslate,
                      isLoading: translateState.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (translateState.result != null)
                  TranslateResultCard(result: translateState.result!),
                statsAsync.when(
                  data: (stats) => _StatsRow(stats: stats),
                  loading: () => const LoadingWidget(),
                  error: (err, _) => _ApiErrorCard(message: err.toString()),
                ),
                if (translateState.history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('السجل',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: colorScheme.primary)),
                      TextButton(
                        onPressed: () =>
                            ref.read(translateProvider.notifier).clearHistory(),
                        child: const Text('مسح'),
                      ),
                    ],
                  ),
                  ...translateState.history
                      .take(5)
                      .map((e) => WordCard(entry: e)),
                ],
                randomAsync.when(
                  data: (word) {
                    if (word == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text('كلمة اليوم',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: colorScheme.primary)),
                        const SizedBox(height: 8),
                        WordCard(entry: word, highlight: true),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiErrorCard extends StatelessWidget {
  const _ApiErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.replaceFirst('Bad state: ', ''),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslateInput extends StatelessWidget {
  const _TranslateInput({
    required this.controller,
    required this.onSubmit,
    required this.isLoading,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'أدخل الكلمة الحضرمية...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: .6)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('ترجمة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final AppStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
              '${stats.totalWords}', 'كلمة', Icons.book, colorScheme.primary),
          _StatItem('${stats.translated}', 'مترجمة', Icons.check_circle,
              Colors.green),
          _StatItem(
              '${stats.completionPercent.toStringAsFixed(0)}%',
              'الاكتمال',
              Icons.trending_up,
              colorScheme.secondary),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.value, this.label, this.icon, this.color);
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
