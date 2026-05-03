# Unified Hadrami Chat — Implementation & Test Notes

## Goal

Merge `/ask` and translation behaviour into `/chat` so the Flutter app's three
in-scope features (**main**, **chat**, **search**) talk to a single LLM
endpoint. The chat endpoint now auto-classifies each user message into one of
five intents and routes through the matching retrieval + prompt path, all
under one canonical Hadrami system prompt.

## Scope

| Flutter feature | Backend touchpoint | LLM? |
|---|---|---|
| **main** (home) | `/stats`, `/random`, `/sections`, `/words` | No — deterministic |
| **chat** | `/chat` (unified dispatcher) | Yes — this is where the work landed |
| **search** | `/search` (Postgres ilike + scoring) | No — deterministic |

`/ask` and `/translate-phrase` are **not removed**; the other Flutter modules
(`ask`, `phrase`) still call them and still work. They are simply no longer the
primary surface — anything new should go through `/chat`.

## What changed

### New file

- **`backend/app/rag/system_prompt.py`** — single source of truth for the
  Hadrami system prompt + the `intent_for()` classifier.

  | Intent | Trigger |
  |---|---|
  | `word` | One or two bare tokens, no punctuation |
  | `translate` | Explicit `ترجم / translate` directive, OR multi-word free text without another marker |
  | `define` | `ما معنى / اشرح / what does X mean / define …` |
  | `semantic` | `كلمة تعني… / أداة ل… / word for…` (concept-without-word) |
  | `qa` | `ما / هل / كيف / متى / من / أين / لماذا` openers, or trailing `؟` |

### Edited files

- **`app/rag/generation.py`** — `gemini_generate()` accepts an optional
  `system_instruction` kwarg, passed to `GenerativeModel(system_instruction=…)`.
  All existing call sites keep working (default is `None`).
- **`app/rag/config.py`** — adds `RAG_CONFIDENCE_GATE` (default `0.65`,
  env-overridable). Used as a soft confidence threshold, **not** a retrieval
  cutoff. The existing vector floor (`0.25`) and keyword fallback (`≥ 70`)
  are unchanged.
- **`app/rag/prompts.py`** — `ask_context_block` and `phrase_context_block`
  now wrap retrieved entries with `[CONTEXT START]` / `[CONTEXT END]` markers
  and include entry IDs (so the model can cite them per the spec).
  `chat_prompt` is trimmed: role / grounding rules now live in the system
  prompt instead of being duplicated in the user message. `rag_prompt` and
  `translation_prompt` are unchanged so `/ask` and `/translate-phrase` keep
  their original prompts for backward compat.
- **`app/rag/serialization.py`** — `finalize_ask_payload` threads a
  `suggest_word: bool` field.
- **`app/rag/pipeline.py`** — `get_chat_answer` rewritten as a dispatcher:
  1. Classify the user message via `intent_for()`.
  2. If `translate` → phrase-lexicon retrieval + `translation_prompt` body;
     else → hybrid RAG retrieval + `chat_prompt` body.
  3. Compute `confident = top_keyword_score ≥ 70 OR top_similarity ≥ gate`.
  4. If **not confident** AND intent is `word` / `define` / `translate`,
     short-circuit to the unknown-word block (`_suggest_word_block`) and
     skip the Gemini call.
  5. Otherwise call `gemini_generate(..., system_instruction=HADRAMI_SYSTEM_PROMPT)`.
  6. Return `{ reply, intent, suggest_word, answer_source, context, … }`.

  `get_rag_answer` and `get_translation_answer` are untouched.
- **`app/schemas.py`** — `ChatResponse` gains `intent`, `suggest_word`,
  `answer_source`.
- **`app/main.py`** — `/chat` handler threads the new fields through to the
  HTTP response.

## Tests

A single new test file covers the dispatcher and the intent classifier:
**`backend/tests/test_chat_unified.py`** (16 test cases).

All tests stub Supabase retrieval and Gemini so the suite is **hermetic** —
no network, no credentials required.

### Why these tests exist

The work this PR ships is mostly **routing logic**: based on a user message,
pick the right retrieval + prompt path and decide whether to call the LLM
at all. Routing logic that lives only in production has two failure modes:

1. **Silent regressions** — a small refactor in `prompts.py` or `retrieval.py`
   could quietly stop passing the system prompt, swap the wrong retriever in
   for `translate`, or skip the suggest-word short-circuit. None of those
   would crash; the user would just get worse answers.
2. **Cost / latency leaks** — the unknown-word short-circuit is a Gemini
   call we deliberately skip. If the short-circuit breaks, every "word not
   in lexicon" question costs an LLM round-trip plus latency. A test pins
   the contract.

So the tests answer four questions, one per concern:

| Concern | Test that proves it |
|---|---|
| Does the classifier match the spec's TYPE 1–5 examples? | 12 parametrized cases on `intent_for()` |
| Does the system prompt actually reach Gemini? | `test_chat_qa_passes_system_prompt` |
| Does `translate` use phrase retrieval (not `/ask` retrieval)? | `test_chat_translation_uses_phrase_retrieval` |
| Does the suggest-word path skip Gemini entirely? | `test_chat_unknown_word_short_circuits_to_suggest` |

### How the tests work

#### How #1 — Classifier tests are pure functions

`intent_for(question) -> Literal["word","translate","define","semantic","qa"]`
is deterministic: no I/O, no globals. So the classifier tests are just a
parametrized table — input string, expected label — calling the function
directly. They run in milliseconds and never need stubs.

```python
@pytest.mark.parametrize("question,expected", [
    ("بغية", "word"),
    ("ترجم: إكس على كلامه", "translate"),
    ("ما معنى أمبوه؟", "define"),
    ...
])
def test_intent_classifier(question, expected):
    assert intent_for(question) == expected
```

#### How #2 — Dispatcher tests stub the two side-effects

`get_chat_answer()` has exactly two side-effects: (a) it calls retrieval
helpers that hit Supabase, (b) it calls `gemini_generate()` which hits the
Gemini API. To make the test hermetic and assertion-friendly we replace
both via `pytest.MonkeyPatch`.

A small helper centralises the retrieval stubs:

```python
def _stub_retrieval(monkeypatch, *, hits):
    monkeypatch.setattr(pipeline, "retrieve_rag_context",
                        lambda q: (hits, hits))
    monkeypatch.setattr(pipeline, "retrieve_phrase_context",
                        lambda q: (hits, hits))
    monkeypatch.setattr(pipeline, "expanded_keyword_context",
                        lambda q, top_k=8: {
                            "results": hits,
                            "top_score": 100 if hits else 0,
                        })
    monkeypatch.setattr(pipeline, "phrase_top_score",
                        lambda q: 100 if hits else 0)
```

For Gemini we install a fake that *records its arguments*. That's the trick
that lets us assert on `system_instruction`:

```python
captured = {}
def fake_gemini(prompt, api_key, *args, **kwargs):
    captured["prompt"] = prompt
    captured["system_instruction"] = kwargs.get("system_instruction")
    return "إجابة من النموذج"

monkeypatch.setattr(pipeline, "gemini_generate", fake_gemini)
...
assert captured["system_instruction"] == HADRAMI_SYSTEM_PROMPT
```

For the short-circuit test we flip it: install a fake that fails the test
if it's *ever* called.

```python
gemini_called = {"n": 0}
def fake_gemini(*a, **kw):
    gemini_called["n"] += 1
    return "should not be called"
...
assert gemini_called["n"] == 0  # short-circuit must skip the LLM
```

#### How #3 — Routing is asserted via call counts

For "translate intent must use phrase retrieval, not RAG retrieval" we don't
inspect internal state — we just count calls per retriever:

```python
calls = {"phrase": 0, "rag": 0}
def fake_phrase(q): calls["phrase"] += 1; return (hits, hits)
def fake_rag(q):    calls["rag"]    += 1; return ([], [])

monkeypatch.setattr(pipeline, "retrieve_phrase_context", fake_phrase)
monkeypatch.setattr(pipeline, "retrieve_rag_context",   fake_rag)
...
assert calls["phrase"] == 1
assert calls["rag"]    == 0
```

This assertion is robust to internal refactors as long as the **public
contract** ("translate routes to phrase retrieval") holds.

#### How #4 — Suggest-block content is asserted by substring

We check three substrings rather than the exact reply text, so cosmetic
edits to the suggest block don't break the test, but the load-bearing
strings (the spec marker the Flutter UI keys off) stay pinned:

```python
assert result["suggest_word"] is True
assert result["answer_source"] == "lexicon"
assert "هذه الكلمة غير موجودة في القاموس الحالي" in result["reply"]
assert "بامحقب" in result["reply"]                    # the offending word
assert "⚠️ كلمات غير موجودة في القاموس" in result["reply"]  # spec marker
```

### Where the tests live

```
backend/
└── tests/
    ├── test_api.py              # existing live E2E suite (Supabase + Gemini)
    └── test_chat_unified.py     # NEW — hermetic unit tests for /chat dispatcher
```

The test file is committed alongside the existing `test_api.py` so a single
`pytest` invocation runs both. The hermetic tests run first (~1 sec) and
the live tests run after (~60 sec when credentials are present, otherwise
auto-skipped via the `db_only` / `rag_only` markers in `test_api.py`).

The new file deliberately does **not** import `TestClient` or `app.main` —
it tests the pipeline function directly. This keeps it independent of the
HTTP layer and means a routing change in `main.py` cannot mask a logic bug
in the dispatcher.

### When to run the tests

| Trigger | Command | Why |
|---|---|---|
| **Every save** while editing `pipeline.py`, `system_prompt.py`, or `prompts.py` | `pytest tests/test_chat_unified.py -v` | ~1 sec, hermetic, catches routing/wiring regressions immediately |
| **Before committing** any backend change | `pytest -v` (full suite) | Runs hermetic + live E2E; catches regressions in retrieval, Supabase contract, Gemini integration |
| **Before merging a PR** | Same as above, with credentials present in `.env` | The 26 E2E tests in `test_api.py` are the only ones that exercise the real Supabase schema and Gemini API |
| **In CI without secrets** | `pytest -v` will auto-skip the live tests via `db_only` / `rag_only` markers; the 16 hermetic tests still run |
| **When tuning `RAG_CONFIDENCE_GATE`** | `RAG_CONFIDENCE_GATE=0.50 pytest tests/test_chat_unified.py` | The gate is read at module import; override per-run to verify behaviour at different thresholds |
| **After bumping the Gemini SDK** (the deprecation warning above) | Full suite, then a manual `curl /chat` smoke | The fake `gemini_generate` won't catch SDK breakage; live tests + smoke do |

### Last green run

```
$ python -m pytest tests/test_chat_unified.py -v
============================== 16 passed in 1.46s ===============================

$ python -m pytest -v
============================== 42 passed in 63.94s ==============================
```

No regressions in the 26 pre-existing E2E tests.

### Coverage

| # | Test | What it proves |
|---|---|---|
| 1 | `test_intent_classifier[بغية → word]` | Single Arabic token → `word` |
| 2 | `test_intent_classifier[أم حبيل → word]` | Two-token compound headword → `word` |
| 3 | `test_intent_classifier[ترجم: إكس على كلامه → translate]` | Explicit Arabic translation directive |
| 4 | `test_intent_classifier[translate this … → translate]` | Explicit English translation directive |
| 5 | `test_intent_classifier[ما معنى أمبوه؟ → define]` | `ما معنى` → `define` (not `qa`) |
| 6 | `test_intent_classifier[اشرح كلمة بانه → define]` | `اشرح` → `define` |
| 7 | `test_intent_classifier[أداة لفك الصواميل → semantic]` | `أداة ل…` concept-search |
| 8 | `test_intent_classifier[كلمة تعني التريث → semantic]` | `كلمة تعني` concept-search |
| 9 | `test_intent_classifier[هل كلمة باير … → qa]` | `هل` opener → `qa` |
| 10 | `test_intent_classifier[كيف أقول … → qa]` | `كيف` opener → `qa` |
| 11 | `test_intent_classifier[أبوي قال … → translate]` | Multi-word Hadrami text without explicit instruction defaults to `translate` |
| 12 | `test_intent_classifier['' → qa]` | Empty input falls through to `qa` |
| 13 | `test_chat_qa_passes_system_prompt` | `gemini_generate` is called with `system_instruction=HADRAMI_SYSTEM_PROMPT`. Result has `intent="qa"`, `suggest_word=False`, `answer_source="model"` |
| 14 | `test_chat_translation_uses_phrase_retrieval` | Translate intent calls `retrieve_phrase_context` and **does not** call `retrieve_rag_context`. Result `intent="translate"` |
| 15 | `test_chat_unknown_word_short_circuits_to_suggest` | Empty retrieval + word/define/translate intent → Gemini is NOT called, response has `suggest_word=True`, `answer_source="lexicon"`, includes `هذه الكلمة غير موجودة في القاموس الحالي` and `⚠️ كلمات غير موجودة في القاموس` and the offending word |
| 16 | `test_chat_qa_with_no_hits_does_not_short_circuit` | Generic question with empty retrieval still calls Gemini (system prompt handles refusal); not the dispatcher's job |

### Stubbing pattern

Each test uses pytest's `monkeypatch` to:

```python
def _stub_retrieval(monkeypatch, *, hits):
    monkeypatch.setattr(pipeline, "retrieve_rag_context", lambda q: (hits, hits))
    monkeypatch.setattr(pipeline, "retrieve_phrase_context", lambda q: (hits, hits))
    monkeypatch.setattr(pipeline, "expanded_keyword_context",
                        lambda q, top_k=8: {"results": hits, "top_score": 100 if hits else 0})
    monkeypatch.setattr(pipeline, "phrase_top_score", lambda q: 100 if hits else 0)
```

`gemini_generate` is replaced with a fake that records its kwargs so we can
assert on `system_instruction`. `is_gemini_unavailable` is forced to `False`
so we exercise the happy path. For the short-circuit test we instead assert
the fake is **never called**.

### Results

```
$ python -m pytest tests/test_chat_unified.py -v
============================== 16 passed ==============================

$ python -m pytest -v          # full suite, including live Supabase/Gemini E2E
============================== 42 passed ==============================
```

No regressions in the existing 26 E2E tests under `tests/test_api.py`.

## How to verify locally

```bash
cd backend
source venv/bin/activate

# Hermetic unit suite (fast, no network)
python -m pytest tests/test_chat_unified.py -v

# Full suite (needs SUPABASE_URL + GEMINI_API_KEY in .env)
python -m pytest -v

# Live smoke test — start the server and hit /chat for each intent
uvicorn app.main:app --reload
# Then in another shell:
curl -s -X POST localhost:8000/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "ما معنى بغية؟", "history": []}' | jq
# Expect: { "intent": "define", "suggest_word": false, "reply": "📖 …", … }

curl -s -X POST localhost:8000/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "بامحقب", "history": []}' | jq
# Expect: { "intent": "word", "suggest_word": true,
#           "reply": "هذه الكلمة غير موجودة في القاموس الحالي …", … }
```

## Notes for future work

- `RAG_CONFIDENCE_GATE=0.65` is a guess. Once the unified `/chat` is in
  production traffic, sweep `0.45–0.75` against a labelled eval set to pick a
  data-driven value.
- The Flutter `chat` module can now read `intent` to switch render layouts
  (e.g. card view for `word`, paragraph for `qa`/`translate`) and use
  `suggest_word=true` to surface the "اقترح إضافتها" call-to-action without
  parsing the answer text.
- `google-generativeai` is deprecated upstream; migrating to `google.genai`
  is tracked separately and will not change the `gemini_generate` interface.
