import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';

part 'dictionary_provider.g.dart';

@Riverpod(keepAlive: true)
class SelectedLetter extends _$SelectedLetter {
  @override
  String? build() => null;
  void setLetter(String? value) => state = value;
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
    final result = await ref
        .read(apiServiceProvider)
        .listWords(page: 1, letter: letter);
    _total = result.total;
    _reachedMax = result.results.length >= _total;
    return result.results;
  }

  Future<void> loadMore() async {
    if (state.isLoading || _reachedMax) return;

    state = const AsyncLoading<List<WordEntry>>().copyWithPrevious(state);
    _currentPage++;

    final letter = ref.read(selectedLetterProvider);
    final result = await ref
        .read(apiServiceProvider)
        .listWords(page: _currentPage, size: ApiConfig.defaultPageSize, letter: letter);

    _total = result.total;
    final current = state.value ?? [];
    final combined = [...current, ...result.results];
    _reachedMax = combined.length >= _total;
    state = AsyncValue.data(combined);
  }
}
