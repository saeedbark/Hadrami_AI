#!/usr/bin/env python3
"""Build the HuggingFace Datasets release bundle.

Outputs to ``release/huggingface/``:
  * ``data/train.jsonl`` — line-delimited JSON with native arrays.
  * ``data/train.parquet`` — same content in Apache Parquet (loaded by `datasets`).
  * ``README.md`` — dataset card with YAML frontmatter
    (HuggingFace renders this on the dataset page).
  * ``dataset_infos.json`` — light-weight schema descriptor.

Publish with::

    huggingface-cli login
    huggingface-cli upload hadrami-arabic-dialect-dictionary release/huggingface . \\
        --repo-type=dataset
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts" / "export"))

from _pull import pull_all_entries  # noqa: E402

OUT_DIR = REPO_ROOT / "release" / "huggingface"
OUT_DATA = OUT_DIR / "data"
OUT_DATA.mkdir(parents=True, exist_ok=True)


EXCLUDE_COLUMNS: set[str] = set()  # nothing excluded — both columns are now backfilled


def _strip_excluded(entry: dict[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in entry.items() if k not in EXCLUDE_COLUMNS}


def write_jsonl(entries: list[dict[str, Any]], path: Path) -> None:
    with open(path, "w", encoding="utf-8") as f:
        for e in entries:
            f.write(json.dumps(_strip_excluded(e), ensure_ascii=False))
            f.write("\n")


def write_parquet(entries: list[dict[str, Any]], path: Path) -> bool:
    """Best-effort Parquet writer using ``pyarrow`` if installed."""
    try:
        import pyarrow as pa
        import pyarrow.parquet as pq
    except ImportError:
        print("  (pyarrow not installed — skipping Parquet; JSONL still works for HF)")
        return False

    # Coerce list-typed columns to JSON strings so Parquet schema stays simple.
    list_cols = {"synonyms", "phonetic_variants", "examples", "proverbs", "tags"}
    entries = [_strip_excluded(e) for e in entries]
    flat: list[dict[str, Any]] = []
    for e in entries:
        row = {}
        for k, v in e.items():
            if k in list_cols and not isinstance(v, str):
                row[k] = json.dumps(v or [], ensure_ascii=False)
            else:
                row[k] = v
        flat.append(row)
    table = pa.Table.from_pylist(flat)
    pq.write_table(table, path)
    return True


def write_readme(n: int, path: Path) -> None:
    body = f"""---
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

A curated lexicon of **{n} Hadrami Arabic** headwords paired with Modern
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
| `root` | string \\| null | Arabic root; null for compound proper nouns |
| `pos` | string | Part of speech. One of: Noun, Verb, Adjective, Adverb, Pronoun, Interrogative, Particle, Preposition, Expression, Verb Phrase, Noun/Verb (legacy compound for ~14 rows). |
| `semantic_intent` | string | Coarse semantic class: action / object / person / emotion / place / time / descriptor / expression / function. ~10% LLM, rest rule-based. |
| `fusha_equivalent` | string | Modern Standard Arabic gloss |
| `definition` | string | Arabic definition |
| `region` | string | Hadhramaut sub-region (lowercase) |
| `synonyms` | string\\* | JSON-encoded list of synonyms |
| `phonetic_variants` | string\\* | JSON-encoded list of phonetic variants |
| `note` | string \\| null | Lexicographer note (null when none) |
| `source` | string | Citation |
| `examples` | string\\* | JSON-encoded list of `{{"h": ..., "f": ...}}` example pairs |
| `proverbs` | string\\* | JSON-encoded list of proverbs |
| `tags` | string\\* | JSON-encoded lowercase topic tags |
| `searchable_text` | string | Canonical embedding-doc text used by the project's retriever |

\\* List-typed columns are JSON-encoded strings in the Parquet schema for
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
@misc{{hadramirag2026,
  title  = {{Hadrami-RAG: A Retrieval-Grounded Conversational System and
            Lexicon for the Hadrami Arabic Dialect}},
  author = {{Bark, Abdelwedoud}},
  year   = {{2026}},
  url    = {{https://github.com/saeedbark/Hadrami_AI}}
}}
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
"""
    path.write_text(body, encoding="utf-8")


def write_dataset_infos(n: int, path: Path) -> None:
    info = {
        "default": {
            "description": "Curated Hadrami Arabic dialect lexicon.",
            "license": "cc-by-sa-4.0",
            "features": {
                "id": {"dtype": "int32", "_type": "Value"},
                "word_vocalized": {"dtype": "string", "_type": "Value"},
                "word_clean": {"dtype": "string", "_type": "Value"},
                "transliteration": {"dtype": "string", "_type": "Value"},
                "root": {"dtype": "string", "_type": "Value"},
                "pos": {"dtype": "string", "_type": "Value"},
                "semantic_intent": {"dtype": "string", "_type": "Value"},
                "fusha_equivalent": {"dtype": "string", "_type": "Value"},
                "definition": {"dtype": "string", "_type": "Value"},
                "region": {"dtype": "string", "_type": "Value"},
                "synonyms": {"dtype": "string", "_type": "Value"},
                "phonetic_variants": {"dtype": "string", "_type": "Value"},
                "note": {"dtype": "string", "_type": "Value"},
                "source": {"dtype": "string", "_type": "Value"},
                "examples": {"dtype": "string", "_type": "Value"},
                "proverbs": {"dtype": "string", "_type": "Value"},
                "tags": {"dtype": "string", "_type": "Value"},
                "searchable_text": {"dtype": "string", "_type": "Value"},
            },
            "splits": {"train": {"name": "train", "num_examples": n}},
        }
    }
    path.write_text(json.dumps(info, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    print("Pulling entries from Supabase…", flush=True)
    entries = pull_all_entries()
    n = len(entries)
    print(f"  {n} rows fetched.")

    jsonl_path = OUT_DATA / "train.jsonl"
    parquet_path = OUT_DATA / "train.parquet"
    write_jsonl(entries, jsonl_path)
    has_parquet = write_parquet(entries, parquet_path)
    write_dataset_infos(n, OUT_DIR / "dataset_infos.json")
    write_readme(n, OUT_DIR / "README.md")

    print(f"\nHuggingFace bundle written to {OUT_DIR}/")
    for p in sorted(OUT_DIR.rglob("*")):
        if p.is_file():
            print(f"  {p.relative_to(OUT_DIR)}  ({p.stat().st_size:,} bytes)")
    if not has_parquet:
        print(
            "\nNOTE: Parquet skipped — install pyarrow for the canonical "
            "HF Datasets format:\n"
            "    backend/venv/bin/pip install pyarrow"
        )


if __name__ == "__main__":
    main()
