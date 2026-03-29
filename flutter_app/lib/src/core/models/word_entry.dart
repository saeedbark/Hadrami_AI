import 'package:freezed_annotation/freezed_annotation.dart';

part 'word_entry.freezed.dart';
part 'word_entry.g.dart';

@freezed
class WordEntry with _$WordEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WordEntry({
    @Default(0) int id,
    @Default('') String hadramiWord,
    @Default('') String arabicFus7a,
    @Default('') String fullDefinition,
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
class AppStats with _$AppStats {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AppStats({
    @Default(0) int totalWords,
    @Default(0) int translated,
    @Default(0) int pending,
    @Default(0.0) double completionPercent,
  }) = _AppStats;

  factory AppStats.fromJson(Map<String, dynamic> json) =>
      _$AppStatsFromJson(json);
}
