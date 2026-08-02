import 'package:hadrami_nlp/src/modules/home/home_models/home_model.dart';
import 'package:hadrami_nlp/src/modules/home/home_models/lexicon_section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/configs/api_endpoints.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';

part 'home_service.g.dart';

/// Thin home-facing wrapper over the shared [ApiService] — keeps `/random`
/// and `/sections` scoped to this module. `/stats` and `/words` (listWords)
/// stay directly on [ApiService] since settings and the dictionary module
/// call them too.
@riverpod
HomeService homeService(HomeServiceRef ref) =>
    HomeService(ref.read(apiServiceProvider));

class HomeService {
  HomeService(this._api);

  final ApiService _api;

  Future<AppStats?> getStats() async {
    try {
      final data = await _api.getJson(ApiEndpoints.stats);
      return AppStats.fromJson(data);
    } catch (_) {
      return const AppStats();
    }
  }

  Future<WordEntry?> randomWord() async {
    try {
      final data = await _api.getJson(
        ApiEndpoints.random,
        timeout: const Duration(seconds: 5),
      );
      return WordEntry.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<LexiconSection>> getSections() async {
    try {
      final data = await _api.getJson(
        ApiEndpoints.sections,
        timeout: const Duration(seconds: 5),
      ) as Map<String, dynamic>;
      final raw = data['sections'];
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(LexiconSection.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
