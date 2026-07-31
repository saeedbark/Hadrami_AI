import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/core/models/dictionary_labels.dart';
import 'package:hadrami_nlp/src/modules/dictionary/providers/dictionary_provider.dart';
import 'package:hadrami_nlp/src/modules/dictionary/widgets/word_card.dart';
import 'package:hadrami_nlp/src/widgets/animated_appear.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/empty_state.dart';
import 'package:hadrami_nlp/src/widgets/error_widget.dart';
import 'package:hadrami_nlp/src/widgets/loading_widget.dart';
import 'package:hadrami_nlp/src/widgets/text_input.dart';

class DictionaryPage extends HookConsumerWidget {
  const DictionaryPage({super.key});

  static const List<String> _arabicLetters = [
    'أ',
    'ب',
    'ت',
    'ث',
    'ج',
    'ح',
    'خ',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ع',
    'غ',
    'ف',
    'ق',
    'ك',
    'ل',
    'م',
    'ن',
    'ه',
    'و',
    'ي',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLetter = ref.watch(selectedLetterProvider);
    final wordsAsync = ref.watch(wordListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final letterFromRoute =
        GoRouterState.of(context).uri.queryParameters['letter'];

    final searchController = useTextEditingController();
    final searchQuery = ref.watch(dictionarySearchQueryProvider);
    final searchResultsAsync = ref.watch(dictionarySearchResultsProvider);
    final isSearching = searchQuery.trim().isNotEmpty;
    final filterPanelVisible = ref.watch(dictionaryFilterPanelVisibleProvider);

    void toggleFilterPanel() {
      final opening = !filterPanelVisible;
      ref.read(dictionaryFilterPanelVisibleProvider.notifier).toggle();
      if (opening) {
        ref.read(selectedLetterProvider.notifier).setLetter(null);
      } else {
        searchController.clear();
        ref.read(dictionarySearchQueryProvider.notifier).setImmediate('');
        ref.read(selectedPosProvider.notifier).setPos(null);
        ref.read(selectedTagProvider.notifier).setTag(null);
      }
    }

    useEffect(() {
      final p = letterFromRoute;
      if (p != null && p.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedLetterProvider.notifier).setLetter(p);
        });
      }
      return null;
    }, [letterFromRoute]);

    final scrollController = useScrollController();
    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          ref.read(wordListProvider.notifier).loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return AppScaffold(
      appBar: AppAppBar(
        title: const Text('القاموس الكامل'),
        actions: [
          IconButton(
            icon: Icon(filterPanelVisible
                ? Icons.filter_alt_off_rounded
                : Icons.filter_alt_rounded),
            tooltip: filterPanelVisible ? 'إغلاق البحث والفلاتر' : 'بحث وفلاتر',
            onPressed: toggleFilterPanel,
          ),
        ],
        bottom: filterPanelVisible
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _LetterFilter(
                  letters: _arabicLetters,
                  selected: selectedLetter,
                  onSelect: (letter) => ref
                      .read(selectedLetterProvider.notifier)
                      .setLetter(letter),
                ),
              ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filterPanelVisible) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AppTextField(
                controller: searchController,
                hintText: 'ابحث بالحضرمي أو الفصحى...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          searchController.clear();
                          ref
                              .read(dictionarySearchQueryProvider.notifier)
                              .setImmediate('');
                        },
                      )
                    : null,
                onChanged: (value) =>
                    ref.read(dictionarySearchQueryProvider.notifier).set(value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _PosAndCategoryFilter(ref: ref),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: wordsAsync.when(
                data: (_) {
                  final total = ref.read(wordListProvider.notifier).total;
                  return Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$total كلمة',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (selectedLetter != null) ...[
                      const SizedBox(width: 8),
                      InputChip(
                        label: Text('حرف $selectedLetter'),
                        onDeleted: () => ref
                            .read(selectedLetterProvider.notifier)
                            .setLetter(null),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ]);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          Expanded(
            child: isSearching
                ? searchResultsAsync.when(
                    data: (result) {
                      if (result.results.isEmpty) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          message: 'لا نتائج لـ "$searchQuery"',
                          subtitle: 'جرّب كلمة مختلفة أو تهجئة أخرى',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: result.results.length,
                        itemBuilder: (_, i) => AnimatedAppear(
                          duration: const Duration(milliseconds: 280),
                          delay: Duration(milliseconds: 20 * (i < 12 ? i : 12)),
                          child: WordCard(entry: result.results[i]),
                        ),
                      );
                    },
                    loading: () => const LoadingWidget(),
                    error: (e, _) => Center(child: Text('$e')),
                  )
                : wordsAsync.when(
                    data: (words) {
                      if (words.isEmpty) {
                        return const EmptyState(
                            icon: Icons.menu_book_rounded,
                            message: 'لا توجد كلمات');
                      }
                      final total = ref.read(wordListProvider.notifier).total;
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount:
                            words.length + (words.length < total ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == words.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator.adaptive()),
                            );
                          }
                          return AnimatedAppear(
                            duration: const Duration(milliseconds: 280),
                            delay:
                                Duration(milliseconds: 20 * (i < 12 ? i : 12)),
                            child: WordCard(entry: words[i]),
                          );
                        },
                      );
                    },
                    loading: () => const LoadingWidget(),
                    error: (e, _) => AppErrorWidget(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(wordListProvider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LetterFilter extends HookWidget {
  const _LetterFilter({
    required this.letters,
    required this.selected,
    required this.onSelect,
  });

  final List<String> letters;
  final String? selected;
  final Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scrollController = useScrollController();
    return Container(
      height: 52,
      margin: const EdgeInsets.only(left: 20),
      // Mouse wheels only report a vertical delta, and Scrollable ignores it
      // on a horizontal axis by default -- forward it manually so wheel
      // scrolling works here the same as it does over a vertical list.
      child: Listener(
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent || !scrollController.hasClients) {
            return;
          }
          final delta = event.scrollDelta.dx != 0
              ? event.scrollDelta.dx
              : event.scrollDelta.dy;
          scrollController.jumpTo(
            (scrollController.offset + delta).clamp(
              scrollController.position.minScrollExtent,
              scrollController.position.maxScrollExtent,
            ),
          );
        },
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: letters.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              final isAll = selected == null;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: FilterChip(
                  label: const Text('الكل'),
                  selected: isAll,
                  onSelected: (_) => onSelect(null),
                  selectedColor: colorScheme.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                      color: isAll ? Colors.white : null,
                      fontSize: 12,
                      fontWeight: isAll ? FontWeight.bold : FontWeight.normal),
                ),
              );
            }
            final letter = letters[i - 1];
            final isSelected = selected == letter;
            return Padding(
              padding: const EdgeInsets.only(left: 5),
              child: FilterChip(
                label: Text(letter),
                selected: isSelected,
                onSelected: (_) => onSelect(isSelected ? null : letter),
                selectedColor: colorScheme.primary,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PosAndCategoryFilter extends StatelessWidget {
  const _PosAndCategoryFilter({required this.ref});
  final WidgetRef ref;

  static const _posOptions = ['Noun', 'Verb', 'Adjective', 'Expression'];
  // Supabase stores tags lowercased — these must match exactly since the
  // backend filter (`.contains("tags", ...)`) is a case-sensitive match.
  static const _tagOptions = [
    'nature',
    'behavior',
    'wisdom',
    'insects',
    'food',
    'social',
    'emotions',
    'daily life',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPos = ref.watch(selectedPosProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildDropdown(
            context,
            value: selectedPos,
            hint: 'نوع الكلمة',
            icon: Icons.label_rounded,
            items: _posOptions,
            labelOf: PartOfSpeech.arabicLabelFor,
            onChanged: (v) => ref.read(selectedPosProvider.notifier).setPos(v),
          ),
          const SizedBox(width: 6),
          _buildDropdown(
            context,
            value: selectedTag,
            hint: 'التصنيف',
            icon: Icons.category_rounded,
            items: _tagOptions,
            labelOf: tagArabicLabel,
            onChanged: (v) => ref.read(selectedTagProvider.notifier).setTag(v),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required String Function(String) labelOf,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = value != null;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(hint,
                  style: TextStyle(fontSize: 11, color: colorScheme.outline)),
            ],
          ),
          icon: isActive
              ? InkWell(
                  onTap: () => onChanged(null),
                  child: Icon(Icons.close_rounded,
                      size: 14, color: colorScheme.primary),
                )
              : Icon(Icons.arrow_drop_down_rounded,
                  size: 18, color: colorScheme.outline),
          isDense: true,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(labelOf(item))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
