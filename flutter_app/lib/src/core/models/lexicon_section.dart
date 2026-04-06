class LexiconSection {
  const LexiconSection({
    required this.letter,
    required this.wordCount,
  });

  final String letter;
  final int wordCount;

  factory LexiconSection.fromJson(Map<String, dynamic> json) {
    return LexiconSection(
      letter: json['letter'] as String? ?? '',
      wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
    );
  }
}
