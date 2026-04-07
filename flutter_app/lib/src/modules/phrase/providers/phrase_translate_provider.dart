import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';

part 'phrase_translate_provider.g.dart';

class PhraseTranslateState {
  final bool isLoading;
  final PhraseTranslateResult? result;

  const PhraseTranslateState({this.isLoading = false, this.result});

  PhraseTranslateState copyWith({
    bool? isLoading,
    PhraseTranslateResult? result,
  }) =>
      PhraseTranslateState(
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
      );
}

@riverpod
class PhraseTranslate extends _$PhraseTranslate {
  @override
  PhraseTranslateState build() => const PhraseTranslateState();

  Future<void> translate({
    required String text,
    required String direction,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (state.isLoading) return;
    state = PhraseTranslateState(isLoading: true, result: state.result);
    final result = await ref.read(apiServiceProvider).translatePhrase(
          text: trimmed,
          direction: direction,
        );
    state = PhraseTranslateState(isLoading: false, result: result);
  }
}
