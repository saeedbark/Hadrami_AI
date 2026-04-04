from app.services.dictionary_service import _score_phrase_token_match, search_phrase_lexicon


def test_score_rejects_short_headword_as_substring_inside_token():
    entry = {"hadrami_word": "أح", "arabic_fus7a": "آه", "full_definition": "تعبير"}
    assert _score_phrase_token_match("يحكيلنا", entry) == 0


def test_score_exact_token_matches_headword():
    entry = {"hadrami_word": "ويش", "arabic_fus7a": "ماذا", "full_definition": "استفهام"}
    assert _score_phrase_token_match("ويش", entry) == 100


def test_score_allows_min_length_headword_as_substring_of_token():
    entry = {"hadrami_word": "ويش", "arabic_fus7a": "ماذا", "full_definition": "استفهام"}
    assert _score_phrase_token_match("ياويش", entry) > 0


def test_search_phrase_prefers_real_tokens_over_noise():
    q = "ماذا حدث عندك اليوم"
    out = search_phrase_lexicon(q, limit=20)
    surfaces = {e["hadrami_word"].strip() for e in out["results"]}
    assert "أح" not in surfaces
    assert "با" not in surfaces
