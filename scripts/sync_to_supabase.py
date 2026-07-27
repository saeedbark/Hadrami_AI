#!/usr/bin/env python3
"""Canonical ETL for the Hadrami dataset: JSON -> (optional CSV) -> Supabase + embeddings.

This script replaces the older pair ``sync_to_supabase.py`` +
``json_to_csv_and_supabase.py``. It is the single source of truth for:

* loading ``backend/data/hadrami_dataset.json`` (list or ``{"entries": [...]}``),
* deduplicating by ``id`` (last-wins, required for PostgreSQL ``ON CONFLICT``),
* (optionally) writing a CSV snapshot with JSON columns as JSON text,
* upserting into the Supabase ``entries`` table (jsonb columns as native
  Python lists, not stringified),
* (optionally) backfilling Gemini ``gemini-embedding-001`` vectors (768-dim; legacy
  ``text-embedding-004`` is no longer available on the API as of 2026).

Usage (examples)::

    # Full pipeline (CSV + upsert + embeddings, only missing embeddings)
    python scripts/sync_to_supabase.py

    # Upsert only (no CSV, no embeddings)
    python scripts/sync_to_supabase.py --skip-csv --skip-embeddings

    # Only regenerate embeddings for rows missing one or flagged dirty
    python scripts/sync_to_supabase.py --embeddings-only

    # Only write the CSV snapshot
    python scripts/sync_to_supabase.py --skip-supabase --skip-embeddings

Required env (from ``backend/.env`` or shell):
    SUPABASE_URL          https://<ref>.supabase.co
    SUPABASE_SERVICE_KEY  service_role JWT (NOT the anon key)
    GEMINI_API_KEY        Google AI Studio key (only needed for embeddings)
"""

from __future__ import annotations

import argparse
import base64
import csv
import json
import os
import platform
import sys
import time
from pathlib import Path
from typing import Any, Optional

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
BACKEND_DIR = REPO_ROOT / "backend"
DATA_JSON = BACKEND_DIR / "data" / "hadrami_dataset.json"
DEFAULT_CSV = BACKEND_DIR / "data" / "hadrami_entries.csv"


# ---------------------------------------------------------------------------
# venv fallback + env loading
# ---------------------------------------------------------------------------

def _prepend_venv_site_packages() -> None:
    """Allow running with system ``python`` while using deps from ``backend/venv``."""
    win_site = BACKEND_DIR / "venv" / "Lib" / "site-packages"
    if win_site.is_dir():
        p = str(win_site)
        if p not in sys.path:
            sys.path.insert(0, p)
        return
    lib = BACKEND_DIR / "venv" / "lib"
    if not lib.is_dir():
        return
    matches = sorted(lib.glob("python*/site-packages"), key=lambda x: str(x), reverse=True)
    for site_pkg in matches:
        if site_pkg.is_dir():
            p = str(site_pkg)
            if p not in sys.path:
                sys.path.insert(0, p)
            break


_prepend_venv_site_packages()
sys.path.insert(0, str(BACKEND_DIR))

try:
    from dotenv import load_dotenv

    load_dotenv(BACKEND_DIR / ".env")
except ImportError:
    pass

from app.services.embedding_doc import (  # noqa: E402  -- after sys.path setup
    EMBEDDING_DOC_VERSION,
    embedding_text_for_entry as _embedding_text_for_entry,
)


SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "").strip()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()


TABLE = "entries"
UPSERT_BATCH = 100
EMBED_MODEL = "models/gemini-embedding-001"
EMBED_TASK = "RETRIEVAL_DOCUMENT"
EMBED_OUTPUT_DIM = 768
EMBED_PAGE_SIZE = 50
EMBED_RETRIES = 3
EMBED_DELAY_SECONDS = 0.1

CSV_COLUMNS = [
    "id",
    "word_vocalized",
    "word_clean",
    "root",
    "pos",
    "fusha_equivalent",
    "definition",
    "region",
    "synonyms",
    "phonetic_variants",
    "note",
    "source",
    "examples",
    "proverbs",
    "tags",
]


# ---------------------------------------------------------------------------
# Credential + env checks
# ---------------------------------------------------------------------------

def _jwt_role(key: str) -> str | None:
    """Return the ``role`` claim of a JWT without signature verification."""
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


def _require_service_role() -> None:
    missing = []
    if not SUPABASE_URL:
        missing.append("SUPABASE_URL")
    if not SUPABASE_SERVICE_KEY:
        missing.append("SUPABASE_SERVICE_KEY")
    if missing:
        sys.exit(f"ERROR: Missing env vars: {', '.join(missing)} (set them in backend/.env)")
    role = _jwt_role(SUPABASE_SERVICE_KEY)
    if role != "service_role":
        sys.exit(
            "ERROR: SUPABASE_SERVICE_KEY must be the **service_role** JWT "
            "(Dashboard -> Project Settings -> API -> service_role), not the anon key.\n"
            f"Decoded role is {role!r}. RLS blocks writes for anon."
        )


# ---------------------------------------------------------------------------
# Dataset loading + normalization
# ---------------------------------------------------------------------------

def _load_dataset() -> list[dict[str, Any]]:
    if not DATA_JSON.exists():
        sys.exit(f"ERROR: Dataset not found: {DATA_JSON}")
    with open(DATA_JSON, encoding="utf-8") as f:
        payload = json.load(f)
    if isinstance(payload, list):
        entries = payload
    elif isinstance(payload, dict):
        entries = payload.get("entries", [])
    else:
        sys.exit("ERROR: JSON must be a list or {\"entries\": [...]}")
    print(f"Loaded {len(entries)} entries from {DATA_JSON.name}")
    return entries


def _dedupe_by_id(entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """One row per ``id`` (last wins). Duplicate ids break ``ON CONFLICT (id)``."""
    by_id: dict[Any, dict[str, Any]] = {}
    without_id: list[dict[str, Any]] = []
    for e in entries:
        eid = e.get("id")
        if eid is None:
            without_id.append(e)
        else:
            by_id[eid] = e
    ordered = [by_id[k] for k in sorted(by_id.keys())]
    return ordered + without_id


# ---------------------------------------------------------------------------
# Row shaping (CSV + Supabase)
# ---------------------------------------------------------------------------

def _as_list(v: Any) -> list:
    return v if isinstance(v, list) else []


def _json_cell(value: Any) -> str:
    """Serialize lists/dicts as JSON-text for a CSV cell (``[]`` when empty/None)."""
    if value is None:
        return "[]"
    return json.dumps(value, ensure_ascii=False)


def _row_for_csv(entry: dict[str, Any]) -> dict[str, str]:
    return {
        "id": str(entry.get("id", "")),
        "word_vocalized": entry.get("word_vocalized") or "",
        "word_clean": entry.get("word_clean") or "",
        "root": entry.get("root") or "",
        "pos": entry.get("pos") or "",
        "fusha_equivalent": entry.get("fusha_equivalent") or "",
        "definition": entry.get("definition") or "",
        "region": entry.get("region") or "General",
        "synonyms": _json_cell(_as_list(entry.get("synonyms"))),
        "phonetic_variants": _json_cell(_as_list(entry.get("phonetic_variants"))),
        "note": entry.get("note") or "",
        "source": entry.get("source") or "",
        "examples": _json_cell(_as_list(entry.get("examples"))),
        "proverbs": _json_cell(_as_list(entry.get("proverbs"))),
        "tags": _json_cell(_as_list(entry.get("tags"))),
    }


def _row_for_supabase(entry: dict[str, Any]) -> dict[str, Any]:
    """Row payload for PostgREST — jsonb columns stay as Python lists/dicts.

    Crucially, do NOT ``json.dumps`` list fields: PostgREST will then store
    them as strings inside jsonb, breaking all ``jsonb_array_elements_text``
    queries downstream.
    """
    return {
        "id": entry["id"],
        "word_vocalized": entry.get("word_vocalized") or "",
        "word_clean": entry.get("word_clean"),
        "root": entry.get("root"),
        "pos": entry.get("pos"),
        "fusha_equivalent": entry.get("fusha_equivalent"),
        "definition": entry.get("definition"),
        "region": entry.get("region") or "General",
        "note": entry.get("note") or "",
        "source": entry.get("source") or "",
        "synonyms": _as_list(entry.get("synonyms")),
        "phonetic_variants": _as_list(entry.get("phonetic_variants")),
        "examples": _as_list(entry.get("examples")),
        "proverbs": _as_list(entry.get("proverbs")),
        "tags": _as_list(entry.get("tags")),
    }


# ---------------------------------------------------------------------------
# Supabase client
# ---------------------------------------------------------------------------

def _make_supabase_client():
    try:
        from supabase import create_client
    except ImportError as exc:
        is_win = platform.system() == "Windows"
        venv_py = (
            BACKEND_DIR / "venv" / "Scripts" / "python.exe"
            if is_win
            else BACKEND_DIR / "venv" / "bin" / "python3"
        )
        sys.exit(
            "ERROR: The 'supabase' package is not importable.\n"
            "  Fix: use the backend venv Python, e.g.\n"
            f"    {venv_py} scripts/sync_to_supabase.py\n"
            "  Or: pip install supabase (in this environment).\n"
            f"  Original error: {exc}"
        )
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


# ---------------------------------------------------------------------------
# CSV snapshot
# ---------------------------------------------------------------------------

def write_csv(entries: list[dict[str, Any]], csv_path: Path) -> None:
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with open(csv_path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        w.writeheader()
        for e in entries:
            w.writerow(_row_for_csv(e))
    print(f"Wrote {len(entries)} rows to {csv_path}")


# ---------------------------------------------------------------------------
# Supabase upsert
# ---------------------------------------------------------------------------

def upsert_entries(entries: list[dict[str, Any]], client=None) -> int:
    if client is None:
        client = _make_supabase_client()
    total = 0
    for i in range(0, len(entries), UPSERT_BATCH):
        batch = [_row_for_supabase(e) for e in entries[i : i + UPSERT_BATCH]]
        client.table(TABLE).upsert(batch, on_conflict="id").execute()
        total += len(batch)
        print(f"  upserted {total}/{len(entries)}")
    return total


# ---------------------------------------------------------------------------
# Embeddings
# ---------------------------------------------------------------------------

def _embed_text(text: str) -> Optional[list[float]]:
    """Call Gemini with retries. Handles daily quota (free tier) with long backoff."""
    import re

    import google.generativeai as genai

    if not text.strip():
        return None
    genai.configure(api_key=GEMINI_API_KEY)
    last_err: Optional[str] = None
    for attempt in range(EMBED_RETRIES):
        try:
            result = genai.embed_content(
                model=EMBED_MODEL,
                content=text,
                task_type=EMBED_TASK,
                output_dimensionality=EMBED_OUTPUT_DIM,
            )
            vec = result.get("embedding")
            if not vec or len(vec) != EMBED_OUTPUT_DIM:
                last_err = f"bad length {0 if not vec else len(vec)}"
                time.sleep(1.0 * (attempt + 1))
                continue
            return vec
        except Exception as exc:  # noqa: BLE001 — log and retry
            last_err = repr(exc)
            is_quota = "ResourceExhausted" in type(
                exc
            ).__name__ or "quota" in str(exc).lower()
            if is_quota:
                m = re.search(r"retry in ([0-9.]+)s", str(exc), re.I)
                wait = min(120.0, float(m.group(1)) + 2.0 if m else 65.0)
                print(f"  embed quota / rate limit; sleeping {wait:.1f}s …", flush=True)
                time.sleep(wait)
            elif attempt < EMBED_RETRIES - 1:
                time.sleep(1.5 * (attempt + 1))
    print(f"  embed error (after {EMBED_RETRIES} tries): {last_err}")
    return None




def _embedding_status_counts(
    client: Any,
) -> tuple[Optional[int], Optional[int], Optional[int]]:
    """(total, null_embedding, still_dirty) using count=exact, or Nones on error."""
    import httpx  # type: ignore[import-not-found]

    def _c(build_query_fn) -> Optional[int]:
        try:
            r = build_query_fn().execute()
            return r.count
        except (TypeError, httpx.HTTPError, Exception):
            return None

    total = _c(lambda: client.table(TABLE).select("id", count="exact"))
    nulls = _c(
        lambda: client.table(TABLE)
        .select("id", count="exact")
        .is_("embedding", "null")
    )
    dirty = _c(
        lambda: client.table(TABLE)
        .select("id", count="exact")
        .eq("embedding_dirty", True)
    )
    return total, nulls, dirty


def backfill_embeddings(only_missing: bool = True) -> int:
    if not GEMINI_API_KEY:
        print("GEMINI_API_KEY not set -- skipping embeddings")
        return 0

    client = _make_supabase_client()
    page_size = EMBED_PAGE_SIZE
    select_cols = (
        "id, word_vocalized, word_clean, root, "
        "definition, synonyms, examples, note"
    )

    def _rows_missing() -> list[dict[str, Any]]:
        r = (
            client.table(TABLE)
            .select(select_cols)
            .or_("embedding.is.null,embedding_dirty.eq.true")
            .order("id", desc=False)
            .limit(page_size)
            .execute()
        )
        return r.data or []

    def _rows_page(off: int) -> list[dict[str, Any]]:
        r = (
            client.table(TABLE)
            .select(select_cols)
            .order("id", desc=False)
            .range(off, off + page_size - 1)
            .execute()
        )
        return r.data or []

    sample_texts: list[str] = []
    total_attempted = 0
    updated = 0
    failed_ids: list[int] = []

    def _do_row(row: dict[str, Any]) -> None:
        nonlocal total_attempted, updated
        text = _embedding_text_for_entry(row)
        if len(sample_texts) < 3 and (text or "").strip():
            sample_texts.append(text)
        total_attempted += 1
        embedding = _embed_text(text)
        if embedding is None:
            failed_ids.append(int(row["id"]))
            time.sleep(EMBED_DELAY_SECONDS)
            return
        client.table(TABLE).update(
            {"embedding": embedding, "embedding_dirty": False}
        ).eq("id", row["id"]).execute()
        updated += 1
        time.sleep(EMBED_DELAY_SECONDS)

    print(
        f"Model={EMBED_MODEL!r} output_dim={EMBED_OUTPUT_DIM} "
        f"batch={page_size} retries/row={EMBED_RETRIES}\n"
        f"(Request was text-embedding-004; that model is not available in the API — "
        f"using the supported replacement.)\n",
        flush=True,
    )

    if only_missing:
        no_progress_streak = 0
        while True:
            rows = _rows_missing()
            if not rows:
                break
            n_before = updated
            for row in rows:
                _do_row(row)
            if updated == n_before and rows:
                no_progress_streak += 1
                if no_progress_streak >= 2:
                    print(
                        "  Stopping: no successful embeddings in 2 consecutive batches "
                        "(often daily API quota; re-run tomorrow or use a paid tier).",
                        flush=True,
                    )
                    break
            else:
                no_progress_streak = 0
            print(
                f"  batch of {len(rows)}: updated {updated} (attempted {total_attempted}, "
                f"failures {len(failed_ids)})",
                flush=True,
            )
    else:
        offset = 0
        while True:
            rows = _rows_page(offset)
            if not rows:
                break
            for row in rows:
                _do_row(row)
            print(
                f"  offset {offset}… +{len(rows)} rows: updated {updated} (attempted {total_attempted})",
                flush=True,
            )
            if len(rows) < page_size:
                break
            offset += page_size

    failures = len(failed_ids)
    print("\n--- Embedding backfill summary ---")
    print(f"  Rows processed (candidates in run): {total_attempted}")
    print(f"  Successful updates: {updated}")
    print(f"  Failed (see ids): {failures}")
    if failed_ids:
        print(
            f"  Failed entry ids: {failed_ids[:50]}{'…' if len(failed_ids) > 50 else ''}"
        )
    t, n, d = _embedding_status_counts(client)
    if t is not None:
        print(f"  DB total entries: {t}")
    if n is not None:
        print(f"  Rows with NULL embedding after run: {n}")
    if d is not None:
        print(f"  Rows with embedding_dirty=true after run: {d}")
    if n == 0 and d == 0 and failures == 0:
        print("  RAG: 768-d vectors stored; no NULL or dirty flags — semantic search ready.\n")
    else:
        print("  RAG: verify remaining NULLs/dirty rows; re-run or fix key if needed.\n")
    for i, st in enumerate(sample_texts, 1):
        print(f"--- sample embedding input {i} ---\n{st}\n")
    return updated


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _build_argparser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Sync hadrami_dataset.json to Supabase (optional CSV + embeddings).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--csv",
        type=Path,
        default=DEFAULT_CSV,
        help="Output CSV snapshot path",
    )
    p.add_argument("--skip-csv", action="store_true", help="Do not write the CSV snapshot")
    p.add_argument("--skip-supabase", action="store_true", help="Do not upsert rows to Supabase")
    p.add_argument(
        "--skip-embeddings",
        action="store_true",
        help="Do not (re)generate embeddings after upsert",
    )
    p.add_argument(
        "--embeddings-only",
        action="store_true",
        help="Only run the embedding backfill (skips CSV and entry upsert)",
    )
    p.add_argument(
        "--reembed-all",
        action="store_true",
        help="Re-embed every row, not only missing/dirty ones",
    )
    return p


def main() -> None:
    args = _build_argparser().parse_args()

    if args.embeddings_only:
        _require_service_role()
        backfill_embeddings(only_missing=not args.reembed_all)
        return

    entries = _load_dataset()
    n_raw = len(entries)
    entries = _dedupe_by_id(entries)
    if len(entries) < n_raw:
        print(
            f"Warning: deduplicated by id ({n_raw} -> {len(entries)} rows); "
            "last occurrence kept per id."
        )

    if not args.skip_csv:
        write_csv(entries, args.csv.resolve())

    if not args.skip_supabase:
        _require_service_role()
        print("=== Upserting entries to Supabase ===")
        upsert_entries(entries)

    if args.skip_supabase or args.skip_embeddings:
        if args.skip_embeddings:
            print("Skipping embedding generation (--skip-embeddings)")
    else:
        if not GEMINI_API_KEY:
            print("GEMINI_API_KEY not set -- skipping embeddings. Re-run with the key to backfill.")
        else:
            print("=== Generating embeddings ===")
            backfill_embeddings(only_missing=not args.reembed_all)

    print("\nDone!")


if __name__ == "__main__":
    main()
