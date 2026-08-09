"""Hermetic unit tests for the phrase-lexicon scorer used by dialect conversion.

Regression coverage for a P0 outage (see docs/chat_testing.md): the keyword
branch of the RAG confidence gate was permanently dead because
``search_phrase_lexicon`` never returned a ``top_score`` key, and the token
scorer ignored Arabic normalization (diacritics / alef variants), so exact
content-word matches scored 0 while short stopword substrings scored high.

These tests monkeypatch ``dictionary_service.search`` (not Supabase), so they
run with no network/DB dependency.
"""

from __future__ import annotations

from typing import Any

import pytest

from app.services import dictionary_service


def _entry(
    entry_id: int,
    word_vocalized: str,
    word_clean: str,
    fusha_equivalent: str = "",
    definition: str = "",
) -> dict[str, Any]:
    return {
        "id": entry_id,
        "word_vocalized": word_vocalized,
        "word_clean": word_clean,
        "fusha_equivalent": fusha_equivalent,
        "definition": definition,
    }


# ---------------------------------------------------------------------------
# _score_phrase_token_match
# ---------------------------------------------------------------------------


def test_score_phrase_token_match_normalizes_alef_and_diacritics() -> None:
    """"ادحق" (undiacritized) must match its own entry stored as "إِدْحَق"."""
    entry = _entry(1, "إِدْحَق", "ادحق", fusha_equivalent="أسرِع")
    assert dictionary_service._score_phrase_token_match("ادحق", entry) == 100


def test_score_phrase_token_match_rejects_short_stopword_substring() -> None:
    """"لا" must not substring-match into an unrelated word like "طُلاب"."""
    entry = _entry(2, "طُلاب", "طلاب", fusha_equivalent="students")
    assert dictionary_service._score_phrase_token_match("لا", entry) == 0


def test_score_phrase_token_match_still_allows_real_subword_match() -> None:
    """A 3+ char candidate substring match still scores (regression guard for
    the new length gate not being overly strict)."""
    entry = _entry(3, "مدحرج", "مدحرج", fusha_equivalent="متدحرج")
    assert dictionary_service._score_phrase_token_match("دحرج", entry) == 88


# ---------------------------------------------------------------------------
# search_phrase_lexicon -> top_score wiring
# ---------------------------------------------------------------------------


def test_search_phrase_lexicon_returns_top_score(monkeypatch: pytest.MonkeyPatch) -> None:
    hit = _entry(4, "إِدْحَق", "ادحق", fusha_equivalent="أسرِع")

    def fake_search(cand: str, limit: int) -> dict[str, Any]:
        return {"total": 1, "results": [hit], "top_score": 100}

    monkeypatch.setattr(dictionary_service, "search", fake_search)

    payload = dictionary_service.search_phrase_lexicon("ادحق بسرعة", limit=8)

    assert "top_score" in payload
    assert payload["top_score"] == 100
    assert payload["results"][0]["id"] == 4


def test_search_phrase_lexicon_top_score_zero_when_no_hits(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def fake_search(cand: str, limit: int) -> dict[str, Any]:
        return {"total": 0, "results": [], "top_score": 0}

    monkeypatch.setattr(dictionary_service, "search", fake_search)

    payload = dictionary_service.search_phrase_lexicon("زنكوش", limit=8)

    assert payload["top_score"] == 0
    assert payload["results"] == []
