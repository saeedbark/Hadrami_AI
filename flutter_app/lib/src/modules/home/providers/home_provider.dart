import 'package:hadrami_nlp/src/modules/home/home_models/home_model.dart';
import 'package:hadrami_nlp/src/modules/home/home_models/lexicon_section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/modules/home/services/home_service.dart';

part 'home_provider.g.dart';

@riverpod
Future<AppStats> stats(StatsRef ref) async {
  final data = await ref.read(homeServiceProvider).getStats();
  if (data == null || data.totalWords == 0) {
    throw StateError(
      AppStrings.homeProviderStatsErrorMessage,
    );
  }
  return data;
}

@riverpod
Future<WordEntry?> randomWord(RandomWordRef ref) async {
  return ref.read(homeServiceProvider).randomWord();
}

@riverpod
Future<List<LexiconSection>> sections(SectionsRef ref) async {
  return ref.read(homeServiceProvider).getSections();
}

@riverpod
Future<List<WordEntry>> featuredWords(FeaturedWordsRef ref) async {
  final result = await ref.read(apiServiceProvider).listWords(page: 1, size: 8);
  return result.results;
}
