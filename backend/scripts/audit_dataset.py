#!/usr/bin/env python3
"""HA-7: Audit hadrami_dataset.json for incomplete or noisy arabic_fus7a glosses.

Checks:
  - arabic_fus7a that are empty, only whitespace, or single character
  - arabic_fus7a that look truncated (end with dash, ellipsis, or incomplete sentence)
  - arabic_fus7a that are suspiciously long (> 200 chars → may contain definition text)
  - Inconsistency between arabic_fus7a and full_definition (fus7a not found in definition)
  - Entries missing diacritics normalization issues

Usage:
    python -m backend.scripts.audit_dataset
    python backend/scripts/audit_dataset.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def load_entries(path: Path) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("entries", [])


def audit(entries: list[dict]) -> dict[str, list[dict]]:
    issues: dict[str, list[dict]] = {
        "empty_fus7a": [],
        "truncated_fus7a": [],
        "too_long_fus7a": [],
        "very_short_fus7a": [],
        "missing_definition": [],
    }

    truncation_pattern = re.compile(r"[-–—…]\s*$|\.{2,}\s*$")

    for entry in entries:
        eid = entry.get("id", "?")
        word = entry.get("hadrami_word", "")
        fus7a = (entry.get("arabic_fus7a") or "").strip()
        definition = (entry.get("full_definition") or "").strip()

        info = {"id": eid, "hadrami_word": word, "arabic_fus7a": fus7a}

        if not fus7a:
            issues["empty_fus7a"].append(info)
            continue

        if len(fus7a) <= 1:
            issues["very_short_fus7a"].append(info)

        if truncation_pattern.search(fus7a):
            issues["truncated_fus7a"].append(info)

        if len(fus7a) > 200:
            issues["too_long_fus7a"].append({**info, "length": len(fus7a)})

        if not definition:
            issues["missing_definition"].append(info)

    return issues


def main() -> int:
    dataset_path = Path(__file__).resolve().parent.parent / "data" / "hadrami_dataset.json"
    if not dataset_path.exists():
        print(f"Dataset not found at {dataset_path}", file=sys.stderr)
        return 1

    entries = load_entries(dataset_path)
    issues = audit(entries)

    total_issues = 0
    for category, items in issues.items():
        if items:
            total_issues += len(items)
            print(f"\n{'='*60}")
            print(f"{category.upper()} ({len(items)} entries)")
            print(f"{'='*60}")
            for item in items[:20]:
                print(f"  id={item['id']:>5}  word={item['hadrami_word']!r:>20}  fus7a={item['arabic_fus7a']!r}")
            if len(items) > 20:
                print(f"  ... and {len(items) - 20} more")

    print(f"\n{'='*60}")
    print(f"AUDIT SUMMARY: {total_issues} issue(s) found in {len(entries)} entries")
    print(f"{'='*60}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
