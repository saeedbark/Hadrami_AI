# CLAUDE.md

Guidance for Claude Code sessions working in this repository.

## Project purpose

Hadrami NLP is a bilingual dictionary and dialect-conversion tool for the **Hadrami dialect** of Yemeni Arabic. It combines a curated 1,000+ entry lexicon with RAG (Retrieval-Augmented Generation) powered by Gemini to provide:

- Word-level interpretation (Hadrami → Modern Standard Arabic / Fus7a)
- Phrase/paragraph-level bidirectional dialect conversion (MSA ↔ Hadrami)
- AI-powered Q&A about the Hadrami dialect

**Terminology note:** this project deliberately avoids the word "ترجمة"/"translation" for what it does, since Hadrami and MSA are dialects of the same language, not separate languages. Internally and in the UI, the concepts are "interpretation" (تفسير/شرح المعنى — explaining a word's meaning), "conversion" (تحويل — rendering a phrase from one register to the other), and "normalization to Fusha" (تطبيع اللهجة إلى الفصحى). Endpoint/function/schema names follow this: `/interpret`, `/convert-phrase`, `get_conversion_answer`, `InterpretResponse`, `ConvertPhraseRequest/Response`, etc. Don't reintroduce "translate"/"Translation" naming in new code — match the existing convention instead.

The long-term goal (see `docs/research_paper_plan.md` if present) includes an academic paper — **Hadrami-RAG** — targeting ArabicNLP@EMNLP 2026, with LREC-COLING 2026 as backup. Treat dataset quality and evaluation rigor as first-class concerns, not just app features.

## Architecture overview

`feature/rag-chat-unified` was merged into `main` on 2026-07-27 (PR #27 → `dev`, PR #28 `dev` → `main`). The backend is now **Supabase-backed** (PostgreSQL + pgvector) — there is no in-memory JSON data store anymore in production:

```
Flutter client (Riverpod + go_router)
        │  HTTP/JSON
        ▼
FastAPI backend (uvicorn)
  ├─ main.py                          — routes only, thin controllers
  ├─ core/data_store.py               — Supabase client + queries (fetch_all, text_search,
  │                                      rpc_match_entries, rpc_search_entries_expanded,
  │                                      insert_feedback, count_rows, ...)
  ├─ services/dictionary_service.py   — search/scoring/formatting on top of data_store
  ├─ services/phrase_conversion_service.py — chunked bidirectional phrase conversion
  ├─ services/embedding_service.py / embedding_doc.py — embedding generation for semantic search
  └─ rag/                             — modular RAG pipeline
      ├─ pipeline.py    — get_rag_answer() (/ask) and get_chat_answer() (/chat) entry points
      ├─ retrieval.py   — keyword + vector retrieval over Supabase
      ├─ generation.py  — Gemini prompt construction + generation
      ├─ prompts.py / system_prompt.py
      ├─ serialization.py, text_utils.py, logging_utils.py, config.py
```

**`backend/app/rag_engine.py` no longer exists** — it was a backward-compat shim re-exporting `app.rag.*` symbols; confirmed zero importers (app code, tests, scripts) and deleted. If you see a stale reference to it anywhere, the real pipeline is `backend/app/rag/`.

`backend/data/hadrami_dataset.json` is **not read by the running app** — it's a local staging/working copy used by `backend/scripts/*.py` (audit/refactor/validate) before syncing to Supabase via `scripts/sync_to_supabase.py`. Supabase is the single source of truth for what the API actually serves.

New unified endpoint: `POST /chat` auto-classifies a message into `word`/`convert`/`define`/`semantic`/`qa` intent and routes through the matching retrieval+prompt path — meant to eventually replace direct `/ask` + `/convert-phrase` calls for chat-style clients.

## Deployment (read this before touching Flutter deploy config)

Both `backend/` and `flutter_app/` deploy to **separate Vercel projects** (`hadrami-ai` and `hadrami-ai-lr7j`) from the same GitHub repo, root-directory-scoped.

- **Backend** (`hadrami-ai`): needs `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` (exact names — not `NEXT_PUBLIC_*`, that's a Next.js convention this project doesn't use) set as **Production** environment variables in the Vercel project. `SUPABASE_SERVICE_KEY` must be the `service_role` secret, not the anon/publishable key, or writes get silently blocked by RLS.
- **Frontend** (`hadrami-ai-lr7j`): has **no static build committed to git** — `flutter_app/vercel.json` sets `"buildCommand": "bash vercel_build.sh"`, which clones Flutter `stable` fresh and runs `flutter build web` on *every* deploy. Two hard-won lessons from a 2026-07-27 production outage, both now fixed but easy to reintroduce:
  1. `vercel_build.sh` **must** run `dart run build_runner build --delete-conflicting-outputs` before `flutter build web` — `*.freezed.dart`/`*.g.dart`/`*.gform.dart` are gitignored (correctly) and don't exist on a fresh clone.
  2. Because the build clones Flutter `stable` fresh each time, a pinned dependency that happens to compile fine on your local (older) Flutter can still break the Vercel build months later when `stable` moves forward. If a Vercel build fails with a `dart2js`/const-evaluation error pointing into a `.pub-cache` package, it's very likely a Dart-SDK-vs-dependency-version issue, not your code — check the package's changelog for a compiler-compat fix and bump within the existing `pubspec.yaml` constraint first.
  - Never re-commit `flutter_app/build/` to git — it's gitignored on purpose now; the build step regenerates it every deploy.
  - To debug a failed deploy: Vercel dashboard → project → Deployments → the failed one → **Deploy Logs**, then click the "❌ N" error filter — the real compiler error is usually buried under `flutter_tools` async stack-trace noise above it.

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
- No framework-level logging setup — debug output goes through `rag_log()` in `rag/logging_utils.py`, gated by `RAG_DEBUG` env var. Don't introduce `print()` elsewhere; route RAG-related debug output through the existing logger helper.
- Routes in `main.py` stay thin — business logic belongs in `services/*.py` or `rag/*.py`, not inline in route handlers.
- Docstrings are used sparingly, only to explain *why* (a non-obvious regex, a workaround, an ordering constraint) — see existing one-liners in `dictionary_service.py` and `rag/retrieval.py` as the model. Don't add docstrings that restate the function name.
- Arabic string literals (prompts, regexes, error messages) are common and intentional — don't "fix" or reformat Arabic text unless the task is specifically about it.
- Tests follow the `TestXxx` class-per-endpoint-group pattern in `backend/tests/test_api.py` (pytest, `TestClient`).

**Frontend (Flutter/Dart)**
- Standard `flutter_lints` rules (`flutter_app/analysis_options.yaml`), nothing customized.
- Module layout: `lib/src/modules/<feature>/{pages,providers,forms,widgets}/`, plus `services/` for a module-scoped `ApiService` wrapper and a per-module models folder when the module owns its own models (e.g. `chat/models/`; `home/` uses `home_models/` instead of `models/` to avoid shadowing `core/models/` on import — an existing quirk, not a pattern to imitate elsewhere). New features should follow the `pages/providers/widgets` shape at minimum.
- Cross-feature shared widgets live in `lib/src/widgets/` (e.g. `app_scaffold.dart`, `empty_state.dart`), not inside a module's own `widgets/` folder.
- `ApiService` (`lib/src/core/services/api_service.dart`) is the single HTTP *transport* boundary (`getJson`/`postJson`, URI building, timeouts) plus a couple of endpoints shared across multiple modules (`listWords`, `sendChatMessage`). Module-specific endpoints live in scoped services that wrap it — `DictionaryService` (`modules/dictionary/services/dictionary_service.dart`, `/search` + `/feedback`) and `HomeService` (`modules/home/services/home_service.dart`, `/random` + `/sections`) — exposed via `@riverpod` providers (`dictionaryServiceProvider`/`homeServiceProvider`) that inject `apiServiceProvider`. Every method still catches its own errors and returns an Arabic-language fallback/error state rather than throwing. When adding a new endpoint, ask whether it belongs on the shared `ApiService` (used by 2+ modules) or a new/existing module-scoped service (used by one) before defaulting to bolting it onto `ApiService`.
- Backend route paths are centralized in `ApiEndpoints` (`lib/src/configs/api_endpoints.dart`) and frontend GoRouter paths in `AppRoutes` (`lib/src/core/routing/app_routes.dart`) — don't inline a `'/some-path'` string literal in a service or `router.dart` when one of these already exists or should be extended.
- UI copy (titles, hints, error/empty-state text, snackbars — not dataset/lexicon content) is centralized in `AppStrings` (`lib/src/core/strings/app_strings.dart`), grouped by screen/widget. Add new literals there instead of inlining Arabic strings in widgets, so text can't drift or duplicate silently across screens.
- **Text input fields:** use `AppTextField` (`lib/src/widgets/text_input.dart`) instead of a raw `TextField`/`ReactiveTextField`. It switches internally between a plain `TextEditingController` and a `reactive_forms` `formControlName` (pass exactly one), and exposes an `AppTextFieldVariant` (`standard`/`pill`/`compact`) for the few real visual differences that exist across the app (default themed field, the borderless chat pill, the dictionary feedback box's custom radius). Don't hand-roll a new `InputDecoration` for a text field — extend `AppTextField`'s variant enum instead if a genuinely new look is needed.
- Generated files (`*.freezed.dart`, `*.g.dart`, `*.gform.dart`) are gitignored and must be regenerated after touching annotated classes:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Never hand-edit generated files.

## Important files

| File | Purpose |
|---|---|
| [backend/app/main.py](backend/app/main.py) | All API routes |
| [backend/app/rag/pipeline.py](backend/app/rag/pipeline.py) | `get_rag_answer()` / `get_chat_answer()` — the actual live RAG entry points |
| [backend/app/core/data_store.py](backend/app/core/data_store.py) | Supabase client + all read/write queries |
| [backend/app/services/dictionary_service.py](backend/app/services/dictionary_service.py) | Search/scoring/formatting on top of `data_store` |
| [backend/app/services/phrase_conversion_service.py](backend/app/services/phrase_conversion_service.py) | Chunked phrase conversion |
| [backend/app/core/config.py](backend/app/core/config.py) | Constants, paths, Supabase env var names, chunk sizes |
| [backend/app/schemas.py](backend/app/schemas.py) | All Pydantic request/response models (`Entry` now has `word_vocalized`, `pos`, `region`, `tags`, `proverbs`, etc. — Supabase schema, not the old flat lexicon shape) |
| [backend/.env.example](backend/.env.example) | Required env vars and their exact names — check this before assuming a var name |
| [backend/data/hadrami_dataset.json](backend/data/hadrami_dataset.json) | Local staging copy for dataset maintenance scripts — **not read by the running app** |
| [backend/data/eval_pairs.json](backend/data/eval_pairs.json) | Held-out Hadrami↔MSA pairs for evaluation |
| [backend/scripts/](backend/scripts/) | Dataset audit/refactor/validate scripts (tracked) |
| [scripts/sync_to_supabase.py](scripts/sync_to_supabase.py) | Pushes the local staged dataset to Supabase (service-role key required) |
| [scripts/eval/](scripts/eval/) | Hallucination/intent/lookup/conversion eval suite |
| [flutter_app/vercel_build.sh](flutter_app/vercel_build.sh) | Vercel build script — installs Flutter, runs codegen, builds web. Read the Deployment section above before touching this. |
| [flutter_app/lib/src/core/services/api_service.dart](flutter_app/lib/src/core/services/api_service.dart) | Shared HTTP transport (`getJson`/`postJson`) + cross-module endpoints (`listWords`, `sendChatMessage`) |
| [flutter_app/lib/src/modules/dictionary/services/dictionary_service.dart](flutter_app/lib/src/modules/dictionary/services/dictionary_service.dart) | Dictionary-scoped `/search` + `/feedback` calls, wraps `ApiService` |
| [flutter_app/lib/src/modules/home/services/home_service.dart](flutter_app/lib/src/modules/home/services/home_service.dart) | Home-scoped `/random` + `/sections` calls, wraps `ApiService` |
| [flutter_app/lib/src/configs/api_endpoints.dart](flutter_app/lib/src/configs/api_endpoints.dart) | Backend route path constants, kept in sync with `backend/app/main.py` |
| [flutter_app/lib/src/core/routing/app_routes.dart](flutter_app/lib/src/core/routing/app_routes.dart) | Frontend GoRouter path constants, incl. legacy redirect targets (`/search`, `/ask`, `/phrase-translate`) |
| [flutter_app/lib/src/core/strings/app_strings.dart](flutter_app/lib/src/core/strings/app_strings.dart) | Centralized UI copy (mostly Arabic), grouped by screen/widget |
| [flutter_app/lib/src/configs/api_config.dart](flutter_app/lib/src/configs/api_config.dart) | Backend base URL (baked in at build time via `--dart-define=API_BASE_URL`), timeouts |
| [docs/methods_evaluation.md](docs/methods_evaluation.md) | Architecture + evaluation protocol write-up (partly aspirational — verify claims against actual code/data before citing) |
| [ROADMAP.md](ROADMAP.md) | Prioritized backlog — check before proposing "new" improvements, they may already be tracked |

## Rules for modifying code

- **Never commit `backend/.env`** — it holds `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`. Already gitignored; don't remove it from `.gitignore`. Note: this file has gone missing from the local checkout more than once during branch churn — if backend calls are failing locally with a `RuntimeError` about `SUPABASE_URL`/`SUPABASE_SERVICE_KEY`, check it exists before assuming a code bug (see [backend/.env.example](backend/.env.example) for the required shape).
- **Database writes:** `SUPABASE_SERVICE_KEY` is the `service_role` secret and bypasses row-level security. Never run `UPDATE`/`INSERT`/`DELETE` against Supabase (directly, via `data_store.py`, or via `scripts/sync_to_supabase.py`) without explicit per-step user approval.
- **Never write to `backend/data/hadrami_dataset.json` and expect it to affect the running app** — it's a staging file, not the data source. Dataset edits go through `backend/scripts/` (`refactor_dataset.py`, etc.) → validate (`validate_dataset.py`) → `scripts/sync_to_supabase.py` to push to Supabase. Ad-hoc edits to the local file alone do nothing in production.
- **Don't reformat or "clean up" Arabic text** (prompts, dataset entries, error strings) as a side effect of an unrelated change — dialect spelling and MSA glosses are content, not style.
- **Don't silently change RAG fallback/degrade behavior** without flagging it — check `backend/app/rag/pipeline.py` for the current fallback path before assuming it matches older descriptions of this system.
- **Regenerate Flutter codegen** after touching any `@freezed`, `@JsonSerializable`, `@riverpod`, or `@ReactiveFormAnnotation`-decorated class (`dart run build_runner build --delete-conflicting-outputs`); don't hand-patch generated output, and don't commit `*.freezed.dart`/`*.g.dart`/`*.gform.dart` — they're gitignored on purpose and regenerated by `vercel_build.sh` on every deploy.
- **`backend/app/rag_engine.py` was deleted** (dead backward-compat shim, zero importers) — the RAG pipeline lives entirely in `backend/app/rag/`.
- **Frontend nav is 4 destinations** (Home, Dictionary, Favorites, Chat) — Search, Ask, and Phrase-translate were merged in as redundant with Dictionary/Chat and their modules deleted; `/search`, `/ask`, `/phrase-translate` are GoRouter redirects now, not real pages. Don't re-add a standalone page for one of these without confirming with the user first — it was a deliberate consolidation, not an oversight.
- **Run tests before declaring backend changes done:** `cd backend && python -m pytest tests/ -v`.
- **After any change touching `flutter_app/pubspec.yaml`, `vercel_build.sh`, or `vercel.json`, verify locally before pushing to `main`:** `flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter build web --release`. This exact gap (untested Vercel-only build path) caused a production outage on 2026-07-27 — see the Deployment section above.
- Don't add authentication, rate limiting, or other ROADMAP "High Priority" items speculatively — implement them only when the user asks for that specific item.

## Dataset copyright / usage rules

- The Hadrami lexicon (`hadrami_dataset.json`) is described in-repo as "compiled from dialect references and community contributions." Treat it as the project owner's proprietary research dataset, not public-domain data:
  - Do not upload, paste, or transmit the dataset (or non-trivial excerpts of it) to third-party tools, external APIs, gists, or pastebins without the user's explicit, per-instance approval — this includes export tooling like `scripts/export/to_huggingface.py`/`to_kaggle.py`. Publishing the dataset is a deliberate research decision for the user to make, not something to do proactively.
  - The `feedback` table (Supabase) holds user-submitted contributions gated by an explicit `consent` flag (`FeedbackRequest.consent`). Never merge feedback entries into the main dataset, and never export/share feedback data, without checking the `consent` flag was set to `true` for each entry.
  - No personally identifiable information should be stored or added to dataset entries or feedback records.
  - When citing example sentences or definitions in documentation, commit messages, or PR descriptions, keep excerpts short (a few words) — don't reproduce large verbatim blocks of the lexicon outside the dataset file itself.
- If asked to scrape, generate, or "borrow" dialect content from external published sources (dictionaries, books, social media) to grow the lexicon, flag the copyright/licensing question to the user explicitly rather than proceeding — this is called out as a real risk in the project's own ethics notes (`docs/methods_evaluation.md`).
