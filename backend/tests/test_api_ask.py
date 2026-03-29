def test_ask_endpoint_returns_shape_and_limits_context(monkeypatch):
    # Import app after monkeypatching rag behavior to avoid heavy deps / external calls.
    from app import rag_engine

    monkeypatch.setattr(rag_engine, "MODE", "simple")

    ctx = [
        {"id": 1, "hadrami_word": "a", "arabic_fus7a": "A", "full_definition": "def"},
        {"id": 2, "hadrami_word": "b", "arabic_fus7a": "B", "full_definition": "def"},
        {"id": 3, "hadrami_word": "c", "arabic_fus7a": "C", "full_definition": "def"},
        {"id": 4, "hadrami_word": "d", "arabic_fus7a": "D", "full_definition": "def"},
    ]
    monkeypatch.setattr(rag_engine, "_keyword_context", lambda *_args, **_kwargs: ctx)

    # Call the endpoint function directly (TestClient is incompatible with the
    # currently installed httpx/starlette versions in this environment).
    from app.main import ask

    payload = ask("اختبار")
    assert set(payload.keys()) == {"question", "answer", "mode", "context"}
    assert payload["question"] == "اختبار"
    assert payload["mode"] == "simple"
    assert isinstance(payload["context"], list)
    assert len(payload["context"]) <= 3

