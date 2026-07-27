#!/usr/bin/env python3
"""Audit `backend/data/hadrami_dataset.json` — descriptive stats for the new schema.

Reports:
  * total entries, unique ids, duplicate ids
  * field coverage per optional field (how many entries populate it)
  * POS distribution
  * top regions, tags, roots
  * example coverage (h-only / f-only / both)
  * token-length distributions for word_vocalized, fusha_equivalent, definition

No side effects: read-only.
"""

from __future__ import annotations

import json
import statistics
import sys
from collections import Counter
from pathlib import Path
from typing import Any

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "hadrami_dataset.json"


def _load() -> list[dict[str, Any]]:
    if not DATA_PATH.exists():
        print(f"[FATAL] missing {DATA_PATH}", file=sys.stderr)
        sys.exit(2)
    raw = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    if isinstance(raw, dict) and "entries" in raw:
        raw = raw["entries"]
    if not isinstance(raw, list):
        print("[FATAL] dataset root must be list", file=sys.stderr)
        sys.exit(2)
    return [e for e in raw if isinstance(e, dict)]


def _pct(n: int, total: int) -> str:
    return f"{(100.0 * n / total):5.1f}%" if total else "  -  "


def _nonempty(v: Any) -> bool:
    if v is None:
        return False
    if isinstance(v, str):
        return bool(v.strip())
    if isinstance(v, list):
        return len(v) > 0
    return True


def _summarize_length(values: list[int], label: str) -> str:
    if not values:
        return f"  {label}: (no data)"
    return (
        f"  {label}: "
        f"min={min(values)} p50={int(statistics.median(values))} "
        f"mean={statistics.mean(values):.1f} p95={_pctile(values, 95)} max={max(values)}"
    )


def _pctile(values: list[int], p: int) -> int:
    s = sorted(values)
    k = max(0, min(len(s) - 1, int(round((p / 100.0) * (len(s) - 1)))))
    return s[k]


def main() -> int:
    entries = _load()
    n = len(entries)
    print(f"# Hadrami Dataset Audit — {DATA_PATH.name}")
    print(f"entries: {n}")

    ids = [e.get("id") for e in entries if isinstance(e.get("id"), int)]
    dup = [i for i, c in Counter(ids).items() if c > 1]
    print(f"unique ids: {len(set(ids))}")
    print(f"duplicate ids: {sorted(dup) if dup else 'none'}")
    print(f"id range: [{min(ids) if ids else '-'}, {max(ids) if ids else '-'}]")
    if ids:
        missing = sorted(set(range(min(ids), max(ids) + 1)) - set(ids))
        print(f"missing id gaps: {len(missing)} (first 10: {missing[:10]})")

    print("\n## Field coverage")
    scalar_fields = [
        "word_vocalized", "word_clean", "root", "pos", "fusha_equivalent",
        "definition", "region", "note", "source",
    ]
    list_fields = ["synonyms", "phonetic_variants", "proverbs", "tags", "examples"]
    for f in scalar_fields + list_fields:
        hits = sum(1 for e in entries if _nonempty(e.get(f)))
        print(f"  {f:22s} {hits:5d}/{n} ({_pct(hits, n)})")

    print("\n## POS distribution")
    pos_counts = Counter((e.get("pos") or "").strip() or "(unset)" for e in entries)
    for pos, c in pos_counts.most_common():
        print(f"  {pos:15s} {c:5d} ({_pct(c, n)})")

    print("\n## Top regions (max 15)")
    region_counts = Counter((e.get("region") or "").strip() or "(unset)" for e in entries)
    for r, c in region_counts.most_common(15):
        print(f"  {r:25s} {c:5d}")

    print("\n## Top tags (max 20)")
    tag_counts: Counter[str] = Counter()
    for e in entries:
        for t in e.get("tags") or []:
            if isinstance(t, str) and t.strip():
                tag_counts[t.strip()] += 1
    for t, c in tag_counts.most_common(20):
        print(f"  {t:25s} {c:5d}")

    print("\n## Top roots (max 15)")
    root_counts = Counter((e.get("root") or "").strip() for e in entries if (e.get("root") or "").strip())
    for r, c in root_counts.most_common(15):
        print(f"  {r:15s} {c:5d}")

    print("\n## Example coverage")
    ex_both = ex_h_only = ex_f_only = ex_empty = ex_count = 0
    for e in entries:
        for ex in e.get("examples") or []:
            if not isinstance(ex, dict):
                continue
            ex_count += 1
            h = (ex.get("h") or "").strip()
            f = (ex.get("f") or "").strip()
            if h and f:
                ex_both += 1
            elif h:
                ex_h_only += 1
            elif f:
                ex_f_only += 1
            else:
                ex_empty += 1
    print(f"  total examples          : {ex_count}")
    print(f"  with both h+f           : {ex_both}  ({_pct(ex_both, ex_count)})")
    print(f"  h-only (no MSA gloss)   : {ex_h_only}  ({_pct(ex_h_only, ex_count)})")
    print(f"  f-only (no Hadrami)     : {ex_f_only}  ({_pct(ex_f_only, ex_count)})")
    print(f"  empty                   : {ex_empty}  ({_pct(ex_empty, ex_count)})")

    print("\n## Length distributions (chars)")
    for f in ("word_vocalized", "fusha_equivalent", "definition"):
        lengths = [len((e.get(f) or "")) for e in entries if isinstance(e.get(f), str)]
        print(_summarize_length(lengths, f))

    print("\n[OK] audit complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
