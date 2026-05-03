#!/usr/bin/env python3
"""Replace ``""`` with NULL on free-text columns where empty == missing.

Per user: an empty ``note`` should be NULL, not ``""`` — the difference
matters for downstream `IS NULL` filters in SQL and for `null` vs `""` in
JSON / Parquet.

Touched columns: ``note``, ``root``. ``source``, ``fusha_equivalent``,
``definition`` are NOT touched because the audit shows they are 100%
populated and an empty string there would be a bug worth flagging, not
silently nulling.

Workflow::

    backend/venv/bin/python scripts/null_empty_strings.py            # dry-run
    backend/venv/bin/python scripts/null_empty_strings.py --apply    # commit
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

NULLABLE_FIELDS = ("note", "root")


def fetch_rows(client: Any) -> list[dict[str, Any]]:
    cols = "id, " + ", ".join(NULLABLE_FIELDS)
    out = []
    off = 0
    while True:
        r = client.table("entries").select(cols).order("id").range(off, off + 499).execute()
        out.extend(r.data or [])
        if len(r.data or []) < 500:
            break
        off += 500
    return out


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply", action="store_true")
    args = p.parse_args()

    sync._require_service_role()
    client = sync._make_supabase_client()
    rows = fetch_rows(client)

    plans: list[dict[str, Any]] = []
    for r in rows:
        update: dict[str, Any] = {}
        for col in NULLABLE_FIELDS:
            v = r.get(col)
            if isinstance(v, str) and not v.strip():
                update[col] = None
        if update:
            plans.append({"id": r["id"], "update": update})

    print(f"Total rows scanned:  {len(rows)}")
    print(f"Rows to NULLify:     {len(plans)}")
    by_field: dict[str, int] = {}
    for p_ in plans:
        for k in p_["update"]:
            by_field[k] = by_field.get(k, 0) + 1
    for k, n in sorted(by_field.items()):
        print(f"  {k}: {n}")

    record_path = RESULTS_DIR / (
        "null_empty_strings.applied.json" if args.apply else "null_empty_strings.dryrun.json"
    )
    record_path.write_text(json.dumps(plans, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.apply:
        n = 0
        for p_ in plans:
            client.table("entries").update(p_["update"]).eq("id", p_["id"]).execute()
            n += 1
            if n % 100 == 0:
                print(f"  {n}/{len(plans)}", flush=True)
        print(f"\nApplied {n} UPDATEs.")
    else:
        print("\nDry-run only. Re-run with --apply to commit.")
    print(f"Change record: {record_path}")


if __name__ == "__main__":
    main()
