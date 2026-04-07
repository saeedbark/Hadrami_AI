#!/usr/bin/env python3
"""HA-11: Dataset validation script for hadrami_dataset.json.

Checks:
  - Unique IDs
  - No duplicate hadrami_word entries (warns on exact duplication)
  - Required keys present on every entry (id, hadrami_word, arabic_fus7a, full_definition)
  - Suspiciously short arabic_fus7a (< 2 chars)
  - Optional JSON schema validation for new fields (examples, aliases, fus7a_short)
  - Total count consistency

Usage:
    python -m backend.scripts.validate_dataset          # from project root
    python backend/scripts/validate_dataset.py          # direct
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REQUIRED_KEYS = {"id", "hadrami_word", "arabic_fus7a", "full_definition"}
OPTIONAL_KEYS = {"fus7a_short", "aliases", "examples", "verified_by", "source", "version"}
SHORT_FUS7A_THRESHOLD = 2


def load_dataset(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    warnings: list[str] = []

    try:
        data = load_dataset(path)
    except (json.JSONDecodeError, OSError) as exc:
        return [f"FATAL: Cannot load {path}: {exc}"]

    if not isinstance(data, dict):
        return [f"FATAL: Root must be an object, got {type(data).__name__}"]

    entries = data.get("entries")
    if not isinstance(entries, list):
        return [f"FATAL: 'entries' key must be a list"]

    declared_total = data.get("total")
    if declared_total is not None and declared_total != len(entries):
        errors.append(
            f"'total' ({declared_total}) does not match actual entry count ({len(entries)})"
        )

    seen_ids: dict[int, int] = {}
    seen_words: dict[str, list[int]] = {}

    for idx, entry in enumerate(entries):
        if not isinstance(entry, dict):
            errors.append(f"entries[{idx}]: not a dict")
            continue

        for key in REQUIRED_KEYS:
            if key not in entry:
                errors.append(f"entries[{idx}]: missing required key '{key}'")

        eid = entry.get("id")
        if eid is not None:
            if not isinstance(eid, int):
                errors.append(f"entries[{idx}]: 'id' must be int, got {type(eid).__name__}")
            elif eid in seen_ids:
                errors.append(
                    f"entries[{idx}]: duplicate id={eid} (first at index {seen_ids[eid]})"
                )
            else:
                seen_ids[eid] = idx

        word = entry.get("hadrami_word", "")
        if isinstance(word, str):
            w = word.strip()
            seen_words.setdefault(w, []).append(idx)

        fus7a = entry.get("arabic_fus7a", "")
        if isinstance(fus7a, str) and len(fus7a.strip()) < SHORT_FUS7A_THRESHOLD:
            warnings.append(
                f"entries[{idx}] (id={eid}): arabic_fus7a is suspiciously short: '{fus7a}'"
            )

        examples = entry.get("examples")
        if examples is not None:
            if not isinstance(examples, list):
                errors.append(f"entries[{idx}]: 'examples' must be a list")
            else:
                for ei, ex in enumerate(examples):
                    if not isinstance(ex, dict):
                        errors.append(f"entries[{idx}].examples[{ei}]: must be a dict")

        aliases = entry.get("aliases")
        if aliases is not None:
            if not isinstance(aliases, list):
                errors.append(f"entries[{idx}]: 'aliases' must be a list of strings")
            elif not all(isinstance(a, str) for a in aliases):
                errors.append(f"entries[{idx}]: 'aliases' items must be strings")

        fus7a_short = entry.get("fus7a_short")
        if fus7a_short is not None and not isinstance(fus7a_short, str):
            errors.append(f"entries[{idx}]: 'fus7a_short' must be a string")

    KNOWN_POLYSEMOUS = {"الخيل", "القس", "يولف"}
    for word, indices in seen_words.items():
        if len(indices) > 1:
            if word in KNOWN_POLYSEMOUS:
                continue
            warnings.append(
                f"duplicate hadrami_word '{word}' at indices {indices}"
            )

    results: list[str] = []
    for e in errors:
        results.append(f"ERROR: {e}")
    for w in warnings:
        results.append(f"WARNING: {w}")

    if not errors and not warnings:
        results.append(f"OK: {len(entries)} entries validated with no issues.")
    else:
        results.append(f"Summary: {len(errors)} error(s), {len(warnings)} warning(s) in {len(entries)} entries.")

    return results


def main() -> int:
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

    dataset_path = Path(__file__).resolve().parent.parent / "data" / "hadrami_dataset.json"
    if not dataset_path.exists():
        print(f"Dataset not found at {dataset_path}", file=sys.stderr)
        return 1

    results = validate(dataset_path)
    has_errors = any(r.startswith("ERROR:") for r in results)

    for line in results:
        print(line)

    return 1 if has_errors else 0


if __name__ == "__main__":
    sys.exit(main())
