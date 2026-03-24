import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';

part 'search_provider.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';
  void set(String value) => state = value;
}

@riverpod
Future<SearchResult> searchResults(SearchResultsRef ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) {
    return const SearchResult(total: 0, results: []);
  }
  return ref.read(apiServiceProvider).search(query);
}
