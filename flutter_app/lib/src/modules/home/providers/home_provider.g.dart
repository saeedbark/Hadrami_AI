// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statsHash() => r'37e2386fe3a183c42598dae31bb340756752bf00';

/// See also [stats].
@ProviderFor(stats)
final statsProvider = AutoDisposeFutureProvider<AppStats>.internal(
  stats,
  name: r'statsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$statsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatsRef = AutoDisposeFutureProviderRef<AppStats>;
String _$randomWordHash() => r'282275b57bc33613853abb940796008f6c619fad';

/// See also [randomWord].
@ProviderFor(randomWord)
final randomWordProvider = AutoDisposeFutureProvider<WordEntry?>.internal(
  randomWord,
  name: r'randomWordProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$randomWordHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RandomWordRef = AutoDisposeFutureProviderRef<WordEntry?>;
String _$translateHash() => r'b19247f84b28f30a474ec269e076f0e06a38373e';

/// See also [Translate].
@ProviderFor(Translate)
final translateProvider = NotifierProvider<Translate, TranslateState>.internal(
  Translate.new,
  name: r'translateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$translateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Translate = Notifier<TranslateState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
