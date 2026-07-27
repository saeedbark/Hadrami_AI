# CLAUDE.md

Guidance for Claude Code sessions working in this repository.

## Project purpose

Hadrami NLP is a bilingual dictionary and translation tool for the **Hadrami dialect** of Yemeni Arabic. It combines a curated 1,000+ entry lexicon with RAG (Retrieval-Augmented Generation) powered by Gemini to provide:

- Word-level translation (Hadrami → Modern Standard Arabic / Fus7a)
- Phrase/paragraph-level bidirectional translation (MSA ↔ Hadrami)
- AI-powered Q&A about the Hadrami dialect

The long-term goal (see `docs/research_paper_plan.md` if present) includes an academic paper — **Hadrami-RAG** — targeting ArabicNLP@EMNLP 2026, with LREC-COLING 2026 as backup. Treat dataset quality and evaluation rigor as first-class concerns, not just app features.

## Architecture overview

Three tiers, no database on `main` — the lexicon is a JSON file loaded into memory at process start:

```
Flutter client (Riverpod + go_router)
        │  HTTP/JSON
        ▼
FastAPI backend (uvicorn)
  ├─ main.py                 — routes only, thin controllers
  ├─ services/dictionary_service.py   — keyword search/scoring over in-memory ENTRIES
  ├─ rag_engine.py                    — retrieval + Gemini prompt construction + generation
  ├─ services/phrase_translation_service.py — chunked bidirectional phrase translation
  └─ core/data_store.py               — loads backend/data/hadrami_dataset.json → ENTRIES (module-level global)
```

RAG flow for `/ask` and `/translate-phrase`: keyword retrieval (token-split, scored) over `ENTRIES` → optional ChromaDB vector search (off by default, `RAG_USE_CHROMA=1`) → merge → build an Arabic prompt → call Gemini (`gemini-2.5-flash` with a hardcoded fallback chain) → on any Gemini failure, silently degrade to returning the top matched entry's gloss (`mode: "simple"`).

**Important:** there is a separate branch, `feature/rag-chat-unified` (also on `origin`), containing a more advanced, modular RAG pipeline (`backend/app/rag/` package instead of the monolithic `rag_engine.py`), Supabase sync, an eval suite (hallucination/intent/lookup/translation), and dataset export tooling. It is **not merged into `main`**. Do not assume Supabase, embeddings, or the eval framework exist unless you've confirmed which branch/checkout you're on — `git branch --show-current` and `git status` first if anything seems inconsistent with this file.

## Technology stack

| Layer | Technology |
|---|---|
| Backend | FastAPI, Pydantic v2, Uvicorn, Python 3.11+ |
| AI / RAG | Google Gemini via `google-generativeai` (deprecated package — see ROADMAP for migration to `google-genai`) |
| Frontend | Flutter 3.x, Riverpod (`hooks_riverpod` + `riverpod_generator`), go_router |
| Frontend forms | `reactive_forms` + `reactive_forms_generator` (codegen) |
| Frontend models | `freezed` + `json_serializable` (codegen) |
| Testing | pytest (backend, `backend/tests/`), flutter_test (frontend, minimal) |
| Deployment | Vercel (`backend/vercel.json`, `flutter_app/vercel.json`) |

## Coding conventions

**Backend (Python)**
- Type hints everywhere; modern syntax (`list[dict]`, `X | None`, `from __future__ import annotations` where used).
- No framework-level logging setup — debug output goes through `_rag_log()` in `rag_engine.py`, gated by `RAG_DEBUG` env var. Don't introduce `print()` elsewhere; route RAG-related debug output through the existing logger helper.
- Routes in `main.py` stay thin — business logic belongs in `services/*.py` or `rag_engine.py`, not inline in route handlers.
- Docstrings are used sparingly, only to explain *why* (a non-obvious regex, a workaround, an ordering constraint) — see existing one-liners in `dictionary_service.py` and `rag_engine.py` as the model. Don't add docstrings that restate the function name.
- Arabic string literals (prompts, regexes, error messages) are common and intentional — don't "fix" or reformat Arabic text unless the task is specifically about it.
- Tests follow the `TestXxx` class-per-endpoint-group pattern in `backend/tests/test_api.py` (pytest, `TestClient`).

**Frontend (Flutter/Dart)**
- Standard `flutter_lints` rules (`flutter_app/analysis_options.yaml`), nothing customized.
- Module layout: `lib/src/modules/<feature>/{pages,providers,forms,widgets}/`. New features should follow this shape.
- `ApiService` (`lib/src/core/services/api_service.dart`) is the single HTTP boundary — every method catches its own errors and returns an Arabic-language fallback/error state rather than throwing. Match this pattern for new endpoints; don't let exceptions propagate into widgets.
- Generated files (`*.freezed.dart`, `*.g.dart`, `*.gform.dart`) are gitignored and must be regenerated after touching annotated classes:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Never hand-edit generated files.

## Important files

| File | Purpose |
|---|---|
| [backend/app/main.py](backend/app/main.py) | All API routes |
| [backend/app/rag_engine.py](backend/app/rag_engine.py) | RAG retrieval + Gemini generation (main-branch implementation) |
| [backend/app/services/dictionary_service.py](backend/app/services/dictionary_service.py) | Search/scoring/feedback logic |
| [backend/app/services/phrase_translation_service.py](backend/app/services/phrase_translation_service.py) | Chunked phrase translation |
| [backend/app/core/config.py](backend/app/core/config.py) | Constants, paths, chunk sizes, worker limits |
| [backend/app/core/data_store.py](backend/app/core/data_store.py) | Loads the dataset into the `ENTRIES` global at import time |
| [backend/app/schemas.py](backend/app/schemas.py) | All Pydantic request/response models |
| [backend/data/hadrami_dataset.json](backend/data/hadrami_dataset.json) | The lexicon itself — 1,026 entries, versioned envelope |
| [backend/data/eval_pairs.json](backend/data/eval_pairs.json) | Held-out Hadrami↔MSA pairs for evaluation |
| [backend/data/feedback.json](backend/data/feedback.json) | User-submitted corrections (gitignored, local only) |
| [backend/scripts/](backend/scripts/) | Dataset audit/refactor/validate scripts (tracked) |
| [flutter_app/lib/src/core/services/api_service.dart](flutter_app/lib/src/core/services/api_service.dart) | Sole HTTP client boundary |
| [flutter_app/lib/src/configs/api_config.dart](flutter_app/lib/src/configs/api_config.dart) | Backend base URL, timeouts |
| [docs/methods_evaluation.md](docs/methods_evaluation.md) | Architecture + evaluation protocol write-up (partly aspirational — verify claims against actual code/data before citing) |
| [ROADMAP.md](ROADMAP.md) | Prioritized backlog — check before proposing "new" improvements, they may already be tracked |

## Rules for modifying code

- **Never commit `backend/.env`** — it holds `GEMINI_API_KEY`. Already gitignored; don't remove it from `.gitignore`.
- **Never write to `backend/data/hadrami_dataset.json` directly in application code.** Dataset edits go through the scripts in `backend/scripts/` (`refactor_dataset.py`, etc.) with validation (`validate_dataset.py`) run after, and should bump `version`/`updated` in the JSON envelope. Ad-hoc edits break the audit trail.
- **Don't reformat or "clean up" Arabic text** (prompts, dataset entries, error strings) as a side effect of an unrelated change — dialect spelling and MSA glosses are content, not style.
- **Don't silently change RAG fallback/degrade behavior** (e.g. what happens when Gemini fails) without flagging it — the current silent degrade-to-`mode:"simple"` is a known rough edge (see prior session notes / ROADMAP), not something to "fix" incidentally while working on something else.
- **Regenerate Flutter codegen** after touching any `@freezed`, `@JsonSerializable`, `@riverpod`, or `@ReactiveFormAnnotation`-decorated class; don't hand-patch the generated output.
- **Check which git branch you're on before assuming architecture.** `main` uses the monolithic `rag_engine.py` and in-memory JSON; `feature/rag-chat-unified` has a different, more advanced (unmerged) pipeline with Supabase. Don't blend patterns from one branch into the other without the user explicitly asking to merge/port.
- **Database writes:** if Supabase or any other external DB is in play (e.g. on `feature/rag-chat-unified` or in scripts using the service-role key), never run `UPDATE`/`INSERT`/`DELETE` without explicit per-step user approval — the service-role key bypasses row-level security.
- **Run tests before declaring backend changes done:** `cd backend && python -m pytest tests/ -v`.
- Don't add authentication, rate limiting, a real database, or other ROADMAP "High Priority" items speculatively — implement them only when the user asks for that specific item.

## Dataset copyright / usage rules

- The Hadrami lexicon (`hadrami_dataset.json`) is described in-repo as "compiled from dialect references and community contributions." Treat it as the project owner's proprietary research dataset, not public-domain data:
  - Do not upload, paste, or transmit the dataset (or non-trivial excerpts of it) to third-party tools, external APIs, gists, or pastebins without the user's explicit, per-instance approval — this includes export tooling like `to_huggingface.py`/`to_kaggle.py` seen on the unmerged feature branch. Publishing the dataset is a deliberate research decision for the user to make, not something to do proactively.
  - `feedback.json` contains user-submitted contributions gated by an explicit `consent` flag (`FeedbackRequest.consent`). Never merge feedback entries into the main dataset, and never export/share feedback data, without checking the `consent` flag was set to `true` for each entry.
  - No personally identifiable information should be stored or added to dataset entries or feedback records.
  - When citing example sentences or definitions in documentation, commit messages, or PR descriptions, keep excerpts short (a few words) — don't reproduce large verbatim blocks of the lexicon outside the dataset file itself.
- If asked to scrape, generate, or "borrow" dialect content from external published sources (dictionaries, books, social media) to grow the lexicon, flag the copyright/licensing question to the user explicitly rather than proceeding — this is called out as a real risk in the project's own ethics notes (`docs/methods_evaluation.md`).
