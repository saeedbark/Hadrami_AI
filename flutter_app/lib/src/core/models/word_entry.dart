import 'package:freezed_annotation/freezed_annotation.dart';

part 'word_entry.freezed.dart';
part 'word_entry.g.dart';

@freezed
class ExamplePair with _$ExamplePair {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExamplePair({
    @Default('') String hadrami,
    @Default('') String fusha,
  }) = _ExamplePair;

  factory ExamplePair.fromJson(Map<String, dynamic> json) =>
      _$ExamplePairFromJson(json);
}

@freezed
class WordEntry with _$WordEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WordEntry({
    @Default(0) int id,
    @Default('') String hadramiWord,
    @Default('') String arabicFus7a,
    @Default('') String fullDefinition,
    String? fus7aShort,
    String? searchKey,
    String? partOfSpeech,
    String? thematicCategory,
    @Default(false) bool isArchaic,
    List<String>? pronunciationNotes,
    List<String>? proverbRecord,
    String? culturalNote,
    List<String>? aliases,
    List<ExamplePair>? examples,
  }) = _WordEntry;

  factory WordEntry.fromJson(Map<String, dynamic> json) =>
      _$WordEntryFromJson(json);
}

@freezed
class TranslateResult with _$TranslateResult {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TranslateResult({
    @Default(false) bool found,
    @Default('') String hadramiWord,
    @Default('') String arabicFus7a,
    @Default('') String fullDefinition,
    @Default('not_found') String confidence,
  }) = _TranslateResult;

  factory TranslateResult.fromJson(Map<String, dynamic> json) =>
      _$TranslateResultFromJson(json);
}

@freezed
class SearchResult with _$SearchResult {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory SearchResult({
    @Default(0) int total,
    @Default(<WordEntry>[]) List<WordEntry> results,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);
}

@freezed
class AskResult with _$AskResult {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AskResult({
    @Default('') String question,
    @Default('') String answer,
    @Default('simple') String mode,
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> context,
  }) = _AskResult;

  factory AskResult.fromJson(Map<String, dynamic> json) =>
      _$AskResultFromJson(json);
}

@freezed
class HadramiSpan with _$HadramiSpan {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory HadramiSpan({
    @Default(0) int start,
    @Default(0) int end,
    @Default('') String surface,
  }) = _HadramiSpan;

  factory HadramiSpan.fromJson(Map<String, dynamic> json) =>
      _$HadramiSpanFromJson(json);
}

@freezed
class PhraseTranslateResult with _$PhraseTranslateResult {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PhraseTranslateResult({
    @Default('') String inputText,
    @Default('') String direction,
    @Default('') String translatedText,
    @Default(<HadramiSpan>[]) List<HadramiSpan> hadramiSpans,
    @Default('error') String mode,
    @Default('') String ragMode,
    @Default(<WordEntry>[]) List<WordEntry> context,
  }) = _PhraseTranslateResult;

  factory PhraseTranslateResult.fromJson(Map<String, dynamic> json) =>
      _$PhraseTranslateResultFromJson(json);
}

@freezed
class AppStats with _$AppStats {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AppStats({
    @Default(0) int totalWords,
    @Default(0) int translated,
    @Default(0) int pending,
    @Default(0.0) double completionPercent,
    @Default(<String, int>{}) Map<String, int> byPartOfSpeech,
    @Default(<String, int>{}) Map<String, int> byThematicCategory,
    @Default(0) int archaicWords,
    @Default(0) int totalProverbs,
  }) = _AppStats;

  factory AppStats.fromJson(Map<String, dynamic> json) =>
      _$AppStatsFromJson(json);
}
