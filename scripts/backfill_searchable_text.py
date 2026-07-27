#!/usr/bin/env python3
"""Populate ``entries.searchable_text`` with the canonical embedding doc.

Pre-requisite: the columns ``searchable_text`` (TEXT) and
``searchable_text_version`` (TEXT) must already exist. Run the
``backend/migrations/20260503_add_searchable_text.sql`` migration first.

Idempotent: only updates rows whose stored
``searchable_text_version`` differs from the current
``EMBEDDING_DOC_VERSION``.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402

from app.services.embedding_doc import (  # noqa: E402
    EMBEDDING_DOC_VERSION,
    embedding_text_for_entry,
)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--all",
        action="store_true",
        help="Re-write every row (default: only those whose version is stale).",
    )
    args = p.parse_args()

    sync._require_service_role()
    client = sync._make_supabase_client()

    fields = (
        "id, word_vocalized, word_clean, root, fusha_equivalent, definition, "
        "synonyms, examples, tags, note, searchable_text_version"
    )

    rows: list[dict[str, Any]] = []
    off = 0
    while True:
        r = client.table("entries").select(fields).order("id").range(off, off + 499).execute()
        rows.extend(r.data or [])
        if len(r.data or []) < 500:
            break
        off += 500
    print(f"Fetched {len(rows)} rows.")

    todo = [
        r for r in rows
        if args.all or (r.get("searchable_text_version") or "") != EMBEDDING_DOC_VERSION
    ]
    print(f"To update: {len(todo)} (version target = {EMBEDDING_DOC_VERSION!r})")
    if not todo:
        print("All rows already at the current version. Done.")
        return

    n = 0
    for row in todo:
        text = embedding_text_for_entry(row)
        client.table("entries").update(
            {
                "searchable_text": text,
                "searchable_text_version": EMBEDDING_DOC_VERSION,
            }
        ).eq("id", row["id"]).execute()
        n += 1
        if n % 100 == 0 or n == len(todo):
            print(f"  {n}/{len(todo)}", flush=True)
    print(f"Done. Wrote searchable_text to {n} rows.")


if __name__ == "__main__":
    main()
