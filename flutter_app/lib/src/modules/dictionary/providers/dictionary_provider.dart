import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/modules/dictionary/services/dictionary_service.dart';

part 'dictionary_provider.g.dart';

@Riverpod(keepAlive: true)
class SelectedLetter extends _$SelectedLetter {
  @override
  String? build() => null;
  void setLetter(String? value) => state = value;
}

@Riverpod(keepAlive: true)
class SelectedPos extends _$SelectedPos {
  @override
  String? build() => null;
  void setPos(String? value) => state = value;
}

@Riverpod(keepAlive: true)
class SelectedTag extends _$SelectedTag {
  @override
  String? build() => null;
  void setTag(String? value) => state = value;
}

/// Whether the search + status-filter panel is shown instead of the letter
/// filter. Toggled by the filter icon in [DictionaryPage].
@Riverpod(keepAlive: true)
class DictionaryFilterPanelVisible extends _$DictionaryFilterPanelVisible {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

@riverpod
class WordList extends _$WordList {
  int _currentPage = 1;
  int _total = 0;
  bool _reachedMax = false;

  int get total => _total;

  @override
  Future<List<WordEntry>> build() async {
    _currentPage = 1;
    _reachedMax = false;
    final letter = ref.watch(selectedLetterProvider);
    final pos = ref.watch(selectedPosProvider);
    final tag = ref.watch(selectedTagProvider);
    final result = await ref
        .read(apiServiceProvider)
        .listWords(page: 1, letter: letter, pos: pos, tag: tag);
    _total = result.total;
    _reachedMax = result.results.length >= _total;
    return result.results;
  }

  Future<void> loadMore() async {
    if (state.isLoading || _reachedMax) return;

    state = const AsyncLoading<List<WordEntry>>().copyWithPrevious(state);
    _currentPage++;

    final letter = ref.read(selectedLetterProvider);
    final pos = ref.read(selectedPosProvider);
    final tag = ref.read(selectedTagProvider);
    final result = await ref.read(apiServiceProvider).listWords(
          page: _currentPage,
          size: ApiConfig.defaultPageSize,
          letter: letter,
          pos: pos,
          tag: tag,
        );

    _total = result.total;
    final current = state.value ?? [];
    final combined = [...current, ...result.results];
    _reachedMax = combined.length >= _total;
    state = AsyncValue.data(combined);
  }
}

/// Free-text search over the dictionary (merged in from the former standalone
/// Search page — `/search` doesn't support a letter param, so this stays a
/// separate query path from [WordList]; pos/tag are shared with it).
@riverpod
class DictionarySearchQuery extends _$DictionarySearchQuery {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void set(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      state = value;
    });
  }

  void setImmediate(String value) => state = value;
}

@riverpod
Future<SearchResult> dictionarySearchResults(
  DictionarySearchResultsRef ref,
) async {
  final query = ref.watch(dictionarySearchQueryProvider);
  final pos = ref.watch(selectedPosProvider);
  final tag = ref.watch(selectedTagProvider);
  if (query.trim().length < 2) {
    return const SearchResult(total: 0, results: []);
  }
  return ref.read(dictionaryServiceProvider).search(query, pos: pos, tag: tag);
}
