import 'package:hadrami_nlp/src/core/network/api_endpoints.dart';
import 'package:hadrami_nlp/src/core/network/api_service.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/word_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dictionary_service.g.dart';

/// Thin dictionary-facing wrapper over the shared [ApiService] — keeps `/search`
/// scoped to this module while the underlying HTTP client stays the single
/// boundary shared with other modules. `/words`, `/stats` and `/feedback` live
/// on `LexiconService` instead: they are consumed by more than one module, so
/// they belong to the lexicon domain rather than to this screen.
@riverpod
DictionaryService dictionaryService(DictionaryServiceRef ref) =>
    DictionaryService(ref.read(apiServiceProvider));

class DictionaryService {
  DictionaryService(this._api);

  final ApiService _api;

  Future<SearchResult> search(
    String query, {
    int limit = 20,
    String? pos,
    String? region,
    String? tag,
  }) async {
    try {
      final data = await _api.getJson(
        ApiEndpoints.search,
        queryParameters: {
          'q': query,
          'limit': '$limit',
          if (pos != null) 'pos': pos,
          if (region != null) 'region': region,
          if (tag != null) 'tag': tag,
        },
      );
      return SearchResult.fromJson(data);
    } catch (_) {
      return const SearchResult(total: 0, results: []);
    }
  }
}
