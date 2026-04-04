def test_translate_phrase_gemini_json(monkeypatch):
    from app.services import phrase_translation_service as pts

    ctx = [
        {
            "id": 1,
            "hadrami_word": "ويش",
            "arabic_fus7a": "ماذا",
            "full_definition": "تعني ماذا",
        }
    ]
    monkeypatch.setattr(pts, "MODE", "local")
    monkeypatch.setattr(pts, "retrieve_phrase_context", lambda _q: (ctx, ctx))
    monkeypatch.setattr(pts, "_gemini_api_key", lambda: "k")

    def _fake(_prompt, _api_key):  # noqa: ARG001
        return (
            '{"translated_text":"ويش صار؟","hadrami_spans":[{"start":0,"end":3,"surface":"ويش"}]}'
        )

    monkeypatch.setattr(pts, "_gemini_generate", _fake)

    out = pts.translate_phrase("ماذا حدث؟", "ar_to_hadrami")
    assert out["mode"] == "local_gemini"
    assert out["translated_text"] == "ويش صار؟"
    assert len(out["hadrami_spans"]) == 1
    assert out["hadrami_spans"][0]["start"] == 0
    assert out["hadrami_spans"][0]["end"] == 3
    assert len(out["context"]) == 1


def test_translate_phrase_spans_filtered_to_lexicon(monkeypatch):
    from app.services import phrase_translation_service as pts

    ctx = [
        {
            "id": 1,
            "hadrami_word": "ويش",
            "arabic_fus7a": "ماذا",
            "full_definition": "تعني ماذا",
        }
    ]
    monkeypatch.setattr(pts, "MODE", "local")
    monkeypatch.setattr(pts, "retrieve_phrase_context", lambda _q: (ctx, ctx))
    monkeypatch.setattr(pts, "_gemini_api_key", lambda: "k")

    def _fake(_prompt, _api_key):  # noqa: ARG001
        return (
            '{"translated_text":"ويش على","hadrami_spans":['
            '{"start":0,"end":3,"surface":"ويش"},'
            '{"start":4,"end":7,"surface":"على"}'
            "]}"
        )

    monkeypatch.setattr(pts, "_gemini_generate", _fake)

    out = pts.translate_phrase("ماذا على المائدة؟", "ar_to_hadrami")
    assert len(out["hadrami_spans"]) == 1
    assert out["hadrami_spans"][0]["surface"] == "ويش"


def test_translate_phrase_gemini_unavailable(monkeypatch):
    from app.services import phrase_translation_service as pts

    ctx: list = []
    monkeypatch.setattr(pts, "MODE", "local")
    monkeypatch.setattr(pts, "retrieve_phrase_context", lambda _q: (ctx, ctx))
    monkeypatch.setattr(pts, "_gemini_api_key", lambda: "")
    monkeypatch.setattr(pts, "_gemini_generate", lambda _p, _k: "Gemini not available: no key")

    out = pts.translate_phrase("اختبار", "hadrami_to_ar")
    assert out["mode"] == "error"
    assert out["hadrami_spans"] == []
