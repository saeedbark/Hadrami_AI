import json
import random
import re
from typing import Any, Optional

from ..core.config import FEEDBACK_FILE
from ..core.data_store import ENTRIES
from ..schemas import TranslateResponse


def get_stats() -> dict[str, Any]:
    total = len(ENTRIES)
    with_fus7a = sum(1 for entry in ENTRIES if entry.get("arabic_fus7a", "").strip())
    return {
        "total_words": total,
        "translated": with_fus7a,
        "pending": total - with_fus7a,
        "completion_percent": round(with_fus7a / total * 100, 1) if total else 0,
    }


def translate(query: str) -> TranslateResponse:
    clean_query = query.strip()

    for entry in ENTRIES:
        if entry["hadrami_word"].strip() == clean_query:
            return TranslateResponse(
                found=True,
                hadrami_word=entry["hadrami_word"],
                arabic_fus7a=entry["arabic_fus7a"],
                full_definition=entry["full_definition"],
                confidence="exact",
            )

    for entry in ENTRIES:
        word = entry["hadrami_word"].strip()
        if clean_query in word or word in clean_query:
            return TranslateResponse(
                found=True,
                hadrami_word=entry["hadrami_word"],
                arabic_fus7a=entry["arabic_fus7a"],
                full_definition=entry["full_definition"],
                confidence="partial",
            )

    for entry in ENTRIES:
        if clean_query in entry.get("full_definition", ""):
            return TranslateResponse(
                found=True,
                hadrami_word=entry["hadrami_word"],
                arabic_fus7a=entry["arabic_fus7a"],
                full_definition=entry["full_definition"],
                confidence="partial",
            )

    return TranslateResponse(
        found=False,
        hadrami_word=clean_query,
        arabic_fus7a="",
        full_definition="الكلمة غير موجودة في القاموس",
        confidence="not_found",
    )


def search(query: str, limit: int) -> dict[str, Any]:
    clean_query = query.strip()
    scored: list[tuple[int, dict[str, Any]]] = []

    for entry in ENTRIES:
        score = 0
        word = entry["hadrami_word"]
        fus7a = entry.get("arabic_fus7a", "")
        definition = entry.get("full_definition", "")

        if word == clean_query:
            score = 100
        elif clean_query in word:
            score = 80
        elif word in clean_query:
            score = 70
        elif clean_query in fus7a:
            score = 60
        elif clean_query in definition:
            score = 40

        if score > 0:
            scored.append((score, entry))

    scored.sort(key=lambda item: -item[0])
    top = [item[1] for item in scored[:limit]]
    return {"total": len(scored), "results": top}


_AR_QUESTION_FRAG = re.compile(
    r"ما\s*معنى|مامعنى|ما\s*هو\s*معنى|وش\s*يعني|يعني\s*ايش|ايش\s*يعني|معنى\s*كلمة|^كلمة\s*",
    re.IGNORECASE,
)


def _extract_search_candidates(raw: str) -> list[str]:
    """Split questions like 'ما معنى الزقر' into tokens so 'الزقر' can match 'الزقره'."""
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
    """Merge keyword search across the full question and extracted tokens (higher recall for /ask)."""
    seen_ids: set[int] = set()
    merged: list[dict[str, Any]] = []
    inner = max(limit, 12)
    for cand in _extract_search_candidates(query):
        for entry in search(cand, limit=inner)["results"]:
            eid = entry["id"]
            if eid not in seen_ids:
                seen_ids.add(eid)
                merged.append(entry)
            if len(merged) >= limit:
                return {"total": len(merged), "results": merged}
    return {"total": len(merged), "results": merged}


# For long phrases: `search()` matched 2-codepoint headwords inside unrelated tokens (e.g. "أح" in "يحكيلنا").
# Allow 3+ codepoint headwords as substrings of a token; block 1–2 (noise).
_MIN_SUBWORD_LEN = 3


def _score_phrase_token_match(cand: str, entry: dict[str, Any]) -> int:
    """Stricter matching per whitespace token — reduces garbage RAG for /translate-phrase."""
    cand = cand.strip()
    if len(cand) < 2:
        return 0
    word = (entry.get("hadrami_word") or "").strip()
    fus7a = (entry.get("arabic_fus7a") or "").strip()
    definition = (entry.get("full_definition") or "").strip()

    if word == cand or fus7a == cand:
        return 100
    if cand in word and len(cand) >= 2:
        return 88
    if word in cand:
        if len(word) < _MIN_SUBWORD_LEN:
            return 0
        return 78
    if len(cand) >= 4 and cand in fus7a:
        return 62
    if len(cand) >= 5 and cand in definition:
        return 32
    return 0


def search_phrase_lexicon(query: str, limit: int) -> dict[str, Any]:
    """Lexicon hits for phrase translation: token-wise scoring, no short substring noise."""
    best: dict[int, tuple[int, dict[str, Any]]] = {}
    for cand in _extract_search_candidates(query):
        for entry in ENTRIES:
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
    for entry in ENTRIES:
        if entry["id"] == word_id:
            return entry
    return None


def list_words(page: int, size: int, letter: Optional[str] = None) -> dict[str, Any]:
    filtered = ENTRIES
    if letter:
        filtered = [entry for entry in ENTRIES if entry["hadrami_word"].strip().startswith(letter)]

    start = (page - 1) * size
    end = start + size
    return {"total": len(filtered), "results": filtered[start:end]}


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
    if not ENTRIES:
        return None
    return random.choice(ENTRIES)
