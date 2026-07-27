#!/usr/bin/env python3
"""Build the Kaggle release bundle.

Outputs to ``release/kaggle/``:
  * ``hadrami_dictionary.csv`` — flat CSV with JSON-stringified list columns.
  * ``hadrami_dictionary.json`` — same content, UTF-8 JSON list.
  * ``dataset-metadata.json`` — Kaggle dataset metadata template.
  * ``README.md`` — human-readable dataset card.

Submit with::

    cd release/kaggle
    kaggle datasets create -p .                     # first time
    kaggle datasets version -p . -m "v1.0 release"  # subsequent versions
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts" / "export"))

from _pull import pull_all_entries  # noqa: E402

OUT_DIR = REPO_ROOT / "release" / "kaggle"
OUT_DIR.mkdir(parents=True, exist_ok=True)

CSV_COLS = [
    "id",
    "word_vocalized",
    "word_clean",
    "transliteration",
    "root",
    "pos",
    "semantic_intent",
    "fusha_equivalent",
    "definition",
    "region",
    "synonyms",
    "phonetic_variants",
    "note",
    "source",
    "examples",
    "proverbs",
    "tags",
    "searchable_text",
]
EXCLUDE_COLUMNS: set[str] = set()  # nothing excluded — both columns now backfilled


def _json_cell(v: Any) -> str:
    if v is None:
        return "[]"
    return json.dumps(v, ensure_ascii=False)


def _row(entry: dict[str, Any]) -> dict[str, str]:
    out: dict[str, str] = {}
    for col in CSV_COLS:
        v = entry.get(col)
        if isinstance(v, list):
            out[col] = _json_cell(v)
        else:
            out[col] = "" if v is None else str(v)
    return out


def write_csv(entries: list[dict[str, Any]], path: Path) -> None:
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=CSV_COLS, extrasaction="ignore")
        w.writeheader()
        for e in entries:
            w.writerow(_row(e))


def _strip_excluded(entry: dict[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in entry.items() if k not in EXCLUDE_COLUMNS}


def write_json(entries: list[dict[str, Any]], path: Path) -> None:
    payload = {
        "entries": [_strip_excluded(e) for e in entries],
        "version": "1.0",
        "license": "CC-BY-SA-4.0",
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def write_metadata(n: int, path: Path) -> None:
    meta = {
        "title": "Hadrami Arabic Dialect Dictionary",
        "id": "REPLACE_USERNAME/hadrami-arabic-dialect-dictionary",
        "licenses": [{"name": "CC-BY-SA-4.0"}],
        "keywords": [
            "arabic",
            "dialect",
            "lexicon",
            "low-resource",
            "yemen",
            "hadrami",
            "nlp",
        ],
        "subtitle": f"{n} verified Hadrami headwords with MSA glosses, definitions, and examples",
        "description": (
            "Curated Hadrami Arabic dialect lexicon with Modern Standard Arabic "
            "equivalents, definitions, examples, proverbs, and tags. See README.md "
            "for the full schema and citation."
        ),
    }
    path.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")


def write_readme(n: int, path: Path) -> None:
    body = f"""# Hadrami Arabic Dialect Dictionary

A curated lexicon of **{n} Hadrami Arabic** headwords with Modern Standard
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
| `root` | str \\| null | Arabic triliteral root; null for compound proper nouns. |
| `pos` | str | Part of speech. One of: Noun, Verb, Adjective, Adverb, Pronoun, Interrogative, Particle, Preposition, Expression, Verb Phrase, Noun/Verb (legacy compound for ~14 rows). |
| `semantic_intent` | str | Coarse semantic class: action, object, person, emotion, place, time, descriptor, expression, function. ~10% LLM-classified; rest from rule-based mapping over POS + tags. |
| `fusha_equivalent` | str | Modern Standard Arabic gloss. |
| `definition` | str | Arabic definition / explanation. |
| `region` | str | Hadhramaut sub-region (lowercase: coast, wadi, rural, general, …). |
| `synonyms` | list[str] | Alternative Hadrami forms. |
| `phonetic_variants` | list[str] | Pronunciation variants. |
| `note` | str \\| null | Lexicographer note (null when no note). |
| `source` | str | Citation for the entry. |
| `examples` | list[{{h, f}}] | Example sentence pairs (Hadrami / MSA). |
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
@misc{{hadramirag2026,
  title  = {{Hadrami-RAG: A Retrieval-Grounded Conversational System and
            Lexicon for the Hadrami Arabic Dialect}},
  author = {{Bark, Abdelwedoud}},
  year   = {{2026}},
  url    = {{https://github.com/saeedbark/Hadrami_AI}}
}}
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
"""
    path.write_text(body, encoding="utf-8")


def main() -> None:
    print("Pulling entries from Supabase…", flush=True)
    entries = pull_all_entries()
    n = len(entries)
    print(f"  {n} rows fetched.")
    write_csv(entries, OUT_DIR / "hadrami_dictionary.csv")
    write_json(entries, OUT_DIR / "hadrami_dictionary.json")
    write_metadata(n, OUT_DIR / "dataset-metadata.json")
    write_readme(n, OUT_DIR / "README.md")
    print(f"\nKaggle bundle written to {OUT_DIR}/")
    for p in sorted(OUT_DIR.iterdir()):
        print(f"  {p.name}  ({p.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
