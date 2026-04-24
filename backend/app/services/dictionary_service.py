"""Dictionary service -- all read queries go through Supabase (PostgREST).

Scoring / ranking logic that cannot be expressed as pure SQL is done
client-side on the (small) result sets returned by the DB.
"""

from __future__ import annotations

import json
import random
import re
from typing import Any, Optional

from ..core.config import FEEDBACK_FILE
from ..core.data_store import (
    TABLE,
    _SELECT_COLS,
    _execute_with_retry,
    count_rows,
    fetch_all,
    fetch_by_id,
    get_client,
    rpc_match_entries,
    rpc_search_entries_expanded,
)
from ..schemas import TranslateResponse

_AR_LETTER_ORDER = (
    "أ", "إ", "آ", "ا", "ب", "ت", "ث", "ج", "ح", "خ",
    "د", "ذ", "ر", "ز", "س", "ش", "ص", "ض", "ط", "ظ",
    "ع", "غ", "ف", "ق", "ك", "ل", "م", "ن", "ه", "و",
    "ي", "ء", "ؤ", "ئ", "ة", "ى",
)


def _section_sort_key(letter: str) -> tuple[int, str]:
    try:
        return (_AR_LETTER_ORDER.index(letter[0]), letter)
    except (ValueError, IndexError):
        return (len(_AR_LETTER_ORDER), letter)


def _normalize_alef(text: str) -> str:
    for c in ("أ", "إ", "آ"):
        text = text.replace(c, "ا")
    return text


def _entry_match_score(entry: dict[str, Any], clean: str, norm: str) -> int:
    word = (entry.get("word_vocalized") or "").strip()
    word_clean = (entry.get("word_clean") or "").strip()
    fusha = (entry.get("fusha_equivalent") or "").strip()
    definition = (entry.get("definition") or "").strip()
    synonyms = entry.get("synonyms")
    syn_values = [a.strip() for a in synonyms if isinstance(a, str) and a.strip()] if isinstance(synonyms, list) else []

    if word == clean or word_clean == norm or clean in syn_values or norm in syn_values:
        return 100
    if clean in word or norm in word_clean or any(clean in a or norm in a for a in syn_values):
        return 80
    if word and word in clean:
        return 70
    if clean in fusha:
        return 60
    if clean in definition:
        return 40
    return 0


# ---------------------------------------------------------------------------
# Public service functions
# ---------------------------------------------------------------------------

def get_sections() -> dict[str, Any]:
    """Group headwords by first character for browse-by-letter sections."""
    rows = fetch_all("word_vocalized")
    counts: dict[str, int] = {}
    for row in rows:
        word = (row.get("word_vocalized") or "").strip()
        if not word:
            continue
        key = word[0]
        counts[key] = counts.get(key, 0) + 1
    sections = [{"letter": letter, "word_count": n} for letter, n in counts.items()]
    sections.sort(key=lambda row: _section_sort_key(row["letter"]))
    return {"sections": sections}


def get_stats() -> dict[str, Any]:
    rows = fetch_all(
        "id, fusha_equivalent, pos, tags, proverbs"
    )
    total = len(rows)
    with_fusha = sum(1 for r in rows if (r.get("fusha_equivalent") or "").strip())

    pos_counts: dict[str, int] = {}
    tag_counts: dict[str, int] = {}
    proverb_count = 0
    for entry in rows:
        pos = entry.get("pos") or "Unknown"
        pos_counts[pos] = pos_counts.get(pos, 0) + 1
        tags = entry.get("tags")
        if isinstance(tags, list):
            for tag in tags:
                if isinstance(tag, str) and tag.strip():
                    tag_counts[tag.strip()] = tag_counts.get(tag.strip(), 0) + 1
        pr = entry.get("proverbs")
        if isinstance(pr, list):
            proverb_count += len(pr)

    return {
        "total_words": total,
        "translated": with_fusha,
        "pending": total - with_fusha,
        "completion_percent": round(with_fusha / total * 100, 1) if total else 0,
        "by_pos": pos_counts,
        "by_tag": tag_counts,
        "total_proverbs": proverb_count,
    }


def translate(query: str) -> TranslateResponse:
    clean = query.strip()
    norm = _normalize_alef(clean)

    resp = (
        get_client().table(TABLE).select(_SELECT_COLS)
        .eq("word_vocalized", clean)
        .limit(1)
        .execute()
    )
    if resp.data:
        e = resp.data[0]
        return TranslateResponse(
            found=True,
            word_vocalized=e["word_vocalized"],
            fusha_equivalent=e.get("fusha_equivalent", ""),
            definition=e.get("definition", ""),
            confidence="exact",
        )

    resp = (
        get_client().table(TABLE).select(_SELECT_COLS)
        .eq("word_clean", norm)
        .limit(1)
        .execute()
    )
    if resp.data:
        e = resp.data[0]
        return TranslateResponse(
            found=True,
            word_vocalized=e["word_vocalized"],
            fusha_equivalent=e.get("fusha_equivalent", ""),
            definition=e.get("definition", ""),
            confidence="exact",
        )

    pattern = f"%{clean}%"
    resp = (
        get_client().table(TABLE).select(_SELECT_COLS)
        .or_(f"word_vocalized.ilike.{pattern},word_clean.ilike.{pattern}")
        .limit(1)
        .execute()
    )
    if resp.data:
        e = resp.data[0]
        return TranslateResponse(
            found=True,
            word_vocalized=e["word_vocalized"],
            fusha_equivalent=e.get("fusha_equivalent", ""),
            definition=e.get("definition", ""),
            confidence="partial",
        )

    resp = (
        get_client().table(TABLE).select(_SELECT_COLS)
        .ilike("definition", pattern)
        .limit(1)
        .execute()
    )
    if resp.data:
        e = resp.data[0]
        return TranslateResponse(
            found=True,
            word_vocalized=e["word_vocalized"],
            fusha_equivalent=e.get("fusha_equivalent", ""),
            definition=e.get("definition", ""),
            confidence="partial",
        )

    return TranslateResponse(
        found=False,
        word_vocalized=clean,
        fusha_equivalent="",
        definition="الكلمة غير موجودة في القاموس",
        confidence="not_found",
    )


def search(query: str, limit: int) -> dict[str, Any]:
    """Keyword search with client-side relevance scoring."""
    clean = query.strip()
    norm = _normalize_alef(clean)
    try:
        rows = rpc_search_entries_expanded(clean, match_count=max(limit * 3, limit))
        if rows:
            top_score = max(int(r.get("match_score") or 0) for r in rows)
            return {"total": len(rows), "results": rows[:limit], "top_score": top_score}
    except Exception:
        pass

    pattern = f"%{clean}%"

    resp = (
        get_client().table(TABLE).select(_SELECT_COLS)
        .or_(
            f"word_vocalized.ilike.{pattern},"
            f"word_clean.ilike.{pattern},"
            f"fusha_equivalent.ilike.{pattern},"
            f"definition.ilike.{pattern}"
        )
        .limit(limit * 3)
        .execute()
    )
    candidates = resp.data or []

    scored: list[tuple[int, dict[str, Any]]] = []
    for entry in candidates:
        score = _entry_match_score(entry, clean, norm)
        if score > 0:
            scored.append((score, {**entry, "match_score": score}))

    scored.sort(key=lambda item: -item[0])
    top = [item[1] for item in scored[:limit]]
    return {"total": len(scored), "results": top, "top_score": scored[0][0] if scored else 0}


def semantic_search(
    query_embedding: list[float],
    match_threshold: float = 0.3,
    match_count: int = 10,
) -> list[dict[str, Any]]:
    """Vector similarity search via the ``match_entries`` Postgres RPC."""
    return rpc_match_entries(query_embedding, match_threshold, match_count)


# ---------------------------------------------------------------------------
# Expanded / phrase search (used by RAG layer)
# ---------------------------------------------------------------------------

_AR_QUESTION_FRAG = re.compile(
    r"ما\s*معنى|مامعنى|ما\s*هو\s*معنى|وش\s*يعني|يعني\s*ايش|ايش\s*يعني|معنى\s*كلمة|^كلمة\s*",
    re.IGNORECASE,
)


def _extract_search_candidates(raw: str) -> list[str]:
    q = raw.strip()
    if not q:
        return []
    stripped = _AR_QUESTION_FRAG.sub(" ", q)
    parts = re.split(r"[\s،,.;:!؟?]+", stripped)
    out: list[str] = []
    for p in parts:
        t = p.strip()
        if len(t) >= 2:
            out.append(t)
        if t.startswith("ال") and len(t) > 3:
            out.append(t[2:])
    if q not in out:
        out.insert(0, q)
    seen: set[str] = set()
    uniq: list[str] = []
    for x in out:
        if x and x not in seen:
            seen.add(x)
            uniq.append(x)
    return uniq


def search_expanded(query: str, limit: int) -> dict[str, Any]:
    """Merge keyword search across the full question and extracted tokens."""
    try:
        rows = rpc_search_entries_expanded(query, match_count=limit)
        if rows:
            top_score = max(int(r.get("match_score") or 0) for r in rows)
            return {"total": len(rows), "results": rows[:limit], "top_score": top_score}
    except Exception:
        pass

    seen_ids: set[int] = set()
    merged: list[dict[str, Any]] = []
    top_score = 0
    inner = max(limit, 12)
    for cand in _extract_search_candidates(query):
        payload = search(cand, limit=inner)
        top_score = max(top_score, int(payload.get("top_score") or 0))
        for entry in payload["results"]:
            eid = entry["id"]
            if eid not in seen_ids:
                seen_ids.add(eid)
                merged.append(entry)
            if len(merged) >= limit:
                return {"total": len(merged), "results": merged, "top_score": top_score}
    return {"total": len(merged), "results": merged, "top_score": top_score}


_MIN_SUBWORD_LEN = 3


def _score_phrase_token_match(cand: str, entry: dict[str, Any]) -> int:
    cand = cand.strip()
    if len(cand) < 2:
        return 0
    word = (entry.get("word_vocalized") or "").strip()
    fusha = (entry.get("fusha_equivalent") or "").strip()
    definition = (entry.get("definition") or "").strip()

    if word == cand or fusha == cand:
        return 100
    if cand in word and len(cand) >= 2:
        return 88
    if word in cand:
        if len(word) < _MIN_SUBWORD_LEN:
            return 0
        return 78
    if len(cand) >= 4 and cand in fusha:
        return 62
    if len(cand) >= 5 and cand in definition:
        return 32
    return 0


def search_phrase_lexicon(query: str, limit: int) -> dict[str, Any]:
    """Lexicon hits for phrase translation -- token-wise scoring."""
    candidates = _extract_search_candidates(query)
    all_entries: list[dict[str, Any]] = []
    seen_ids: set[int] = set()

    for cand in candidates:
        rows = search(cand, limit=limit * 2)["results"]
        for r in rows:
            if r["id"] not in seen_ids:
                seen_ids.add(r["id"])
                all_entries.append(r)

    best: dict[int, tuple[int, dict[str, Any]]] = {}
    for cand in candidates:
        for entry in all_entries:
            sc = _score_phrase_token_match(cand, entry)
            if sc <= 0:
                continue
            eid = entry["id"]
            prev = best.get(eid)
            if prev is None or sc > prev[0]:
                best[eid] = (sc, entry)

    ranked = sorted(best.values(), key=lambda x: -x[0])
    merged = [e for _, e in ranked[:limit]]
    return {"total": len(merged), "results": merged}


def get_word(word_id: int) -> Optional[dict[str, Any]]:
    return fetch_by_id(word_id)


def list_words(
    page: int,
    size: int,
    letter: Optional[str] = None,
    pos: Optional[str] = None,
    region: Optional[str] = None,
    tag: Optional[str] = None,
) -> dict[str, Any]:
    start = (page - 1) * size
    end = start + size - 1

    def _build(c):
        q = c.table(TABLE).select(_SELECT_COLS, count="exact")
        if letter:
            q = q.ilike("word_vocalized", f"{letter}%")
        if pos:
            q = q.eq("pos", pos)
        if region:
            q = q.eq("region", region)
        if tag:
            q = q.contains("tags", f'["{tag}"]')
        return q.range(start, end)

    resp = _execute_with_retry(_build)
    return {"total": resp.count or 0, "results": resp.data or []}


def _load_feedback() -> list[dict[str, Any]]:
    if not FEEDBACK_FILE.exists():
        return []
    try:
        with open(FEEDBACK_FILE, encoding="utf-8") as file:
            data = json.load(file)
        if isinstance(data, list):
            return data
    except (json.JSONDecodeError, OSError):
        pass
    return []


def save_feedback(payload: dict[str, Any]) -> None:
    feedbacks = _load_feedback()
    feedbacks.append(payload)
    FEEDBACK_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(FEEDBACK_FILE, "w", encoding="utf-8") as file:
        json.dump(feedbacks, file, ensure_ascii=False, indent=2)


def random_word() -> Optional[dict[str, Any]]:
    total = count_rows()
    if total == 0:
        return None
    offset = random.randint(0, total - 1)
    resp = _execute_with_retry(
        lambda c, o=offset: c.table(TABLE).select(_SELECT_COLS).range(o, o)
    )
    return resp.data[0] if resp.data else None
