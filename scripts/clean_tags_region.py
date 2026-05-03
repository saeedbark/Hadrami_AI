#!/usr/bin/env python3
"""Lowercase + dedupe tags; lowercase region; trim whitespace.

Examples:
    tags=["Daily Life", "Daily Life ", "DAILY LIFE"]  →  ["daily life"]
    tags=["Nature", "Animals", "Insects"]             →  ["animals", "insects", "nature"]
    region="General"                                  →  region="general"

Tag values are kept as plain lowercase strings with embedded spaces
(``"daily life"``, not ``"daily_life"``) — matches HuggingFace tag style
and stays human-readable in the Arabic-first lexicon.

Workflow::

    backend/venv/bin/python scripts/clean_tags_region.py            # dry-run
    backend/venv/bin/python scripts/clean_tags_region.py --apply    # commit
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402

RESULTS_DIR = REPO_ROOT / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def _norm_tag(t: Any) -> str:
    if not isinstance(t, str):
        return ""
    return " ".join(t.strip().lower().split())  # collapse internal whitespace too


def _norm_region(r: Any) -> str:
    if not isinstance(r, str):
        return ""
    s = r.strip().lower()
    # keep slash-compound regions consistent
    return s


def plan_change(row: dict[str, Any]) -> dict[str, Any] | None:
    changes: dict[str, Any] = {}
    notes: list[str] = []

    raw_tags = row.get("tags") or []
    if isinstance(raw_tags, list):
        seen: set[str] = set()
        norm_tags: list[str] = []
        for t in raw_tags:
            n = _norm_tag(t)
            if n and n not in seen:
                seen.add(n)
                norm_tags.append(n)
        if norm_tags != raw_tags:
            changes["tags"] = norm_tags
            if len(norm_tags) != len(raw_tags):
                notes.append(f"tags:dedupe({len(raw_tags)}->{len(norm_tags)})")
            else:
                notes.append("tags:case")

    region_raw = row.get("region") or ""
    region_norm = _norm_region(region_raw)
    if region_norm and region_norm != region_raw:
        changes["region"] = region_norm
        notes.append(f"region:{region_raw!r}->{region_norm!r}")

    if not changes:
        return None
    return {"id": row["id"], "before": {k: row.get(k) for k in changes}, "after": changes, "notes": notes}


def fetch_rows(client: Any) -> list[dict[str, Any]]:
    out = []
    off = 0
    while True:
        r = client.table("entries").select("id, tags, region").order("id").range(off, off + 499).execute()
        out.extend(r.data or [])
        if len(r.data or []) < 500:
            break
        off += 500
    return out


def apply_changes(client: Any, plans: list[dict[str, Any]]) -> int:
    n = 0
    for p in plans:
        client.table("entries").update(p["after"]).eq("id", p["id"]).execute()
        n += 1
    return n


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    sync._require_service_role()
    client = sync._make_supabase_client()
    rows = fetch_rows(client)
    plans = [c for c in (plan_change(r) for r in rows) if c is not None]

    print(f"Total rows scanned:  {len(rows)}")
    print(f"Rows changed:        {len(plans)}")
    print()

    sample = plans[:25]
    for p in sample:
        print(f"  id={p['id']:>4}  notes={p['notes']}")
        for col, before in p["before"].items():
            print(f"      {col}: {before!r} -> {p['after'][col]!r}")
    if len(plans) > 25:
        print(f"  … {len(plans) - 25} more")

    # Tag-set summary, before/after.
    before_tags: Counter[str] = Counter()
    after_tags: Counter[str] = Counter()
    for r in rows:
        for t in r.get("tags") or []:
            if isinstance(t, str):
                before_tags[t] += 1
        normalized = []
        seen = set()
        for t in r.get("tags") or []:
            n = _norm_tag(t)
            if n and n not in seen:
                seen.add(n)
                normalized.append(n)
        for t in normalized:
            after_tags[t] += 1

    print()
    print(f"Distinct tag values:  before={len(before_tags)}  after={len(after_tags)}")
    out_path = RESULTS_DIR / ("clean_tags_region.applied.json" if args.apply else "clean_tags_region.dryrun.json")
    out_path.write_text(json.dumps({"updates": plans, "tag_counts_after": after_tags.most_common()}, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.apply:
        n = apply_changes(client, plans)
        print(f"\nApplied {n} UPDATEs.")
    else:
        print("\nDry-run only. Re-run with --apply to commit.")
    print(f"Change record: {out_path}")


if __name__ == "__main__":
    main()
