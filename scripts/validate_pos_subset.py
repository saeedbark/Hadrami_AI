#!/usr/bin/env python3
"""Run the POS validator on a focused subset (e.g. just Expression entries).

Useful when the full sweep is rate-limited — picks the highest-suspicion
buckets where errors are most likely. Writes results to
``results/pos_subset_<bucket>.json``.

Usage::

    backend/venv/bin/python scripts/validate_pos_subset.py --bucket Expression
    backend/venv/bin/python scripts/validate_pos_subset.py --bucket Noun/Verb
    backend/venv/bin/python scripts/validate_pos_subset.py --bucket Adjective/Verb
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402

from validate_pos import classify_entry  # noqa: E402

RESULTS_DIR = REPO_ROOT / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--bucket", required=True, help="POS bucket to validate (e.g. Expression).")
    p.add_argument("--sleep", type=float, default=12.0, help="Seconds between requests.")
    args = p.parse_args()

    sync._require_service_role()
    client = sync._make_supabase_client()
    rows = (
        client.table("entries")
        .select("id, word_vocalized, fusha_equivalent, definition, pos")
        .eq("pos", args.bucket)
        .order("id")
        .execute()
        .data
        or []
    )
    print(f"Validating {len(rows)} rows in bucket {args.bucket!r} (sleep={args.sleep}s)…")
    out_path = RESULTS_DIR / f"pos_subset_{args.bucket.replace('/', '_')}.json"

    results: list[dict] = []
    for i, row in enumerate(rows, 1):
        llm = classify_entry(row)
        results.append(
            {
                "id": row["id"],
                "word": row.get("word_vocalized"),
                "fusha": row.get("fusha_equivalent"),
                "stored_pos": row.get("pos"),
                "llm": llm,
            }
        )
        if i % 5 == 0 or i == len(rows):
            out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
            disagree = [r for r in results if r["llm"] and r["llm"]["pos"] != r["stored_pos"]]
            print(f"  {i}/{len(rows)} (disagree so far: {len(disagree)})", flush=True)
        time.sleep(args.sleep)

    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    disagree = [r for r in results if r["llm"] and r["llm"]["pos"] != r["stored_pos"]]
    unparseable = [r for r in results if not r["llm"]]
    print()
    print(f"Total:        {len(results)}")
    print(f"Disagree:     {len(disagree)}")
    print(f"Unparseable:  {len(unparseable)}")
    print()
    print("--- All disagreements ---")
    for d in disagree:
        llm = d["llm"]
        print(
            f"  id={d['id']:>4} stored={d['stored_pos']:<12} -> "
            f"llm={llm['pos']:<14} ({llm['confidence']:<6}) "
            f"word={d['word']:<22} fusha={(d['fusha'] or '')[:30]}"
        )
    print()
    print(f"Wrote: {out_path}")


if __name__ == "__main__":
    main()
