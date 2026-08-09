# Roadmap — Future Improvements

A prioritized list of improvements and new features for the Hadrami NLP project.
Items are grouped by area and roughly ordered by impact.

---

## High Priority

### Dataset Quality

*Re-baselined 2026-08-08 against a fresh `python scripts/audit_dataset.py` run on the live 1047-entry dataset — the previous bullets here (170/1026 `fus7a_short`, 338 examples) described a schema from an earlier refactor pass (`v1.1.0`) that no longer matches the live dataset (`fus7a_short` isn't a field at all today; it was superseded by a later full-stack refactor to the current `word_vocalized`/`fusha_equivalent`/`word_clean` schema). Current real gaps, largest first:*

- [ ] **Add phonetic transcription**: only 29/1047 (2.8%) entries have `phonetic_variants` populated. Include IPA or a simplified phonetic field to help non-native learners with pronunciation.
- [ ] **Add usage notes**: 620/1047 (59.2%) entries have a `note`; the rest don't.
- [ ] **Add proverbs**: only 89/1047 (8.5%) entries have `proverbs`.
- [ ] **Add synonyms**: 742/1047 (70.9%) entries have `synonyms`.
- [ ] **Backfill missing examples**: 1043/1047 (99.6%) entries have at least one example; 4 entries have none. Of the 1268 example pairs, 1267 (99.9%) already have both the Hadrami and MSA side — only 1 pair is missing its MSA gloss. This gap is nearly closed already; low remaining effort.
- [ ] **Expert review workflow**: Recruit native Hadrami speakers to verify `fusha_equivalent` glosses and usage examples. Distribute via spreadsheet batches and track with a `verified_by` field.
- [ ] **Grow the lexicon to 2000+ entries**: Collect new words from community contributions, social media, and published Hadrami dialect resources. See `CLAUDE.md`'s "Dataset copyright / usage rules" before scraping any external source — needs explicit per-source approval.

### Backend

- [ ] **Add authentication**: Protect `/admin/*` endpoints and track feedback submitters. Consider simple API keys or OAuth.
- [ ] **Rate limiting**: Add rate limits to Gemini-powered endpoints (`/ask`, `/convert-phrase`) to control API costs.
- [ ] **Caching layer**: Cache Gemini responses for repeated queries to reduce latency and cost. Redis or in-memory LRU.
- [ ] **Structured logging**: Replace print-based logging with Python `logging` module and structured JSON output for production.
- [ ] **Migrate to `google-genai`**: The current `google-generativeai` package is deprecated. Migrate to the new `google-genai` SDK.

### Frontend

- [ ] **Offline mode**: Cache the dictionary locally so basic search/interpret works without internet. Use `sqflite` or `hive`.
- [ ] **Search suggestions / autocomplete**: Show suggestions as the user types, before they finish the query.
- [ ] **Onboarding flow**: First-launch tutorial explaining the app's features and how Hadrami dialect differs from MSA.
- [ ] **Accessibility**: Full screen reader support, semantic labels, and sufficient contrast ratios.

---

## Medium Priority

### Features

- [ ] **Favorites sync**: Sync favorites across devices using Firebase or a simple backend endpoint.
- [ ] **Word of the Day notifications**: Daily push notification with a random Hadrami word and its meaning.
- [ ] **Audio pronunciation**: Record native speaker audio clips for common words. Play them from the word detail sheet.
- [ ] **Flashcard mode**: Spaced repetition learning mode for saved words.
- [ ] **Sentence pairs corpus**: Build a parallel sentence corpus (Hadrami ↔ MSA) for better phrase conversion and potential model fine-tuning.
- [ ] **Community contributions**: In-app word submission form that goes through a review queue before entering the main dataset.
- [ ] **Share word cards**: Generate shareable image cards for social media with a word, its meaning, and an example.

### Backend Improvements

- [x] **Evaluation pipeline**: Automated chrF/BLEU scoring already exists in `backend/scripts/evaluate.py` (uses `sacrebleu`, reads `backend/data/eval_pairs.json`, supports 5 systems, reports latency/domain breakdown) — it was just undocumented as done. Separately, `scripts/eval/` has a hallucination/intent/lookup/conversion suite (`CLAUDE.md`-referenced). Known gap: `eval_pairs.json` pairs have no `gold_ids`, so Recall@k/MRR never actually run against them — that's a content/annotation task, not a code gap.
- [ ] **API versioning**: Introduce `/v1/` prefix to allow backward-compatible API evolution.
- [ ] **Batch conversion endpoint**: Accept multiple words or phrases in a single request to reduce round trips.
- [ ] **WebSocket for streaming**: Stream long phrase conversions token-by-token for better UX.

### Code Quality

- [ ] **Backend integration tests**: Expand beyond smoke tests to cover edge cases, Unicode handling, and concurrent requests.
- [ ] **Flutter widget tests**: Add widget tests for key screens (home, search, dictionary).
- [ ] **CI/CD pipeline**: GitHub Actions for automated testing, linting, and deployment.
- [ ] **Docker support**: Dockerfile for the backend to simplify deployment and ensure consistent environments.
- [ ] **Pre-commit hooks**: Auto-format Python (black/ruff) and Dart (dart format) on commit.

---

## Low Priority / Long-term

- [ ] **Multi-dialect support**: Extend the architecture to support other Arabic dialects alongside Hadrami.
- [ ] **Fine-tuned model**: Fine-tune a smaller language model on the parallel corpus for faster, cheaper, offline-capable conversion.
- [ ] **Admin dashboard**: Web-based admin panel for managing the lexicon, reviewing feedback, and monitoring usage.
- [ ] **Public API**: Publish the API with documentation for third-party developers to build on.
- [ ] **Hadrami keyboard**: Custom keyboard layout or input method for typing Hadrami-specific expressions.
- [ ] **OCR support**: Scan handwritten or printed Hadrami text and convert it to MSA.
- [ ] **Voice input/output**: Speech-to-text for Hadrami dialect input and text-to-speech for pronunciation.

---

## Completed

- [x] **Fixed P0 chat/conversion outage (2026-08-08)**: `phrase_top_score()` always returned 0 (`search_phrase_lexicon()` never set the key it reads), and the phrase scorer ignored Arabic normalization (diacritics/alef variants), so real content words scored 0 while short stopword substrings scored high — together these made dialect conversion refuse almost every input. Also fixed: `_SEMANTIC_PATTERN` missing `كلمة تستخدم`, and added `sanitize_model_reply()` to strip prompt-scaffold leaks (raw `id: N`, echoed context/role labels) from Gemini replies. Verified live against the exact failing cases in `docs/chat_testing.md`. See that doc's §4 for full detail and what's still open (prod deploy config, Supabase RLS finding — separate decisions, not code bugs).
- [x] Migrated from in-memory JSON store to Supabase (PostgreSQL + pgvector)
- [x] Added pgvector-based semantic search (`/semantic-search` endpoint + `match_entries` RPC)
- [x] Gemini text-embedding-004 integration for 768-dim entry embeddings
- [x] Supabase sync script with embedding backfill (`scripts/sync_to_supabase.py`)
- [x] Deep semantic structuring: POS classification, thematic categories, proverb extraction, archaic detection
- [x] Dataset refactoring: fix truncated fus7a, merge duplicates, extract examples (v1.1.0)
- [x] New schema fields: `fus7a_short`, `aliases`, `examples` (HA-6)
- [x] Extended feedback types: correction, new_word, sentence_pair, spelling_variant (HA-5)
- [x] Chunked phrase conversion for long texts (HA-9)
- [x] Dataset validation and audit scripts (HA-11)
- [x] Evaluation pairs for benchmarking (HA-12)
- [x] UI polish: animations, dark mode persistence, responsive navigation
- [x] Search debouncing for performance
- [x] Backend API smoke tests (21 tests)
- [x] Replaced deprecated `@app.on_event("startup")` with modern `lifespan` context manager
- [x] Added `__init__.py` files to backend packages for proper module resolution