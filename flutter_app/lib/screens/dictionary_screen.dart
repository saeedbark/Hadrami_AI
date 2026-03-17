import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../widgets/word_card.dart';
import '../widgets/drawer_trigger.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _scrollController = ScrollController();
  String? _selectedLetter;

  static const List<String> _arabicLetters = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز',
    'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك',
    'ل', 'م', 'ن', 'ه', 'و', 'ي'
  ];

  @override
  void initState() {
    super.initState();
    context.read<AppProvider>().loadWords();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<AppProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _filterByLetter(String? letter) {
    setState(() => _selectedLetter = letter);
    context.read<AppProvider>().loadWords(letter: letter);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: DrawerTrigger.of(context),
        ),
        title: const Text('القاموس الكامل'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _LetterFilter(
            letters: _arabicLetters,
            selected: _selectedLetter,
            onSelect: _filterByLetter,
          ),
        ),
      ),
      body: Column(
        children: [
          // Count bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${provider.wordListTotal} كلمة',
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.bold),
                ),
                if (_selectedLetter != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('حرف $_selectedLetter'),
                    onDeleted: () => _filterByLetter(null),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ],
            ),
          ),

          // Word list
          Expanded(
            child: provider.isLoading && provider.wordList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.wordList.isEmpty
                    ? Center(
                        child: Text('لا توجد كلمات',
                            style: TextStyle(color: cs.outline)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: provider.wordList.length + 1,
                        itemBuilder: (_, i) {
                          if (i == provider.wordList.length) {
                            if (provider.wordList.length <
                                provider.wordListTotal) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return WordCard(entry: provider.wordList[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _LetterFilter extends StatelessWidget {
  final List<String> letters;
  final String? selected;
  final Function(String?) onSelect;

  const _LetterFilter({
    required this.letters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: letters.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            final isAll = selected == null;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: FilterChip(
                label: const Text('الكل'),
                selected: isAll,
                onSelected: (_) => onSelect(null),
                backgroundColor: isAll ? cs.primary : null,
                labelStyle: TextStyle(
                    color: isAll ? Colors.white : null, fontSize: 12),
              ),
            );
          }
          final letter = letters[i - 1];
          final isSelected = selected == letter;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              label: Text(letter),
              selected: isSelected,
              onSelected: (_) => onSelect(isSelected ? null : letter),
              backgroundColor: isSelected ? cs.primary : null,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null, fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}
