import json
import random
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
