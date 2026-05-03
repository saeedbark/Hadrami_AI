#!/usr/bin/env python3
"""Validate `backend/data/hadrami_dataset.json` against the production schema.

Schema (as of 2026-04 — mirrors `backend/app/schemas.py:Entry`):

    id                int, unique, required, >= 1
    word_vocalized    str, required, non-empty
    word_clean        str, optional (auto-derivable from word_vocalized)
    root              str, optional
    pos               str, optional  (one of: Noun, Verb, Adj, Adv, Particle, Phrase, Idiom, Proverb, Other)
    fusha_equivalent  str, required, non-empty
    definition        str, required, non-empty
    region            str, optional
    synonyms          list[str], optional
    phonetic_variants list[str], optional
    note              str, optional
    source            str, optional
    examples          list[{h: str, f: str}], optional
    proverbs          list[str], optional
    tags              list[str], optional

Exit codes:
    0  dataset is valid
    1  validation errors found (see stderr)
    2  file missing / unreadable
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "hadrami_dataset.json"

REQUIRED_STR_FIELDS = ("word_vocalized", "fusha_equivalent", "definition")
OPTIONAL_STR_FIELDS = ("word_clean", "root", "pos", "region", "note", "source")
LIST_OF_STR_FIELDS = ("synonyms", "phonetic_variants", "tags")
LIST_OF_STR_OR_HF_FIELDS = ("proverbs",)
ALLOWED_POS = {
    "",
    "Noun", "Verb", "Adj", "Adjective", "Adv", "Adverb",
    "Particle", "Phrase", "Expression", "Idiom", "Proverb",
    "Pronoun", "Preposition", "Interjection", "Conjunction",
    "Noun/Verb", "Verb/Noun",
    "Other",
}
ALL_KNOWN_FIELDS = set(
    REQUIRED_STR_FIELDS
    + OPTIONAL_STR_FIELDS
    + LIST_OF_STR_FIELDS
    + LIST_OF_STR_OR_HF_FIELDS
) | {"id", "examples"}


def _load(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        print(f"[FATAL] dataset not found: {path}", file=sys.stderr)
        sys.exit(2)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"[FATAL] invalid JSON in {path}: {e}", file=sys.stderr)
        sys.exit(2)
    if isinstance(data, dict) and "entries" in data:
        data = data["entries"]
    if not isinstance(data, list):
        print("[FATAL] dataset root must be a list (or {'entries': [...]})", file=sys.stderr)
        sys.exit(2)
    return data


def _validate_entry(idx: int, entry: Any) -> tuple[list[str], list[str]]:
    """Return (errors, warnings) for a single entry."""
    errs: list[str] = []
    warns: list[str] = []
    if not isinstance(entry, dict):
        return [f"#{idx}: not an object"], []

    eid = entry.get("id")
    if not isinstance(eid, int) or eid < 1:
        errs.append(f"#{idx}: id must be positive int (got {eid!r})")

    for f in REQUIRED_STR_FIELDS:
        val = entry.get(f)
        if not isinstance(val, str) or not val.strip():
            errs.append(f"#{idx} (id={eid}): required field '{f}' missing or empty")

    for f in OPTIONAL_STR_FIELDS:
        if f in entry and entry[f] is not None and not isinstance(entry[f], str):
            errs.append(f"#{idx} (id={eid}): '{f}' must be string or null")

    pos = entry.get("pos")
    if isinstance(pos, str) and pos and pos not in ALLOWED_POS:
        warns.append(f"#{idx} (id={eid}): non-canonical pos={pos!r}")

    for f in LIST_OF_STR_FIELDS:
        if f in entry and entry[f] is not None:
            v = entry[f]
            if not isinstance(v, list) or not all(isinstance(x, str) for x in v):
                errs.append(f"#{idx} (id={eid}): '{f}' must be list[str]")

    for f in LIST_OF_STR_OR_HF_FIELDS:
        if f in entry and entry[f] is not None:
            v = entry[f]
            if not isinstance(v, list):
                errs.append(f"#{idx} (id={eid}): '{f}' must be list")
                continue
            for j, item in enumerate(v):
                if isinstance(item, str):
                    continue
                if isinstance(item, dict):
                    bad = [k for k, val in item.items() if val is not None and not isinstance(val, str)]
                    if bad:
                        errs.append(f"#{idx} (id={eid}): {f}[{j}] has non-string values for {bad}")
                    continue
                errs.append(f"#{idx} (id={eid}): {f}[{j}] must be str or {{h,f}} dict (got {type(item).__name__})")

    examples = entry.get("examples")
    if examples is not None:
        if not isinstance(examples, list):
            errs.append(f"#{idx} (id={eid}): examples must be a list")
        else:
            for j, ex in enumerate(examples):
                if not isinstance(ex, dict):
                    errs.append(f"#{idx} (id={eid}): examples[{j}] not an object")
                    continue
                for k in ("h", "f"):
                    if k in ex and ex[k] is not None and not isinstance(ex[k], str):
                        errs.append(f"#{idx} (id={eid}): examples[{j}].{k} must be string")

    unknown = set(entry.keys()) - ALL_KNOWN_FIELDS
    if unknown:
        warns.append(f"#{idx} (id={eid}): unknown fields {sorted(unknown)}")

    return errs, warns


def _duplicate_ids(entries: Iterable[dict[str, Any]]) -> list[int]:
    counts = Counter(e.get("id") for e in entries if isinstance(e, dict))
    return sorted(i for i, c in counts.items() if isinstance(i, int) and c > 1)


def main() -> int:
    entries = _load(DATA_PATH)
    print(f"[INFO] loaded {len(entries)} entries from {DATA_PATH}")

    errors: list[str] = []
    warnings: list[str] = []
    for i, e in enumerate(entries):
        errs, warns = _validate_entry(i, e)
        errors.extend(errs)
        warnings.extend(warns)

    dup = _duplicate_ids(entries)
    if dup:
        errors.append(f"duplicate ids: {dup}")

    if warnings:
        print(f"[WARN] {len(warnings)} non-fatal warning(s):")
        for w in warnings[:20]:
            print(f"  - {w}")
        if len(warnings) > 20:
            print(f"  ... ({len(warnings) - 20} more)")

    if errors:
        print(f"[FAIL] {len(errors)} validation error(s):", file=sys.stderr)
        for err in errors[:100]:
            print(f"  - {err}", file=sys.stderr)
        if len(errors) > 100:
            print(f"  ... ({len(errors) - 100} more)", file=sys.stderr)
        return 1

    print(f"[OK] dataset is valid ({len(entries)} entries, 0 duplicate ids)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
