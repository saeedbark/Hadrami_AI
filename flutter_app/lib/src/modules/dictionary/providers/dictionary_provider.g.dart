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
String _$selectedCategoryHash() => r'72d7f8d2d326e469263856b407180753aeeca1ee';

/// See also [SelectedCategory].
@ProviderFor(SelectedCategory)
final selectedCategoryProvider =
    NotifierProvider<SelectedCategory, String?>.internal(
  SelectedCategory.new,
  name: r'selectedCategoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCategoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCategory = Notifier<String?>;
String _$wordListHash() => r'4fc40d80e4680ff911dd5f4a8677417723111c37';

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
