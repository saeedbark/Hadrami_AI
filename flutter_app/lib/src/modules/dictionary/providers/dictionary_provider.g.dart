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
String _$selectedPosHash() => r'95cdc6ed1724964572103807e8e9f254fb23a31b';

/// See also [SelectedPos].
@ProviderFor(SelectedPos)
final selectedPosProvider = NotifierProvider<SelectedPos, String?>.internal(
  SelectedPos.new,
  name: r'selectedPosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedPosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedPos = Notifier<String?>;
String _$selectedTagHash() => r'6bf84e16782e9f0060c5b211f48f15ebffff9317';

/// See also [SelectedTag].
@ProviderFor(SelectedTag)
final selectedTagProvider = NotifierProvider<SelectedTag, String?>.internal(
  SelectedTag.new,
  name: r'selectedTagProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedTagHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedTag = Notifier<String?>;
String _$wordListHash() => r'345c6e495802643ab8b214c0128fa5bfeb351b50';

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
