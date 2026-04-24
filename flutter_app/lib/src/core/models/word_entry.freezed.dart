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

ExamplePair _$ExamplePairFromJson(Map<String, dynamic> json) {
  return _ExamplePair.fromJson(json);
}

/// @nodoc
mixin _$ExamplePair {
  String get h => throw _privateConstructorUsedError;
  String get f => throw _privateConstructorUsedError;

  /// Serializes this ExamplePair to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExamplePair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExamplePairCopyWith<ExamplePair> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamplePairCopyWith<$Res> {
  factory $ExamplePairCopyWith(
          ExamplePair value, $Res Function(ExamplePair) then) =
      _$ExamplePairCopyWithImpl<$Res, ExamplePair>;
  @useResult
  $Res call({String h, String f});
}

/// @nodoc
class _$ExamplePairCopyWithImpl<$Res, $Val extends ExamplePair>
    implements $ExamplePairCopyWith<$Res> {
  _$ExamplePairCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExamplePair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? h = null,
    Object? f = null,
  }) {
    return _then(_value.copyWith(
      h: null == h
          ? _value.h
          : h // ignore: cast_nullable_to_non_nullable
              as String,
      f: null == f
          ? _value.f
          : f // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExamplePairImplCopyWith<$Res>
    implements $ExamplePairCopyWith<$Res> {
  factory _$$ExamplePairImplCopyWith(
          _$ExamplePairImpl value, $Res Function(_$ExamplePairImpl) then) =
      __$$ExamplePairImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String h, String f});
}

/// @nodoc
class __$$ExamplePairImplCopyWithImpl<$Res>
    extends _$ExamplePairCopyWithImpl<$Res, _$ExamplePairImpl>
    implements _$$ExamplePairImplCopyWith<$Res> {
  __$$ExamplePairImplCopyWithImpl(
      _$ExamplePairImpl _value, $Res Function(_$ExamplePairImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExamplePair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? h = null,
    Object? f = null,
  }) {
    return _then(_$ExamplePairImpl(
      h: null == h
          ? _value.h
          : h // ignore: cast_nullable_to_non_nullable
              as String,
      f: null == f
          ? _value.f
          : f // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ExamplePairImpl implements _ExamplePair {
  const _$ExamplePairImpl({this.h = '', this.f = ''});

  factory _$ExamplePairImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamplePairImplFromJson(json);

  @override
  @JsonKey()
  final String h;
  @override
  @JsonKey()
  final String f;

  @override
  String toString() {
    return 'ExamplePair(h: $h, f: $f)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamplePairImpl &&
            (identical(other.h, h) || other.h == h) &&
            (identical(other.f, f) || other.f == f));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, h, f);

  /// Create a copy of ExamplePair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamplePairImplCopyWith<_$ExamplePairImpl> get copyWith =>
      __$$ExamplePairImplCopyWithImpl<_$ExamplePairImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamplePairImplToJson(
      this,
    );
  }
}

abstract class _ExamplePair implements ExamplePair {
  const factory _ExamplePair({final String h, final String f}) =
      _$ExamplePairImpl;

  factory _ExamplePair.fromJson(Map<String, dynamic> json) =
      _$ExamplePairImpl.fromJson;

  @override
  String get h;
  @override
  String get f;

  /// Create a copy of ExamplePair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamplePairImplCopyWith<_$ExamplePairImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WordEntry _$WordEntryFromJson(Map<String, dynamic> json) {
  return _WordEntry.fromJson(json);
}

/// @nodoc
mixin _$WordEntry {
  int get id => throw _privateConstructorUsedError;
  String get wordVocalized => throw _privateConstructorUsedError;
  String? get wordClean => throw _privateConstructorUsedError;
  String? get root => throw _privateConstructorUsedError;
  String? get pos => throw _privateConstructorUsedError;
  String? get fushaEquivalent => throw _privateConstructorUsedError;
  String? get definition => throw _privateConstructorUsedError;
  String get region => throw _privateConstructorUsedError;
  List<String>? get synonyms => throw _privateConstructorUsedError;
  List<String>? get phoneticVariants => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  List<ExamplePair>? get examples => throw _privateConstructorUsedError;
  List<String>? get proverbs => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;

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
      {int id,
      String wordVocalized,
      String? wordClean,
      String? root,
      String? pos,
      String? fushaEquivalent,
      String? definition,
      String region,
      List<String>? synonyms,
      List<String>? phoneticVariants,
      String? note,
      String? source,
      List<ExamplePair>? examples,
      List<String>? proverbs,
      List<String>? tags});
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
    Object? wordVocalized = null,
    Object? wordClean = freezed,
    Object? root = freezed,
    Object? pos = freezed,
    Object? fushaEquivalent = freezed,
    Object? definition = freezed,
    Object? region = null,
    Object? synonyms = freezed,
    Object? phoneticVariants = freezed,
    Object? note = freezed,
    Object? source = freezed,
    Object? examples = freezed,
    Object? proverbs = freezed,
    Object? tags = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      wordVocalized: null == wordVocalized
          ? _value.wordVocalized
          : wordVocalized // ignore: cast_nullable_to_non_nullable
              as String,
      wordClean: freezed == wordClean
          ? _value.wordClean
          : wordClean // ignore: cast_nullable_to_non_nullable
              as String?,
      root: freezed == root
          ? _value.root
          : root // ignore: cast_nullable_to_non_nullable
              as String?,
      pos: freezed == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as String?,
      fushaEquivalent: freezed == fushaEquivalent
          ? _value.fushaEquivalent
          : fushaEquivalent // ignore: cast_nullable_to_non_nullable
              as String?,
      definition: freezed == definition
          ? _value.definition
          : definition // ignore: cast_nullable_to_non_nullable
              as String?,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
      synonyms: freezed == synonyms
          ? _value.synonyms
          : synonyms // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      phoneticVariants: freezed == phoneticVariants
          ? _value.phoneticVariants
          : phoneticVariants // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      examples: freezed == examples
          ? _value.examples
          : examples // ignore: cast_nullable_to_non_nullable
              as List<ExamplePair>?,
      proverbs: freezed == proverbs
          ? _value.proverbs
          : proverbs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
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
      {int id,
      String wordVocalized,
      String? wordClean,
      String? root,
      String? pos,
      String? fushaEquivalent,
      String? definition,
      String region,
      List<String>? synonyms,
      List<String>? phoneticVariants,
      String? note,
      String? source,
      List<ExamplePair>? examples,
      List<String>? proverbs,
      List<String>? tags});
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
    Object? wordVocalized = null,
    Object? wordClean = freezed,
    Object? root = freezed,
    Object? pos = freezed,
    Object? fushaEquivalent = freezed,
    Object? definition = freezed,
    Object? region = null,
    Object? synonyms = freezed,
    Object? phoneticVariants = freezed,
    Object? note = freezed,
    Object? source = freezed,
    Object? examples = freezed,
    Object? proverbs = freezed,
    Object? tags = freezed,
  }) {
    return _then(_$WordEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      wordVocalized: null == wordVocalized
          ? _value.wordVocalized
          : wordVocalized // ignore: cast_nullable_to_non_nullable
              as String,
      wordClean: freezed == wordClean
          ? _value.wordClean
          : wordClean // ignore: cast_nullable_to_non_nullable
              as String?,
      root: freezed == root
          ? _value.root
          : root // ignore: cast_nullable_to_non_nullable
              as String?,
      pos: freezed == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as String?,
      fushaEquivalent: freezed == fushaEquivalent
          ? _value.fushaEquivalent
          : fushaEquivalent // ignore: cast_nullable_to_non_nullable
              as String?,
      definition: freezed == definition
          ? _value.definition
          : definition // ignore: cast_nullable_to_non_nullable
              as String?,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
      synonyms: freezed == synonyms
          ? _value._synonyms
          : synonyms // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      phoneticVariants: freezed == phoneticVariants
          ? _value._phoneticVariants
          : phoneticVariants // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      examples: freezed == examples
          ? _value._examples
          : examples // ignore: cast_nullable_to_non_nullable
              as List<ExamplePair>?,
      proverbs: freezed == proverbs
          ? _value._proverbs
          : proverbs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$WordEntryImpl implements _WordEntry {
  const _$WordEntryImpl(
      {this.id = 0,
      this.wordVocalized = '',
      this.wordClean,
      this.root,
      this.pos,
      this.fushaEquivalent,
      this.definition,
      this.region = 'General',
      final List<String>? synonyms,
      final List<String>? phoneticVariants,
      this.note,
      this.source,
      final List<ExamplePair>? examples,
      final List<String>? proverbs,
      final List<String>? tags})
      : _synonyms = synonyms,
        _phoneticVariants = phoneticVariants,
        _examples = examples,
        _proverbs = proverbs,
        _tags = tags;

  factory _$WordEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$WordEntryImplFromJson(json);

  @override
  @JsonKey()
  final int id;
  @override
  @JsonKey()
  final String wordVocalized;
  @override
  final String? wordClean;
  @override
  final String? root;
  @override
  final String? pos;
  @override
  final String? fushaEquivalent;
  @override
  final String? definition;
  @override
  @JsonKey()
  final String region;
  final List<String>? _synonyms;
  @override
  List<String>? get synonyms {
    final value = _synonyms;
    if (value == null) return null;
    if (_synonyms is EqualUnmodifiableListView) return _synonyms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _phoneticVariants;
  @override
  List<String>? get phoneticVariants {
    final value = _phoneticVariants;
    if (value == null) return null;
    if (_phoneticVariants is EqualUnmodifiableListView)
      return _phoneticVariants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? note;
  @override
  final String? source;
  final List<ExamplePair>? _examples;
  @override
  List<ExamplePair>? get examples {
    final value = _examples;
    if (value == null) return null;
    if (_examples is EqualUnmodifiableListView) return _examples;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _proverbs;
  @override
  List<String>? get proverbs {
    final value = _proverbs;
    if (value == null) return null;
    if (_proverbs is EqualUnmodifiableListView) return _proverbs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'WordEntry(id: $id, wordVocalized: $wordVocalized, wordClean: $wordClean, root: $root, pos: $pos, fushaEquivalent: $fushaEquivalent, definition: $definition, region: $region, synonyms: $synonyms, phoneticVariants: $phoneticVariants, note: $note, source: $source, examples: $examples, proverbs: $proverbs, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WordEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.wordVocalized, wordVocalized) ||
                other.wordVocalized == wordVocalized) &&
            (identical(other.wordClean, wordClean) ||
                other.wordClean == wordClean) &&
            (identical(other.root, root) || other.root == root) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.fushaEquivalent, fushaEquivalent) ||
                other.fushaEquivalent == fushaEquivalent) &&
            (identical(other.definition, definition) ||
                other.definition == definition) &&
            (identical(other.region, region) || other.region == region) &&
            const DeepCollectionEquality().equals(other._synonyms, _synonyms) &&
            const DeepCollectionEquality()
                .equals(other._phoneticVariants, _phoneticVariants) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._examples, _examples) &&
            const DeepCollectionEquality().equals(other._proverbs, _proverbs) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      wordVocalized,
      wordClean,
      root,
      pos,
      fushaEquivalent,
      definition,
      region,
      const DeepCollectionEquality().hash(_synonyms),
      const DeepCollectionEquality().hash(_phoneticVariants),
      note,
      source,
      const DeepCollectionEquality().hash(_examples),
      const DeepCollectionEquality().hash(_proverbs),
      const DeepCollectionEquality().hash(_tags));

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
      final String wordVocalized,
      final String? wordClean,
      final String? root,
      final String? pos,
      final String? fushaEquivalent,
      final String? definition,
      final String region,
      final List<String>? synonyms,
      final List<String>? phoneticVariants,
      final String? note,
      final String? source,
      final List<ExamplePair>? examples,
      final List<String>? proverbs,
      final List<String>? tags}) = _$WordEntryImpl;

  factory _WordEntry.fromJson(Map<String, dynamic> json) =
      _$WordEntryImpl.fromJson;

  @override
  int get id;
  @override
  String get wordVocalized;
  @override
  String? get wordClean;
  @override
  String? get root;
  @override
  String? get pos;
  @override
  String? get fushaEquivalent;
  @override
  String? get definition;
  @override
  String get region;
  @override
  List<String>? get synonyms;
  @override
  List<String>? get phoneticVariants;
  @override
  String? get note;
  @override
  String? get source;
  @override
  List<ExamplePair>? get examples;
  @override
  List<String>? get proverbs;
  @override
  List<String>? get tags;

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
  String get wordVocalized => throw _privateConstructorUsedError;
  String get fushaEquivalent => throw _privateConstructorUsedError;
  String get definition => throw _privateConstructorUsedError;
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
      String wordVocalized,
      String fushaEquivalent,
      String definition,
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
    Object? wordVocalized = null,
    Object? fushaEquivalent = null,
    Object? definition = null,
    Object? confidence = null,
  }) {
    return _then(_value.copyWith(
      found: null == found
          ? _value.found
          : found // ignore: cast_nullable_to_non_nullable
              as bool,
      wordVocalized: null == wordVocalized
          ? _value.wordVocalized
          : wordVocalized // ignore: cast_nullable_to_non_nullable
              as String,
      fushaEquivalent: null == fushaEquivalent
          ? _value.fushaEquivalent
          : fushaEquivalent // ignore: cast_nullable_to_non_nullable
              as String,
      definition: null == definition
          ? _value.definition
          : definition // ignore: cast_nullable_to_non_nullable
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
      String wordVocalized,
      String fushaEquivalent,
      String definition,
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
    Object? wordVocalized = null,
    Object? fushaEquivalent = null,
    Object? definition = null,
    Object? confidence = null,
  }) {
    return _then(_$TranslateResultImpl(
      found: null == found
          ? _value.found
          : found // ignore: cast_nullable_to_non_nullable
              as bool,
      wordVocalized: null == wordVocalized
          ? _value.wordVocalized
          : wordVocalized // ignore: cast_nullable_to_non_nullable
              as String,
      fushaEquivalent: null == fushaEquivalent
          ? _value.fushaEquivalent
          : fushaEquivalent // ignore: cast_nullable_to_non_nullable
              as String,
      definition: null == definition
          ? _value.definition
          : definition // ignore: cast_nullable_to_non_nullable
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
      this.wordVocalized = '',
      this.fushaEquivalent = '',
      this.definition = '',
      this.confidence = 'not_found'});

  factory _$TranslateResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranslateResultImplFromJson(json);

  @override
  @JsonKey()
  final bool found;
  @override
  @JsonKey()
  final String wordVocalized;
  @override
  @JsonKey()
  final String fushaEquivalent;
  @override
  @JsonKey()
  final String definition;
  @override
  @JsonKey()
  final String confidence;

  @override
  String toString() {
    return 'TranslateResult(found: $found, wordVocalized: $wordVocalized, fushaEquivalent: $fushaEquivalent, definition: $definition, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranslateResultImpl &&
            (identical(other.found, found) || other.found == found) &&
            (identical(other.wordVocalized, wordVocalized) ||
                other.wordVocalized == wordVocalized) &&
            (identical(other.fushaEquivalent, fushaEquivalent) ||
                other.fushaEquivalent == fushaEquivalent) &&
            (identical(other.definition, definition) ||
                other.definition == definition) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, found, wordVocalized,
      fushaEquivalent, definition, confidence);

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
      final String wordVocalized,
      final String fushaEquivalent,
      final String definition,
      final String confidence}) = _$TranslateResultImpl;

  factory _TranslateResult.fromJson(Map<String, dynamic> json) =
      _$TranslateResultImpl.fromJson;

  @override
  bool get found;
  @override
  String get wordVocalized;
  @override
  String get fushaEquivalent;
  @override
  String get definition;
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
  List<HadramiSpan> get hadramiSpans => throw _privateConstructorUsedError;
  List<String> get highlightSurfaces => throw _privateConstructorUsedError;
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
      List<HadramiSpan> hadramiSpans,
      List<String> highlightSurfaces,
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
    Object? hadramiSpans = null,
    Object? highlightSurfaces = null,
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
      hadramiSpans: null == hadramiSpans
          ? _value.hadramiSpans
          : hadramiSpans // ignore: cast_nullable_to_non_nullable
              as List<HadramiSpan>,
      highlightSurfaces: null == highlightSurfaces
          ? _value.highlightSurfaces
          : highlightSurfaces // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      List<HadramiSpan> hadramiSpans,
      List<String> highlightSurfaces,
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
    Object? hadramiSpans = null,
    Object? highlightSurfaces = null,
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
      hadramiSpans: null == hadramiSpans
          ? _value._hadramiSpans
          : hadramiSpans // ignore: cast_nullable_to_non_nullable
              as List<HadramiSpan>,
      highlightSurfaces: null == highlightSurfaces
          ? _value._highlightSurfaces
          : highlightSurfaces // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      final List<HadramiSpan> hadramiSpans = const <HadramiSpan>[],
      final List<String> highlightSurfaces = const <String>[],
      final List<Map<String, dynamic>> context =
          const <Map<String, dynamic>>[]})
      : _hadramiSpans = hadramiSpans,
        _highlightSurfaces = highlightSurfaces,
        _context = context;

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
  final List<HadramiSpan> _hadramiSpans;
  @override
  @JsonKey()
  List<HadramiSpan> get hadramiSpans {
    if (_hadramiSpans is EqualUnmodifiableListView) return _hadramiSpans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hadramiSpans);
  }

  final List<String> _highlightSurfaces;
  @override
  @JsonKey()
  List<String> get highlightSurfaces {
    if (_highlightSurfaces is EqualUnmodifiableListView)
      return _highlightSurfaces;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_highlightSurfaces);
  }

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
    return 'AskResult(question: $question, answer: $answer, mode: $mode, hadramiSpans: $hadramiSpans, highlightSurfaces: $highlightSurfaces, context: $context)';
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
            const DeepCollectionEquality()
                .equals(other._hadramiSpans, _hadramiSpans) &&
            const DeepCollectionEquality()
                .equals(other._highlightSurfaces, _highlightSurfaces) &&
            const DeepCollectionEquality().equals(other._context, _context));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      question,
      answer,
      mode,
      const DeepCollectionEquality().hash(_hadramiSpans),
      const DeepCollectionEquality().hash(_highlightSurfaces),
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
      final List<HadramiSpan> hadramiSpans,
      final List<String> highlightSurfaces,
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
  List<HadramiSpan> get hadramiSpans;
  @override
  List<String> get highlightSurfaces;
  @override
  List<Map<String, dynamic>> get context;

  /// Create a copy of AskResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AskResultImplCopyWith<_$AskResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HadramiSpan _$HadramiSpanFromJson(Map<String, dynamic> json) {
  return _HadramiSpan.fromJson(json);
}

/// @nodoc
mixin _$HadramiSpan {
  int get start => throw _privateConstructorUsedError;
  int get end => throw _privateConstructorUsedError;
  String get surface => throw _privateConstructorUsedError;

  /// Serializes this HadramiSpan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HadramiSpan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HadramiSpanCopyWith<HadramiSpan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HadramiSpanCopyWith<$Res> {
  factory $HadramiSpanCopyWith(
          HadramiSpan value, $Res Function(HadramiSpan) then) =
      _$HadramiSpanCopyWithImpl<$Res, HadramiSpan>;
  @useResult
  $Res call({int start, int end, String surface});
}

/// @nodoc
class _$HadramiSpanCopyWithImpl<$Res, $Val extends HadramiSpan>
    implements $HadramiSpanCopyWith<$Res> {
  _$HadramiSpanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HadramiSpan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? surface = null,
  }) {
    return _then(_value.copyWith(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as int,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as int,
      surface: null == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HadramiSpanImplCopyWith<$Res>
    implements $HadramiSpanCopyWith<$Res> {
  factory _$$HadramiSpanImplCopyWith(
          _$HadramiSpanImpl value, $Res Function(_$HadramiSpanImpl) then) =
      __$$HadramiSpanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int start, int end, String surface});
}

/// @nodoc
class __$$HadramiSpanImplCopyWithImpl<$Res>
    extends _$HadramiSpanCopyWithImpl<$Res, _$HadramiSpanImpl>
    implements _$$HadramiSpanImplCopyWith<$Res> {
  __$$HadramiSpanImplCopyWithImpl(
      _$HadramiSpanImpl _value, $Res Function(_$HadramiSpanImpl) _then)
      : super(_value, _then);

  /// Create a copy of HadramiSpan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? surface = null,
  }) {
    return _then(_$HadramiSpanImpl(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as int,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as int,
      surface: null == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$HadramiSpanImpl implements _HadramiSpan {
  const _$HadramiSpanImpl({this.start = 0, this.end = 0, this.surface = ''});

  factory _$HadramiSpanImpl.fromJson(Map<String, dynamic> json) =>
      _$$HadramiSpanImplFromJson(json);

  @override
  @JsonKey()
  final int start;
  @override
  @JsonKey()
  final int end;
  @override
  @JsonKey()
  final String surface;

  @override
  String toString() {
    return 'HadramiSpan(start: $start, end: $end, surface: $surface)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HadramiSpanImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.surface, surface) || other.surface == surface));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, start, end, surface);

  /// Create a copy of HadramiSpan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HadramiSpanImplCopyWith<_$HadramiSpanImpl> get copyWith =>
      __$$HadramiSpanImplCopyWithImpl<_$HadramiSpanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HadramiSpanImplToJson(
      this,
    );
  }
}

abstract class _HadramiSpan implements HadramiSpan {
  const factory _HadramiSpan(
      {final int start,
      final int end,
      final String surface}) = _$HadramiSpanImpl;

  factory _HadramiSpan.fromJson(Map<String, dynamic> json) =
      _$HadramiSpanImpl.fromJson;

  @override
  int get start;
  @override
  int get end;
  @override
  String get surface;

  /// Create a copy of HadramiSpan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HadramiSpanImplCopyWith<_$HadramiSpanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PhraseTranslateResult _$PhraseTranslateResultFromJson(
    Map<String, dynamic> json) {
  return _PhraseTranslateResult.fromJson(json);
}

/// @nodoc
mixin _$PhraseTranslateResult {
  String get inputText => throw _privateConstructorUsedError;
  String get direction => throw _privateConstructorUsedError;
  String get translatedText => throw _privateConstructorUsedError;
  List<HadramiSpan> get hadramiSpans => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  String get ragMode => throw _privateConstructorUsedError;
  List<WordEntry> get context => throw _privateConstructorUsedError;

  /// Serializes this PhraseTranslateResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PhraseTranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PhraseTranslateResultCopyWith<PhraseTranslateResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhraseTranslateResultCopyWith<$Res> {
  factory $PhraseTranslateResultCopyWith(PhraseTranslateResult value,
          $Res Function(PhraseTranslateResult) then) =
      _$PhraseTranslateResultCopyWithImpl<$Res, PhraseTranslateResult>;
  @useResult
  $Res call(
      {String inputText,
      String direction,
      String translatedText,
      List<HadramiSpan> hadramiSpans,
      String mode,
      String ragMode,
      List<WordEntry> context});
}

/// @nodoc
class _$PhraseTranslateResultCopyWithImpl<$Res,
        $Val extends PhraseTranslateResult>
    implements $PhraseTranslateResultCopyWith<$Res> {
  _$PhraseTranslateResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PhraseTranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inputText = null,
    Object? direction = null,
    Object? translatedText = null,
    Object? hadramiSpans = null,
    Object? mode = null,
    Object? ragMode = null,
    Object? context = null,
  }) {
    return _then(_value.copyWith(
      inputText: null == inputText
          ? _value.inputText
          : inputText // ignore: cast_nullable_to_non_nullable
              as String,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: null == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String,
      hadramiSpans: null == hadramiSpans
          ? _value.hadramiSpans
          : hadramiSpans // ignore: cast_nullable_to_non_nullable
              as List<HadramiSpan>,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      ragMode: null == ragMode
          ? _value.ragMode
          : ragMode // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as List<WordEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PhraseTranslateResultImplCopyWith<$Res>
    implements $PhraseTranslateResultCopyWith<$Res> {
  factory _$$PhraseTranslateResultImplCopyWith(
          _$PhraseTranslateResultImpl value,
          $Res Function(_$PhraseTranslateResultImpl) then) =
      __$$PhraseTranslateResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String inputText,
      String direction,
      String translatedText,
      List<HadramiSpan> hadramiSpans,
      String mode,
      String ragMode,
      List<WordEntry> context});
}

/// @nodoc
class __$$PhraseTranslateResultImplCopyWithImpl<$Res>
    extends _$PhraseTranslateResultCopyWithImpl<$Res,
        _$PhraseTranslateResultImpl>
    implements _$$PhraseTranslateResultImplCopyWith<$Res> {
  __$$PhraseTranslateResultImplCopyWithImpl(_$PhraseTranslateResultImpl _value,
      $Res Function(_$PhraseTranslateResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of PhraseTranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inputText = null,
    Object? direction = null,
    Object? translatedText = null,
    Object? hadramiSpans = null,
    Object? mode = null,
    Object? ragMode = null,
    Object? context = null,
  }) {
    return _then(_$PhraseTranslateResultImpl(
      inputText: null == inputText
          ? _value.inputText
          : inputText // ignore: cast_nullable_to_non_nullable
              as String,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: null == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String,
      hadramiSpans: null == hadramiSpans
          ? _value._hadramiSpans
          : hadramiSpans // ignore: cast_nullable_to_non_nullable
              as List<HadramiSpan>,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      ragMode: null == ragMode
          ? _value.ragMode
          : ragMode // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value._context
          : context // ignore: cast_nullable_to_non_nullable
              as List<WordEntry>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$PhraseTranslateResultImpl implements _PhraseTranslateResult {
  const _$PhraseTranslateResultImpl(
      {this.inputText = '',
      this.direction = '',
      this.translatedText = '',
      final List<HadramiSpan> hadramiSpans = const <HadramiSpan>[],
      this.mode = 'error',
      this.ragMode = '',
      final List<WordEntry> context = const <WordEntry>[]})
      : _hadramiSpans = hadramiSpans,
        _context = context;

  factory _$PhraseTranslateResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PhraseTranslateResultImplFromJson(json);

  @override
  @JsonKey()
  final String inputText;
  @override
  @JsonKey()
  final String direction;
  @override
  @JsonKey()
  final String translatedText;
  final List<HadramiSpan> _hadramiSpans;
  @override
  @JsonKey()
  List<HadramiSpan> get hadramiSpans {
    if (_hadramiSpans is EqualUnmodifiableListView) return _hadramiSpans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hadramiSpans);
  }

  @override
  @JsonKey()
  final String mode;
  @override
  @JsonKey()
  final String ragMode;
  final List<WordEntry> _context;
  @override
  @JsonKey()
  List<WordEntry> get context {
    if (_context is EqualUnmodifiableListView) return _context;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_context);
  }

  @override
  String toString() {
    return 'PhraseTranslateResult(inputText: $inputText, direction: $direction, translatedText: $translatedText, hadramiSpans: $hadramiSpans, mode: $mode, ragMode: $ragMode, context: $context)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhraseTranslateResultImpl &&
            (identical(other.inputText, inputText) ||
                other.inputText == inputText) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.translatedText, translatedText) ||
                other.translatedText == translatedText) &&
            const DeepCollectionEquality()
                .equals(other._hadramiSpans, _hadramiSpans) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.ragMode, ragMode) || other.ragMode == ragMode) &&
            const DeepCollectionEquality().equals(other._context, _context));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      inputText,
      direction,
      translatedText,
      const DeepCollectionEquality().hash(_hadramiSpans),
      mode,
      ragMode,
      const DeepCollectionEquality().hash(_context));

  /// Create a copy of PhraseTranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PhraseTranslateResultImplCopyWith<_$PhraseTranslateResultImpl>
      get copyWith => __$$PhraseTranslateResultImplCopyWithImpl<
          _$PhraseTranslateResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PhraseTranslateResultImplToJson(
      this,
    );
  }
}

abstract class _PhraseTranslateResult implements PhraseTranslateResult {
  const factory _PhraseTranslateResult(
      {final String inputText,
      final String direction,
      final String translatedText,
      final List<HadramiSpan> hadramiSpans,
      final String mode,
      final String ragMode,
      final List<WordEntry> context}) = _$PhraseTranslateResultImpl;

  factory _PhraseTranslateResult.fromJson(Map<String, dynamic> json) =
      _$PhraseTranslateResultImpl.fromJson;

  @override
  String get inputText;
  @override
  String get direction;
  @override
  String get translatedText;
  @override
  List<HadramiSpan> get hadramiSpans;
  @override
  String get mode;
  @override
  String get ragMode;
  @override
  List<WordEntry> get context;

  /// Create a copy of PhraseTranslateResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PhraseTranslateResultImplCopyWith<_$PhraseTranslateResultImpl>
      get copyWith => throw _privateConstructorUsedError;
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
  Map<String, int> get byPos => throw _privateConstructorUsedError;
  Map<String, int> get byTag => throw _privateConstructorUsedError;
  int get totalProverbs => throw _privateConstructorUsedError;

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
      {int totalWords,
      int translated,
      int pending,
      double completionPercent,
      Map<String, int> byPos,
      Map<String, int> byTag,
      int totalProverbs});
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
    Object? byPos = null,
    Object? byTag = null,
    Object? totalProverbs = null,
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
      byPos: null == byPos
          ? _value.byPos
          : byPos // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      byTag: null == byTag
          ? _value.byTag
          : byTag // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      totalProverbs: null == totalProverbs
          ? _value.totalProverbs
          : totalProverbs // ignore: cast_nullable_to_non_nullable
              as int,
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
      {int totalWords,
      int translated,
      int pending,
      double completionPercent,
      Map<String, int> byPos,
      Map<String, int> byTag,
      int totalProverbs});
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
    Object? byPos = null,
    Object? byTag = null,
    Object? totalProverbs = null,
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
      byPos: null == byPos
          ? _value._byPos
          : byPos // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      byTag: null == byTag
          ? _value._byTag
          : byTag // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      totalProverbs: null == totalProverbs
          ? _value.totalProverbs
          : totalProverbs // ignore: cast_nullable_to_non_nullable
              as int,
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
      this.completionPercent = 0.0,
      final Map<String, int> byPos = const <String, int>{},
      final Map<String, int> byTag = const <String, int>{},
      this.totalProverbs = 0})
      : _byPos = byPos,
        _byTag = byTag;

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
  final Map<String, int> _byPos;
  @override
  @JsonKey()
  Map<String, int> get byPos {
    if (_byPos is EqualUnmodifiableMapView) return _byPos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_byPos);
  }

  final Map<String, int> _byTag;
  @override
  @JsonKey()
  Map<String, int> get byTag {
    if (_byTag is EqualUnmodifiableMapView) return _byTag;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_byTag);
  }

  @override
  @JsonKey()
  final int totalProverbs;

  @override
  String toString() {
    return 'AppStats(totalWords: $totalWords, translated: $translated, pending: $pending, completionPercent: $completionPercent, byPos: $byPos, byTag: $byTag, totalProverbs: $totalProverbs)';
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
                other.completionPercent == completionPercent) &&
            const DeepCollectionEquality().equals(other._byPos, _byPos) &&
            const DeepCollectionEquality().equals(other._byTag, _byTag) &&
            (identical(other.totalProverbs, totalProverbs) ||
                other.totalProverbs == totalProverbs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalWords,
      translated,
      pending,
      completionPercent,
      const DeepCollectionEquality().hash(_byPos),
      const DeepCollectionEquality().hash(_byTag),
      totalProverbs);

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
      final double completionPercent,
      final Map<String, int> byPos,
      final Map<String, int> byTag,
      final int totalProverbs}) = _$AppStatsImpl;

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
  @override
  Map<String, int> get byPos;
  @override
  Map<String, int> get byTag;
  @override
  int get totalProverbs;

  /// Create a copy of AppStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppStatsImplCopyWith<_$AppStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatResult _$ChatResultFromJson(Map<String, dynamic> json) {
  return _ChatResult.fromJson(json);
}

/// @nodoc
mixin _$ChatResult {
  String get reply => throw _privateConstructorUsedError;
  List<WordEntry> get context => throw _privateConstructorUsedError;
  List<HadramiSpan> get hadramiSpans => throw _privateConstructorUsedError;
  List<String> get highlightSurfaces => throw _privateConstructorUsedError;

  /// Serializes this ChatResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatResultCopyWith<ChatResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatResultCopyWith<$Res> {
  factory $ChatResultCopyWith(
          ChatResult value, $Res Function(ChatResult) then) =
      _$ChatResultCopyWithImpl<$Res, ChatResult>;
  @useResult
  $Res call(
      {String reply,
      List<WordEntry> context,
      List<HadramiSpan> hadramiSpans,
      List<String> highlightSurfaces});
}

/// @nodoc
class _$ChatResultCopyWithImpl<$Res, $Val extends ChatResult>
    implements $ChatResultCopyWith<$Res> {
  _$ChatResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reply = null,
    Object? context = null,
    Object? hadramiSpans = null,
    Object? highlightSurfaces = null,
  }) {
    return _then(_value.copyWith(
      reply: null == reply
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as List<WordEntry>,
      hadramiSpans: null == hadramiSpans
          ? _value.hadramiSpans
          : hadramiSpans // ignore: cast_nullable_to_non_nullable
              as List<HadramiSpan>,
      highlightSurfaces: null == highlightSurfaces
          ? _value.highlightSurfaces
          : highlightSurfaces // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatResultImplCopyWith<$Res>
    implements $ChatResultCopyWith<$Res> {
  factory _$$ChatResultImplCopyWith(
          _$ChatResultImpl value, $Res Function(_$ChatResultImpl) then) =
      __$$ChatResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String reply,
      List<WordEntry> context,
      List<HadramiSpan> hadramiSpans,
      List<String> highlightSurfaces});
}

/// @nodoc
class __$$ChatResultImplCopyWithImpl<$Res>
    extends _$ChatResultCopyWithImpl<$Res, _$ChatResultImpl>
    implements _$$ChatResultImplCopyWith<$Res> {
  __$$ChatResultImplCopyWithImpl(
      _$ChatResultImpl _value, $Res Function(_$ChatResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reply = null,
    Object? context = null,
    Object? hadramiSpans = null,
    Object? highlightSurfaces = null,
  }) {
    return _then(_$ChatResultImpl(
      reply: null == reply
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value._context
          : context // ignore: cast_nullable_to_non_nullable
              as List<WordEntry>,
      hadramiSpans: null == hadramiSpans
          ? _value._hadramiSpans
          : hadramiSpans // ignore: cast_nullable_to_non_nullable
              as List<HadramiSpan>,
      highlightSurfaces: null == highlightSurfaces
          ? _value._highlightSurfaces
          : highlightSurfaces // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ChatResultImpl implements _ChatResult {
  const _$ChatResultImpl(
      {this.reply = '',
      final List<WordEntry> context = const <WordEntry>[],
      final List<HadramiSpan> hadramiSpans = const <HadramiSpan>[],
      final List<String> highlightSurfaces = const <String>[]})
      : _context = context,
        _hadramiSpans = hadramiSpans,
        _highlightSurfaces = highlightSurfaces;

  factory _$ChatResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatResultImplFromJson(json);

  @override
  @JsonKey()
  final String reply;
  final List<WordEntry> _context;
  @override
  @JsonKey()
  List<WordEntry> get context {
    if (_context is EqualUnmodifiableListView) return _context;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_context);
  }

  final List<HadramiSpan> _hadramiSpans;
  @override
  @JsonKey()
  List<HadramiSpan> get hadramiSpans {
    if (_hadramiSpans is EqualUnmodifiableListView) return _hadramiSpans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hadramiSpans);
  }

  final List<String> _highlightSurfaces;
  @override
  @JsonKey()
  List<String> get highlightSurfaces {
    if (_highlightSurfaces is EqualUnmodifiableListView)
      return _highlightSurfaces;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_highlightSurfaces);
  }

  @override
  String toString() {
    return 'ChatResult(reply: $reply, context: $context, hadramiSpans: $hadramiSpans, highlightSurfaces: $highlightSurfaces)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatResultImpl &&
            (identical(other.reply, reply) || other.reply == reply) &&
            const DeepCollectionEquality().equals(other._context, _context) &&
            const DeepCollectionEquality()
                .equals(other._hadramiSpans, _hadramiSpans) &&
            const DeepCollectionEquality()
                .equals(other._highlightSurfaces, _highlightSurfaces));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      reply,
      const DeepCollectionEquality().hash(_context),
      const DeepCollectionEquality().hash(_hadramiSpans),
      const DeepCollectionEquality().hash(_highlightSurfaces));

  /// Create a copy of ChatResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatResultImplCopyWith<_$ChatResultImpl> get copyWith =>
      __$$ChatResultImplCopyWithImpl<_$ChatResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatResultImplToJson(
      this,
    );
  }
}

abstract class _ChatResult implements ChatResult {
  const factory _ChatResult(
      {final String reply,
      final List<WordEntry> context,
      final List<HadramiSpan> hadramiSpans,
      final List<String> highlightSurfaces}) = _$ChatResultImpl;

  factory _ChatResult.fromJson(Map<String, dynamic> json) =
      _$ChatResultImpl.fromJson;

  @override
  String get reply;
  @override
  List<WordEntry> get context;
  @override
  List<HadramiSpan> get hadramiSpans;
  @override
  List<String> get highlightSurfaces;

  /// Create a copy of ChatResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatResultImplCopyWith<_$ChatResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
