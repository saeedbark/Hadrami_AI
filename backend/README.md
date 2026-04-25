# Backend — Hadrami NLP API

FastAPI REST API serving the Hadrami dialect dictionary, word/phrase
translation, semantic search, conversational chat, and **retrieval-grounded**
Q&A. Data lives in **Supabase** (PostgreSQL + pgvector).

---

## Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate          # Linux/macOS
# .\venv\Scripts\Activate.ps1     # Windows PowerShell

pip install -r requirements.txt
cp .env.example .env              # then fill in the required keys
```

### Environment variables

`backend/.env` — never commit it. The important ones:

| Variable | Required for | Notes |
|----------|--------------|-------|
| `SUPABASE_URL` | all endpoints | `https://<ref>.supabase.co` |
| `SUPABASE_SERVICE_KEY` | all endpoints | **service_role JWT**, not anon |
| `GEMINI_API_KEY` | `/ask`, `/chat`, `/translate-phrase`, `/semantic-search` | Google AI Studio key |
| `RAG_MODE` | optional | `local` (default, hybrid) or `simple` (keyword-only) |
| `GEMINI_MODEL` | optional | Default `gemini-2.5-flash` |
| `RAG_CACHE_TTL_SECONDS` | optional | In-memory query cache TTL (default 90, 0 disables) |
| `RAG_DEBUG` | optional | `1` (default) enables retrieval/prompt logging to stdout |
| `ASK_MAX_CHARS` | optional | Max body length for `/ask` / `/chat` (default 3000) |
| `PHRASE_TRANSLATE_MAX_WORKERS` | optional | Parallelism for chunked translation (default 3, max 8) |

### Run the server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Or use the helper scripts: `./run.sh` (Linux/macOS) or `.\run.ps1` (Windows).

Swagger UI is at <http://localhost:8000/docs>.

---

## Code Architecture

```
app/
├── __init__.py
├── main.py                      ← FastAPI app (lifespan, CORS, routes)
├── schemas.py                   ← Pydantic models (Entry, AskResponse, ChatResponse, …)
├── rag_engine.py                ← Backward-compat shim → app.rag.*
├── rag/                         ← Modular RAG pipeline
│   ├── __init__.py              ← Re-exports public entrypoints
│   ├── config.py                ← RAG_MODE, GEMINI_MODEL, cache TTL
│   ├── retrieval.py             ← Keyword / vector / phrase retrievers + orchestrators
│   ├── generation.py            ← Gemini wrapper (model fallbacks, chat config)
│   ├── prompts.py               ← ask / chat / translate / phrase prompts (grounded)
│   ├── serialization.py         ← DB-row → Entry + response shaping
│   ├── text_utils.py            ← Arabic normalization + span detection
│   ├── logging_utils.py         ← RAG_DEBUG logging + previews
│   └── pipeline.py              ← get_rag_answer / get_chat_answer / get_translation_answer
├── core/
│   ├── __init__.py
│   ├── config.py                ← App constants, Supabase config, translation limits
│   └── data_store.py            ← Supabase client + PostgREST / RPC helpers
└── services/
    ├── __init__.py
    ├── dictionary_service.py           ← Keyword search, translate, feedback, pagination
    ├── embedding_service.py            ← Gemini text-embedding-004 wrapper
    └── phrase_translation_service.py   ← Chunked phrase translation with grounding
```

### Key design decisions

- **Supabase as single source of truth.** The lexicon lives in a Postgres
  `entries` table. Reads go through PostgREST (for keyword / filter
  queries) or custom SQL functions (`match_entries`,
  `search_entries_expanded`) for ranking and ANN lookups.
- **Hybrid retrieval.** `app.rag.retrieval` merges expanded keyword search
  and pgvector ANN results by ID. If the top keyword score ≥ 100
  (exact headword/synonym/variant hit), vector search is skipped.
- **Lexicon-grounded prompting.** `app.rag.prompts` mandates that every
  dialectal mapping the LLM emits be licensed by a retrieved entry
  (headword, synonyms, MSA gloss, definition, or examples). Function
  words (prepositions, pronouns) are the only exemption.
- **Honest refusal instead of hallucination.** When retrieval is empty or
  weak, the pipeline returns a single admission line. The offline
  fallback (used when Gemini is unavailable) applies the same rule: it
  refuses to emit an MSA gloss when `top_score < 70`.
- **Supabase-persisted feedback.** `/feedback` writes to a Postgres table
  (`feedback`) instead of a local JSON file — works under serverless
  deployments and is auditable.
- **Chunked phrase translation.** Long inputs are split on paragraph /
  sentence boundaries and translated in bounded parallel (default 3
  workers).

---

## API Reference

### Dictionary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | API info + total entries |
| `/stats` | GET | Dataset coverage statistics |
| `/sections` | GET | Lexicon partitioned by first Arabic letter |
| `/translate?q=<word>` | GET | Translate a single Hadrami word (exact → partial → definition match) |
| `/search?q=<query>&limit=20` | GET | Scored keyword search across headword, synonyms, gloss, definition |
| `/semantic-search?q=<query>&limit=10&threshold=0.3` | GET | Vector similarity search using pgvector embeddings |
| `/words?page=1&size=20&letter=أ` | GET | Paginated list (optional `letter`, `pos`, `tag` filters) |
| `/word/<id>` | GET | Single entry by ID |
| `/random` | GET | Random entry |

### AI / Translation

| Endpoint | Method | Body | Purpose |
|----------|--------|------|---------|
| `/ask?q=<question>` | GET | — | Retrieval-grounded Q&A |
| `/ask` | POST | `{"q":"..."}` | Same, via JSON body |
| `/chat` | POST | `{"message":"...","history":[{"role":"user","content":"..."}]}` | Multi-turn chat, grounded |
| `/translate-phrase` | POST | `{"text":"...","direction":"ar_to_hadrami"}` | Phrase translation (MSA ↔ Hadrami) |

Direction values: `ar_to_hadrami`, `hadrami_to_ar`.

### Feedback

| Endpoint | Method | Body |
|----------|--------|------|
| `/feedback` | POST | `{"word_vocalized":"...","suggested_fusha":"...","feedback_type":"correction","consent":true}` |

`feedback_type` ∈ `correction`, `new_word`, `sentence_pair`,
`spelling_variant`. Additional optional fields: `word_id`, `comment`,
`spelling_variants`, `sentence_pair_hadrami`, `sentence_pair_fusha`.

---

## Testing

```bash
python -m pytest tests/ -v
```

`tests/test_api.py` contains **26 smoke tests** that exercise every
endpoint end-to-end. Tests that need Supabase are automatically skipped
when `SUPABASE_URL` / `SUPABASE_SERVICE_KEY` are missing; tests that need
Gemini are skipped when `GEMINI_API_KEY` is missing.

Notable tests:

- `test_ask_with_irrelevant_question_refuses_or_admits` — guards against
  the single largest hallucination path in the audit: returning the MSA
  gloss of a loosely-matched entry for an out-of-domain question.
- `test_translate_phrase_*_returns_shape` — validates the grounded
  phrase-translation response shape in both directions.
- `test_submit_basic_feedback_persists` — round-trips feedback through
  Supabase.

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate_dataset.py` | Validate `hadrami_dataset.json` against the `Entry` schema (required fields, types, allowed POS). Downgrades non-canonical POS / unknown fields to warnings. |
| `scripts/audit_dataset.py` | Descriptive statistics: field coverage, POS distribution, top regions / tags / roots, length distributions. |
| `../scripts/sync_to_supabase.py` | Canonical ETL: JSON → optional CSV → Supabase upsert → (optional) Gemini embedding backfill. |

Run from the `backend/` directory with the venv interpreter:

```bash
python scripts/validate_dataset.py
python scripts/audit_dataset.py
python ../scripts/sync_to_supabase.py --help
```

---

## Dataset Format

Source of truth: `data/hadrami_dataset.json`. Accepts either a top-level
list of entries or `{"version":"…","entries":[…]}`.

```json
{
  "id": 1,
  "word_vocalized": "أَمّ حُبَيْل",
  "word_clean": "أم حبيل",
  "root": "حبل",
  "pos": "Noun",
  "fusha_equivalent": "العنكبوت",
  "definition": "اسم محلي للعنكبوت.",
  "region": "General",
  "synonyms": ["بنت حبيل"],
  "phonetic_variants": [],
  "examples": [{"h": "شفت أم حبيل في الركن", "f": "رأيت العنكبوت في الزاوية"}],
  "proverbs": [],
  "tags": ["حيوانات"]
}
```

Optional fields may be omitted or set to `null`. Lists may be empty. See
[`../README.md#dataset-schema`](../README.md#dataset-schema) for the full
type table.

---

## Deployment

Deployable to Vercel via `vercel.json`; `pyproject.toml` declares the ASGI
entry point for Vercel's Python runtime. Any WSGI/ASGI host that supports
Python 3.10+ and can reach Supabase + Google Gemini endpoints should work
out of the box.
