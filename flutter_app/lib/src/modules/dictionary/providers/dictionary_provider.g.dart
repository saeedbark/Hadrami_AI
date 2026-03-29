// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictionary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedLetterHash() => r'cc5444a5e0be0b92e63da47c4c844bd5ad2b473e';

/// See also [SelectedLetter].
@ProviderFor(SelectedLetter)
final selectedLetterProvider =
    NotifierProvider<SelectedLetter, String?>.internal(
  SelectedLetter.new,
  name: r'selectedLetterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedLetterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedLetter = Notifier<String?>;
String _$wordListHash() => r'd0df3075f75b5e7324f0eaf0e01c7de4395e7e20';

/// See also [WordList].
@ProviderFor(WordList)
final wordListProvider =
    AutoDisposeAsyncNotifierProvider<WordList, List<WordEntry>>.internal(
  WordList.new,
  name: r'wordListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$wordListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WordList = AutoDisposeAsyncNotifier<List<WordEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
