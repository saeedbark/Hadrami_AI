# Methods, Architecture & Evaluation Protocol

> Honest, reproducible description of the Hadrami NLP system. Pairs with
> the codebase in this repo; every claim below is backed by a pointer to
> the implementation or the test that guards it.

## 1. System overview

The Hadrami NLP system is a **lexicon-grounded, retrieval-augmented
generation (RAG) system** for a low-resource Arabic variety (Hadrami
Arabic, spoken in Hadhramaut, Yemen). It exposes four user-facing tasks:

| Task | Endpoint | Grounding strategy |
|------|----------|-------------------|
| Word translation | `GET /translate` | Exact / partial scoring over the lexicon (no LLM) |
| Phrase translation | `POST /translate-phrase` | Retrieve lexicon entries → prompt Gemini → lexicon-filter spans |
| Semantic search | `GET /semantic-search` | pgvector ANN over Gemini 768-dim embeddings |
| Q&A | `GET·POST /ask`, `POST /chat` | Hybrid retrieval → grounded prompt → refusal when empty |

### 1.1 Architecture

```
┌──────────────────┐            ┌────────────────────────────────────────────┐
│  Flutter client  │◄─── HTTP ──►│              FastAPI backend               │
│  (Riverpod +     │             │  ┌──────────────────────────────────────┐  │
│   go_router)     │             │  │  app.rag.retrieval                   │  │
└──────────────────┘             │  │   ├─ search_entries_expanded (SQL)   │  │
                                 │  │   ├─ match_entries (pgvector RPC)    │  │
                                 │  │   └─ merge-by-id orchestrator        │  │
                                 │  └──────────────────────────────────────┘  │
                                 │  ┌──────────────────────────────────────┐  │
                                 │  │  app.rag.prompts                     │  │
                                 │  │   └─ lexicon-grounded templates      │  │
                                 │  └──────────────────────────────────────┘  │
                                 │  ┌──────────────────────────────────────┐  │
                                 │  │  app.rag.generation (Gemini)         │  │
                                 │  │   └─ primary + 3 fallback models     │  │
                                 │  └──────────────────────────────────────┘  │
                                 │  ┌──────────────────────────────────────┐  │
                                 │  │  app.rag.pipeline                    │  │
                                 │  │   └─ retrieve → prompt → generate    │  │
                                 │  │        → grounded-fallback-if-empty   │  │
                                 │  └──────────────────────────────────────┘  │
                                 │                                            │
                                 │  ┌──────────────────────────────────────┐  │
                                 │  │  Supabase (Postgres + pgvector)      │  │
                                 │  │   • entries  (lexicon + embeddings)  │  │
                                 │  │   • feedback (user submissions)      │  │
                                 │  │   • SQL fns: match_entries,          │  │
                                 │  │              search_entries_expanded │  │
                                 │  └──────────────────────────────────────┘  │
                                 └────────────────────────────────────────────┘
```

All modules are under `backend/app/`. The `rag/` subpackage is the core
research contribution (see §3).

## 2. Data

### 2.1 Lexicon (`backend/data/hadrami_dataset.json` → Supabase `entries`)

The lexicon is versioned in-repo and synced to Supabase via
`scripts/sync_to_supabase.py`. Each entry matches the Pydantic `Entry`
model in `backend/app/schemas.py`:

| Field | Type | Required | Role in retrieval |
|-------|------|----------|-------------------|
| `id` | int | ✅ | Dedup key for hybrid merge |
| `word_vocalized` | str | ✅ | Primary headword; exact-match score = 100 |
| `word_clean` | str? | — | Un-vocalized form for relaxed matching |
| `root` | str? | — | Classical root (optional retrieval signal) |
| `pos` | str? | — | Part of speech (Noun, Verb, Adjective, Adverb, Expression, Noun/Verb, …) |
| `fusha_equivalent` | str? | — | MSA gloss (primary Hadrami→MSA supervision signal) |
| `definition` | str? | — | Definition / usage notes |
| `region` | str | — | Sub-regional tag (default `"General"`) |
| `synonyms` | str[]? | — | Alternative Hadrami forms (also score-100 on exact match) |
| `phonetic_variants` | str[]? | — | Spelling / phonetic variants |
| `note` | str? | — | Free-form note |
| `source` | str? | — | Provenance |
| `examples` | `{h,f}[]?` | — | Hadrami↔MSA sentence pairs (grounding evidence) |
| `proverbs` | `(str | {h,f})[]?` | — | Related proverbs / sayings |
| `tags` | str[]? | — | Topical tags |

Data quality is enforced by `backend/scripts/validate_dataset.py`
(required fields, type coercion, allowed POS values) and monitored by
`backend/scripts/audit_dataset.py` (coverage, POS distribution, length
histograms).

**Current size.** The exact `total` is printed by `validate_dataset.py`
and by the `/stats` endpoint. Counts in documentation should not be
hardcoded.

**Ethics.** User-submitted feedback requires an explicit `consent` flag.
Client User-Agent is truncated to 512 chars before persistence; client IP
is stored only when it is a valid RFC-compliant IP (fabricated values
from test clients are dropped — see `backend/app/main.py`
`submit_feedback`).

### 2.2 Embeddings

- Model: Gemini `gemini-embedding-001` (768-dim, task
  `RETRIEVAL_DOCUMENT` for entries, `RETRIEVAL_QUERY` for queries).
- Embedding payload: concatenation of `word_vocalized`, `synonyms`,
  `fusha_equivalent`, `definition`, `note`, and the first 3 example
  pairs. Assembled in
  `scripts/sync_to_supabase.py::_embedding_text_for_entry`.
- Stored in the `embedding` column (`vector(768)`) with an HNSW index
  (or IVFFlat fallback) configured in Supabase.
- Re-embedding is triggered by the `embedding_dirty = true` flag, which
  can be set by migration scripts after content changes.

### 2.3 Evaluation pairs (`backend/data/eval_pairs.json`)

Held-out Hadrami↔MSA sentence pairs collected independently from the
lexicon. They are not used for retrieval or as few-shot exemplars during
inference; they exist solely for the evaluation protocol in §4.

## 3. Methods

### 3.1 Word-level translation (`/translate`)

Implemented in `dictionary_service.translate`. Deterministic, non-LLM:

1. **Exact match** on `word_vocalized`, `word_clean`, or `synonyms` → score 100.
2. **Prefix / substring** match → score 70–80.
3. **Definition containment** → score 40–60.
4. **Not found** → structured response with `found=false` and a
   suggestion to rephrase.

No LLM call, no hallucination risk. Used as the reliable lower bound of
the system.

### 3.2 Semantic search (`/semantic-search`)

1. Query → `gemini-embedding-001` (768-dim, `RETRIEVAL_QUERY` task).
2. `match_entries(query_embedding, match_threshold, match_count)` SQL
   function returns top-k entries by cosine similarity above the
   threshold (default 0.25, client-overridable).
3. Response includes similarity score per hit.

### 3.3 Phrase translation (`/translate-phrase`)

Implemented in `services/phrase_translation_service.py` using
`rag.retrieval.retrieve_phrase_context` and `rag.prompts.phrase_prompt`:

1. **Lexicon-first retrieval** — `search_phrase_lexicon` tokenizes the
   input, scores each token against headwords / synonyms /
   phonetic_variants, and deduplicates. A pgvector pass augments
   semantically-related entries.
2. **Chunking** — inputs > `PHRASE_TRANSLATE_CHUNK_SIZE` (default
   800 chars) are split on paragraph boundaries (then sentence
   boundaries if needed) and translated with bounded thread-pool
   parallelism (`PHRASE_TRANSLATE_MAX_WORKERS`, default 3, max 8).
3. **Grounded prompt** — the prompt mandates that every
   dialectal mapping be licensed by an entry in the retrieved
   context (headword, synonym, or example). Function words
   (prepositions, pronouns, conjunctions) are the only exemption
   because they are shared with MSA. If the context is empty, the model
   is instructed to return an empty string and
   `"note": "insufficient_lexicon_coverage"`.
4. **Span post-processing** — the model returns
   `{"translated_text": "...", "hadrami_spans": [...], "note": "..."}`.
   Spans are normalized (Arabic alef variants collapsed, tashkeel
   stripped) and **filtered to the retrieved lexicon surfaces** — no
   span survives that doesn't match a headword or MSA gloss in the
   retrieved context (`_filter_spans_to_lexicon`).
5. **Merge across chunks** — span offsets are remapped to the merged
   output.

### 3.4 Q&A (`/ask`) and chat (`/chat`)

Implemented in `rag/pipeline.py`.

1. **Translation-intent detection** — `/ask` questions matching a
   translation pattern (`ترجم`, `إلى الفصحى`, etc.) are routed to the
   phrase-translation pipeline.
2. **Hybrid retrieval** — `retrieve_rag_context`:
   - `search_entries_expanded` (server-side, PostgREST RPC) for scored
     keyword matches over headword, synonyms, gloss, and definition.
   - If the top keyword score < 100, a pgvector pass via `match_entries`
     augments the results.
   - Results merged by ID, top-5 returned for the prompt.
3. **Grounded prompting** — `rag.prompts.rag_prompt` / `chat_prompt`
   force the model to quote `fusha_equivalent`, `synonyms`, and
   examples verbatim and forbid fabricated meanings. When retrieval
   returns zero entries, `rag_prompt_no_hits` forbids any answer beyond
   a one-line admission.
4. **Deterministic fallback** — when the Gemini call fails (rate limit,
   network, missing API key), `_lexicon_fallback_answer` composes a
   grounded reply **only** when `top_score ≥ 70`; otherwise it returns
   `_INSUFFICIENT_CONTEXT_MSG`. This single threshold is the most
   important hallucination guard in the system — it is regression-tested
   by `test_ask_with_irrelevant_question_refuses_or_admits`.

### 3.5 Caching

`rag.retrieval` uses an in-process TTL cache (`RAG_CACHE_TTL_SECONDS`,
default 90 s) for expanded-keyword and vector retrieval. The cache is
per-process (fine for a single-worker dev server), but does **not** span
replicas; a real deployment should front the RPC endpoints with Redis or
a CDN for true multi-replica reuse. This is flagged honestly in §5.

## 4. Evaluation protocol

### 4.1 Automatic metrics

Using `backend/data/eval_pairs.json`:

| Metric | Purpose |
|--------|---------|
| **chrF / chrF++** | Character-level F-score; robust to Arabic morphology |
| **BLEU-4** | n-gram precision, standard MT reference |
| **Exact Match** | Surface-exact matches (mostly a sanity bound) |
| **Recall@k** | Fraction of pairs whose gold head-word is in top-k retrieval |
| **MRR** | Mean reciprocal rank of the gold head-word in retrieval |

Recall@k and MRR are retrieval-only metrics; they stress the lexicon +
retrieval layer independently of the LLM.

### 4.2 Baselines

| System | Retrieval | Generation | Role |
|--------|-----------|------------|------|
| `keyword_only` | Expanded keyword | deterministic fallback | pure-lexicon lower bound |
| `vector_only` | pgvector ANN only | deterministic fallback | retrieval-quality ablation |
| `plain_gemini` | — (no context) | Gemini `2.5-flash` | zero-shot LLM ceiling |
| `ours_local` (default) | Hybrid (keyword ∪ vector) | Gemini + grounded prompt | main system |
| `ours_simple` | Keyword only | Gemini + grounded prompt | prompt-grounding ablation |
| `ceiling_pro` | Hybrid | Gemini Pro / larger model | capability ceiling |

Switch between systems via `RAG_MODE` (`local` / `simple`) and
`GEMINI_MODEL`. Disable retrieval entirely by pointing at a build that
bypasses `retrieve_rag_context` (not yet implemented in-tree; tracked in
[ROADMAP.md](../ROADMAP.md)).

### 4.3 Human evaluation

- **Adequacy** (1–5): does the output preserve meaning?
- **Fluency** (1–5): is it natural in the target variety?
- **Dialect fidelity** (1–5): for MSA→Hadrami, does it sound authentically Hadrami?
- **Grounding** (binary): is every dialectal form in the output traceable
  to a retrieved lexicon entry?

Minimum 2 native Hadrami speakers; Cohen's κ reported for each axis.

### 4.4 Running the evaluation

```bash
python backend/scripts/evaluate.py \
    --pairs backend/data/eval_pairs.json \
    --system ours_local \
    --output results/ours_local.json
```

The `evaluate.py` script is tracked under ROADMAP item D1 — it will emit
a JSON report with per-pair hypotheses, retrieval hits, chrF/BLEU
numbers, and Recall@k/MRR for the retrieval stage.

## 5. Limitations & ethical considerations

**Dataset scale.** The lexicon is on the order of 10³ entries. Many
regional and register-specific forms are unavoidably out of coverage.
The system addresses this by refusing to answer rather than fabricating,
but that refusal will be visible to users and should be communicated
transparently in the UI.

**Regional variation.** Coastal vs inland Hadrami, as well as diaspora
varieties, are not tagged consistently. The `region` field defaults to
`"General"` and should not be interpreted as a validated sub-dialect
label without further annotation.

**LLM hallucination risk.** Even with grounded prompting, Gemini may
paraphrase beyond what the retrieved entries license — especially for
compound sentences where the prompt cannot unambiguously license every
word. The evaluation protocol includes a **grounding** axis specifically
to measure this; regression-tested by
`test_ask_with_irrelevant_question_refuses_or_admits`.

**Cache locality.** The in-process retrieval cache does not span
replicas. A realistic production deployment should front the RPC
endpoints with a shared cache or rely entirely on database-level caching.

**Embedding drift.** Re-embedding is gated by `embedding_dirty`. If
rows are edited directly in Supabase without setting this flag, vector
retrieval will silently point at stale semantics.

**Evaluation honesty.** `eval_pairs.json` is small (<50 pairs at time
of writing). Reported chrF/BLEU numbers should always be accompanied by
the pair count and — once available — human-eval κ.

**Privacy / consent.** Feedback submission requires the `consent` flag.
Client IP is persisted only when it is a valid IP; User-Agent is
truncated to 512 chars. No tokens, API keys, or device identifiers are
stored. Row-Level Security on the `feedback` table restricts inserts to
the service-role key.

**SDK deprecation.** The current implementation uses
`google-generativeai`, which Google has deprecated in favor of
`google-genai`. Migration is tracked in [ROADMAP.md](../ROADMAP.md).

## 6. Reproducibility checklist

| Concern | Status |
|---------|--------|
| Pinned Python version | `requirements.txt` + `pyproject.toml` |
| Pinned dataset version | `hadrami_dataset.json` committed |
| Pinned Gemini model | `GEMINI_MODEL` env var, default `gemini-2.5-flash` |
| Deterministic retrieval | yes when keyword-only; vector results deterministic modulo floating-point ties |
| Deterministic generation | partial (`temperature=0.35` for chat, default otherwise); set `temperature=0` for evaluation runs |
| Schema validation script | `backend/scripts/validate_dataset.py` |
| Coverage audit script | `backend/scripts/audit_dataset.py` |
| End-to-end test suite | `backend/tests/test_api.py` (26 tests) |
| Evaluation script | tracked as ROADMAP D1 |
| Versioned eval set | `backend/data/eval_pairs.json` |

## 7. Future work

- **Expand the lexicon** to 5K+ entries with expert review and
  region-specific tagging (coastal vs inland vs diaspora).
- **Migrate** from deprecated `google-generativeai` to `google-genai`.
- **Publish** the dataset and evaluation pairs under a permissive license
  with proper provenance metadata.
- **Fine-tune** a smaller open model on verified pairs for offline
  translation (privacy + latency win).
- **Cross-dialect generalization**: test whether the lexicon-grounded
  pipeline transfers to other low-resource Arabic varieties (Mehri,
  Soqotri) without changes to the pipeline.
