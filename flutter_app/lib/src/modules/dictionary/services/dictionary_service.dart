import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/configs/api_endpoints.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';

part 'dictionary_service.g.dart';

/// Thin dictionary-facing wrapper over the shared [ApiService] — keeps the
/// `/search` and `/feedback` calls scoped to this module while the underlying
/// HTTP client stays the single boundary shared with other modules. `/words`
/// (listWords) stays directly on [ApiService] since home's featured-words
/// preview calls it too, not just the dictionary module.
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

  Future<bool> submitFeedback({
    required String wordVocalized,
    String suggestedFusha = '',
    int wordId = 0,
    String? comment,
    String feedbackType = 'correction',
    List<String>? spellingVariants,
    String? sentencePairHadrami,
    String? sentencePairFusha,
    bool consent = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'word_id': wordId,
        'word_vocalized': wordVocalized,
        'suggested_fusha': suggestedFusha,
        'comment': comment,
        'feedback_type': feedbackType,
        'consent': consent,
      };
      if (spellingVariants != null) {
        body['spelling_variants'] = spellingVariants;
      }
      if (sentencePairHadrami != null) {
        body['sentence_pair_hadrami'] = sentencePairHadrami;
      }
      if (sentencePairFusha != null) {
        body['sentence_pair_fusha'] = sentencePairFusha;
      }
      await _api.postJson(
        ApiEndpoints.feedback,
        body,
        timeout: const Duration(seconds: 5),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
