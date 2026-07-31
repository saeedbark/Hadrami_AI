import 'package:freezed_annotation/freezed_annotation.dart';

part 'word_entry.freezed.dart';
part 'word_entry.g.dart';

@freezed
class ExamplePair with _$ExamplePair {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExamplePair({
    @Default('') String h,
    @Default('') String f,
  }) = _ExamplePair;

  factory ExamplePair.fromJson(Map<String, dynamic> json) =>
      _$ExamplePairFromJson(json);
}

@freezed
class WordEntry with _$WordEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WordEntry({
    @Default(0) int id,
    @Default('') String wordVocalized,
    String? wordClean,
    String? root,
    String? pos,
    String? fushaEquivalent,
    String? definition,
    @Default('General') String region,
    List<String>? synonyms,
    List<String>? phoneticVariants,
    String? note,
    String? source,
    List<ExamplePair>? examples,
    List<String>? proverbs,
    List<String>? tags,
  }) = _WordEntry;

  factory WordEntry.fromJson(Map<String, dynamic> json) =>
      _$WordEntryFromJson(json);
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
class AppStats with _$AppStats {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AppStats({
    @Default(0) int totalWords,
    @Default(0) int completed,
    @Default(0) int pending,
    @Default(0.0) double completionPercent,
    @Default(<String, int>{}) Map<String, int> byPos,
    @Default(<String, int>{}) Map<String, int> byTag,
    @Default(0) int totalProverbs,
  }) = _AppStats;

  factory AppStats.fromJson(Map<String, dynamic> json) =>
      _$AppStatsFromJson(json);
}

@freezed
class ChatResult with _$ChatResult {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChatResult({
    @Default('') String reply,
    @Default(<WordEntry>[]) List<WordEntry> context,
    @Default(<HadramiSpan>[]) List<HadramiSpan> hadramiSpans,
    @Default(<String>[]) List<String> highlightSurfaces,
  }) = _ChatResult;

  factory ChatResult.fromJson(Map<String, dynamic> json) =>
      _$ChatResultFromJson(json);
}
