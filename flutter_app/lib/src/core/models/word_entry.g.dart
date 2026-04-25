// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExamplePairImpl _$$ExamplePairImplFromJson(Map<String, dynamic> json) =>
    _$ExamplePairImpl(
      h: json['h'] as String? ?? '',
      f: json['f'] as String? ?? '',
    );

Map<String, dynamic> _$$ExamplePairImplToJson(_$ExamplePairImpl instance) =>
    <String, dynamic>{
      'h': instance.h,
      'f': instance.f,
    };

_$WordEntryImpl _$$WordEntryImplFromJson(Map<String, dynamic> json) =>
    _$WordEntryImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      wordVocalized: json['word_vocalized'] as String? ?? '',
      wordClean: json['word_clean'] as String?,
      root: json['root'] as String?,
      pos: json['pos'] as String?,
      fushaEquivalent: json['fusha_equivalent'] as String?,
      definition: json['definition'] as String?,
      region: json['region'] as String? ?? 'General',
      synonyms: (json['synonyms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      phoneticVariants: (json['phonetic_variants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      note: json['note'] as String?,
      source: json['source'] as String?,
      examples: (json['examples'] as List<dynamic>?)
          ?.map((e) => ExamplePair.fromJson(e as Map<String, dynamic>))
          .toList(),
      proverbs: (json['proverbs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$WordEntryImplToJson(_$WordEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'word_vocalized': instance.wordVocalized,
      'word_clean': instance.wordClean,
      'root': instance.root,
      'pos': instance.pos,
      'fusha_equivalent': instance.fushaEquivalent,
      'definition': instance.definition,
      'region': instance.region,
      'synonyms': instance.synonyms,
      'phonetic_variants': instance.phoneticVariants,
      'note': instance.note,
      'source': instance.source,
      'examples': instance.examples,
      'proverbs': instance.proverbs,
      'tags': instance.tags,
    };

_$TranslateResultImpl _$$TranslateResultImplFromJson(
        Map<String, dynamic> json) =>
    _$TranslateResultImpl(
      found: json['found'] as bool? ?? false,
      wordVocalized: json['word_vocalized'] as String? ?? '',
      fushaEquivalent: json['fusha_equivalent'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'not_found',
    );

Map<String, dynamic> _$$TranslateResultImplToJson(
        _$TranslateResultImpl instance) =>
    <String, dynamic>{
      'found': instance.found,
      'word_vocalized': instance.wordVocalized,
      'fusha_equivalent': instance.fushaEquivalent,
      'definition': instance.definition,
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
      answerSource: json['answer_source'] as String? ?? 'model',
      hadramiSpans: (json['hadrami_spans'] as List<dynamic>?)
              ?.map((e) => HadramiSpan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HadramiSpan>[],
      highlightSurfaces: (json['highlight_surfaces'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      context: (json['context'] as List<dynamic>?)
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WordEntry>[],
    );

Map<String, dynamic> _$$AskResultImplToJson(_$AskResultImpl instance) =>
    <String, dynamic>{
      'question': instance.question,
      'answer': instance.answer,
      'mode': instance.mode,
      'answer_source': instance.answerSource,
      'hadrami_spans': instance.hadramiSpans,
      'highlight_surfaces': instance.highlightSurfaces,
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
      byPos: (json['by_pos'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      byTag: (json['by_tag'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      totalProverbs: (json['total_proverbs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$AppStatsImplToJson(_$AppStatsImpl instance) =>
    <String, dynamic>{
      'total_words': instance.totalWords,
      'translated': instance.translated,
      'pending': instance.pending,
      'completion_percent': instance.completionPercent,
      'by_pos': instance.byPos,
      'by_tag': instance.byTag,
      'total_proverbs': instance.totalProverbs,
    };

_$ChatResultImpl _$$ChatResultImplFromJson(Map<String, dynamic> json) =>
    _$ChatResultImpl(
      reply: json['reply'] as String? ?? '',
      context: (json['context'] as List<dynamic>?)
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WordEntry>[],
      hadramiSpans: (json['hadrami_spans'] as List<dynamic>?)
              ?.map((e) => HadramiSpan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HadramiSpan>[],
      highlightSurfaces: (json['highlight_surfaces'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$ChatResultImplToJson(_$ChatResultImpl instance) =>
    <String, dynamic>{
      'reply': instance.reply,
      'context': instance.context,
      'hadrami_spans': instance.hadramiSpans,
      'highlight_surfaces': instance.highlightSurfaces,
    };
