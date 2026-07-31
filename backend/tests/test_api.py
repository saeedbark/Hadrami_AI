"""End-to-end smoke tests for the Hadrami NLP API (new schema).

These tests hit the FastAPI app via TestClient and exercise the real Supabase
backend. They are skipped automatically when ``SUPABASE_URL`` is not configured,
which keeps the suite runnable in offline CI without secrets.

Run:
    cd backend
    python -m pytest tests/test_api.py -v
"""

from __future__ import annotations

import os
import pytest
from fastapi.testclient import TestClient

from app.main import app

_HAS_DB = bool(os.getenv("SUPABASE_URL") and os.getenv("SUPABASE_SERVICE_KEY"))
_HAS_GEMINI = bool(os.getenv("GEMINI_API_KEY"))

db_only = pytest.mark.skipif(not _HAS_DB, reason="SUPABASE credentials not set")
rag_only = pytest.mark.skipif(
    not (_HAS_DB and _HAS_GEMINI),
    reason="RAG tests require SUPABASE + GEMINI credentials",
)


@pytest.fixture(scope="module")
def client() -> TestClient:
    return TestClient(app)


# ---------------------------------------------------------------------------
# Root / health
# ---------------------------------------------------------------------------


@db_only
def test_root_returns_version_and_total(client: TestClient):
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert "message" in data
    assert "version" in data
    assert "total_words" in data
    assert isinstance(data["total_words"], int)
    assert data["total_words"] > 0


@db_only
def test_stats_returns_counts(client: TestClient):
    resp = client.get("/stats")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_words"] > 0
    assert 0.0 <= float(data["completion_percent"]) <= 100.0
    assert isinstance(data["by_pos"], dict)
    assert isinstance(data["by_tag"], dict)


# ---------------------------------------------------------------------------
# Interpret (single word)
# ---------------------------------------------------------------------------


@db_only
def test_interpret_known_word_returns_fusha(client: TestClient):
    resp = client.get("/interpret", params={"q": "أم حبيل"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is True
    assert data["confidence"] in ("exact", "partial")
    assert "العنكبوت" in data["fusha_equivalent"]


@db_only
def test_interpret_unknown_word_returns_not_found(client: TestClient):
    resp = client.get("/interpret", params={"q": "xyznonexistent123"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is False
    assert data["confidence"] == "not_found"


def test_interpret_requires_query(client: TestClient):
    resp = client.get("/interpret")
    assert resp.status_code == 422


# ---------------------------------------------------------------------------
# Search (keyword + expanded)
# ---------------------------------------------------------------------------


@db_only
def test_search_returns_results(client: TestClient):
    resp = client.get("/search", params={"q": "أبوي", "limit": 5})
    assert resp.status_code == 200
    data = resp.json()
    assert "total" in data and "results" in data
    assert isinstance(data["results"], list)
    for entry in data["results"]:
        assert "id" in entry
        assert "word_vocalized" in entry
        assert "fusha_equivalent" in entry


@db_only
def test_search_empty_returns_zero(client: TestClient):
    resp = client.get("/search", params={"q": "كلمة_بعيدة_جداً_عن_أي_شيء"})
    assert resp.status_code == 200
    assert resp.json()["total"] == 0


# ---------------------------------------------------------------------------
# Sections / words
# ---------------------------------------------------------------------------


@db_only
def test_sections_sum_matches_total(client: TestClient):
    secs = client.get("/sections").json()
    stats = client.get("/stats").json()
    total_from_sections = sum(s["word_count"] for s in secs["sections"])
    assert total_from_sections == stats["total_words"]


@db_only
def test_list_words_paginated_and_typed(client: TestClient):
    resp = client.get("/words", params={"page": 1, "size": 10})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["results"]) <= 10
    for e in data["results"]:
        assert "word_vocalized" in e
        assert "fusha_equivalent" in e


@db_only
def test_list_words_letter_filter_matches_prefix(client: TestClient):
    resp = client.get("/words", params={"page": 1, "size": 10, "letter": "أ"})
    assert resp.status_code == 200
    for e in resp.json()["results"]:
        assert (e.get("word_vocalized") or "").strip().startswith("أ")


@db_only
def test_get_single_word_has_schema_fields(client: TestClient):
    resp = client.get("/word/1")
    assert resp.status_code == 200
    e = resp.json()
    assert e["id"] == 1
    for key in ("word_vocalized", "word_clean", "fusha_equivalent", "definition"):
        assert key in e


def test_get_word_not_found(client: TestClient):
    resp = client.get("/word/999999")
    assert resp.status_code == 404


# ---------------------------------------------------------------------------
# Random
# ---------------------------------------------------------------------------


@db_only
def test_random_word_returns_entry(client: TestClient):
    resp = client.get("/random")
    assert resp.status_code == 200
    data = resp.json()
    assert "id" in data
    assert "word_vocalized" in data


# ---------------------------------------------------------------------------
# Feedback (Supabase-backed)
# ---------------------------------------------------------------------------


@db_only
def test_submit_basic_feedback_persists(client: TestClient):
    resp = client.post(
        "/feedback",
        json={
            "word_id": 1,
            "word_vocalized": "أم حبيل",
            "suggested_fusha": "العنكبوت",
            "comment": "pytest:smoke:auto",
            "feedback_type": "correction",
        },
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["status"] == "success"
    assert isinstance(data.get("id"), int)


@db_only
def test_submit_extended_feedback_all_fields(client: TestClient):
    resp = client.post(
        "/feedback",
        json={
            "word_vocalized": "ويش",
            "suggested_fusha": "ماذا",
            "feedback_type": "new_word",
            "spelling_variants": ["ويش", "وش"],
            "sentence_pair_hadrami": "ويش تبغى؟",
            "sentence_pair_fusha": "ماذا تريد؟",
            "comment": "pytest:smoke:auto",
            "consent": True,
        },
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "success"


def test_feedback_missing_required_422(client: TestClient):
    resp = client.post("/feedback", json={})
    assert resp.status_code == 422


# ---------------------------------------------------------------------------
# Phrase conversion (/convert-phrase)
# ---------------------------------------------------------------------------


@rag_only
def test_convert_phrase_ar_to_hadrami_returns_shape(client: TestClient):
    resp = client.post(
        "/convert-phrase",
        json={"text": "مرحبا كيف حالك", "direction": "ar_to_hadrami"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["direction"] == "ar_to_hadrami"
    assert "converted_text" in data
    assert "hadrami_spans" in data and isinstance(data["hadrami_spans"], list)
    assert "context" in data and isinstance(data["context"], list)


@rag_only
def test_convert_phrase_hadrami_to_ar_returns_shape(client: TestClient):
    resp = client.post(
        "/convert-phrase",
        json={"text": "شحوالك", "direction": "hadrami_to_ar"},
    )
    assert resp.status_code == 200
    assert resp.json()["direction"] == "hadrami_to_ar"


def test_convert_phrase_invalid_direction_422(client: TestClient):
    resp = client.post(
        "/convert-phrase",
        json={"text": "test", "direction": "invalid"},
    )
    assert resp.status_code == 422


def test_convert_phrase_empty_text_422(client: TestClient):
    resp = client.post(
        "/convert-phrase",
        json={"text": "", "direction": "ar_to_hadrami"},
    )
    assert resp.status_code == 422


def test_convert_phrase_too_long_422(client: TestClient):
    resp = client.post(
        "/convert-phrase",
        json={"text": "كلمة " * 1000, "direction": "ar_to_hadrami"},
    )
    assert resp.status_code == 422


# ---------------------------------------------------------------------------
# /ask (RAG) — the endpoint that the research paper is actually about
# ---------------------------------------------------------------------------


@rag_only
def test_ask_returns_grounded_shape(client: TestClient):
    resp = client.post("/ask", json={"q": "ما معنى أم حبيل؟"})
    assert resp.status_code == 200
    data = resp.json()
    assert "answer" in data and data["answer"].strip()
    assert "mode" in data
    assert data.get("answer_source") in (None, "model", "lexicon")
    assert isinstance(data.get("context", []), list)
    assert isinstance(data.get("hadrami_spans", []), list)


@rag_only
def test_ask_with_irrelevant_question_refuses_or_admits(client: TestClient):
    """Grounding test: asking about a completely unrelated topic must not
    hallucinate a dialectal translation.
    """
    resp = client.post(
        "/ask",
        json={"q": "اشرح نظرية النسبية العامة لآينشتاين بالتفصيل"},
    )
    assert resp.status_code == 200
    data = resp.json()
    answer_lower = data["answer"].lower()
    # Either the server returns an explicit "not in dictionary" style message,
    # or the context is empty (both are acceptable grounded behaviours).
    grounded = (
        not data.get("context")
        or "قاموس" in data["answer"]
        or "لم يُسترجَع" in data["answer"]
        or "لم يسترجع" in answer_lower
        or "غير متوفر" in data["answer"]
        or "لا يوجد" in data["answer"]
        or "المراجع" in data["answer"]
    )
    assert grounded, f"RAG hallucinated on out-of-domain query: {data['answer'][:200]}"


def test_ask_rejects_empty(client: TestClient):
    resp = client.post("/ask", json={"q": ""})
    assert resp.status_code == 422


# ---------------------------------------------------------------------------
# /chat (multi-turn RAG)
# ---------------------------------------------------------------------------


@rag_only
def test_chat_returns_reply_with_context(client: TestClient):
    resp = client.post(
        "/chat",
        json={
            "message": "ما معنى ويش؟",
            "history": [],
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "reply" in data and data["reply"].strip()
    assert "context" in data


# ---------------------------------------------------------------------------
# /semantic-search (vector RPC — only works when embeddings are backfilled)
# ---------------------------------------------------------------------------


@rag_only
def test_semantic_search_shape(client: TestClient):
    resp = client.get("/semantic-search", params={"q": "حشرة العنكبوت", "limit": 5})
    # Allow 200 even if embeddings are absent; result shape is what we check.
    # If the embedding service is unavailable, the backend returns 503 — also ok.
    assert resp.status_code in (200, 503)
    if resp.status_code == 200:
        data = resp.json()
        assert "results" in data and isinstance(data["results"], list)
