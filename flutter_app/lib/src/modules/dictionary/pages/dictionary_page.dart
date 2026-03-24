import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/modules/dictionary/providers/dictionary_provider.dart';
import 'package:hadrami_nlp/src/modules/dictionary/widgets/word_card.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/empty_state.dart';
import 'package:hadrami_nlp/src/widgets/error_widget.dart';
import 'package:hadrami_nlp/src/widgets/loading_widget.dart';

class DictionaryPage extends HookConsumerWidget {
  const DictionaryPage({super.key});

  static const List<String> _arabicLetters = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز',
    'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك',
    'ل', 'م', 'ن', 'ه', 'و', 'ي',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLetter = ref.watch(selectedLetterProvider);
    final wordsAsync = ref.watch(wordListProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _LetterFilter(
            letters: _arabicLetters,
            selected: selectedLetter,
            onSelect: (letter) =>
                ref.read(selectedLetterProvider.notifier).setLetter(letter),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              wordsAsync.when(
                data: (_) => Text(
                  '${ref.read(wordListProvider.notifier).total} كلمة',
                  style: TextStyle(
                      color: colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (selectedLetter != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text('حرف $selectedLetter'),
                  onDeleted: () =>
                      ref.read(selectedLetterProvider.notifier).setLetter(null),
                  deleteIcon: const Icon(Icons.close, size: 16),
                ),
              ],
            ]),
          ),
          Expanded(
            child: wordsAsync.when(
              data: (words) {
                if (words.isEmpty) {
                  return const EmptyState(
                      icon: Icons.menu_book, message: 'لا توجد كلمات');
                }
                final total = ref.read(wordListProvider.notifier).total;
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: words.length + (words.length < total ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == words.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator.adaptive()),
                      );
                    }
                    return WordCard(entry: words[i]);
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

class _LetterFilter extends StatelessWidget {
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
    return SizedBox(
      height: 52,
      child: ListView.builder(
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
                backgroundColor: isAll ? colorScheme.primary : null,
                labelStyle: TextStyle(
                    color: isAll ? Colors.white : null, fontSize: 12),
              ),
            );
          }
          final letter = letters[i - 1];
          final isSelected = selected == letter;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              label: Text(letter),
              selected: isSelected,
              onSelected: (_) => onSelect(isSelected ? null : letter),
              backgroundColor: isSelected ? colorScheme.primary : null,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null, fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}
