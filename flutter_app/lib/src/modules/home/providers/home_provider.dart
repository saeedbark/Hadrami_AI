import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
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

class TranslateState {
  final bool isLoading;
  final TranslateResult? result;
  final List<WordEntry> history;

  const TranslateState({
    this.isLoading = false,
    this.result,
    this.history = const [],
  });

  TranslateState copyWith({
    bool? isLoading,
    TranslateResult? result,
    List<WordEntry>? history,
  }) {
    return TranslateState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      history: history ?? this.history,
    );
  }
}

@Riverpod(keepAlive: true)
class Translate extends _$Translate {
  @override
  TranslateState build() => const TranslateState();

  Future<void> translate(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, result: null);

    final result = await ref.read(apiServiceProvider).translate(query);
    final history = [...state.history];

    if (result.found) {
      final entry = WordEntry(
        id: 0,
        hadramiWord: result.hadramiWord,
        arabicFus7a: result.arabicFus7a,
        fullDefinition: result.fullDefinition,
      );
      history.removeWhere((e) => e.hadramiWord == entry.hadramiWord);
      history.insert(0, entry);
      if (history.length > 50) history.removeRange(50, history.length);
    }

    state = TranslateState(
      isLoading: false,
      result: result,
      history: history,
    );
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }
}
