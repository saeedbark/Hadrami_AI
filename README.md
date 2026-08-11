# Hadrami NLP Project

A bilingual dictionary and **retrieval-augmented** dialect-conversion system
for the **Hadrami dialect** of Yemeni Arabic. The system combines a curated
1,000+ entry lexicon stored in Supabase (Postgres + pgvector) with
Google Gemini generation to provide:

- word-level interpretation (exact / partial / expanded keyword search)
- phrase conversion (MSA ↔ Hadrami) with **lexicon-grounded** prompting
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
│   │   ├── rag/                     ← Modular RAG pipeline
│   │   │   ├── config.py            ← Env knobs (RAG_MODE, GEMINI_MODEL, cache TTL)
│   │   │   ├── retrieval.py         ← Keyword / vector / phrase retrievers
│   │   │   ├── generation.py        ← Gemini client + fallback models
│   │   │   ├── prompts.py           ← All grounded prompts (ask, chat, convert)
│   │   │   ├── serialization.py     ← DB-row → Pydantic Entry + response shaping
│   │   │   ├── text_utils.py        ← Arabic normalization + span detection
│   │   │   ├── system_prompt.py     ← HADRAMI_SYSTEM_PROMPT + intent_for() classifier
│   │   │   ├── logging_utils.py     ← RAG_DEBUG logging
│   │   │   └── pipeline.py          ← Public entrypoints (get_rag_answer etc.)
│   │   ├── core/
│   │   │   ├── config.py            ← App constants, Supabase config, limits
│   │   │   └── data_store.py        ← Supabase client + PostgREST / RPC helpers
│   │   └── services/
│   │       ├── dictionary_service.py        ← Search, interpret, pagination, feedback
│   │       ├── embedding_service.py         ← Gemini gemini-embedding-001 wrapper (768-dim)
│   │       ├── embedding_doc.py             ← Canonical embedding-doc text (versioned, v2)
│   │       └── phrase_conversion_service.py ← Chunked phrase conversion
│   ├── data/
│   │   ├── hadrami_dataset.json     ← Main lexicon (source of truth; see schema below)
│   │   └── eval_pairs.json          ← Held-out Hadrami↔MSA evaluation pairs
│   ├── scripts/
│   │   ├── validate_dataset.py      ← Schema + required-field validation
│   │   └── audit_dataset.py         ← Coverage / POS / length statistics
│   ├── tests/                       ← 42 tests passing (test_api.py: 26 live E2E; test_chat_unified.py: 16 hermetic)
│   ├── migrations/                  ← v2 schema delta (searchable_text, semantic_intent, transliteration)
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
│   │       ├── configs/             ← API URL, endpoint path constants, colors, radii, phrase limits
│   │       ├── core/
│   │       │   ├── models/          ← Shared models (WordEntry, dictionary labels, ...)
│   │       │   ├── services/        ← api_service.dart — shared HTTP transport + cross-module endpoints
│   │       │   ├── providers/       ← App-wide Riverpod providers
│   │       │   ├── routing/         ← GoRouter setup + app_routes.dart path constants
│   │       │   ├── strings/         ← app_strings.dart — centralized UI copy (per screen/widget)
│   │       │   └── theme/           ← Material 3 theme, light/dark
│   │       ├── widgets/             ← Shared UI components
│   │       └── modules/             ← Feature modules (home, dictionary, favorites, chat, landing, settings),
│   │                                  each with pages/providers/widgets and, where the module owns
│   │                                  module-specific API calls or models, its own services/ and models/
│   │                                  (e.g. dictionary/services/, home/services/ + home/home_models/)
│   └── pubspec.yaml
│
├── scripts/
│   ├── sync_to_supabase.py          ← JSON → (CSV) → Supabase + embeddings
│   ├── clean_lexicon.py / clean_tags_region.py / null_empty_strings.py
│   │                                  ← One-shot cleanup passes (already applied to live DB)
│   ├── validate_pos.py / apply_pos_corrections.py
│   │                                  ← LLM-based POS validator + auto-collapse
│   ├── generate_enrichment.py        ← Fill semantic_intent + transliteration via Gemini
│   ├── backfill_searchable_text.py   ← Re-run canonical embedding-doc text into DB
│   ├── gemini_rotator.py             ← Round-robin across multiple GEMINI_API_KEY env vars
│   ├── finalize_pipeline.sh          ← Apply POS + audit + Kaggle/HF re-export
│   ├── eval/                         ← Per-experiment runners (E1–E5) + test-set seed builder
│   └── export/                       ← Release bundle builders (Kaggle + HuggingFace)
│
├── docs/
│   ├── README.md                    ← This file (top-level overview)
│   ├── methods_evaluation.md        ← Architecture + evaluation protocol
│   ├── research_paper_plan.md       ← Paper outline, experiments, timeline
│   ├── hadrami_rag_paper.html       ← Paper draft (real numbers + TBD provenance)
│   ├── search.md                    ← Search/retrieval component (How / When / Where / Why)
│   ├── chat_unified_changes.md      ← Backend `/chat` dispatcher refactor changelog
│   └── flutter_ui_changes.md        ← Frontend UI / animations / responsive changelog
│
├── results/                         ← Eval outputs (corpus_stats.json, intent_eval.json, …)
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
| GET | `/interpret?q=word` | Interpret a single Hadrami word |
| POST | `/convert-phrase` | Phrase conversion, body: `{"text","direction"}` |
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

Every AI-facing endpoint (`/ask`, `/chat`, `/convert-phrase`) follows the
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
| Embeddings | Gemini `gemini-embedding-001` (768-dim) |
| Frontend | Flutter 3.x, Riverpod, hooks, go_router (`StatefulShellRoute.indexedStack`) |
| Forms | reactive_forms (+ codegen) |
| Models | freezed + json_serializable |
| Theme | Material 3, light + dark, responsive (mobile / tablet / desktop), warm Yemeni palette (terracotta + saffron + cream) |
| Animations | Native Flutter primitives only — `AnimatedAppear` + `StaggeredAppear` shared widgets, `AnimatedSwitcher` on theme toggle, `TweenAnimationBuilder` elastic on empty-state, no extra packages |
| Testing | pytest (backend, **42 passing**), flutter_test (frontend), `flutter analyze` clean (15 pre-existing infra issues, 0 errors) |
| Deployment | Vercel (backend), multi-platform Flutter (Android / iOS / Web / Windows / macOS / Linux) |

---

## App Screens (Flutter)

1. **Home** — interpret a word, dataset stats, word of the day.
2. **Dictionary** — full word list filtered by Arabic letter/POS/tag, plus a
   built-in text search (merged in from the former standalone Search screen).
3. **Favorites** — locally saved words.
4. **Chat** — multi-turn, grounded Q&A and dialect conversion in one surface
   (the former single-turn Ask screen and the dedicated Phrase-translate
   screen were merged into Chat; `/ask` and `/phrase-translate` deep links
   redirect here).
5. **Settings** — connection test, theme toggle, about info.

The backend still exposes `/ask` and `/convert-phrase` as separate, tested
API routes (used by the evaluation scripts in `scripts/eval/`) — only the
dedicated frontend screens for them were removed as redundant with Chat.

---

## Contributing

See [ROADMAP.md](ROADMAP.md) for planned improvements and
[docs/methods_evaluation.md](docs/methods_evaluation.md) for the evaluation
protocol. Contributions welcome — especially dataset corrections via the
`/feedback` endpoint or direct PRs against `backend/data/hadrami_dataset.json`
(include a `source` field when you can).
