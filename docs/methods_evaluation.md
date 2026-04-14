# HA-12: System Architecture, Methods & Evaluation Protocol

## 1. System Overview

The Hadrami NLP system is a bilingual dictionary and translation tool for the Hadrami dialect of Yemeni Arabic. It combines a curated lexicon with RAG (Retrieval-Augmented Generation) to provide:

- **Word-level translation** (Hadrami → MSA)
- **Phrase/paragraph-level translation** (bidirectional: MSA ↔ Hadrami)
- **Semantic search** (vector similarity via pgvector)
- **AI-powered Q&A** about the Hadrami dialect

### Architecture

```
┌──────────────────┐       ┌──────────────────────────────────┐
│  Flutter Client   │◄─────►│        FastAPI Backend            │
│  (Riverpod +      │  HTTP │                                  │
│   go_router)      │       │  ┌────────────────────────────┐  │
└──────────────────┘       │  │   Dictionary Service        │  │
                           │  │   (keyword search, scoring, │  │
                           │  │    pagination, sections)     │  │
                           │  └──────────┬─────────────────┘  │
                           │             │                     │
                           │  ┌──────────▼─────────────────┐  │
                           │  │     RAG Engine              │  │
                           │  │  - Keyword retrieval        │  │
                           │  │  - pgvector similarity      │  │
                           │  │  - Gemini generation        │  │
                           │  └────────────────────────────┘  │
                           │                                  │
                           │  ┌────────────────────────────┐  │
                           │  │   Embedding Service         │  │
                           │  │   (Gemini text-embedding-   │  │
                           │  │    004, 768-dim vectors)     │  │
                           │  └────────────────────────────┘  │
                           │                                  │
                           │  ┌────────────────────────────┐  │
                           │  │  Supabase (PostgreSQL)      │  │
                           │  │  entries table + pgvector   │  │
                           │  │  (~1026 entries + embeddings)│  │
                           │  └────────────────────────────┘  │
                           └──────────────────────────────────┘
```

## 2. Data Sources

### 2.1 Hadrami Lexicon (Supabase `entries` table)

- **Size**: ~1026 entries (as of v1.1.0)
- **Schema**: Each entry has `id`, `hadrami_word`, `arabic_fus7a` (MSA gloss), `full_definition`
- **Optional fields** (HA-6): `examples` (sentence pairs), `aliases` (spelling variants), `fus7a_short` (one-line MSA gloss)
- **Embeddings**: 768-dim vectors from Gemini `text-embedding-004` stored in a `embedding` column (pgvector)
- **Source**: Compiled from dialect references and community contributions; synced via `scripts/sync_to_supabase.py`
- **Ethics**: User-submitted feedback requires consent flag; no personally identifiable information is stored

### 2.2 User Feedback (`feedback.json`)

- Corrections, new word suggestions, sentence pairs, spelling variants
- Requires explicit consent before storage
- Triaged by expert reviewers before merge into main dataset

## 3. Methods

### 3.1 Word-Level Translation

- **Exact match**: Score 100 — Hadrami headword matches query exactly
- **Substring match**: Score 70-80 — partial containment
- **Definition search**: Score 40-60 — query found in fus7a or definition
- Falls back to "not found" with suggestion to rephrase

### 3.2 Semantic Search (pgvector)

1. **Query embedding**: Input text is embedded via Gemini `text-embedding-004` (768-dim, `RETRIEVAL_QUERY` task)
2. **Cosine similarity**: The `match_entries` Postgres function performs cosine-similarity search against stored entry embeddings
3. **Threshold filtering**: Results below the configurable similarity threshold are excluded
4. **Returns**: Top-k entries ranked by semantic similarity

### 3.3 Phrase-Level Translation (RAG + Gemini)

1. **Retrieval**: `search_phrase_lexicon()` with token-wise scoring to avoid short-substring noise
2. **Vector augmentation**: pgvector similarity search merges additional semantically relevant entries
3. **Context building**: Top-5 lexicon matches injected into prompt as dictionary references
4. **Generation**: Gemini (2.5-flash → fallback chain) with structured JSON output
5. **Post-processing**: Span normalization + lexicon-only span filtering
6. **Chunking** (HA-13): Texts > 800 chars split on paragraph/sentence boundaries, translated chunk-by-chunk, reassembled

### 3.4 AI Q&A (RAG)

1. **Retrieval**: Expanded keyword search across headwords, fus7a, definitions
2. **Vector retrieval**: pgvector similarity search via Supabase `match_entries` RPC
3. **Merged context**: Keyword + vector results deduplicated by entry ID
4. **Prompt**: Context-grounded Arabic prompt with example generation
5. **Translation detection**: Auto-detects "translate to MSA" intent and switches to few-shot translation prompt

## 4. Evaluation Protocol

### 4.1 Automatic Metrics

Using `eval_pairs.json` (HA-8) — 20+ held-out Hadrami ↔ MSA sentence pairs:

| Metric | Description |
|--------|-------------|
| **chrF** | Character-level F-score — good for morphologically rich Arabic |
| **BLEU** | n-gram precision — standard MT metric |
| **Exact Match** | Percentage of pairs with exact output match |

### 4.2 Baselines

| System | Description |
|--------|-------------|
| **Plain Gemini** | Gemini 2.5-flash without lexicon context (zero-shot) |
| **System (ours)** | Lexicon-grounded RAG + Gemini with pgvector retrieval |
| **Larger model** | Gemini Pro or GPT-4 without lexicon (capability ceiling) |

### 4.3 Human Evaluation

- **Adequacy** (1-5): Does the translation preserve meaning?
- **Fluency** (1-5): Is the output natural in the target variety?
- **Dialect fidelity** (1-5): For MSA→Hadrami, does it sound authentically Hadrami?
- Minimum 2 native Hadrami speakers as evaluators
- Inter-annotator agreement reported (Cohen's kappa)

### 4.4 Evaluation Script

```bash
python -m backend.scripts.evaluate --pairs backend/data/eval_pairs.json --output results.json
```

## 5. Limitations & Ethical Considerations

- Lexicon size is limited (~1K entries); coverage will improve with community feedback
- Gemini model may hallucinate Hadrami forms not present in the dialect
- Regional variation within Hadramawt (coastal vs inland) not yet captured
- All user data collection requires explicit consent
- No real API keys or credentials are committed to the repository

## 6. Future Work

- Expand lexicon to 5K+ entries with expert review
- Add pronunciation guide / audio clips
- Fine-tune a smaller model on verified pairs for offline translation
- Publish dataset and benchmarks under appropriate license
- Migrate from `google-generativeai` to the new `google-genai` SDK
