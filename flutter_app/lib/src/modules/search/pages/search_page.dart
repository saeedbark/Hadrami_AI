import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/modules/dictionary/widgets/word_card.dart';
import 'package:hadrami_nlp/src/modules/search/providers/search_provider.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/empty_state.dart';
import 'package:hadrami_nlp/src/widgets/loading_widget.dart';

class SearchPage extends HookConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final hasQuery = query.trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppAppBar(
        title: const Text('بحث في القاموس'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: controller,
              autofocus: true,
              textDirection: TextDirection.rtl,
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).set(value),
              decoration: InputDecoration(
                hintText: 'ابحث بالحضرمي أو الفصحى...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          controller.clear();
                          ref
                              .read(searchQueryProvider.notifier)
                              .setImmediate('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !hasQuery
            ? const EmptyState(
                key: ValueKey('empty'),
                icon: Icons.menu_book_rounded,
                message: 'ابحث عن أي كلمة حضرمية',
                subtitle: 'يمكنك البحث بالحضرمي أو الفصحى',
              )
            : resultsAsync.when(
                data: (result) {
                  if (result.results.isEmpty) {
                    return EmptyState(
                      key: const ValueKey('no-results'),
                      icon: Icons.search_off_rounded,
                      message: 'لا نتائج لـ "$query"',
                      subtitle: 'جرّب كلمة مختلفة أو تهجئة أخرى',
                    );
                  }
                  return Column(
                    key: const ValueKey('results'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${result.total} نتيجة',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: result.results.length,
                          itemBuilder: (_, i) =>
                              WordCard(entry: result.results[i]),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LoadingWidget(key: ValueKey('loading')),
                error: (e, _) => Center(
                    key: const ValueKey('error'), child: Text('$e')),
              ),
      ),
    );
  }
}
