def test_get_rag_answer_simple_no_context(monkeypatch):
    from app import rag_engine

    monkeypatch.setattr(rag_engine, "MODE", "simple")
    monkeypatch.setattr(rag_engine, "_keyword_context", lambda *_args, **_kwargs: [])

    out = rag_engine.get_rag_answer("سؤال")
    assert out["mode"] == "simple"
    assert out["answer"]
    assert out["context"] == []


def test_get_rag_answer_simple_with_context(monkeypatch):
    from app import rag_engine

    ctx = [
        {
            "id": 1,
            "hadrami_word": "ويش",
            "arabic_fus7a": "ماذا",
            "full_definition": "تعني ماذا",
        }
    ]
    monkeypatch.setattr(rag_engine, "MODE", "simple")
    monkeypatch.setattr(rag_engine, "_keyword_context", lambda *_args, **_kwargs: ctx)

    out = rag_engine.get_rag_answer("ويش")
    assert out["mode"] == "simple"
    assert out["answer"] == "ماذا"
    assert out["context"] == ctx


def test_get_rag_answer_local_gemini_success(monkeypatch):
    from app import rag_engine

    ctx = [
        {
            "id": 1,
            "hadrami_word": "ويش",
            "arabic_fus7a": "ماذا",
            "full_definition": "تعني ماذا",
        }
    ]
    monkeypatch.setattr(rag_engine, "MODE", "local")
    monkeypatch.setattr(rag_engine, "_expanded_keyword_context", lambda *_args, **_kwargs: ctx)
    monkeypatch.setattr(rag_engine, "_local_rag", rag_engine.LocalRAG())
    monkeypatch.setattr(rag_engine._local_rag, "chroma_search", lambda *_a, **_k: None)
    monkeypatch.setattr(rag_engine, "_gemini_api_key", lambda: "test-key")

    def _fake_gemini_generate(_prompt, _api_key):  # noqa: ARG001
        return "الإجابة من النموذج"

    monkeypatch.setattr(rag_engine, "_gemini_generate", _fake_gemini_generate)

    out = rag_engine.get_rag_answer("ما معنى ويش؟")
    assert out["mode"] == "local_gemini"
    assert out["answer"] == "الإجابة من النموذج"
    assert out["context"] == ctx


def test_get_rag_answer_local_gemini_unavailable_falls_back(monkeypatch):
    from app import rag_engine

    ctx = [
        {
            "id": 1,
            "hadrami_word": "ويش",
            "arabic_fus7a": "ماذا",
            "full_definition": "تعني ماذا",
        }
    ]
    monkeypatch.setattr(rag_engine, "MODE", "local")
    monkeypatch.setattr(rag_engine, "_expanded_keyword_context", lambda *_args, **_kwargs: ctx)
    monkeypatch.setattr(rag_engine, "_local_rag", rag_engine.LocalRAG())
    monkeypatch.setattr(rag_engine._local_rag, "chroma_search", lambda *_a, **_k: None)

    def _fake_gemini_generate(_prompt, _api_key):  # noqa: ARG001
        return "Gemini not available: network error"

    monkeypatch.setattr(rag_engine, "_gemini_generate", _fake_gemini_generate)

    out = rag_engine.get_rag_answer("ما معنى ويش؟")
    assert out["mode"] == "simple"
    assert out["answer"] == "ماذا"
    assert out["context"] == ctx

