import types


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


def test_get_rag_answer_local_ollama_success(monkeypatch):
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
    monkeypatch.setattr(rag_engine, "_keyword_context", lambda *_args, **_kwargs: ctx)
    monkeypatch.setattr(rag_engine, "_local_rag", rag_engine.LocalRAG())

    # Make vector_search deterministic and avoid Chroma/embeddings.
    monkeypatch.setattr(rag_engine._local_rag, "vector_search", lambda *_a, **_k: ctx)

    class _Resp:
        status_code = 200

        def json(self):
            return {"response": "الإجابة من النموذج"}

    def _fake_post(_url, json=None, timeout=None):  # noqa: ARG001
        return _Resp()

    monkeypatch.setattr(rag_engine, "OLLAMA_URL", "http://localhost:11434")
    monkeypatch.setattr(rag_engine, "OLLAMA_MODEL", "tinyllama")

    fake_requests = types.SimpleNamespace(post=_fake_post)
    monkeypatch.setitem(__import__("sys").modules, "requests", fake_requests)

    out = rag_engine.get_rag_answer("ما معنى ويش؟")
    assert out["mode"] == "local_ollama"
    assert out["answer"] == "الإجابة من النموذج"
    assert out["context"] == ctx


def test_get_rag_answer_local_ollama_unavailable_falls_back(monkeypatch):
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
    monkeypatch.setattr(rag_engine, "_keyword_context", lambda *_args, **_kwargs: ctx)
    monkeypatch.setattr(rag_engine, "_local_rag", rag_engine.LocalRAG())
    monkeypatch.setattr(rag_engine._local_rag, "vector_search", lambda *_a, **_k: ctx)

    def _fake_post(_url, json=None, timeout=None):  # noqa: ARG001
        raise RuntimeError("no ollama")

    fake_requests = types.SimpleNamespace(post=_fake_post)
    monkeypatch.setitem(__import__("sys").modules, "requests", fake_requests)

    out = rag_engine.get_rag_answer("ما معنى ويش؟")
    # Code explicitly returns simple mode on Ollama failure.
    assert out["mode"] == "simple"
    assert out["answer"] == "ماذا"
    assert out["context"] == ctx

