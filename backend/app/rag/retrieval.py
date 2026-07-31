"""Retrieval stage of the RAG pipeline.

Three retrievers:

* :func:`keyword_context`           — thin wrapper over ``search()``
* :func:`expanded_keyword_context`  — question-aware server-side expansion
                                      (token splitting + score aggregation)
* :func:`vector_context`            — pgvector cosine similarity via RPC

Plus the two orchestrators that callers should use:

* :func:`retrieve_rag_context`     — hybrid merge for ``/ask`` and ``/chat``
* :func:`retrieve_phrase_context`  — stricter lexicon retrieval for
                                      ``/convert-phrase``
"""

from __future__ import annotations

import re
import time
from typing import Any

from ..core.data_store import rpc_match_entries
from ..services.dictionary_service import (
    focus_query_for_embedding,
    search as keyword_search,
    search_expanded,
    search_phrase_lexicon,
)
from .config import MODE, QUERY_CACHE_TTL_SECONDS
from .logging_utils import rag_log


_keyword_cache: dict[tuple[str, int], tuple[float, dict[str, Any]]] = {}
_vector_cache: dict[tuple[str, int], tuple[float, list[dict[str, Any]]]] = {}


def _cache_get(cache: dict[Any, tuple[float, Any]], key: Any) -> Any | None:
    if QUERY_CACHE_TTL_SECONDS <= 0:
        return None
    hit = cache.get(key)
    if hit is None:
        return None
    expires_at, value = hit
    if expires_at < time.time():
        cache.pop(key, None)
        return None
    return value


def _cache_put(cache: dict[Any, tuple[float, Any]], key: Any, value: Any) -> Any:
    if QUERY_CACHE_TTL_SECONDS > 0:
        cache[key] = (time.time() + QUERY_CACHE_TTL_SECONDS, value)
    return value


# ---------------------------------------------------------------------------
# Individual retrievers
# ---------------------------------------------------------------------------

def keyword_context(query: str, top_k: int = 5) -> list[dict]:
    result = keyword_search(query, limit=top_k)
    rows = result["results"]
    labels = [f"{r.get('word_vocalized', '?')}->{r.get('fusha_equivalent', '')}" for r in rows[:5]]
    rag_log(f"keyword_search q={query!r} top_k={top_k} -> {len(rows)} hits: {labels}")
    return rows


def expanded_keyword_context(query: str, top_k: int = 8) -> dict[str, Any]:
    cache_key = (query.strip(), top_k)
    cached = _cache_get(_keyword_cache, cache_key)
    if cached is not None:
        rag_log(
            f"search_expanded cache hit q={query!r} top_k={top_k} "
            f"-> {len(cached.get('results', []))} hits"
        )
        return cached

    payload = search_expanded(query, limit=top_k)
    rows = payload["results"]
    labels = [f"{r.get('word_vocalized', '?')}->{r.get('fusha_equivalent', '')}" for r in rows[:5]]
    rag_log(
        f"search_expanded q={query!r} top_k={top_k} "
        f"score={payload.get('top_score', 0)} -> {len(rows)} hits: {labels}"
    )
    return _cache_put(_keyword_cache, cache_key, payload)


def vector_context(query: str, top_k: int = 6) -> list[dict]:
    cache_key = (query.strip(), top_k)
    cached = _cache_get(_vector_cache, cache_key)
    if cached is not None:
        rag_log(f"vector_context cache hit q={query!r} -> {len(cached)} hits")
        return cached

    from ..services.embedding_service import embed_text

    # Short "focus" query helps vectors match headwords, not the whole MSA question.
    qv = (focus_query_for_embedding(query) or query).strip() or query
    embedding = embed_text(qv)
    if embedding is None:
        rag_log(
            f"vector_context: embedding unavailable for q={query!r} (focus={qv!r}) — skipping"
        )
        return []

    rows = rpc_match_entries(embedding, match_threshold=0.25, match_count=top_k)
    labels = [
        f"{r.get('word_vocalized', '?')}->{r.get('fusha_equivalent', '')} "
        f"({r.get('similarity', 0):.2f})"
        for r in rows[:5]
    ]
    rag_log(f"vector_context q={query!r} -> {len(rows)} hits: {labels}")
    return _cache_put(_vector_cache, cache_key, rows)


# ---------------------------------------------------------------------------
# Orchestrators
# ---------------------------------------------------------------------------

def _merge_entries_by_id(*lists: list[dict]) -> list[dict]:
    seen: set[int] = set()
    out: list[dict] = []
    for lst in lists:
        for e in lst:
            eid = e.get("id")
            if eid is None or eid in seen:
                continue
            seen.add(eid)
            out.append(e)
    return out


def retrieve_rag_context(query: str) -> tuple[list[dict], list[dict]]:
    """Hybrid retrieval for ``/ask`` and ``/chat``.

    Returns ``(entries_for_prompt, entries_for_api_response)``. The two are
    identical today but are kept distinct so we can later prune prompt
    context (token-budget trimming) without affecting the API contract.
    """
    if MODE == "simple":
        context = keyword_context(query, top_k=3)
        return context[:5], context[:5]

    kw_payload = expanded_keyword_context(query, top_k=8)
    kw_ctx = kw_payload["results"]
    top_score = int(kw_payload.get("top_score") or 0)
    if top_score >= 100:
        rag_log(f"exact keyword hit for q={query!r} -- skipping vector search")
        merged = kw_ctx[:5]
        return merged, merged[:5]

    vec_ctx = vector_context(query, top_k=4)
    merged = _merge_entries_by_id(kw_ctx, vec_ctx)[:5]
    return merged, merged[:5]


_PARAGRAPH_HINT_CHARS = 60  # above this OR with ≥2 segments we treat as multi-clause
_SENTENCE_SPLIT = re.compile(r"[\.!\?؟،؛\n]+")


def _split_sentences(text: str) -> list[str]:
    """Sentence-ish split for paragraph-aware retrieval. Cheap and over-eager
    is fine — we only use the pieces to widen the lexicon hit set."""
    parts = [s.strip() for s in _SENTENCE_SPLIT.split(text or "") if s and s.strip()]
    return [p for p in parts if len(p) >= 3]


def _is_multi_clause(text: str, segments: list[str]) -> bool:
    """A query is "multi-clause" if it's long OR has >= 2 sentence-ish segments.

    The 73-char canonical test paragraph hits the segments rule (3 clauses
    separated by ``،``) without hitting the length rule.
    """
    return len(text) >= _PARAGRAPH_HINT_CHARS or len(segments) >= 2


def retrieve_phrase_context(query: str) -> tuple[list[dict], list[dict]]:
    """Stricter lexicon-first retrieval for ``/convert-phrase`` and the
    chat ``convert`` intent.

    For multi-clause input we additionally retrieve per-sentence and merge —
    without this, a 4-headword paragraph can exhaust the top-5 cap and lose
    lexical coverage on later clauses.
    """
    q = (query or "").strip()
    if MODE == "simple":
        rows = search_phrase_lexicon(q, 8)["results"]
        return rows[:5], rows[:5]

    segments = _split_sentences(q)
    is_paragraph = _is_multi_clause(q, segments)
    top_k_main = 12 if is_paragraph else 10
    cap = 12 if is_paragraph else 5

    kw_ctx = search_phrase_lexicon(q, top_k_main)["results"]
    vec_ctx = vector_context(q, top_k=6 if is_paragraph else 4)

    sentence_kw: list[dict] = []
    sentence_vec: list[dict] = []
    if is_paragraph:
        for sentence in segments[:6]:
            try:
                sentence_kw.extend(search_phrase_lexicon(sentence, 4)["results"])
            except Exception:
                pass
            try:
                sentence_vec.extend(vector_context(sentence, top_k=2))
            except Exception:
                pass

    merged = _merge_entries_by_id(kw_ctx, vec_ctx, sentence_kw, sentence_vec)[:cap]
    if is_paragraph:
        rag_log(
            f"retrieve_phrase_context paragraph mode q_len={len(q)} "
            f"kw={len(kw_ctx)} vec={len(vec_ctx)} sent_kw={len(sentence_kw)} "
            f"sent_vec={len(sentence_vec)} merged={len(merged)}"
        )
    return merged, merged[:cap]


def phrase_top_score(query: str) -> int:
    """Top keyword-match score for the phrase-lexicon retriever. Used to decide
    whether the deterministic offline fallback should emit a speculative gloss.
    """
    payload = search_phrase_lexicon(query, 10)
    return int(payload.get("top_score") or 0) if payload else 0
