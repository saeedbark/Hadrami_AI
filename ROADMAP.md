# Roadmap — Future Improvements

A prioritized list of improvements and new features for the Hadrami NLP project.
Items are grouped by area and roughly ordered by impact.

---

## High Priority

### Dataset Quality

- [ ] **Expert review workflow**: Recruit native Hadrami speakers to verify `arabic_fus7a` glosses and usage examples. Distribute via spreadsheet batches and track with a `verified_by` field.
- [ ] **Complete fus7a_short coverage**: Currently 170/1026 entries have concise glosses. Use Gemini to suggest short glosses for the remaining entries, then human-verify.
- [ ] **Fill fusha side of examples**: The 338 extracted examples only have the Hadrami side. Add MSA translations to create proper parallel pairs useful for training.
- [ ] **Grow the lexicon to 2000+ entries**: Collect new words from community contributions, social media, and published Hadrami dialect resources.
- [ ] **Add phonetic transcription**: Include IPA or a simplified phonetic field to help non-native learners with pronunciation.

### Backend

- [ ] **Migrate to a real database**: Replace the in-memory JSON store with SQLite or PostgreSQL for better query performance, concurrent writes, and full-text search.
- [ ] **Add authentication**: Protect `/admin/*` endpoints and track feedback submitters. Consider simple API keys or OAuth.
- [ ] **Rate limiting**: Add rate limits to Gemini-powered endpoints (`/ask`, `/translate-phrase`) to control API costs.
- [ ] **Caching layer**: Cache Gemini responses for repeated queries to reduce latency and cost. Redis or in-memory LRU.
- [ ] **Structured logging**: Replace print-based logging with Python `logging` module and structured JSON output for production.
- [ ] **Migrate to `google-genai`**: The current `google-generativeai` package is deprecated. Migrate to the new `google-genai` SDK.

### Frontend

- [ ] **Offline mode**: Cache the dictionary locally so basic search/translate works without internet. Use `sqflite` or `hive`.
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
- [ ] **Sentence pairs corpus**: Build a parallel sentence corpus (Hadrami ↔ MSA) for better phrase translation and potential model fine-tuning.
- [ ] **Community contributions**: In-app word submission form that goes through a review queue before entering the main dataset.
- [ ] **Share word cards**: Generate shareable image cards for social media with a word, its meaning, and an example.

### Backend Improvements

- [ ] **Vector search with embeddings**: Replace keyword-based RAG retrieval with proper embedding similarity (e.g., `sentence-transformers` + ChromaDB or FAISS).
- [ ] **Evaluation pipeline**: Automated chrF/BLEU scoring against `eval_pairs.json` to track translation quality over time.
- [ ] **API versioning**: Introduce `/v1/` prefix to allow backward-compatible API evolution.
- [ ] **Batch translation endpoint**: Accept multiple words or phrases in a single request to reduce round trips.
- [ ] **WebSocket for streaming**: Stream long phrase translations token-by-token for better UX.

### Code Quality

- [ ] **Backend integration tests**: Expand beyond smoke tests to cover edge cases, Unicode handling, and concurrent requests.
- [ ] **Flutter widget tests**: Add widget tests for key screens (home, search, dictionary).
- [ ] **CI/CD pipeline**: GitHub Actions for automated testing, linting, and deployment.
- [ ] **Docker support**: Dockerfile for the backend to simplify deployment and ensure consistent environments.
- [ ] **Pre-commit hooks**: Auto-format Python (black/ruff) and Dart (dart format) on commit.

---

## Low Priority / Long-term

- [ ] **Multi-dialect support**: Extend the architecture to support other Arabic dialects alongside Hadrami.
- [ ] **Fine-tuned model**: Fine-tune a smaller language model on the parallel corpus for faster, cheaper, offline-capable translation.
- [ ] **Admin dashboard**: Web-based admin panel for managing the lexicon, reviewing feedback, and monitoring usage.
- [ ] **Public API**: Publish the API with documentation for third-party developers to build on.
- [ ] **Hadrami keyboard**: Custom keyboard layout or input method for typing Hadrami-specific expressions.
- [ ] **OCR support**: Scan handwritten or printed Hadrami text and translate it.
- [ ] **Voice input/output**: Speech-to-text for Hadrami dialect input and text-to-speech for pronunciation.

---

## Completed

- [x] Dataset refactoring: fix truncated fus7a, merge duplicates, extract examples (v1.1.0)
- [x] New schema fields: `fus7a_short`, `aliases`, `examples` (HA-6)
- [x] Extended feedback types: correction, new_word, sentence_pair, spelling_variant (HA-5)
- [x] Chunked phrase translation for long texts (HA-9)
- [x] Dataset validation and audit scripts (HA-11)
- [x] Evaluation pairs for benchmarking (HA-12)
- [x] UI polish: animations, dark mode persistence, responsive navigation
- [x] Search debouncing for performance
- [x] Backend API smoke tests (21 tests)
