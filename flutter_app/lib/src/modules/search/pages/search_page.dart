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
    final hasQuery = useMemoized(() => query.trim().isNotEmpty, [query]);

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
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          ref.read(searchQueryProvider.notifier).set('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: !hasQuery
          ? const EmptyState(
              icon: Icons.menu_book,
              message: 'ابحث عن أي كلمة حضرمية',
              subtitle: 'يمكنك البحث بالحضرمي أو الفصحى',
            )
          : resultsAsync.when(
              data: (result) {
                if (result.results.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    message: 'لا نتائج لـ "$query"',
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(children: [
                        Text(
                          '${result.total} نتيجة',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: result.results.length,
                        itemBuilder: (_, i) =>
                            WordCard(entry: result.results[i]),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('$e')),
            ),
    );
  }
}
