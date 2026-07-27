# Hadrami Arabic Dialect Dictionary

A curated lexicon of **1000 Hadrami Arabic** headwords with Modern Standard
Arabic equivalents, definitions, regional metadata, examples, and proverbs.
Hadrami is the dialect spoken in Hadhramaut, Yemen and across the Hadrami
diaspora — a low-resource Arabic dialect with very little prior NLP coverage.

## Files

| File | Description |
|---|---|
| `hadrami_dictionary.csv`  | Flat CSV. List-typed columns are JSON-encoded strings. |
| `hadrami_dictionary.json` | Same content as a UTF-8 JSON document with native arrays. |
| `dataset-metadata.json`   | Kaggle dataset descriptor (edit `id` before publishing). |

## Schema

| Column | Type | Description |
|---|---|---|
| `id` | int | Primary key. |
| `word_vocalized` | str | Headword with diacritics (تشكيل). |
| `word_clean` | str | Headword with diacritics stripped. |
| `transliteration` | str | Latin-script transliteration. ~10% from LLM (Gemini), the rest from a deterministic DIN-31635-lite character map. |
| `root` | str \| null | Arabic triliteral root; null for compound proper nouns. |
| `pos` | str | Part of speech. One of: Noun, Verb, Adjective, Adverb, Pronoun, Interrogative, Particle, Preposition, Expression, Verb Phrase, Noun/Verb (legacy compound for ~14 rows). |
| `semantic_intent` | str | Coarse semantic class: action, object, person, emotion, place, time, descriptor, expression, function. ~10% LLM-classified; rest from rule-based mapping over POS + tags. |
| `fusha_equivalent` | str | Modern Standard Arabic gloss. |
| `definition` | str | Arabic definition / explanation. |
| `region` | str | Hadhramaut sub-region (lowercase: coast, wadi, rural, general, …). |
| `synonyms` | list[str] | Alternative Hadrami forms. |
| `phonetic_variants` | list[str] | Pronunciation variants. |
| `note` | str \| null | Lexicographer note (null when no note). |
| `source` | str | Citation for the entry. |
| `examples` | list[{h, f}] | Example sentence pairs (Hadrami / MSA). |
| `proverbs` | list[str] | Proverbs / idiomatic uses. |
| `tags` | list[str] | Lowercase topic tags (daily life, agriculture, nature …). |
| `searchable_text` | str | Canonical embedding-doc text used by the project's vector retriever. Useful if you re-embed with a different model. |

## License

Released under **CC-BY-SA 4.0**. You are free to share and adapt the work
provided you credit the source and distribute derivative work under the same
license.

## Citation

If you use this dataset, please cite:

```bibtex
@misc{hadramirag2026,
  title  = {Hadrami-RAG: A Retrieval-Grounded Conversational System and
            Lexicon for the Hadrami Arabic Dialect},
  author = {Bark, Abdelwedoud},
  year   = {2026},
  url    = {https://github.com/saeedbark/Hadrami_AI}
}
```

## Companion artifacts

- **GitHub:** https://github.com/saeedbark/Hadrami_AI — the FastAPI/RAG backend
  and Flutter mobile client that consume this lexicon.
- **HuggingFace:** the same dataset is also published as a HuggingFace
  Datasets-format release with a Parquet shard.

## Caveats

- Coverage is intentionally curated rather than exhaustive: rare words and
  recent neologisms are excluded.
- Regional metadata is incomplete — most entries are tagged `General`. A
  small number of entries (`Nature`, `Agriculture`) carry topic labels in
  the region column and are flagged for review in our internal cleaning
  log (`results/clean_lexicon.applied.json`).
- The dataset reflects native-speaker review by a small group; broader
  inter-annotator agreement is in progress for the accompanying paper.
