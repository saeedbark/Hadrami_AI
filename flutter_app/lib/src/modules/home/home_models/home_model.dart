 import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_model.freezed.dart';
part 'home_model.g.dart';

@freezed
class AppStats with _$AppStats {
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