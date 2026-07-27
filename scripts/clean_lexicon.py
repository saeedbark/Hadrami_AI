#!/usr/bin/env python3
"""Normalize POS / region labels and trim whitespace on the live ``entries`` table.

Rules are intentionally conservative — only collapse forms that are obviously
the same concept written two ways. Rows that look ambiguous (e.g. region
``Nature`` / ``Agriculture`` which look like tags that landed in the wrong
column) are *flagged*, not silently rewritten.

Workflow::

    # 1) Dry-run — print every UPDATE that would happen, write nothing.
    backend/venv/bin/python scripts/clean_lexicon.py

    # 2) Commit (after reviewing the dry-run output).
    backend/venv/bin/python scripts/clean_lexicon.py --apply

The script writes ``results/clean_lexicon.dryrun.json`` (dry-run) or
``results/clean_lexicon.applied.json`` (commit) so the change set is
reviewable in version control / linkable from the paper appendix.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402

RESULTS_DIR = REPO_ROOT / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Canonical mappings (only the obviously-equivalent forms; no semantic merges)
# ---------------------------------------------------------------------------

POS_MAP: dict[str, str] = {
    # Spaces around slash → no spaces; alphabetize compound POS.
    "Noun / Verb": "Noun/Verb",
    "Verb / Noun": "Noun/Verb",
    "Verb / Adjective": "Adjective/Verb",
    "Noun/Adjective": "Adjective/Noun",
}

REGION_MAP: dict[str, str] = {
    # Lexical variants of the same concept.
    "Coastal": "Coast",
    "Valleys": "Wadi",
    # Collapse spaces around slash on compound regions.
    "Coast / Wadi": "Coast/Wadi",
    "Desert / Badia": "Desert/Badia",
    "Bedouin / Rural": "Bedouin/Rural",
    "General / Rural": "General/Rural",
}

# Region values we will NOT auto-rewrite — they look like tags that ended up in
# the wrong column. Flag for human review instead.
FLAG_REGIONS: set[str] = {"Nature", "Agriculture"}


# ---------------------------------------------------------------------------
# Cleaning logic (pure)
# ---------------------------------------------------------------------------

def _clean_string(value: Any) -> tuple[Any, bool]:
    """Strip whitespace on string fields. Returns (cleaned, did_change)."""
    if not isinstance(value, str):
        return value, False
    s = value.strip()
    return s, s != value


def plan_change(row: dict[str, Any]) -> dict[str, Any] | None:
    """Return the UPDATE payload for ``row``, or None if nothing changes."""
    changes: dict[str, Any] = {}
    notes: list[str] = []

    pos_raw = row.get("pos") or ""
    pos_stripped, pos_ws = _clean_string(pos_raw)
    pos_target = POS_MAP.get(pos_stripped, pos_stripped)
    if pos_target != pos_raw:
        changes["pos"] = pos_target
        if pos_ws:
            notes.append("pos:trim")
        if pos_target != pos_stripped:
            notes.append(f"pos:{pos_stripped}->{pos_target}")

    region_raw = row.get("region") or ""
    region_stripped, region_ws = _clean_string(region_raw)
    if region_stripped in FLAG_REGIONS:
        notes.append(f"region:flag-for-review:{region_stripped}")
        region_target = region_stripped  # don't rewrite
    else:
        region_target = REGION_MAP.get(region_stripped, region_stripped)
    if region_target != region_raw:
        changes["region"] = region_target
        if region_ws:
            notes.append("region:trim")
        if region_target != region_stripped:
            notes.append(f"region:{region_stripped}->{region_target}")

    # Whitespace cleanup for other free-text fields. We only fix obvious
    # leaks; we do NOT touch definitions / examples beyond outer-trim.
    for col in ("word_vocalized", "word_clean", "fusha_equivalent", "note", "source"):
        cleaned, did = _clean_string(row.get(col))
        if did:
            changes[col] = cleaned
            notes.append(f"{col}:trim")

    if not changes and not notes:
        return None
    return {
        "id": row["id"],
        "before": {k: row.get(k) for k in changes.keys()},
        "after": changes,
        "notes": notes,
    }


# ---------------------------------------------------------------------------
# IO
# ---------------------------------------------------------------------------

def fetch_rows(client: Any) -> list[dict[str, Any]]:
    cols = "id, pos, region, word_vocalized, word_clean, fusha_equivalent, note, source"
    out: list[dict[str, Any]] = []
    off = 0
    page = 500
    while True:
        r = (
            client.table(sync.TABLE).select(cols).order("id").range(off, off + page - 1).execute()
        )
        out.extend(r.data or [])
        if len(r.data or []) < page:
            break
        off += page
    return out


def apply_changes(client: Any, changes: list[dict[str, Any]]) -> int:
    """Issue per-row UPDATEs. Returns the count of rows actually written."""
    n = 0
    for ch in changes:
        if not ch.get("after"):
            continue  # flag-only entry
        client.table(sync.TABLE).update(ch["after"]).eq("id", ch["id"]).execute()
        n += 1
    return n


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply", action="store_true", help="Commit the UPDATEs (default is dry-run).")
    args = p.parse_args()

    sync._require_service_role()
    client = sync._make_supabase_client()

    rows = fetch_rows(client)
    plans = [c for c in (plan_change(r) for r in rows) if c is not None]
    write_plans = [c for c in plans if c.get("after")]
    flag_only = [c for c in plans if not c.get("after")]

    flagged_rows = [
        c for c in plans if any("flag-for-review" in n for n in c.get("notes", []))
    ]
    print(f"Total rows scanned:        {len(rows)}")
    print(f"Rows with UPDATE planned:  {len(write_plans)}")
    print(f"Rows flagged for review:   {len(flagged_rows)} (region looks like a tag)")
    print()
    print("=== UPDATEs that would be applied ===")
    for ch in write_plans[:50]:
        print(f"  id={ch['id']:>4}  notes={ch['notes']}")
        for col, before in ch["before"].items():
            after = ch["after"].get(col, before)
            print(f"      {col}: {before!r} -> {after!r}")
    if len(write_plans) > 50:
        print(f"  … {len(write_plans) - 50} more")

    if flagged_rows:
        print()
        print("=== Flagged for human review (kept as-is; not auto-rewritten) ===")
        for ch in flagged_rows:
            print(f"  id={ch['id']:>4}  notes={ch['notes']}")

    record_path = (
        RESULTS_DIR / ("clean_lexicon.applied.json" if args.apply else "clean_lexicon.dryrun.json")
    )
    record_path.write_text(
        json.dumps(
            {"updates": write_plans, "flagged": flag_only},
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    if args.apply:
        print()
        print(f"Applying {len(write_plans)} UPDATEs…", flush=True)
        n = apply_changes(client, write_plans)
        print(f"Applied {n} UPDATEs.")
    else:
        print()
        print("Dry-run only. Re-run with --apply to commit.")
    print(f"Change record: {record_path}")


if __name__ == "__main__":
    main()
