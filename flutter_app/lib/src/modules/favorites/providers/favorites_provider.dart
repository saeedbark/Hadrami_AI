import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';

part 'favorites_provider.g.dart';

@Riverpod(keepAlive: true)
class Favorites extends _$Favorites {
  @override
  List<WordEntry> build() => [];

  void toggle(WordEntry entry) {
    final list = [...state];
    final idx = list.indexWhere((e) => e.wordVocalized == entry.wordVocalized);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, entry);
    }
    state = list;
  }

  bool isFavorite(WordEntry entry) =>
      state.any((e) => e.wordVocalized == entry.wordVocalized);

  void clearAll() => state = [];
}
