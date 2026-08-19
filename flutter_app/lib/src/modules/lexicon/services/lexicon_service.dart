import 'package:hadrami_nlp/src/core/network/api_config.dart';
import 'package:hadrami_nlp/src/core/network/api_endpoints.dart';
import 'package:hadrami_nlp/src/core/network/api_service.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/app_stats.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/word_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lexicon_service.g.dart';

/// Thin lexicon-facing wrapper over the shared [ApiService], mirroring
/// [DictionaryService]/[HomeService]. Owns `/feedback` because the submission
/// form lives in this module's `word_detail_sheet.dart`, which dictionary,
/// home and favorites all render.
@riverpod
LexiconService lexiconService(LexiconServiceRef ref) =>
    LexiconService(ref.read(apiServiceProvider));

class LexiconService {
  LexiconService(this._api);

  final ApiService _api;

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

  Future<AppStats?> getStats() async {
    try {
      final data = await _api.getJson(ApiEndpoints.stats);
      return AppStats.fromJson(data);
    } catch (_) {
      return const AppStats();
    }
  }

  Future<SearchResult> listWords({
    int page = 1,
    int size = ApiConfig.defaultPageSize,
    String? letter,
    String? pos,
    String? region,
    String? tag,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'size': '$size',
        if (letter != null) 'letter': letter,
        if (pos != null) 'pos': pos,
        if (region != null) 'region': region,
        if (tag != null) 'tag': tag,
      };
      final data =
          await _api.getJson(ApiEndpoints.words, queryParameters: params);
      return SearchResult.fromJson(data);
    } catch (_) {
      return const SearchResult(total: 0, results: []);
    }
  }
}
