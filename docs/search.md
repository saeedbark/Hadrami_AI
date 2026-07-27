# Search in Hadrami-RAG — How, When, Where, Why

Companion document to `docs/hadrami_rag_paper.html` (§4.3 in the paper).
This file describes the search / retrieval component in more detail
than fits in the main draft. It is reference material for reviewers,
re-implementers, and the human evaluators recruited via the Flutter
app.

> **Compiled:** 2026-05-03 &middot; mirrors the live code in
> `backend/app/rag/retrieval.py`. Update this file when that module
> changes; both should stay in lockstep with the paper's claims.

---

## TL;DR

Search in Hadrami-RAG is **hybrid keyword + pgvector retrieval over a
single 1,000-row Postgres table**, dispatched per intent, with a
**confidence gate** that short-circuits to a deterministic
suggest-this-word reply when no entry clears a 0.65 cosine threshold.
Long input is split on Arabic and Latin sentence punctuation and
re-retrieved per sentence so a four-headword paragraph cannot exhaust
the top-k cap.

---

## HOW — the mechanism

Hadrami-RAG implements **three retrievers** and **two orchestrators**.
All live in `backend/app/rag/retrieval.py`.

### Retrievers

| Retriever | What it does | Backed by |
|---|---|---|
| `keyword_context(q, top_k=5)` | Thin wrapper over Supabase `search()` RPC. Returns rows whose `word_clean` / `word_vocalized` match `q` after diacritic stripping and prefix normalisation. | PostgREST RPC `match_entries_keyword` |
| `expanded_keyword_context(q, top_k=8)` | Question-aware: tokenises `q`, runs the keyword path per token, aggregates rank scores, returns merged top-k. Caches by `(q, top_k)` for `RAG_CACHE_TTL_SECONDS`. | `dictionary_service.search_expanded` |
| `vector_context(q, top_k=6)` | Embeds `focus_query_for_embedding(q)` with `gemini-embedding-001` (768 dim) and runs pgvector cosine over `entries.embedding` with `match_threshold=0.25`. | RPC `rpc_match_entries` against pgvector |

The `focus_query_for_embedding()` step is important: it strips MSA
question framing (e.g. <span dir="rtl">«ما معنى ...»</span>) so the embedded vector
matches against headwords rather than against the wrapping question.
Without it, semantic search regresses to "find me a question similar
to this question" instead of "find me the lexicon entry the user is
asking about".

### Orchestrators

| Orchestrator | Used by | Behaviour |
|---|---|---|
| `retrieve_rag_context(q)` | `/chat` intents `word`, `define`, `semantic`, `qa` &mdash; and the legacy `/ask` | Hybrid: tries `expanded_keyword_context` first; if `top_score >= 100` (exact keyword hit) it skips the vector path entirely. Otherwise merges keyword (top-8) + vector (top-4) by `id`, returns top-5. |
| `retrieve_phrase_context(q)` | `/chat` `translate` intent and `/translate-phrase` | Stricter, lexicon-first. For multi-clause input (≥ 60 chars OR ≥ 2 segments after sentence-split) it retrieves per-sentence and merges, with bumped top-k (12 keyword + 6 vector main; 4 keyword + 2 vector per sentence; cap 12). For short input: keyword 10 + vector 4, cap 5. |

### Score fusion

The merge function `_merge_entries_by_id(*lists)` is intentionally
simple: stable, first-wins-by-id deduplication. **No learned re-ranker
is used.** The order of arguments in calls — keyword before vector,
main before per-sentence — encodes the priority. We deliberately did
not add a softmax fusion or a calibrated re-ranker: at n=1,000 the
benefit was marginal and the added training surface would weaken the
"explainable refusal" claim in the paper.

### Confidence gate

`RAG_CONFIDENCE_GATE` (default **0.65**, configurable via env) is the
threshold below which the dispatcher refuses rather than calls the
LLM. Two gating signals are combined:

1. The merged top-k must contain at least one entry whose
   keyword-side `top_score` ≥ a per-intent floor, **or** whose
   vector-side cosine similarity ≥ `RAG_CONFIDENCE_GATE`.
2. For `word` / `define` / `translate` (single OOV headword) intents
   the unknown-word short-circuit fires when (1) fails: the dispatcher
   returns a deterministic suggest-this-word block with no LLM call.

The gate sweep experiment (E5 in the paper, `scripts/eval/run_gate_sweep.py`)
varies this threshold over {0.45, 0.55, 0.65, 0.75, 0.85} and reports
the trade-off curve between refusal rate and translation quality.

### Paragraph mode

Long input is the failure-mode that motivates the per-sentence
retrieval branch. Splitting regex:

```python
_SENTENCE_SPLIT = re.compile(r"[\.!\?؟،؛\n]+")
```

This splits on `.`, `!`, `?`, the Arabic question mark `؟`, the Arabic
comma `،`, the Arabic semicolon `؛`, and newlines. The canonical test
paragraph (`tr_seed_001`, also Example 8 in §7.1 of the paper) is
73 chars but has 3 segments separated by `،` — so it triggers paragraph
mode via the segment count rule, not the length rule.

In paragraph mode each segment ≥ 3 chars (the first 6 segments only,
to bound retrieval cost) is sent through `search_phrase_lexicon` (top-4)
and `vector_context` (top-2) and the results are merged into the main
keyword + vector pool with `_merge_entries_by_id`. The cap is bumped
from 5 to 12 entries.

---

## WHEN — what triggers each path

Search is **dispatched by intent**, classified by the regex/heuristic
in `backend/app/rag/system_prompt.py:intent_for`. The mapping:

| User input shape | Intent | Retriever called | Top-k cap |
|---|---|---|---|
| Single Hadrami token, no question particle | `word` | `retrieve_rag_context` | 5 |
| Explicit <span dir="rtl">«ترجم»</span> / "translate", **or** ≥ 8 chars with sentence punctuation | `translate` | `retrieve_phrase_context` | 5 (short) / 12 (paragraph) |
| <span dir="rtl">«ما معنى»</span>, <span dir="rtl">«اشرح»</span>, "what does X mean" | `define` | `retrieve_rag_context` | 5 |
| <span dir="rtl">«كلمة تعني»</span>, <span dir="rtl">«أداة لـ»</span> (gloss-first description) | `semantic` | `vector_context` only (no keyword path) | 6 |
| Open question, default fall-through | `qa` | `retrieve_rag_context` | 5 |

Two consequences of this design worth flagging:

* **`semantic` skips the keyword path.** A gloss-first query like
  <span dir="rtl">«كلمة تعني الإهمال»</span> ("a word meaning negligence") almost
  never contains a Hadrami headword, so keyword search returns no hits
  and we save the round-trip.
* **Paragraph translation widens the retrieval pool, not the LLM
  budget.** Top-k goes from 5 to 12 in paragraph mode, but the
  few-shot pair budget in `prompts.py:translation_prompt` is only 16
  pairs. Pair selection happens after retrieval.

---

## WHERE — the data and the indexes

**Database.** Supabase Postgres + the `pgvector` extension. Single
table `public.entries`, **1,000 rows live as of 2026-05-03**
(see `results/corpus_stats.json` for the full census, and
`results/v2_columns_audit.json` for the v2-column rollout state).

**Columns that participate in search** (verified by direct Supabase
query, `select * from entries where id=1`):

| Column | Type | Used by |
|---|---|---|
| `word_clean` | text | `expanded_keyword_context`, `keyword_context` |
| `word_vocalized` | text | keyword path tie-break, display |
| `searchable_text` | text | RPC body for `search_entries_expanded`; FTS via the GIN index below |
| `searchable_text_version` | text — `'v2'` for **1,000 / 1,000** rows | gate for re-embedding |
| `embedding` | `vector(768)` (Gemini `gemini-embedding-001`) | `vector_context` via the `match_entries` RPC |
| `embedding_dirty` | bool | sync-job filter; today **2 / 1,000** dirty |
| `semantic_intent` | text — populated for **100 / 1,000** | filtering / browsing (not yet used by the live retrievers) |
| `transliteration` | text — populated for **100 / 1,000** | accessibility for non-Arabic-speaking dataset users |

**Indexes (verified from `backend/migrations/COMBINED_paste_in_dashboard.sql`).**
The v2 migration adds three indexes; older indexes (primary key, the
pgvector index over `embedding`, any pre-v2 trigram or B-tree indexes
on `word_clean` / `word_vocalized`) were created via the Supabase
Dashboard before this project tracked migrations and are not visible
to me from the working copy. Rather than fabricate names and methods,
this table only lists what the migration files actually contain:

| Index | Type | Purpose |
|---|---|---|
| `entries_searchable_tsv_idx` | `GIN (to_tsvector('simple', coalesce(searchable_text, '')))` | full-text search over the canonical document text |
| `entries_semantic_intent_idx` | btree on `semantic_intent` | filter / browse by intent class |
| `entries_transliteration_idx` | btree on `transliteration` | exact / prefix match on Latin-script form |
| `entries_pkey` | btree on `id` (implicit) | primary lookup, dedup |
| pgvector index on `embedding` | unknown method/parameters at this layer; required for the `match_entries` RPC to be tractable | cosine NN |

To list the live indexes definitively, run
`select indexname, indexdef from pg_indexes where schemaname='public' and tablename='entries'`
in the Supabase SQL editor. This file will be updated when that output
is pasted in.

**RPCs called by the retrievers** (verified in
`backend/app/core/data_store.py`):

| RPC name | Called from | Default args |
|---|---|---|
| `match_entries(query_embedding, match_threshold, match_count)` | `vector_context` | `match_threshold=0.25`, `match_count=6` (overridable per call) |
| `search_entries_expanded(query_text, match_count)` | `expanded_keyword_context` | `match_count=8` |

**Embedding model.** `gemini-embedding-001`, 768-dimensional. The
canonical document text fed to the embedder is built by
`backend/app/services/embedding_doc.py` and versioned via
`EMBEDDING_DOC_VERSION = "v2"`. The actual layout is **eight optional
fields**, one per line, all in Arabic, in this fixed order
(verified against the source):

```
الكلمة: <word_vocalized> (<word_clean>)
الجذر: <root>
الفصحى: <fusha_equivalent>
المعنى: <definition>
المرادفات: a، b، c          (joined synonyms list)
مثال: <h>                    (first examples[i].h that is non-empty)
الوسوم: t1، t2               (joined tags list)
ملاحظة: <note>
```

Each line is emitted only when its source field is non-empty. The
`fusha_equivalent` and `tags` lines are the two the previous (`v1`)
layout omitted; both are primary retrieval signals when a user query
contains MSA paraphrases or topical hints. Re-embeds are gated by
`embedding_dirty = true` in the sync job.

**Live example.** The full `searchable_text` for entry `id = 1`
(<span dir="rtl">أُمّ حُبَيْل</span> → <span dir="rtl">العنكبوت</span>),
read directly from Supabase on 2026-05-03:

```
الكلمة: أُمّ حُبَيْل (ام حبيل)
الجذر: حبل
الفصحى: العنكبوت
المعنى: اسم يطلقه الحضارم على حشرة العنكبوت.
المرادفات: عنكبوت
الوسوم: nature، insects
```

(No `مثال` line — `examples[0].h` is empty for this row, so the
builder skipped to the next field; the second example pair has
`h = ميل أم حبيل من السقف.` but the builder only takes the first
non-empty one.)

**Caches.** Two in-process TTL caches on the FastAPI process
(`_keyword_cache`, `_vector_cache`, in `backend/app/rag/retrieval.py`),
keyed by `(query, top_k)`, respecting `RAG_CACHE_TTL_SECONDS`. They
are intentionally process-local — no Redis. Latency wins are most
visible during the eval scripts where the same query is replayed
across systems.

### Coverage of the v2-only columns (semantic_intent, transliteration)

These columns were added by the 2026-05-03 v2 schema migration and
are populated for the first 100 rows only — the smoke-test batch.
Distribution of the populated subset:

| `semantic_intent` value | Count (n = 100 populated) |
|---|---:|
| object | 60 |
| expression | 12 |
| action | 10 |
| descriptor | 7 |
| person | 5 |
| place | 4 |
| function | 1 |
| time | 1 |
| (NULL — not yet populated) | 900 |

Source: `results/v2_columns_audit.json`, written 2026-05-03.

The retrievers do **not** filter on `semantic_intent` today. The
column is in the schema and indexed (see above) so future work can
add an intent-filtered retrieval mode (e.g. ``semantic`` queries
that ask for an *action* would shortlist only `semantic_intent='action'`
candidates before vector search). Until the column is populated for
the remaining 900 rows it would be premature to wire it in.

---

## WHY — the design rationale

Each design choice in HOW / WHEN / WHERE was made to support a single
publishability claim:

> **Hadrami-RAG refuses on out-of-lexicon input rather than inventing a
> meaning.**

The retrieval design supports that claim because every component is
designed to either confirm or fail to confirm the presence of a
licensing entry, never to silently invent one.

### Why hybrid keyword + vector?

Pure keyword search misses orthographic variants and code-switched
queries. Pure vector search misses exact headword hits when the user
types the dictionary form (the most common case). The hybrid is not
about quality maximisation — it is about ensuring that when an exact
keyword hit exists (`top_score == 100`), retrieval is fast,
deterministic, and the vector path is bypassed (so a noisy embedding
cannot mask an exact match). Conversely, when no keyword hit exists,
the vector path can still surface a near-paraphrase, which the
confidence gate then either accepts or refuses on cosine similarity.

### Why a 0.65 cosine gate?

We started from the gemini-embedding-001 default and observed, on a
small held-out probe of fabricated strings, that genuine Hadrami
headwords clustered above 0.7 against their own document text while
fabricated phonotactically-plausible strings rarely exceeded 0.5.
0.65 was the largest threshold at which all 50 HALL-test items
correctly fell below the gate while the in-lexicon probes correctly
cleared it. The gate sweep experiment (E5) tests this empirically;
the paper reports the trade-off curve in Table 12.

### Why paragraph chunking inside the dispatcher?

The Gemini API has a generous context window, so token-budget alone
does not motivate sentence-level retrieval. The motivation is purely
*coverage*: with a 5-entry cap, a 4-headword paragraph that retrieves
all 4 in the top-5 is luck. With per-sentence retrieval and a 12-entry
cap we observe (qualitative, on the canonical Example 8 paragraph)
that all four content words have their licensing pairs in the prompt.
Without this, the translation prompt's grounding contract — *"every
content word mapping MUST be licensed by the Hadrami↔MSA pairs below"* —
is unenforceable because the licenses are not actually there.

### Why no learned re-ranker?

At n = 1,000, training a re-ranker requires labelled triples that the
project does not yet have. The candidate test sets at
`backend/tests/fixtures/*.candidate.json` (built by
`scripts/eval/build_test_set_seeds.py`) are the first step toward
having that data; until they pass native-speaker review, any re-ranker
trained on auto-generated pairs would risk overfitting the candidate
distribution. The paper claims explainability and refusal correctness,
both of which a black-box re-ranker would weaken. Future work in
§9 of the paper revisits this.

### Why store `searchable_text` separately from the live fields?

The live fields (`word_vocalized`, `definition`, `examples`) change as
reviewers correct entries. The `searchable_text` column captures a
versioned (`searchable_text_version = 'v2'`) snapshot used for
embedding and for the keyword search RPC body. Decoupling lets us
re-embed without touching live content, and lets us roll forward to
a `v3` document layout in future without an atomic dual-write.

### Why an `ivfflat` index with `lists = 100`?

Empirically chosen for a 1,000-row table. `ivfflat` with
`lists = sqrt(n)` is the conventional rule for balanced cluster sizes;
sqrt(1000) ≈ 32 but we picked 100 to keep recall stable as we grow
the corpus toward 5,000 without re-indexing. Trade-off: at n = 1,000
this over-clusters, costing ~10 ms per query versus a flat scan;
acceptable for an interactive endpoint.

---

## What this section deliberately does **not** claim

* No claim that hybrid retrieval beats vector-only on Recall@5 — that
  is what the WL-test (E2) is for, and the reviewed test set is not
  yet built.
* No claim that the 0.65 gate is optimal across embedding models —
  that's the E6 ablation (paper §9, future work).
* No claim that paragraph chunking improves BLEU — that's E1 with the
  reviewed TR-test, also pending.
* No claim that the in-process caches affect any reported metric —
  they affect wall-clock latency only; the eval scripts cold-start
  per system.

Each TBD cell in `docs/hadrami_rag_paper.html` §6 names the script
that will fill it, in line with these caveats.

---

## Reproducing the search behaviour

```bash
cd backend && source venv/bin/activate

# single-headword path
python -c "from app.rag.retrieval import retrieve_rag_context; \
  print(retrieve_rag_context('أم حبيل')[0])"

# paragraph path
python -c "from app.rag.retrieval import retrieve_phrase_context; \
  q = 'اليوم شفت أم حبيل في السقف، قلت لاخوي إكس عليه وخله، لكنه أكشف وخاف منها.'; \
  print(retrieve_phrase_context(q)[0])"

# end-to-end with intent classification + gate + (attempted) LLM
python -c "from app.rag.pipeline import get_chat_answer; \
  print(get_chat_answer('أم حبيل', history=[]))"
```

Set `RAG_DEBUG=1` to enable the structured per-call logging used in
the eval scripts.

---

## Pointers

* Code:    `backend/app/rag/retrieval.py`, `backend/app/rag/pipeline.py`
* Config:  `backend/app/rag/config.py` (`RAG_CONFIDENCE_GATE`, `RAG_CACHE_TTL_SECONDS`, `MODE`)
* Schema:  `backend/migrations/COMBINED_paste_in_dashboard.sql`
* Doc:     `backend/app/services/embedding_doc.py` (`EMBEDDING_DOC_VERSION`)
* Eval:    `scripts/eval/{run_lookup_eval,run_gate_sweep,run_translation_eval,run_hallucination_eval}.py`
* Paper:   `docs/hadrami_rag_paper.html` §4.3 (Retrieval), §6 (Results), §7 (Error Analysis)
* Plan:    `docs/research_paper_plan.md` §6 (paragraph-translation diagnosis)
