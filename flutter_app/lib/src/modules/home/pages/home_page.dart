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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final heroColors = isDark
        ? [
            const Color(0xFF0D2137),
            const Color(0xFF122D4A),
            const Color(0xFF0A1929),
          ]
        : [
            AppColors.primaryLight,
            const Color(0xFF1A5F8C),
            AppColors.accent,
          ];

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
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
                          const Icon(Icons.menu_book_rounded,
                              color: Colors.white, size: 26),
                          const SizedBox(width: 10),
                          Text(
                            'قاموس حضرموت',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ]),
                        Row(children: [
                          IconButton(
                            icon: Icon(
                              ref.watch(appThemeModeProvider) == ThemeMode.dark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () => ref
                                .read(appThemeModeProvider.notifier)
                                .toggle(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_rounded,
                                color: Colors.white70),
                            onPressed: () => context.push('/settings'),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ترجم أي كلمة حضرمية',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اكتشف معاني اللهجة الحضرمية اليمنية',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 20),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (translateState.result != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TranslateResultCard(result: translateState.result!),
                  ),
                statsAsync.when(
                  data: (stats) => _StatsRow(stats: stats),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: LoadingWidget(),
                  ),
                  error: (err, _) => _ApiErrorCard(message: err.toString()),
                ),
                if (translateState.history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.history_rounded,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('السجل',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: colorScheme.primary)),
                      ]),
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(translateProvider.notifier).clearHistory(),
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('مسح'),
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                        Row(children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 18, color: colorScheme.secondary),
                          const SizedBox(width: 6),
                          Text('كلمة اليوم',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: colorScheme.secondary)),
                        ]),
                        const SizedBox(height: 8),
                        WordCard(entry: word, highlight: true),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_rounded, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.replaceFirst('Bad state: ', ''),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  height: 1.5,
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
        color: Colors.white.withValues(alpha: .12),
        borderRadius: AppRadius.lg,
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
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
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: .5)),
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
                disabledBackgroundColor: Colors.white54,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: _StatCard(
            '${stats.totalWords}',
            'كلمة',
            Icons.menu_book_rounded,
            colorScheme.primary,
            colorScheme.primaryContainer,
          )),
          const SizedBox(width: 8),
          Expanded(
              child: _StatCard(
            '${stats.translated}',
            'مترجمة',
            Icons.check_circle_rounded,
            AppColors.successLight,
            AppColors.successLight.withValues(alpha: 0.12),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: _StatCard(
            '${stats.completionPercent.toStringAsFixed(0)}%',
            'الاكتمال',
            Icons.trending_up_rounded,
            colorScheme.secondary,
            colorScheme.secondaryContainer,
          )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      this.value, this.label, this.icon, this.color, this.bgColor);
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}
