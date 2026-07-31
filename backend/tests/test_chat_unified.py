"""Tests for the unified ``/chat`` dispatcher.

The chat endpoint now merges ``/ask`` and dialect-conversion behaviour. We verify:

* The intent classifier maps the spec's TYPE 1–5 examples correctly.
* ``get_chat_answer`` passes ``HADRAMI_SYSTEM_PROMPT`` to Gemini and threads
  the ``intent`` / ``suggest_word`` / ``answer_source`` fields through.
* When retrieval is weak for a word/define/convert intent, the dispatcher
  short-circuits to the unknown-word block without calling Gemini.

All tests stub Supabase + Gemini so the suite stays hermetic.
"""

from __future__ import annotations

from typing import Any

import pytest

from app.rag import pipeline
from app.rag.system_prompt import HADRAMI_SYSTEM_PROMPT, intent_for


# ---------------------------------------------------------------------------
# 1. Intent classifier — table-driven
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "question,expected",
    [
        # TYPE 1 — single word
        ("بغية", "word"),
        ("أم حبيل", "word"),
        # TYPE 2 — explicit conversion directive (user's own wording)
        ("ترجم: إكس على كلامه", "convert"),
        ("translate this sentence to fusha", "convert"),
        # TYPE 3 — definition
        ("ما معنى أمبوه؟", "define"),
        ("اشرح كلمة بانه", "define"),
        # TYPE 4 — concept / semantic search
        ("أداة لفك الصواميل", "semantic"),
        ("كلمة تعني التريث", "semantic"),
        # TYPE 5 — generic question
        ("هل كلمة باير تستخدم للناس؟", "qa"),
        ("كيف أقول مرحبا بالحضرمية", "qa"),
        # multi-word free text without explicit instruction → convert fallback
        ("أبوي قال لي إبط في شغلك لا تستعجل", "convert"),
        # empty
        ("", "qa"),
    ],
)
def test_intent_classifier(question: str, expected: str) -> None:
    assert intent_for(question) == expected


# ---------------------------------------------------------------------------
# 2. get_chat_answer wires the system prompt + new fields
# ---------------------------------------------------------------------------

def _stub_retrieval(monkeypatch: pytest.MonkeyPatch, *, hits: list[dict]) -> None:
    """Replace retrieval + keyword-score helpers with deterministic stubs."""
    monkeypatch.setattr(pipeline, "retrieve_rag_context", lambda q: (hits, hits))
    monkeypatch.setattr(pipeline, "retrieve_phrase_context", lambda q: (hits, hits))
    monkeypatch.setattr(
        pipeline,
        "expanded_keyword_context",
        lambda q, top_k=8: {"results": hits, "top_score": 100 if hits else 0},
    )
    monkeypatch.setattr(pipeline, "phrase_top_score", lambda q: 100 if hits else 0)


def test_chat_qa_passes_system_prompt(monkeypatch: pytest.MonkeyPatch) -> None:
    """A plain question routes through the qa path with HADRAMI_SYSTEM_PROMPT."""
    captured: dict[str, Any] = {}

    def fake_gemini(prompt: str, api_key: str, *args: Any, **kwargs: Any) -> str:
        captured["prompt"] = prompt
        captured["system_instruction"] = kwargs.get("system_instruction")
        return "إجابة من النموذج"

    _stub_retrieval(
        monkeypatch,
        hits=[
            {
                "id": 62,
                "word_vocalized": "باير",
                "fusha_equivalent": "فاشل",
                "definition": "شخص فاشل أو سلعة كاسدة",
                "match_score": 100,
            }
        ],
    )
    monkeypatch.setattr(pipeline, "gemini_generate", fake_gemini)
    monkeypatch.setattr(pipeline, "is_gemini_unavailable", lambda r: False)
    monkeypatch.setattr(pipeline, "gemini_api_key", lambda: "stub-key")

    result = pipeline.get_chat_answer("هل كلمة باير تستخدم للناس؟", history=[])

    assert captured["system_instruction"] == HADRAMI_SYSTEM_PROMPT
    assert result["intent"] == "qa"
    assert result["suggest_word"] is False
    assert result["answer_source"] == "model"
    assert result["reply"] == "إجابة من النموذج"


def test_chat_conversion_uses_phrase_retrieval(monkeypatch: pytest.MonkeyPatch) -> None:
    """A conversion directive routes through phrase retrieval + conversion prompt."""
    calls: dict[str, int] = {"phrase": 0, "rag": 0}

    def fake_phrase(q: str) -> tuple[list[dict], list[dict]]:
        calls["phrase"] += 1
        hits = [
            {
                "id": 1,
                "word_vocalized": "إكس",
                "fusha_equivalent": "تجاهل",
                "definition": "اترك ولا تردّ",
                "match_score": 100,
            }
        ]
        return hits, hits

    def fake_rag(q: str) -> tuple[list[dict], list[dict]]:
        calls["rag"] += 1
        return [], []

    monkeypatch.setattr(pipeline, "retrieve_phrase_context", fake_phrase)
    monkeypatch.setattr(pipeline, "retrieve_rag_context", fake_rag)
    monkeypatch.setattr(pipeline, "phrase_top_score", lambda q: 100)
    monkeypatch.setattr(
        pipeline, "expanded_keyword_context", lambda q, top_k=8: {"results": [], "top_score": 0}
    )
    monkeypatch.setattr(
        pipeline, "gemini_generate", lambda *a, **kw: "تجاهَل كلامه"
    )
    monkeypatch.setattr(pipeline, "is_gemini_unavailable", lambda r: False)
    monkeypatch.setattr(pipeline, "gemini_api_key", lambda: "stub-key")

    result = pipeline.get_chat_answer("ترجم: إكس على كلامه", history=[])

    assert calls["phrase"] == 1, "convert intent must use phrase retrieval"
    assert calls["rag"] == 0, "convert intent must NOT use ask retrieval"
    assert result["intent"] == "convert"
    assert result["suggest_word"] is False


# ---------------------------------------------------------------------------
# 3. Suggest-word short-circuit
# ---------------------------------------------------------------------------

def test_chat_unknown_word_short_circuits_to_suggest(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Empty retrieval + word/define/convert intent emits suggest block, no LLM."""
    gemini_called = {"n": 0}

    def fake_gemini(*a: Any, **kw: Any) -> str:
        gemini_called["n"] += 1
        return "should not be called"

    _stub_retrieval(monkeypatch, hits=[])
    monkeypatch.setattr(pipeline, "gemini_generate", fake_gemini)
    monkeypatch.setattr(pipeline, "is_gemini_unavailable", lambda r: False)
    monkeypatch.setattr(pipeline, "gemini_api_key", lambda: "stub-key")

    result = pipeline.get_chat_answer("بامحقب", history=[])

    assert gemini_called["n"] == 0
    assert result["suggest_word"] is True
    assert result["answer_source"] == "lexicon"
    assert "هذه الكلمة غير موجودة في القاموس الحالي" in result["reply"]
    assert "بامحقب" in result["reply"]
    assert "⚠️ كلمات غير موجودة في القاموس" in result["reply"]


def test_chat_qa_with_no_hits_does_not_short_circuit(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """A generic question with no retrieval still calls Gemini; the system
    prompt is responsible for the unknown-word block, not the dispatcher."""
    captured: dict[str, Any] = {}

    def fake_gemini(prompt: str, api_key: str, *a: Any, **kw: Any) -> str:
        captured["called"] = True
        return "نموذجي"

    _stub_retrieval(monkeypatch, hits=[])
    monkeypatch.setattr(pipeline, "gemini_generate", fake_gemini)
    monkeypatch.setattr(pipeline, "is_gemini_unavailable", lambda r: False)
    monkeypatch.setattr(pipeline, "gemini_api_key", lambda: "stub-key")

    result = pipeline.get_chat_answer("كيف حالكم اليوم؟", history=[])

    assert captured.get("called") is True
    assert result["intent"] == "qa"
