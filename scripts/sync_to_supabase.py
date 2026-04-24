#!/usr/bin/env python3
"""Migrate hadrami_dataset.json into Supabase and generate Gemini embeddings.

Usage:
    # Full sync (upsert all entries + generate embeddings)
    python scripts/sync_to_supabase.py

    # Upsert rows only, skip embedding generation
    python scripts/sync_to_supabase.py --skip-embeddings

    # Only backfill embeddings for rows that don't have one yet
    python scripts/sync_to_supabase.py --embeddings-only

Environment variables (required):
    SUPABASE_URL          – project URL  (e.g. https://xxx.supabase.co)
    SUPABASE_SERVICE_KEY  – service-role key (NOT the anon key)
    GEMINI_API_KEY        – Google AI Studio key for text-embedding-004
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Any, Optional

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent / "backend"
DATA_FILE = BACKEND_DIR / "data" / "hadrami_dataset.json"

# Allow importing from backend package when running standalone
sys.path.insert(0, str(BACKEND_DIR))

# ---------------------------------------------------------------------------
# Load env
# ---------------------------------------------------------------------------

try:
    from dotenv import load_dotenv

    load_dotenv(BACKEND_DIR / ".env")
except ImportError:
    pass

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

TABLE = "entries"
EMBED_MODEL = "models/text-embedding-004"
EMBED_TASK = "RETRIEVAL_DOCUMENT"
BATCH_SIZE = 50
EMBED_DELAY = 0.3  # seconds between embed calls to stay under rate limits


def _require_env() -> None:
    missing = []
    if not SUPABASE_URL:
        missing.append("SUPABASE_URL")
    if not SUPABASE_SERVICE_KEY:
        missing.append("SUPABASE_SERVICE_KEY")
    if missing:
        sys.exit(f"ERROR: Missing environment variables: {', '.join(missing)}")


def _load_dataset() -> list[dict[str, Any]]:
    if not DATA_FILE.exists():
        sys.exit(f"ERROR: Dataset not found at {DATA_FILE}")
    with open(DATA_FILE, encoding="utf-8") as f:
        payload = json.load(f)
    entries = payload.get("entries", [])
    print(f"Loaded {len(entries)} entries from {DATA_FILE.name}")
    return entries


def _make_supabase_client():
    from supabase import create_client

    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


def _entry_to_row(entry: dict[str, Any]) -> dict[str, Any]:
    """Map a JSON entry to the DB column layout."""
    row: dict[str, Any] = {
        "id": entry["id"],
        "hadrami_word": entry.get("hadrami_word", ""),
        "search_key": entry.get("search_key"),
        "arabic_fus7a": entry.get("arabic_fus7a"),
        "full_definition": entry.get("full_definition"),
        "cultural_note": entry.get("cultural_note"),
        "part_of_speech": entry.get("part_of_speech"),
        "thematic_category": entry.get("thematic_category"),
        "is_archaic": bool(entry.get("is_archaic", False)),
        "aliases": entry.get("aliases") or [],
    }
    pr = entry.get("proverb_record")
    row["proverb_record"] = json.dumps(pr, ensure_ascii=False) if pr else None

    ex = entry.get("examples")
    row["examples"] = json.dumps(ex, ensure_ascii=False) if ex else None

    return row


# ---------------------------------------------------------------------------
# Upsert
# ---------------------------------------------------------------------------

def upsert_entries(entries: list[dict[str, Any]]) -> int:
    client = _make_supabase_client()
    total = 0
    for i in range(0, len(entries), BATCH_SIZE):
        batch = entries[i : i + BATCH_SIZE]
        rows = [_entry_to_row(e) for e in batch]
        client.table(TABLE).upsert(rows, on_conflict="id").execute()
        total += len(rows)
        print(f"  upserted {total}/{len(entries)}")
    return total


# ---------------------------------------------------------------------------
# Embeddings
# ---------------------------------------------------------------------------

def _embed_text(text: str) -> Optional[list[float]]:
    import google.generativeai as genai

    genai.configure(api_key=GEMINI_API_KEY)
    try:
        result = genai.embed_content(
            model=EMBED_MODEL,
            content=text,
            task_type=EMBED_TASK,
        )
        return result["embedding"]
    except Exception as exc:
        print(f"  ⚠ embed error: {exc}")
        return None


def _embedding_text_for_entry(entry: dict[str, Any]) -> str:
    """Concatenate key fields into a single document string for embedding."""
    parts = [
        entry.get("hadrami_word", ""),
        " ".join(entry.get("aliases") or []) if isinstance(entry.get("aliases"), list) else "",
        entry.get("arabic_fus7a", ""),
        entry.get("full_definition", ""),
    ]
    cultural = entry.get("cultural_note")
    if cultural:
        parts.append(cultural)
    examples = entry.get("examples")
    if isinstance(examples, list):
        for ex in examples[:3]:
            if isinstance(ex, dict):
                h = ex.get("hadrami", "")
                f = ex.get("fusha", "")
                if h:
                    parts.append(h)
                if f:
                    parts.append(f)
    return " ".join(p for p in parts if p)


def backfill_embeddings(only_missing: bool = True) -> int:
    """Generate and store embeddings. Returns count of updated rows."""
    if not GEMINI_API_KEY:
        print("GEMINI_API_KEY not set — skipping embeddings")
        return 0

    client = _make_supabase_client()

    if only_missing:
        resp = (
            client.table(TABLE)
            .select("id, hadrami_word, aliases, arabic_fus7a, full_definition, cultural_note, examples")
            .or_("embedding.is.null,embedding_dirty.eq.true")
            .execute()
        )
        rows = resp.data or []
    else:
        rows = []
        page_size = 1000
        offset = 0
        while True:
            resp = (
                client.table(TABLE)
                .select("id, hadrami_word, aliases, arabic_fus7a, full_definition, cultural_note, examples")
                .range(offset, offset + page_size - 1)
                .execute()
            )
            batch = resp.data or []
            rows.extend(batch)
            if len(batch) < page_size:
                break
            offset += page_size

    print(f"Generating embeddings for {len(rows)} entries …")
    updated = 0
    for i, row in enumerate(rows, 1):
        text = _embedding_text_for_entry(row)
        embedding = _embed_text(text)
        if embedding is None:
            continue
        client.table(TABLE).update(
            {"embedding": embedding, "embedding_dirty": False}
        ).eq("id", row["id"]).execute()
        updated += 1
        if i % 25 == 0 or i == len(rows):
            print(f"  embedded {i}/{len(rows)} (updated {updated})")
        time.sleep(EMBED_DELAY)

    print(f"Embeddings complete — {updated} rows updated")
    return updated


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Sync hadrami dataset to Supabase")
    parser.add_argument("--skip-embeddings", action="store_true", help="Upsert rows only, skip embedding generation")
    parser.add_argument("--embeddings-only", action="store_true", help="Only backfill embeddings for rows missing them")
    args = parser.parse_args()

    _require_env()

    if args.embeddings_only:
        backfill_embeddings(only_missing=True)
        return

    entries = _load_dataset()
    print("=== Upserting entries to Supabase ===")
    upserted = upsert_entries(entries)
    print(f"Upserted {upserted} entries\n")

    if args.skip_embeddings:
        print("Skipping embedding generation (--skip-embeddings)")
    else:
        if not GEMINI_API_KEY:
            print("GEMINI_API_KEY not set — skipping embeddings. Re-run with the key to backfill.")
        else:
            print("=== Generating embeddings ===")
            backfill_embeddings(only_missing=True)

    print("\nDone!")


if __name__ == "__main__":
    main()
