"""Shared loader: pull all entries from the live Supabase table.

Used by the Kaggle and HuggingFace export scripts. Read-only; never writes.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402


CORE_COLUMNS = (
    "id, word_vocalized, word_clean, root, pos, fusha_equivalent, definition, "
    "region, synonyms, phonetic_variants, note, source, examples, proverbs, tags"
)

# Columns added in later schema migrations. We try to fetch them but
# silently fall back if the migration hasn't been applied yet.
OPTIONAL_COLUMNS = (
    "semantic_intent",
    "transliteration",
    "searchable_text",
)


def pull_all_entries() -> list[dict[str, Any]]:
    """Read every public column. Excludes embeddings (binary; users can recompute).

    Tries the extended schema first; if any optional column is missing
    (404 from PostgREST) it retries with just the core columns.
    """
    sync._require_service_role()
    client = sync._make_supabase_client()
    page = 500

    select_cols = CORE_COLUMNS + ", " + ", ".join(OPTIONAL_COLUMNS)

    out: list[dict[str, Any]] = []
    off = 0
    while True:
        try:
            r = (
                client.table(sync.TABLE)
                .select(select_cols)
                .order("id")
                .range(off, off + page - 1)
                .execute()
            )
        except Exception as exc:
            # Optional columns missing — fall back to core schema.
            if "column" in str(exc).lower() or "404" in str(exc):
                print(
                    f"  optional schema not present ({exc!r}); falling back to CORE_COLUMNS",
                    flush=True,
                )
                select_cols = CORE_COLUMNS
                continue
            raise
        rows = r.data or []
        out.extend(rows)
        if len(rows) < page:
            break
        off += page
    return out
