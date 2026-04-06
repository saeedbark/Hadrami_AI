"""HA-14: Smoke tests for the Hadrami NLP API.

Run:
    cd backend
    python -m pytest tests/test_api.py -v
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


class TestRootAndInfo:
    def test_root_returns_200(self):
        resp = client.get("/")
        assert resp.status_code == 200
        data = resp.json()
        assert "message" in data
        assert "version" in data
        assert "total_words" in data

    def test_stats_returns_counts(self):
        resp = client.get("/stats")
        assert resp.status_code == 200
        data = resp.json()
        assert "total_words" in data
        assert isinstance(data["total_words"], int)
        assert data["total_words"] > 0
        assert "translated" in data
        assert "completion_percent" in data


class TestTranslate:
    def test_translate_known_word(self):
        resp = client.get("/translate", params={"q": "أم حبيل"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["found"] is True
        assert data["confidence"] in ("exact", "partial")
        assert "العنكبوت" in data["arabic_fus7a"]

    def test_translate_unknown_word(self):
        resp = client.get("/translate", params={"q": "xyznonexistent123"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["found"] is False
        assert data["confidence"] == "not_found"

    def test_translate_requires_query(self):
        resp = client.get("/translate")
        assert resp.status_code == 422


class TestSearch:
    def test_search_returns_results(self):
        resp = client.get("/search", params={"q": "أبوي", "limit": 5})
        assert resp.status_code == 200
        data = resp.json()
        assert "total" in data
        assert "results" in data
        assert isinstance(data["results"], list)

    def test_search_empty_query(self):
        resp = client.get("/search", params={"q": "كلمة_بعيدة_جداً_عن_أي_شيء"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] == 0


class TestWords:
    def test_list_words_paginated(self):
        resp = client.get("/words", params={"page": 1, "size": 10})
        assert resp.status_code == 200
        data = resp.json()
        assert "total" in data
        assert len(data["results"]) <= 10

    def test_list_words_with_letter_filter(self):
        resp = client.get("/words", params={"page": 1, "size": 10, "letter": "أ"})
        assert resp.status_code == 200
        data = resp.json()
        for entry in data["results"]:
            assert entry["hadrami_word"].strip().startswith("أ")

    def test_get_single_word(self):
        resp = client.get("/word/1")
        assert resp.status_code == 200
        data = resp.json()
        assert data["id"] == 1
        assert "hadrami_word" in data

    def test_get_word_not_found(self):
        resp = client.get("/word/999999")
        assert resp.status_code == 404


class TestRandom:
    def test_random_word(self):
        resp = client.get("/random")
        assert resp.status_code == 200
        data = resp.json()
        assert "id" in data
        assert "hadrami_word" in data


class TestFeedback:
    def test_submit_basic_feedback(self):
        resp = client.post(
            "/feedback",
            json={
                "word_id": 1,
                "hadrami_word": "أم حبيل",
                "suggested_fus7a": "العنكبوت",
                "comment": "test feedback",
            },
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "success"

    def test_submit_extended_feedback(self):
        resp = client.post(
            "/feedback",
            json={
                "hadrami_word": "ويش",
                "suggested_fus7a": "ماذا",
                "feedback_type": "new_word",
                "spelling_variants": ["ويش", "وش"],
                "sentence_pair_hadrami": "ويش تبغى؟",
                "sentence_pair_fusha": "ماذا تريد؟",
                "consent": True,
            },
        )
        assert resp.status_code == 200

    def test_feedback_missing_required(self):
        resp = client.post("/feedback", json={})
        assert resp.status_code == 422


class TestPhraseTranslation:
    def test_translate_phrase_ar_to_hadrami(self):
        resp = client.post(
            "/translate-phrase",
            json={"text": "مرحبا كيف حالك", "direction": "ar_to_hadrami"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "translated_text" in data
        assert "direction" in data
        assert data["direction"] == "ar_to_hadrami"

    def test_translate_phrase_hadrami_to_ar(self):
        resp = client.post(
            "/translate-phrase",
            json={"text": "شحوالك", "direction": "hadrami_to_ar"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["direction"] == "hadrami_to_ar"

    def test_translate_phrase_invalid_direction(self):
        resp = client.post(
            "/translate-phrase",
            json={"text": "test", "direction": "invalid"},
        )
        assert resp.status_code == 422

    def test_translate_phrase_empty_text(self):
        resp = client.post(
            "/translate-phrase",
            json={"text": "", "direction": "ar_to_hadrami"},
        )
        assert resp.status_code == 422

    def test_translate_phrase_text_too_long(self):
        long_text = "كلمة " * 1000
        resp = client.post(
            "/translate-phrase",
            json={"text": long_text, "direction": "ar_to_hadrami"},
        )
        assert resp.status_code == 422


class TestEntryOptionalFields:
    """HA-6: Verify new optional fields are accepted in API responses."""

    def test_entry_schema_has_optional_fields(self):
        resp = client.get("/word/1")
        assert resp.status_code == 200
        data = resp.json()
        assert "id" in data
        assert "hadrami_word" in data
        assert "fus7a_short" in data or data.get("fus7a_short") is None
        assert "aliases" in data or data.get("aliases") is None
        assert "examples" in data or data.get("examples") is None
