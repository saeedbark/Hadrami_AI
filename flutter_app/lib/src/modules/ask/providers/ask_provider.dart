import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';

part 'ask_provider.g.dart';

class AskState {
  final bool isLoading;
  final AskResult? result;

  const AskState({this.isLoading = false, this.result});

  AskState copyWith({bool? isLoading, AskResult? result}) => AskState(
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
      );
}

@riverpod
class Ask extends _$Ask {
  @override
  AskState build() => const AskState();

  Future<void> ask(String question) async {
    if (question.trim().isEmpty) return;
    state = const AskState(isLoading: true);
    final result = await ref.read(apiServiceProvider).ask(question);
    state = AskState(isLoading: false, result: result);
  }
}
