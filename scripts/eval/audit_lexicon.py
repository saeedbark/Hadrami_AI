#!/usr/bin/env python3
"""Read-only audit of the live Supabase ``entries`` table.

Reports:
  * total rows, # missing fusha_equivalent / examples / definition / tags,
  * distribution by POS and region (top-10 each),
  * embedding health: rows with NULL embedding or embedding_dirty=true,
  * top-10 most-common tags.

Output is human-readable text + a JSON sidecar
(``results/lexicon_audit.json``) for downstream papers / tables.

NB: This is read-only. No UPDATE/INSERT/DELETE issued.

Usage::

    backend/venv/bin/python scripts/eval/audit_lexicon.py
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = REPO_ROOT / "backend"
sys.path.insert(0, str(BACKEND_DIR))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

# Borrow the venv-aware setup + service-role check from the sync script.
import sync_to_supabase as sync  # noqa: E402

RESULTS_DIR = REPO_ROOT / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

OUT_JSON = RESULTS_DIR / "lexicon_audit.json"


def _pull_all_rows(client: Any) -> list[dict]:
    """Page through all rows using ``range``. Reads the columns we audit on."""
    cols = (
        "id, word_vocalized, word_clean, fusha_equivalent, definition, "
        "pos, region, examples, tags, embedding_dirty"
    )
    page = 500
    out: list[dict] = []
    offset = 0
    while True:
        r = (
            client.table(sync.TABLE)
            .select(cols)
            .order("id")
            .range(offset, offset + page - 1)
            .execute()
        )
        rows = r.data or []
        if not rows:
            break
        out.extend(rows)
        if len(rows) < page:
            break
        offset += page
    return out


def _is_empty(v: Any) -> bool:
    if v is None:
        return True
    if isinstance(v, str):
        return not v.strip()
    if isinstance(v, list):
        return len(v) == 0
    return False


def audit() -> dict[str, Any]:
    sync._require_service_role()
    client = sync._make_supabase_client()

    print("Pulling rows…", flush=True)
    rows = _pull_all_rows(client)
    total = len(rows)

    missing_fusha = sum(1 for r in rows if _is_empty(r.get("fusha_equivalent")))
    missing_def = sum(1 for r in rows if _is_empty(r.get("definition")))
    missing_examples = sum(1 for r in rows if _is_empty(r.get("examples")))
    missing_tags = sum(1 for r in rows if _is_empty(r.get("tags")))
    missing_word_clean = sum(1 for r in rows if _is_empty(r.get("word_clean")))
    dirty = sum(1 for r in rows if r.get("embedding_dirty") is True)

    by_pos: Counter[str] = Counter()
    by_region: Counter[str] = Counter()
    tag_counts: Counter[str] = Counter()

    for r in rows:
        by_pos[(r.get("pos") or "unspecified").strip() or "unspecified"] += 1
        by_region[(r.get("region") or "unspecified").strip() or "unspecified"] += 1
        for t in r.get("tags") or []:
            if isinstance(t, str) and t.strip():
                tag_counts[t.strip()] += 1

    # Embedding NULL count needs a separate count-only query (data has no embedding column).
    try:
        null_emb = (
            client.table(sync.TABLE)
            .select("id", count="exact")
            .is_("embedding", "null")
            .execute()
            .count
        )
    except Exception as exc:  # noqa: BLE001
        null_emb = None
        print(f"  could not count NULL embeddings: {exc!r}", flush=True)

    summary = {
        "total_entries": total,
        "missing_fusha_equivalent": missing_fusha,
        "missing_definition": missing_def,
        "missing_examples": missing_examples,
        "missing_tags": missing_tags,
        "missing_word_clean": missing_word_clean,
        "embedding_dirty": dirty,
        "embedding_null": null_emb,
        "pos_distribution": by_pos.most_common(),
        "region_distribution": by_region.most_common(),
        "top_tags": tag_counts.most_common(20),
        "embedding_doc_version_in_use": sync.EMBEDDING_DOC_VERSION,
    }

    OUT_JSON.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    return summary


def _pct(n: int | None, total: int) -> str:
    if n is None or total == 0:
        return "—"
    return f"{n} ({100.0 * n / total:.1f}%)"


def _print_report(s: dict[str, Any]) -> None:
    t = s["total_entries"]
    print()
    print("=" * 60)
    print("Hadrami lexicon — audit report")
    print("=" * 60)
    print(f"  total entries:                   {t}")
    print(f"  missing fusha_equivalent:        {_pct(s['missing_fusha_equivalent'], t)}")
    print(f"  missing definition:              {_pct(s['missing_definition'], t)}")
    print(f"  missing examples:                {_pct(s['missing_examples'], t)}")
    print(f"  missing tags:                    {_pct(s['missing_tags'], t)}")
    print(f"  missing word_clean:              {_pct(s['missing_word_clean'], t)}")
    print(f"  embedding_dirty=true:            {_pct(s['embedding_dirty'], t)}")
    print(f"  embedding IS NULL:               {_pct(s['embedding_null'], t)}")
    print(f"  embedding doc version (sync):    {s['embedding_doc_version_in_use']}")
    print()
    print("  POS distribution (top 10):")
    for p, n in s["pos_distribution"][:10]:
        print(f"    {p:<20} {n}")
    print()
    print("  Region distribution (top 10):")
    for r, n in s["region_distribution"][:10]:
        print(f"    {r:<20} {n}")
    print()
    print("  Top 20 tags:")
    for tag, n in s["top_tags"]:
        print(f"    {tag:<20} {n}")
    print()
    print(f"  Wrote JSON sidecar: {OUT_JSON}")


if __name__ == "__main__":
    summary = audit()
    _print_report(summary)
