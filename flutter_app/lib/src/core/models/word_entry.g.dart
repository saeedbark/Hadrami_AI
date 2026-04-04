// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WordEntryImpl _$$WordEntryImplFromJson(Map<String, dynamic> json) =>
    _$WordEntryImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      hadramiWord: json['hadrami_word'] as String? ?? '',
      arabicFus7a: json['arabic_fus7a'] as String? ?? '',
      fullDefinition: json['full_definition'] as String? ?? '',
    );

Map<String, dynamic> _$$WordEntryImplToJson(_$WordEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hadrami_word': instance.hadramiWord,
      'arabic_fus7a': instance.arabicFus7a,
      'full_definition': instance.fullDefinition,
    };

_$TranslateResultImpl _$$TranslateResultImplFromJson(
        Map<String, dynamic> json) =>
    _$TranslateResultImpl(
      found: json['found'] as bool? ?? false,
      hadramiWord: json['hadrami_word'] as String? ?? '',
      arabicFus7a: json['arabic_fus7a'] as String? ?? '',
      fullDefinition: json['full_definition'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'not_found',
    );

Map<String, dynamic> _$$TranslateResultImplToJson(
        _$TranslateResultImpl instance) =>
    <String, dynamic>{
      'found': instance.found,
      'hadrami_word': instance.hadramiWord,
      'arabic_fus7a': instance.arabicFus7a,
      'full_definition': instance.fullDefinition,
      'confidence': instance.confidence,
    };

_$SearchResultImpl _$$SearchResultImplFromJson(Map<String, dynamic> json) =>
    _$SearchResultImpl(
      total: (json['total'] as num?)?.toInt() ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WordEntry>[],
    );

Map<String, dynamic> _$$SearchResultImplToJson(_$SearchResultImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'results': instance.results,
    };

_$AskResultImpl _$$AskResultImplFromJson(Map<String, dynamic> json) =>
    _$AskResultImpl(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      mode: json['mode'] as String? ?? 'simple',
      context: (json['context'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <Map<String, dynamic>>[],
    );

Map<String, dynamic> _$$AskResultImplToJson(_$AskResultImpl instance) =>
    <String, dynamic>{
      'question': instance.question,
      'answer': instance.answer,
      'mode': instance.mode,
      'context': instance.context,
    };

_$HadramiSpanImpl _$$HadramiSpanImplFromJson(Map<String, dynamic> json) =>
    _$HadramiSpanImpl(
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 0,
      surface: json['surface'] as String? ?? '',
    );

Map<String, dynamic> _$$HadramiSpanImplToJson(_$HadramiSpanImpl instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'surface': instance.surface,
    };

_$PhraseTranslateResultImpl _$$PhraseTranslateResultImplFromJson(
        Map<String, dynamic> json) =>
    _$PhraseTranslateResultImpl(
      inputText: json['input_text'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      translatedText: json['translated_text'] as String? ?? '',
      hadramiSpans: (json['hadrami_spans'] as List<dynamic>?)
              ?.map((e) => HadramiSpan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HadramiSpan>[],
      mode: json['mode'] as String? ?? 'error',
      ragMode: json['rag_mode'] as String? ?? '',
      context: (json['context'] as List<dynamic>?)
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WordEntry>[],
    );

Map<String, dynamic> _$$PhraseTranslateResultImplToJson(
        _$PhraseTranslateResultImpl instance) =>
    <String, dynamic>{
      'input_text': instance.inputText,
      'direction': instance.direction,
      'translated_text': instance.translatedText,
      'hadrami_spans': instance.hadramiSpans,
      'mode': instance.mode,
      'rag_mode': instance.ragMode,
      'context': instance.context,
    };

_$AppStatsImpl _$$AppStatsImplFromJson(Map<String, dynamic> json) =>
    _$AppStatsImpl(
      totalWords: (json['total_words'] as num?)?.toInt() ?? 0,
      translated: (json['translated'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completionPercent:
          (json['completion_percent'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$AppStatsImplToJson(_$AppStatsImpl instance) =>
    <String, dynamic>{
      'total_words': instance.totalWords,
      'translated': instance.translated,
      'pending': instance.pending,
      'completion_percent': instance.completionPercent,
    };
