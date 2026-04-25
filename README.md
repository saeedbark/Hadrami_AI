# Hadrami NLP Project

A bilingual dictionary and **retrieval-augmented** translation system for the
**Hadrami dialect** of Yemeni Arabic. The system combines a curated
1,000+ entry lexicon stored in Supabase (Postgres + pgvector) with
Google Gemini generation to provide:

- word-level translation (exact / partial / expanded keyword search)
- phrase translation (MSA ↔ Hadrami) with **lexicon-grounded** prompting
- semantic search over 768-dim Gemini embeddings
- conversational Q&A (`/ask`, `/chat`) that refuses to answer when retrieval
  coverage is insufficient rather than hallucinating from general knowledge

**Backend:** FastAPI (Python 3.10+) + Supabase (PostgreSQL / pgvector)
**Frontend:** Flutter (Riverpod + go_router)

> **Academic scope.** This repo is developed alongside a research paper on
> RAG for low-resource Hadrami Arabic. See
> [`docs/methods_evaluation.md`](docs/methods_evaluation.md) for the
> evaluation protocol (chrF/BLEU/Recall@k/MRR, baseline comparisons).

---

## Project Structure

```
hadrami_project/
├── backend/                         ← FastAPI REST API
│   ├── app/
│   │   ├── main.py                  ← Routes, CORS, lifespan
│   │   ├── schemas.py               ← Pydantic request/response models
│   │   ├── rag_engine.py            ← Backward-compat shim → app.rag.*
│   │   ├── rag/                     ← Modular RAG pipeline
│   │   │   ├── config.py            ← Env knobs (RAG_MODE, GEMINI_MODEL, cache TTL)
│   │   │   ├── retrieval.py         ← Keyword / vector / phrase retrievers
│   │   │   ├── generation.py        ← Gemini client + fallback models
│   │   │   ├── prompts.py           ← All grounded prompts (ask, chat, translate)
│   │   │   ├── serialization.py     ← DB-row → Pydantic Entry + response shaping
│   │   │   ├── text_utils.py        ← Arabic normalization + span detection
│   │   │   ├── logging_utils.py     ← RAG_DEBUG logging
│   │   │   └── pipeline.py          ← Public entrypoints (get_rag_answer etc.)
│   │   ├── core/
│   │   │   ├── config.py            ← App constants, Supabase config, limits
│   │   │   └── data_store.py        ← Supabase client + PostgREST / RPC helpers
│   │   └── services/
│   │       ├── dictionary_service.py        ← Search, translate, pagination, feedback
│   │       ├── embedding_service.py         ← Gemini text-embedding-004 wrapper
│   │       └── phrase_translation_service.py ← Chunked phrase translation
│   ├── data/
│   │   ├── hadrami_dataset.json     ← Main lexicon (source of truth; see schema below)
│   │   └── eval_pairs.json          ← Held-out Hadrami↔MSA evaluation pairs
│   ├── scripts/
│   │   ├── validate_dataset.py      ← Schema + required-field validation
│   │   └── audit_dataset.py         ← Coverage / POS / length statistics
│   ├── tests/test_api.py            ← pytest suite (26 tests, live Supabase)
│   ├── requirements.txt
│   ├── pyproject.toml               ← Package metadata + Vercel entry point
│   ├── run.ps1                      ← Windows: install deps + start server
│   └── run.sh                       ← Linux/macOS: install deps + start server
│
├── flutter_app/                     ← Flutter mobile/web/desktop client
│   ├── lib/
│   │   ├── main.dart                ← Entry point (ProviderScope)
│   │   └── src/
│   │       ├── app.dart             ← MaterialApp.router + theme
│   │       ├── configs/             ← API URL, colors, radii, phrase limits
│   │       ├── core/                ← Models, services, providers, routing, theme
│   │       ├── widgets/             ← Shared UI components
│   │       └── modules/             ← Feature modules (home, dictionary, ask, chat, phrase, …)
│   └── pubspec.yaml
│
├── scripts/
│   └── sync_to_supabase.py          ← JSON → (CSV) → Supabase + embeddings
│
├── docs/
│   └── methods_evaluation.md        ← Architecture + evaluation protocol
│
└── ROADMAP.md                       ← Future improvements
```

---

## Quick Start

### Prerequisites

- **Python 3.10+** with pip (3.11 recommended; 3.10 is supported)
- **Flutter SDK 3.x** — [install guide](https://docs.flutter.dev/get-started/install)
- A **Supabase** project with:
  - the `entries` table (schema: see below),
  - the `feedback` table,
  - the `match_entries` + `search_entries_expanded` SQL functions.
- A **Gemini API key** (Google AI Studio) for AI features.

### 1. Backend

```bash
cd backend
python -m venv venv
```

Activate the venv:

```powershell
# Windows PowerShell
.\venv\Scripts\Activate.ps1
```

```bash
# Linux / macOS
source venv/bin/activate
```

Install deps and launch:

```bash
pip install -r requirements.txt
cp .env.example .env    # then fill in SUPABASE_*, GEMINI_API_KEY
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Verify:

- API root: <http://localhost:8000>
- Swagger docs: <http://localhost:8000/docs>

### 2. Tests

```bash
cd backend
python -m pytest tests/ -v
```

Tests that hit Supabase or Gemini are auto-skipped when the corresponding
env var is missing, so `pytest` works locally even without credentials.

### 3. Frontend

```bash
cd flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

For device-specific URLs see
[`flutter_app/README.md`](flutter_app/README.md).

### 4. Sync Dataset to Supabase

The canonical ETL script lives at `scripts/sync_to_supabase.py`:

```bash
# Full pipeline: CSV snapshot + upsert + (re)embeddings (missing/dirty only)
python scripts/sync_to_supabase.py

# Upsert rows only, no CSV, no embeddings
python scripts/sync_to_supabase.py --skip-csv --skip-embeddings

# Only backfill missing embeddings
python scripts/sync_to_supabase.py --embeddings-only

# Re-embed every row
python scripts/sync_to_supabase.py --embeddings-only --reembed-all
```

Requires `SUPABASE_URL`, `SUPABASE_SERVICE_KEY` (must be the `service_role`
JWT — the script verifies this and refuses anon keys), and `GEMINI_API_KEY`
(only for embedding generation).

---

## API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/` | API info + total entries |
| GET | `/stats` | Dataset coverage statistics |
| GET | `/sections` | Lexicon partitioned by first Arabic letter |
| GET | `/translate?q=word` | Translate a single Hadrami word |
| POST | `/translate-phrase` | Phrase translation, body: `{"text","direction"}` |
| GET | `/search?q=text&limit=20` | Scored keyword search |
| GET | `/semantic-search?q=text&limit=10&threshold=0.3` | pgvector similarity search |
| GET | `/words?page=1&size=20` | Paginated word list (optional `letter`, `pos`, `tag`) |
| GET | `/word/{id}` | Single entry by ID |
| GET | `/random` | Random entry |
| POST | `/feedback` | User correction / suggestion (persisted to Supabase `feedback`) |
| GET·POST | `/ask` | Retrieval-grounded Q&A |
| POST | `/chat` | Multi-turn chat with retrieval grounding |

Swagger UI lives at `/docs` when the server is running.

---

## Dataset Schema

The lexicon is the single source of truth (`backend/data/hadrami_dataset.json`)
and maps 1:1 to the `entries` table on Supabase. Each entry matches the
Pydantic `Entry` model in `backend/app/schemas.py`:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | int | ✅ | Unique across the dataset |
| `word_vocalized` | string | ✅ | Fully-vocalized Hadrami headword |
| `word_clean` | string? | — | Un-vocalized form for matching (auto-fillable) |
| `root` | string? | — | Classical Arabic root (3–4 consonants) |
| `pos` | string? | — | Part of speech — `Noun`, `Verb`, `Adjective`, `Adverb`, `Expression`, `Noun/Verb`, … |
| `fusha_equivalent` | string? | — | Modern Standard Arabic gloss |
| `definition` | string? | — | Definition / usage notes |
| `region` | string | — | Sub-regional tag (defaults to `"General"`) |
| `synonyms` | string[]? | — | Alternative Hadrami forms |
| `phonetic_variants` | string[]? | — | Spelling / phonetic variants |
| `note` | string? | — | Free-form note |
| `source` | string? | — | Provenance |
| `examples` | `{h,f}[]?` | — | Usage examples (Hadrami + MSA) |
| `proverbs` | `(string | {h,f})[]?` | — | Related proverbs / sayings |
| `tags` | string[]? | — | Topical tags |

Validate with:

```bash
cd backend
python scripts/validate_dataset.py
python scripts/audit_dataset.py
```

---

## Retrieval-Augmented Generation

Every AI-facing endpoint (`/ask`, `/chat`, `/translate-phrase`) follows the
same lexicon-grounded contract:

1. **Retrieve** — expanded keyword search (`search_entries_expanded` RPC) and
   pgvector (`match_entries`) combined by ID.
2. **Ground** — prompts explicitly require the model to derive every
   dialectal mapping from a retrieved entry (`word_vocalized`, `synonyms`,
   `fusha_equivalent`, `definition`, or `examples`).
3. **Refuse** — when retrieval is empty or weak, the pipeline returns a
   single line asking the user to rephrase instead of inventing answers.
4. **Fallback** — if Gemini is unavailable (rate-limit, network, missing
   key), a deterministic “lexicon-only” answer is assembled from retrieved
   rows. It refuses to emit a speculative gloss below `top_score ≥ 70`
   (audit §RAG violations).

The full audit that motivated these changes is in
[`docs/methods_evaluation.md`](docs/methods_evaluation.md).

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | FastAPI, Pydantic v2, Uvicorn |
| Database | Supabase (PostgreSQL + pgvector) |
| AI / RAG | Google Gemini (`gemini-2.5-flash` default, with fallbacks) |
| Embeddings | Gemini `text-embedding-004` (768-dim) |
| Frontend | Flutter 3.x, Riverpod, go_router |
| Forms | reactive_forms (+ codegen) |
| Models | freezed + json_serializable |
| Theme | Material 3, responsive layout |
| Testing | pytest (backend), flutter_test (frontend) |
| Deployment | Vercel (backend), multi-platform (frontend) |

---

## App Screens (Flutter)

1. **Home** — translate a word, dataset stats, word of the day.
2. **Search** — live debounced search with result count.
3. **Dictionary** — full word list filtered by Arabic letter.
4. **Favorites** — locally saved words.
5. **Ask** — grounded Q&A about the Hadrami dialect.
6. **Chat** — multi-turn chat with grounded answers.
7. **Phrases** — phrase-level MSA ↔ Hadrami translation with highlighted
   Hadrami spans.
8. **Settings** — connection test, theme toggle, about info.

---

## Contributing

See [ROADMAP.md](ROADMAP.md) for planned improvements and
[docs/methods_evaluation.md](docs/methods_evaluation.md) for the evaluation
protocol. Contributions welcome — especially dataset corrections via the
`/feedback` endpoint or direct PRs against `backend/data/hadrami_dataset.json`
(include a `source` field when you can).
