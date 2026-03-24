// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'word_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WordEntry _$WordEntryFromJson(Map<String, dynamic> json) {
  return _WordEntry.fromJson(json);
}

/// @nodoc
mixin _$WordEntry {
  int get id => throw _privateConstructorUsedError;
  String get hadramiWord => throw _privateConstructorUsedError;
  String get arabicFus7a => throw _privateConstructorUsedError;
  String get fullDefinition => throw _privateConstructorUsedError;

  /// Serializes this WordEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WordEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WordEntryCopyWith<WordEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WordEntryCopyWith<$Res> {
  factory $WordEntryCopyWith(WordEntry value, $Res Function(WordEntry) then) =
      _$WordEntryCopyWithImpl<$Res, WordEntry>;
  @useResult
  $Res call(
      {int id, String hadramiWord, String arabicFus7a, String fullDefinition});
}

/// @nodoc
class _$WordEntryCopyWithImpl<$Res, $Val extends WordEntry>
    implements $WordEntryCopyWith<$Res> {
  _$WordEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WordEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hadramiWord = null,
    Object? arabicFus7a = null,
    Object? fullDefinition = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      hadramiWord: null == hadramiWord
          ? _value.hadramiWord
          : hadramiWord // ignore: cast_nullable_to_non_nullable
              as String,
      arabicFus7a: null == arabicFus7a
          ? _value.arabicFus7a
          : arabicFus7a // ignore: cast_nullable_to_non_nullable
              as String,
      fullDefinition: null == fullDefinition
          ? _value.fullDefinition
          : fullDefinition // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WordEntryImplCopyWith<$Res>
    implements $WordEntryCopyWith<$Res> {
  factory _$$WordEntryImplCopyWith(
          _$WordEntryImpl value, $Res Function(_$WordEntryImpl) then) =
      __$$WordEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, String hadramiWord, String arabicFus7a, String fullDefinition});
}

/// @nodoc
class __$$WordEntryImplCopyWithImpl<$Res>
    extends _$WordEntryCopyWithImpl<$Res, _$WordEntryImpl>
    implements _$$WordEntryImplCopyWith<$Res> {
  __$$WordEntryImplCopyWithImpl(
      _$WordEntryImpl _value, $Res Function(_$WordEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of WordEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hadramiWord = null,
    Object? arabicFus7a = null,
    Object? fullDefinition = null,
  }) {
    return _then(_$WordEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      hadramiWord: null == hadramiWord
          ? _value.hadramiWord
          : hadramiWord // ignore: cast_nullable_to_non_nullable
              as String,
      arabicFus7a: null == arabicFus7a
          ? _value.arabicFus7a
          : arabicFus7a // ignore: cast_nullable_to_non_nullable
              as String,
      fullDefinition: null == fullDefinition
          ? _value.fullDefinition
          : fullDefinition // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$WordEntryImpl implements _WordEntry {
  const _$WordEntryImpl(
      {this.id = 0,
      this.hadramiWord = '',
      this.arabicFus7a = '',
      this.fullDefinition = ''});

  factory _$WordEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$WordEntryImplFromJson(json);

  @override
  @JsonKey()
  final int id;
  @override
  @JsonKey()
  final String hadramiWord;
  @override
  @JsonKey()
  final String arabicFus7a;
  @override
  @JsonKey()
  final String fullDefinition;

  @override
  String toString() {
    return 'WordEntry(id: $id, hadramiWord: $hadramiWord, arabicFus7a: $arabicFus7a, fullDefinition: $fullDefinition)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WordEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.hadramiWord, hadramiWord) ||
                other.hadramiWord == hadramiWord) &&
            (identical(other.arabicFus7a, arabicFus7a) ||
                other.arabicFus7a == arabicFus7a) &&
            (identical(other.fullDefinition, fullDefinition) ||
                other.fullDefinition == fullDefinition));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, hadramiWord, arabicFus7a, fullDefinition);

  /// Create a copy of WordEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WordEntryImplCopyWith<_$WordEntryImpl> get copyWith =>
      __$$WordEntryImplCopyWithImpl<_$WordEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WordEntryImplToJson(
      this,
    );
  }
}

abstract class _WordEntry implements WordEntry {
  const factory _WordEntry(
      {final int id,
      final String hadramiWord,
      final String arabicFus7a,
      final String fullDefinition}) = _$WordEntryImpl;

  factory _WordEntry.fromJson(Map<String, dynamic> json) =
      _$WordEntryImpl.fromJson;

  @override
  int get id;
  @override
  String get hadramiWord;
  @override
  String get arabicFus7a;
  @override
  String get fullDefinition;

  /// Create a copy of WordEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WordEntryImplCopyWith<_$WordEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TranslateResult _$TranslateResultFromJson(Map<String, dynamic> json) {
  return _TranslateResult.fromJson(json);
}

/// @nodoc
mixin _$TranslateResult {
  bool get found => throw _privateConstructorUsedError;
  String get hadramiWord => throw _privateConstructorUsedError;
  String get arabicFus7a => throw _privateConstructorUsedError;
  String get fullDefinition => throw _privateConstructorUsedError;
  String get confidence => throw _privateConstructorUsedError;

  /// Serializes this TranslateResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranslateResultCopyWith<TranslateResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranslateResultCopyWith<$Res> {
  factory $TranslateResultCopyWith(
          TranslateResult value, $Res Function(TranslateResult) then) =
      _$TranslateResultCopyWithImpl<$Res, TranslateResult>;
  @useResult
  $Res call(
      {bool found,
      String hadramiWord,
      String arabicFus7a,
      String fullDefinition,
      String confidence});
}

/// @nodoc
class _$TranslateResultCopyWithImpl<$Res, $Val extends TranslateResult>
    implements $TranslateResultCopyWith<$Res> {
  _$TranslateResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? found = null,
    Object? hadramiWord = null,
    Object? arabicFus7a = null,
    Object? fullDefinition = null,
    Object? confidence = null,
  }) {
    return _then(_value.copyWith(
      found: null == found
          ? _value.found
          : found // ignore: cast_nullable_to_non_nullable
              as bool,
      hadramiWord: null == hadramiWord
          ? _value.hadramiWord
          : hadramiWord // ignore: cast_nullable_to_non_nullable
              as String,
      arabicFus7a: null == arabicFus7a
          ? _value.arabicFus7a
          : arabicFus7a // ignore: cast_nullable_to_non_nullable
              as String,
      fullDefinition: null == fullDefinition
          ? _value.fullDefinition
          : fullDefinition // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranslateResultImplCopyWith<$Res>
    implements $TranslateResultCopyWith<$Res> {
  factory _$$TranslateResultImplCopyWith(_$TranslateResultImpl value,
          $Res Function(_$TranslateResultImpl) then) =
      __$$TranslateResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool found,
      String hadramiWord,
      String arabicFus7a,
      String fullDefinition,
      String confidence});
}

/// @nodoc
class __$$TranslateResultImplCopyWithImpl<$Res>
    extends _$TranslateResultCopyWithImpl<$Res, _$TranslateResultImpl>
    implements _$$TranslateResultImplCopyWith<$Res> {
  __$$TranslateResultImplCopyWithImpl(
      _$TranslateResultImpl _value, $Res Function(_$TranslateResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of TranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? found = null,
    Object? hadramiWord = null,
    Object? arabicFus7a = null,
    Object? fullDefinition = null,
    Object? confidence = null,
  }) {
    return _then(_$TranslateResultImpl(
      found: null == found
          ? _value.found
          : found // ignore: cast_nullable_to_non_nullable
              as bool,
      hadramiWord: null == hadramiWord
          ? _value.hadramiWord
          : hadramiWord // ignore: cast_nullable_to_non_nullable
              as String,
      arabicFus7a: null == arabicFus7a
          ? _value.arabicFus7a
          : arabicFus7a // ignore: cast_nullable_to_non_nullable
              as String,
      fullDefinition: null == fullDefinition
          ? _value.fullDefinition
          : fullDefinition // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$TranslateResultImpl implements _TranslateResult {
  const _$TranslateResultImpl(
      {this.found = false,
      this.hadramiWord = '',
      this.arabicFus7a = '',
      this.fullDefinition = '',
      this.confidence = 'not_found'});

  factory _$TranslateResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranslateResultImplFromJson(json);

  @override
  @JsonKey()
  final bool found;
  @override
  @JsonKey()
  final String hadramiWord;
  @override
  @JsonKey()
  final String arabicFus7a;
  @override
  @JsonKey()
  final String fullDefinition;
  @override
  @JsonKey()
  final String confidence;

  @override
  String toString() {
    return 'TranslateResult(found: $found, hadramiWord: $hadramiWord, arabicFus7a: $arabicFus7a, fullDefinition: $fullDefinition, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranslateResultImpl &&
            (identical(other.found, found) || other.found == found) &&
            (identical(other.hadramiWord, hadramiWord) ||
                other.hadramiWord == hadramiWord) &&
            (identical(other.arabicFus7a, arabicFus7a) ||
                other.arabicFus7a == arabicFus7a) &&
            (identical(other.fullDefinition, fullDefinition) ||
                other.fullDefinition == fullDefinition) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, found, hadramiWord, arabicFus7a, fullDefinition, confidence);

  /// Create a copy of TranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranslateResultImplCopyWith<_$TranslateResultImpl> get copyWith =>
      __$$TranslateResultImplCopyWithImpl<_$TranslateResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranslateResultImplToJson(
      this,
    );
  }
}

abstract class _TranslateResult implements TranslateResult {
  const factory _TranslateResult(
      {final bool found,
      final String hadramiWord,
      final String arabicFus7a,
      final String fullDefinition,
      final String confidence}) = _$TranslateResultImpl;

  factory _TranslateResult.fromJson(Map<String, dynamic> json) =
      _$TranslateResultImpl.fromJson;

  @override
  bool get found;
  @override
  String get hadramiWord;
  @override
  String get arabicFus7a;
  @override
  String get fullDefinition;
  @override
  String get confidence;

  /// Create a copy of TranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranslateResultImplCopyWith<_$TranslateResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) {
  return _SearchResult.fromJson(json);
}

/// @nodoc
mixin _$SearchResult {
  int get total => throw _privateConstructorUsedError;
  List<WordEntry> get results => throw _privateConstructorUsedError;

  /// Serializes this SearchResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchResultCopyWith<SearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResultCopyWith<$Res> {
  factory $SearchResultCopyWith(
          SearchResult value, $Res Function(SearchResult) then) =
      _$SearchResultCopyWithImpl<$Res, SearchResult>;
  @useResult
  $Res call({int total, List<WordEntry> results});
}

/// @nodoc
class _$SearchResultCopyWithImpl<$Res, $Val extends SearchResult>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? results = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<WordEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SearchResultImplCopyWith<$Res>
    implements $SearchResultCopyWith<$Res> {
  factory _$$SearchResultImplCopyWith(
          _$SearchResultImpl value, $Res Function(_$SearchResultImpl) then) =
      __$$SearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, List<WordEntry> results});
}

/// @nodoc
class __$$SearchResultImplCopyWithImpl<$Res>
    extends _$SearchResultCopyWithImpl<$Res, _$SearchResultImpl>
    implements _$$SearchResultImplCopyWith<$Res> {
  __$$SearchResultImplCopyWithImpl(
      _$SearchResultImpl _value, $Res Function(_$SearchResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? results = null,
  }) {
    return _then(_$SearchResultImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<WordEntry>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$SearchResultImpl implements _SearchResult {
  const _$SearchResultImpl(
      {this.total = 0, final List<WordEntry> results = const <WordEntry>[]})
      : _results = results;

  factory _$SearchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchResultImplFromJson(json);

  @override
  @JsonKey()
  final int total;
  final List<WordEntry> _results;
  @override
  @JsonKey()
  List<WordEntry> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'SearchResult(total: $total, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchResultImpl &&
            (identical(other.total, total) || other.total == total) &&
            const DeepCollectionEquality().equals(other._results, _results));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, total, const DeepCollectionEquality().hash(_results));

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchResultImplCopyWith<_$SearchResultImpl> get copyWith =>
      __$$SearchResultImplCopyWithImpl<_$SearchResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchResultImplToJson(
      this,
    );
  }
}

abstract class _SearchResult implements SearchResult {
  const factory _SearchResult(
      {final int total, final List<WordEntry> results}) = _$SearchResultImpl;

  factory _SearchResult.fromJson(Map<String, dynamic> json) =
      _$SearchResultImpl.fromJson;

  @override
  int get total;
  @override
  List<WordEntry> get results;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchResultImplCopyWith<_$SearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AskResult _$AskResultFromJson(Map<String, dynamic> json) {
  return _AskResult.fromJson(json);
}

/// @nodoc
mixin _$AskResult {
  String get question => throw _privateConstructorUsedError;
  String get answer => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get context => throw _privateConstructorUsedError;

  /// Serializes this AskResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AskResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AskResultCopyWith<AskResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AskResultCopyWith<$Res> {
  factory $AskResultCopyWith(AskResult value, $Res Function(AskResult) then) =
      _$AskResultCopyWithImpl<$Res, AskResult>;
  @useResult
  $Res call(
      {String question,
      String answer,
      String mode,
      List<Map<String, dynamic>> context});
}

/// @nodoc
class _$AskResultCopyWithImpl<$Res, $Val extends AskResult>
    implements $AskResultCopyWith<$Res> {
  _$AskResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AskResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? answer = null,
    Object? mode = null,
    Object? context = null,
  }) {
    return _then(_value.copyWith(
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      answer: null == answer
          ? _value.answer
          : answer // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AskResultImplCopyWith<$Res>
    implements $AskResultCopyWith<$Res> {
  factory _$$AskResultImplCopyWith(
          _$AskResultImpl value, $Res Function(_$AskResultImpl) then) =
      __$$AskResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String question,
      String answer,
      String mode,
      List<Map<String, dynamic>> context});
}

/// @nodoc
class __$$AskResultImplCopyWithImpl<$Res>
    extends _$AskResultCopyWithImpl<$Res, _$AskResultImpl>
    implements _$$AskResultImplCopyWith<$Res> {
  __$$AskResultImplCopyWithImpl(
      _$AskResultImpl _value, $Res Function(_$AskResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of AskResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? answer = null,
    Object? mode = null,
    Object? context = null,
  }) {
    return _then(_$AskResultImpl(
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      answer: null == answer
          ? _value.answer
          : answer // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value._context
          : context // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$AskResultImpl implements _AskResult {
  const _$AskResultImpl(
      {this.question = '',
      this.answer = '',
      this.mode = 'simple',
      final List<Map<String, dynamic>> context =
          const <Map<String, dynamic>>[]})
      : _context = context;

  factory _$AskResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AskResultImplFromJson(json);

  @override
  @JsonKey()
  final String question;
  @override
  @JsonKey()
  final String answer;
  @override
  @JsonKey()
  final String mode;
  final List<Map<String, dynamic>> _context;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get context {
    if (_context is EqualUnmodifiableListView) return _context;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_context);
  }

  @override
  String toString() {
    return 'AskResult(question: $question, answer: $answer, mode: $mode, context: $context)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AskResultImpl &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(other._context, _context));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, question, answer, mode,
      const DeepCollectionEquality().hash(_context));

  /// Create a copy of AskResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AskResultImplCopyWith<_$AskResultImpl> get copyWith =>
      __$$AskResultImplCopyWithImpl<_$AskResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AskResultImplToJson(
      this,
    );
  }
}

abstract class _AskResult implements AskResult {
  const factory _AskResult(
      {final String question,
      final String answer,
      final String mode,
      final List<Map<String, dynamic>> context}) = _$AskResultImpl;

  factory _AskResult.fromJson(Map<String, dynamic> json) =
      _$AskResultImpl.fromJson;

  @override
  String get question;
  @override
  String get answer;
  @override
  String get mode;
  @override
  List<Map<String, dynamic>> get context;

  /// Create a copy of AskResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AskResultImplCopyWith<_$AskResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppStats _$AppStatsFromJson(Map<String, dynamic> json) {
  return _AppStats.fromJson(json);
}

/// @nodoc
mixin _$AppStats {
  int get totalWords => throw _privateConstructorUsedError;
  int get translated => throw _privateConstructorUsedError;
  int get pending => throw _privateConstructorUsedError;
  double get completionPercent => throw _privateConstructorUsedError;

  /// Serializes this AppStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppStatsCopyWith<AppStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppStatsCopyWith<$Res> {
  factory $AppStatsCopyWith(AppStats value, $Res Function(AppStats) then) =
      _$AppStatsCopyWithImpl<$Res, AppStats>;
  @useResult
  $Res call(
      {int totalWords, int translated, int pending, double completionPercent});
}

/// @nodoc
class _$AppStatsCopyWithImpl<$Res, $Val extends AppStats>
    implements $AppStatsCopyWith<$Res> {
  _$AppStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalWords = null,
    Object? translated = null,
    Object? pending = null,
    Object? completionPercent = null,
  }) {
    return _then(_value.copyWith(
      totalWords: null == totalWords
          ? _value.totalWords
          : totalWords // ignore: cast_nullable_to_non_nullable
              as int,
      translated: null == translated
          ? _value.translated
          : translated // ignore: cast_nullable_to_non_nullable
              as int,
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as int,
      completionPercent: null == completionPercent
          ? _value.completionPercent
          : completionPercent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppStatsImplCopyWith<$Res>
    implements $AppStatsCopyWith<$Res> {
  factory _$$AppStatsImplCopyWith(
          _$AppStatsImpl value, $Res Function(_$AppStatsImpl) then) =
      __$$AppStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalWords, int translated, int pending, double completionPercent});
}

/// @nodoc
class __$$AppStatsImplCopyWithImpl<$Res>
    extends _$AppStatsCopyWithImpl<$Res, _$AppStatsImpl>
    implements _$$AppStatsImplCopyWith<$Res> {
  __$$AppStatsImplCopyWithImpl(
      _$AppStatsImpl _value, $Res Function(_$AppStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalWords = null,
    Object? translated = null,
    Object? pending = null,
    Object? completionPercent = null,
  }) {
    return _then(_$AppStatsImpl(
      totalWords: null == totalWords
          ? _value.totalWords
          : totalWords // ignore: cast_nullable_to_non_nullable
              as int,
      translated: null == translated
          ? _value.translated
          : translated // ignore: cast_nullable_to_non_nullable
              as int,
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as int,
      completionPercent: null == completionPercent
          ? _value.completionPercent
          : completionPercent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$AppStatsImpl implements _AppStats {
  const _$AppStatsImpl(
      {this.totalWords = 0,
      this.translated = 0,
      this.pending = 0,
      this.completionPercent = 0.0});

  factory _$AppStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppStatsImplFromJson(json);

  @override
  @JsonKey()
  final int totalWords;
  @override
  @JsonKey()
  final int translated;
  @override
  @JsonKey()
  final int pending;
  @override
  @JsonKey()
  final double completionPercent;

  @override
  String toString() {
    return 'AppStats(totalWords: $totalWords, translated: $translated, pending: $pending, completionPercent: $completionPercent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppStatsImpl &&
            (identical(other.totalWords, totalWords) ||
                other.totalWords == totalWords) &&
            (identical(other.translated, translated) ||
                other.translated == translated) &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.completionPercent, completionPercent) ||
                other.completionPercent == completionPercent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, totalWords, translated, pending, completionPercent);

  /// Create a copy of AppStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppStatsImplCopyWith<_$AppStatsImpl> get copyWith =>
      __$$AppStatsImplCopyWithImpl<_$AppStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppStatsImplToJson(
      this,
    );
  }
}

abstract class _AppStats implements AppStats {
  const factory _AppStats(
      {final int totalWords,
      final int translated,
      final int pending,
      final double completionPercent}) = _$AppStatsImpl;

  factory _AppStats.fromJson(Map<String, dynamic> json) =
      _$AppStatsImpl.fromJson;

  @override
  int get totalWords;
  @override
  int get translated;
  @override
  int get pending;
  @override
  double get completionPercent;

  /// Create a copy of AppStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppStatsImplCopyWith<_$AppStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
