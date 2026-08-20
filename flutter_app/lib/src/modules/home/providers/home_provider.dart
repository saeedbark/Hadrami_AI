import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/modules/home/models/lexicon_section.dart';
import 'package:hadrami_nlp/src/modules/home/services/home_service.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/app_stats.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/word_entry.dart';
import 'package:hadrami_nlp/src/modules/lexicon/services/lexicon_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

@riverpod
Future<AppStats> stats(StatsRef ref) async {
  final data = await ref.read(lexiconServiceProvider).getStats();
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
  final result = await ref.read(lexiconServiceProvider).listWords(page: 1, size: 8);
  return result.results;
}
