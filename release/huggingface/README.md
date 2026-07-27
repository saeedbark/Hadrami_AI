---
language:
- ar
license: cc-by-sa-4.0
multilinguality:
- monolingual
pretty_name: Hadrami Arabic Dialect Dictionary
size_categories:
- 1K<n<10K
source_datasets:
- original
task_categories:
- translation
- text-classification
- token-classification
tags:
- arabic
- dialect
- low-resource
- lexicon
- yemen
- hadrami
- hadhramaut
configs:
- config_name: default
  data_files:
  - split: train
    path: data/train.parquet
---

# Hadrami Arabic Dialect Dictionary

A curated lexicon of **1000 Hadrami Arabic** headwords paired with Modern
Standard Arabic (MSA) equivalents, definitions, examples, proverbs, and
regional + topical tags. Hadrami is the dialect spoken across Hadhramaut,
Yemen and the Hadrami diaspora; very few NLP resources exist for it.

## Loading

```python
from datasets import load_dataset

ds = load_dataset("REPLACE_USERNAME/hadrami-arabic-dialect-dictionary")
print(ds["train"][0])
```

## Schema

| Field | Type | Description |
|---|---|---|
| `id` | int32 | Primary key |
| `word_vocalized` | string | Headword with diacritics (تشكيل) |
| `word_clean` | string | Headword without diacritics |
| `transliteration` | string | Latin-script transliteration (lay-reader). ~10% LLM, rest deterministic. |
| `root` | string \| null | Arabic root; null for compound proper nouns |
| `pos` | string | Part of speech. One of: Noun, Verb, Adjective, Adverb, Pronoun, Interrogative, Particle, Preposition, Expression, Verb Phrase, Noun/Verb (legacy compound for ~14 rows). |
| `semantic_intent` | string | Coarse semantic class: action / object / person / emotion / place / time / descriptor / expression / function. ~10% LLM, rest rule-based. |
| `fusha_equivalent` | string | Modern Standard Arabic gloss |
| `definition` | string | Arabic definition |
| `region` | string | Hadhramaut sub-region (lowercase) |
| `synonyms` | string\* | JSON-encoded list of synonyms |
| `phonetic_variants` | string\* | JSON-encoded list of phonetic variants |
| `note` | string \| null | Lexicographer note (null when none) |
| `source` | string | Citation |
| `examples` | string\* | JSON-encoded list of `{"h": ..., "f": ...}` example pairs |
| `proverbs` | string\* | JSON-encoded list of proverbs |
| `tags` | string\* | JSON-encoded lowercase topic tags |
| `searchable_text` | string | Canonical embedding-doc text used by the project's retriever |

\* List-typed columns are JSON-encoded strings in the Parquet schema for
simple loading. The companion JSONL file (`data/train.jsonl`) preserves
native arrays.

## Suggested uses

- **Hadrami → MSA translation** — train or evaluate dialectal MT models.
  The `examples` field contains parallel sentence pairs.
- **Dialect identification** — pair with other Arabic dialect lexicons
  (MADAR, ADIDA, QADI) as labeled positive examples for "hadrami".
- **Lexicon-grounded retrieval (RAG)** — the companion repository at
  https://github.com/saeedbark/Hadrami_AI uses this lexicon as the
  retrieval store for a refusal-grounded chat agent.

## License

Released under **CC-BY-SA 4.0**. You may share and adapt freely with
attribution; derivative works must use the same license.

## Citation

```bibtex
@misc{hadramirag2026,
  title  = {Hadrami-RAG: A Retrieval-Grounded Conversational System and
            Lexicon for the Hadrami Arabic Dialect},
  author = {Bark, Abdelwedoud},
  year   = {2026},
  url    = {https://github.com/saeedbark/Hadrami_AI}
}
```

## Caveats and known issues

- Regional metadata is partial — most entries are tagged `General`. Three
  entries currently carry topic labels (`Nature`, `Agriculture`) in the
  `region` column; these are flagged for human review in the project's
  cleaning log.
- The dataset reflects review by a small native-speaker team; broader
  inter-annotator agreement is in progress for the accompanying paper.
- Embedding vectors used by the retrieval system are NOT included here —
  the lexicon itself is the redistributable artifact. Re-embed with any
  Arabic-aware model (e.g. `gemini-embedding-001`, `LaBSE`,
  `intfloat/multilingual-e5-base`) using the entry text.

## Companion repositories

- Backend + Flutter app: https://github.com/saeedbark/Hadrami_AI
- Kaggle mirror of this dataset is also published.
