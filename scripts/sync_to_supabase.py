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
    SUPABASE_URL          - project URL  (e.g. https://xxx.supabase.co)
    SUPABASE_SERVICE_KEY  - service-role key (NOT the anon key)
    GEMINI_API_KEY        - Google AI Studio key for text-embedding-004
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import time
from pathlib import Path
from typing import Any, Optional

SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent / "backend"
DATA_FILE = BACKEND_DIR / "data" / "hadrami_dataset.json"

sys.path.insert(0, str(BACKEND_DIR))

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
EMBED_DELAY = 0.3


def _jwt_role_from_supabase_key(key: str) -> str | None:
    key = (key or "").strip()
    if not key or "." not in key:
        return None
    try:
        payload_b64 = key.split(".")[1]
        pad = "=" * (-len(payload_b64) % 4)
        raw = base64.urlsafe_b64decode(payload_b64 + pad)
        data = json.loads(raw.decode("utf-8"))
        r = data.get("role")
        return str(r) if r is not None else None
    except Exception:
        return None


def _require_env() -> None:
    missing = []
    if not SUPABASE_URL:
        missing.append("SUPABASE_URL")
    if not SUPABASE_SERVICE_KEY:
        missing.append("SUPABASE_SERVICE_KEY")
    if missing:
        sys.exit(f"ERROR: Missing environment variables: {', '.join(missing)}")
    jwt_role = _jwt_role_from_supabase_key(SUPABASE_SERVICE_KEY)
    if jwt_role != "service_role":
        sys.exit(
            "ERROR: SUPABASE_SERVICE_KEY must be the **service_role** JWT "
            "(Dashboard -> Project Settings -> API -> service_role), not the anon key.\n"
            f"Decoded role is {jwt_role!r}. RLS blocks writes for anon."
        )


def _load_dataset() -> list[dict[str, Any]]:
    if not DATA_FILE.exists():
        sys.exit(f"ERROR: Dataset not found at {DATA_FILE}")
    with open(DATA_FILE, encoding="utf-8") as f:
        payload = json.load(f)
    if isinstance(payload, list):
        entries = payload
    elif isinstance(payload, dict):
        entries = payload.get("entries", [])
    else:
        sys.exit("ERROR: Unexpected JSON format in dataset file")
    print(f"Loaded {len(entries)} entries from {DATA_FILE.name}")
    return entries


def _make_supabase_client():
    from supabase import create_client

    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


def _entry_to_row(entry: dict[str, Any]) -> dict[str, Any]:
    """Map a JSON entry to the DB column layout."""
    row: dict[str, Any] = {
        "id": entry["id"],
        "word_vocalized": entry.get("word_vocalized", ""),
        "word_clean": entry.get("word_clean"),
        "root": entry.get("root"),
        "pos": entry.get("pos"),
        "fusha_equivalent": entry.get("fusha_equivalent"),
        "definition": entry.get("definition"),
        "region": entry.get("region", "General"),
        "note": entry.get("note", ""),
        "source": entry.get("source", ""),
    }

    synonyms = entry.get("synonyms")
    row["synonyms"] = json.dumps(synonyms, ensure_ascii=False) if synonyms else "[]"

    phonetic_variants = entry.get("phonetic_variants")
    row["phonetic_variants"] = json.dumps(phonetic_variants, ensure_ascii=False) if phonetic_variants else "[]"

    examples = entry.get("examples")
    row["examples"] = json.dumps(examples, ensure_ascii=False) if examples else "[]"

    proverbs = entry.get("proverbs")
    row["proverbs"] = json.dumps(proverbs, ensure_ascii=False) if proverbs else "[]"

    tags = entry.get("tags")
    row["tags"] = json.dumps(tags, ensure_ascii=False) if tags else "[]"

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
        print(f"  embed error: {exc}")
        return None


def _embedding_text_for_entry(entry: dict[str, Any]) -> str:
    """Concatenate key fields into a single document string for embedding."""
    parts = [
        entry.get("word_vocalized", ""),
        " ".join(entry.get("synonyms") or []) if isinstance(entry.get("synonyms"), list) else "",
        entry.get("fusha_equivalent", ""),
        entry.get("definition", ""),
    ]
    note = entry.get("note")
    if note:
        parts.append(note)
    examples = entry.get("examples")
    if isinstance(examples, list):
        for ex in examples[:3]:
            if isinstance(ex, dict):
                h = ex.get("h", "")
                f = ex.get("f", "")
                if h:
                    parts.append(h)
                if f:
                    parts.append(f)
    return " ".join(p for p in parts if p)


def backfill_embeddings(only_missing: bool = True) -> int:
    """Generate and store embeddings. Returns count of updated rows."""
    if not GEMINI_API_KEY:
        print("GEMINI_API_KEY not set -- skipping embeddings")
        return 0

    client = _make_supabase_client()

    select_cols = "id, word_vocalized, synonyms, fusha_equivalent, definition, note, examples"

    if only_missing:
        resp = (
            client.table(TABLE)
            .select(select_cols)
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
                .select(select_cols)
                .range(offset, offset + page_size - 1)
                .execute()
            )
            batch = resp.data or []
            rows.extend(batch)
            if len(batch) < page_size:
                break
            offset += page_size

    print(f"Generating embeddings for {len(rows)} entries ...")
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

    print(f"Embeddings complete -- {updated} rows updated")
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
            print("GEMINI_API_KEY not set -- skipping embeddings. Re-run with the key to backfill.")
        else:
            print("=== Generating embeddings ===")
            backfill_embeddings(only_missing=True)

    print("\nDone!")


if __name__ == "__main__":
    main()
