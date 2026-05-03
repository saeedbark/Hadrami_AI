"""Supabase-backed data store for the Hadrami NLP dictionary.

All read operations go through the singleton ``get_client()`` helper
which returns a ``supabase.Client``.
"""

from __future__ import annotations

import threading
from typing import Any

from supabase import Client, create_client

from .config import SUPABASE_SERVICE_KEY, SUPABASE_URL

TABLE = "entries"
FEEDBACK_TABLE = "feedback"

_thread_local = threading.local()


def get_client() -> Client:
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        raise RuntimeError(
            "SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in the environment"
        )
    if not hasattr(_thread_local, "client"):
        _thread_local.client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    return _thread_local.client


def _reset_client() -> Client:
    """Discard the current thread's client so the next call gets a fresh one."""
    if hasattr(_thread_local, "client"):
        del _thread_local.client
    return get_client()


_SELECT_COLS = (
    "id, word_vocalized, word_clean, root, pos, fusha_equivalent, "
    "definition, region, synonyms, phonetic_variants, note, source, "
    "examples, proverbs, tags, tags_ar"
)


def _execute_with_retry(build_query_fn):
    """Run ``build_query_fn(client).execute()``, retrying once on connection errors."""
    import httpx

    for attempt in range(2):
        try:
            return build_query_fn(get_client()).execute()
        except (httpx.LocalProtocolError, httpx.RemoteProtocolError, KeyError):
            if attempt == 0:
                _reset_client()
            else:
                raise


def fetch_all(columns: str = _SELECT_COLS) -> list[dict[str, Any]]:
    """Return every entry (no embedding column -- too large for bulk reads)."""
    rows: list[dict[str, Any]] = []
    page_size = 1000
    offset = 0
    while True:
        start, end = offset, offset + page_size - 1
        resp = _execute_with_retry(
            lambda c, s=start, e=end: c.table(TABLE).select(columns).range(s, e)
        )
        batch = resp.data or []
        rows.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size
    return rows


def fetch_by_id(entry_id: int) -> dict[str, Any] | None:
    resp = _execute_with_retry(
        lambda c: c.table(TABLE).select(_SELECT_COLS).eq("id", entry_id).limit(1)
    )
    return resp.data[0] if resp.data else None


def count_rows() -> int:
    resp = _execute_with_retry(
        lambda c: c.table(TABLE).select("id", count="exact")
    )
    return resp.count or 0


def text_search(
    query: str,
    columns: list[str] | None = None,
    limit: int = 20,
) -> list[dict[str, Any]]:
    """Case-insensitive ``ilike`` search across one or more text columns."""
    cols = columns or ["word_vocalized", "word_clean", "fusha_equivalent", "definition"]
    pattern = f"%{query}%"
    or_filter = ",".join(f"{c}.ilike.{pattern}" for c in cols)
    resp = _execute_with_retry(
        lambda c, f=or_filter, lim=limit: c.table(TABLE).select(_SELECT_COLS).or_(f).limit(lim)
    )
    return resp.data or []


def rpc_match_entries(
    query_embedding: list[float],
    match_threshold: float = 0.3,
    match_count: int = 10,
) -> list[dict[str, Any]]:
    """Call the ``match_entries`` Postgres function for cosine-similarity search."""
    resp = _execute_with_retry(
        lambda c: c.rpc(
            "match_entries",
            {
                "query_embedding": query_embedding,
                "match_threshold": match_threshold,
                "match_count": match_count,
            },
        )
    )
    return resp.data or []


def insert_feedback(payload: dict[str, Any]) -> dict[str, Any]:
    """Persist a feedback submission. Returns the inserted row."""
    resp = _execute_with_retry(
        lambda c, p=payload: c.table(FEEDBACK_TABLE).insert(p)
    )
    rows = resp.data or []
    return rows[0] if rows else {}


def list_feedback(
    limit: int = 50,
    offset: int = 0,
    status: str | None = None,
    feedback_type: str | None = None,
) -> dict[str, Any]:
    """List feedback rows newest-first, with optional status/type filters."""
    def build(c, start=offset, end=offset + limit - 1):
        q = c.table(FEEDBACK_TABLE).select("*", count="exact")
        if status:
            q = q.eq("status", status)
        if feedback_type:
            q = q.eq("feedback_type", feedback_type)
        return q.order("created_at", desc=True).range(start, end)

    resp = _execute_with_retry(build)
    return {"total": resp.count or 0, "results": resp.data or []}


def rpc_search_entries_expanded(query_text: str, match_count: int = 8) -> list[dict[str, Any]]:
    """Call the SQL retrieval helper that expands and ranks question tokens server-side."""
    resp = _execute_with_retry(
        lambda c: c.rpc(
            "search_entries_expanded",
            {
                "query_text": query_text,
                "match_count": match_count,
            },
        )
    )
    return resp.data or []
