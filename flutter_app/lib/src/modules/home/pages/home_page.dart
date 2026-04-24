import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/configs/app_colors.dart';
import 'package:hadrami_nlp/src/configs/app_radius.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/providers/theme_provider.dart';
import 'package:hadrami_nlp/src/modules/dictionary/widgets/word_card.dart';
import 'package:hadrami_nlp/src/modules/home/providers/home_provider.dart';
import 'package:hadrami_nlp/src/widgets/loading_widget.dart';

/// Fixed Hadrami phrases for the home teaser (no API).
const _kPhraseHighlights = <(String phrase, String gloss)>[
  ('إبط تسرع', 'مثل للتأني والحكمة'),
  ('أبداً ما جلست', 'نفي قاطع في اللهجة'),
  ('آل المكلا', 'انتساب ومعرفة بالمكان والأهل'),
];

BoxDecoration _homeInnerTileDecoration(BuildContext context) {
  final c = Theme.of(context).colorScheme;
  final light = Theme.of(context).brightness == Brightness.light;
  return BoxDecoration(
    color: light
        ? c.primaryContainer.withValues(alpha: 0.32)
        : c.surfaceContainerHigh.withValues(alpha: 0.55),
    borderRadius: AppRadius.md,
    border: Border.all(
      color: c.outline.withValues(alpha: light ? 0.11 : 0.28),
    ),
  );
}

/// One home block: heading + short description + content.
class _HomeSectionCard extends StatelessWidget {
  const _HomeSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: light ? colorScheme.surface : colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: light ? 0.15 : 0.24),
          ),
          boxShadow: light
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static void _openDictionarySection(BuildContext context, String letter) {
    final enc = Uri.encodeQueryComponent(letter);
    context.go('/dictionary?letter=$enc');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final randomAsync = ref.watch(randomWordProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final featuredAsync = ref.watch(featuredWordsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final heroTop = isDark
        ? colorScheme.surfaceContainerHigh
        : AppColors.primaryLight;
    final heroBottom = isDark
        ? colorScheme.surfaceContainerLow
        : colorScheme.primary.withValues(alpha: 0.88);
    final onHero = isDark ? colorScheme.onSurface : Colors.white;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [heroTop, heroBottom],
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
                        Row(
                          children: [
                            Icon(Icons.menu_book_rounded,
                                color: onHero, size: 26),
                            const SizedBox(width: 10),
                            Text(
                              'قاموس حضرموت',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: onHero,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                ref.watch(appThemeModeProvider) ==
                                        ThemeMode.dark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                color: onHero.withValues(alpha: 0.85),
                              ),
                              onPressed: () => ref
                                  .read(appThemeModeProvider.notifier)
                                  .toggle(),
                            ),
                            IconButton(
                              icon: Icon(Icons.settings_rounded,
                                  color: onHero.withValues(alpha: 0.85)),
                              onPressed: () => context.push('/settings'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'اللهجة الحضرمية',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: onHero,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تصفح الأقسام أو اطّلع على عينات من الكلمات والعبارات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: onHero.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonal(
                      onPressed: () => context.go('/dictionary'),
                      style: FilledButton.styleFrom(
                        backgroundColor: onHero.withValues(
                            alpha: isDark ? 0.12 : 0.2),
                        foregroundColor: onHero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.md),
                      ),
                      child: const Text('تصفح القاموس الكامل'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                statsAsync.when(
                  data: (stats) => _HomeSectionCard(
                    title: 'إحصائيات المعجم',
                    subtitle:
                        'عدد المدخلات في القاموس، والكلمات ذات الترجمة، ونسبة الاكتمال',
                    child: _StatsRow(stats: stats),
                  ),
                  loading: () => _HomeSectionCard(
                    title: 'إحصائيات المعجم',
                    subtitle: 'جاري تحميل أرقام القاموس…',
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: LoadingWidget(),
                    ),
                  ),
                  error: (err, _) => _HomeSectionCard(
                    title: 'إحصائيات المعجم',
                    subtitle: 'تعذّر الاتصال بالخادم',
                    child: _ApiErrorCard(message: err.toString()),
                  ),
                ),
                _HomeSectionCard(
                  title: 'كلمات وعبارات',
                  subtitle:
                      'عبارات شائعة من اللهجة، وعيّنة مباشرة من أول مدخلات المعجم',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._kPhraseHighlights.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PhraseTeaserCard(phrase: t.$1, gloss: t.$2),
                        ),
                      ),
                      featuredAsync.when(
                        data: (words) {
                          if (words.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              for (final w in words) WordCard(entry: w),
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: LoadingWidget(),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                sectionsAsync.when(
                  data: (sections) {
                    if (sections.isEmpty) {
                      return _HomeSectionCard(
                        title: 'أقسام القاموس',
                        subtitle:
                            'تصفّح حسب أول حرف من الكلمة — يظهر عدد الكلمات في كل قسم',
                        child: _ApiErrorCard(
                          message:
                              'تعذّر تحميل أقسام القاموس. شغّل الـ backend على ${ApiConfig.baseUrl}',
                        ),
                      );
                    }
                    return _HomeSectionCard(
                      title: 'أقسام القاموس',
                      subtitle:
                          'تصفّح حسب أول حرف من الكلمة — يظهر عدد الكلمات في كل قسم',
                      child: Column(
                        children: [
                          for (final s in sections)
                            _SectionTile(
                              letter: s.letter,
                              wordCount: s.wordCount,
                              onTap: () =>
                                  _openDictionarySection(context, s.letter),
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () => _HomeSectionCard(
                    title: 'أقسام القاموس',
                    subtitle:
                        'تصفّح حسب أول حرف من الكلمة — يظهر عدد الكلمات في كل قسم',
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: LoadingWidget(),
                    ),
                  ),
                  error: (err, _) => _HomeSectionCard(
                    title: 'أقسام القاموس',
                    subtitle:
                        'تصفّح حسب أول حرف من الكلمة — يظهر عدد الكلمات في كل قسم',
                    child: _ApiErrorCard(message: err.toString()),
                  ),
                ),
                randomAsync.when(
                  data: (word) {
                    if (word == null) return const SizedBox.shrink();
                    return _HomeSectionCard(
                      title: 'كلمة اليوم',
                      subtitle: 'اقتراح عشوائي من قاموس حضرموت — اضغط البطاقة للتفاصيل',
                      child: WordCard(entry: word, highlight: true),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseTeaserCard extends StatelessWidget {
  const _PhraseTeaserCard({required this.phrase, required this.gloss});

  final String phrase;
  final String gloss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: _homeInnerTileDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote_rounded,
                size: 22, color: colorScheme.secondary.withValues(alpha: 0.8)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gloss,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.letter,
    required this.wordCount,
    required this.onTap,
  });

  final String letter;
  final int wordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _homeInnerTileDecoration(context),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.md,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primary
                        .withValues(alpha: 0.12),
                    foregroundColor: colorScheme.primary,
                    child: Text(
                      letter.isNotEmpty ? letter : '؟',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قسم $letter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$wordCount ${wordCount == 1 ? 'كلمة' : 'كلمات'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: colorScheme.outline),
                ],
              ),
            ),
          ),
        ),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final AppStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  '${stats.totalWords}',
                  'كلمة',
                  Icons.menu_book_rounded,
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  '${stats.translated}',
                  'مترجمة',
                  Icons.check_circle_rounded,
                  colorScheme.secondary,
                  colorScheme.secondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  '${stats.completionPercent.toStringAsFixed(0)}%',
                  'الاكتمال',
                  Icons.trending_up_rounded,
                  colorScheme.primary.withValues(alpha: 0.75),
                  colorScheme.surfaceContainerHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  '${stats.totalProverbs}',
                  'مثل شعبي',
                  Icons.auto_stories_rounded,
                  colorScheme.tertiary,
                  colorScheme.tertiaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  '${stats.archaicWords}',
                  'كلمة قديمة',
                  Icons.history_rounded,
                  colorScheme.error,
                  colorScheme.errorContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  '${stats.byPartOfSpeech.length}',
                  'أصناف نحوية',
                  Icons.label_rounded,
                  Colors.indigo,
                  Colors.indigo.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
    this.value,
    this.label,
    this.icon,
    this.color,
    this.bgColor,
  );
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
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.85),
                ),
          ),
        ],
      ),
    );
  }
}
