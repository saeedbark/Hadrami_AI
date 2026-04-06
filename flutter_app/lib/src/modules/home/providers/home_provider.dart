import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/core/models/lexicon_section.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';

part 'home_provider.g.dart';

@riverpod
Future<AppStats> stats(StatsRef ref) async {
  final data = await ref.read(apiServiceProvider).getStats();
  if (data.isEmpty) {
    throw StateError(
      'تعذّر الاتصال بالخادم. شغّل الـ backend ثم حدّث الصفحة.\n'
      'المتوقع: ${ApiConfig.baseUrl}',
    );
  }
  return AppStats.fromJson(data);
}

@riverpod
Future<WordEntry?> randomWord(RandomWordRef ref) async {
  return ref.read(apiServiceProvider).randomWord();
}

@riverpod
Future<List<LexiconSection>> sections(SectionsRef ref) async {
  return ref.read(apiServiceProvider).getSections();
}

@riverpod
Future<List<WordEntry>> featuredWords(FeaturedWordsRef ref) async {
  final result =
      await ref.read(apiServiceProvider).listWords(page: 1, size: 8);
  return result.results;
}
