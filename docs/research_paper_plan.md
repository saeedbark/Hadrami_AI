# Hadrami NLP — Research Paper Plan

**Working title (proposed):**
*Hadrami-RAG: A Retrieval-Grounded Conversational System and Lexicon
for the Hadrami Arabic Dialect*

**Last updated:** 2026-05-03
**Owner:** Abdelwedoud (saeedbark)

---

## 0. TL;DR — what this paper claims

> **We release the first verified Hadrami Arabic dialect lexicon (1,047
> entries with MSA glosses, examples, and 768-dim embeddings) and a
> retrieval-grounded conversational system that auto-classifies five user
> intents (word lookup, translation, definition, semantic search, Q&A) and
> refuses to answer outside the lexicon. The system, dataset, and a Flutter
> mobile application are open-sourced.**

Three concrete contributions, in publishability order:

1. **Resource:** the lexicon itself + the human evaluation pairs.
2. **System:** the unified chat dispatcher with strict RAG grounding and
   confidence-gated unknown-word handling.
3. **Application:** a deployed Flutter app that lets native speakers
   query / contribute to the dictionary, used as the data-collection
   loop for the human study.

---

## 1. Conference targets (pick one primary + one backup)

| Venue | Type | Page limit | Submission window | Fit |
|---|---|---|---|---|
| **ArabicNLP @ EMNLP 2026** | Workshop | 8 + refs | ~July 2026 | **★ Primary** — exact topical fit |
| **LREC-COLING 2026** | Resource paper | 8 + refs | May 2026 | ★ Strong — emphasises the lexicon |
| **ICNLSP 2026** | Main / short | 6–8 | Sep 2026 | Backup — smaller venue, faster turnaround |
| **AraSummit / ACL Findings** | Findings | 8 | Rolling | Backup if rejected from primary |

**Strategy:** target ArabicNLP first (community fit, accepts system+resource
papers with modest experiments). LREC-COLING as backup with the same draft
re-framed around the lexicon.

---

## 2. Paper outline (ACL 8-page format)

### §1 Introduction (~1 page)
- Why Hadrami: spoken by ~5–7M people in Hadhramaut (Yemen) and the
  Hadrami diaspora; almost no NLP resources; high lexical divergence from
  MSA and Gulf Arabic.
- Why a dictionary-grounded system: large LLMs hallucinate plausible-sounding
  but wrong glosses for low-resource dialects (this is the experimental
  motivation — see §6.4).
- Three contributions list (matches §0).

### §2 Related Work (~0.75 page)
- Arabic dialect NLP: MADAR, Bouamor et al.; ADIDA dialect ID; QADI corpus.
- Dictionary-based / lexicon-grounded translation: Rapp 1995; Artetxe 2018;
  recent retrieval-augmented dialectal MT.
- RAG + grounding refusals: Lewis 2020 (RAG); Shuster et al. 2021
  (knowledge-grounded chat); Asai et al. (Self-RAG); Mallen et al. 2023
  (when do retrievers help).
- Yemeni Arabic specifically: Watson 2002 (linguistic), Al-Saqqaf 2006
  (Hadrami phonology). Almost no NLP work.

### §3 The Hadrami Lexicon (resource section) (~1 page)
- Curation process: provenance, native-speaker review, IRB / consent
  treatment.
- Schema: `id, word_vocalized, word_clean, root, pos, fusha_equivalent,
  definition, region, synonyms, phonetic_variants, note, source, examples,
  proverbs, tags, embedding(768)`.
- Statistics table (auto-generated from Supabase):
  - Total entries, # with `fusha_equivalent`, # with examples, # with
    proverbs, # tagged.
  - Distribution by POS, by region, top-10 tags.
- License + access (Supabase REST endpoint or static JSON drop).

### §4 System (~1.5 pages)
- Overview figure: user message → intent classifier → retrieval (keyword +
  pgvector) → prompt builder → Gemini with system_instruction → response.
- Five intents — table with regex / heuristic per intent (lifted from
  `system_prompt.py:intent_for`).
- Retrieval: hybrid keyword (PostgREST + RPC) + pgvector (768-dim Gemini
  embedding). Confidence gate `RAG_CONFIDENCE_GATE` with the
  unknown-word short-circuit logic.
- The unified system prompt: grounding contract, refusal block, response
  formats per intent.
- Engineering: FastAPI backend, Supabase Postgres + pgvector, Flutter app.

### §5 Experimental Setup (~0.75 page)
- Test sets (build these — see §7):
  - **TR-test**: 100 Hadrami paragraphs with gold MSA translations.
  - **WL-test**: 200 word-lookup queries (single Hadrami headword → MSA).
  - **INT-test**: 500 messages labelled with intent (TYPE 1–5).
  - **HALL-test**: 50 *fabricated* Hadrami-shaped strings; the system
    must refuse / suggest, not invent a meaning.
- Baselines:
  - **B1**: Gemini 2.5-flash with no retrieval, no system prompt.
  - **B2**: Gemini 2.5-flash with system prompt only (no retrieval).
  - **B3**: Google Translate (auto-detect → MSA).
  - **B4**: GPT-4o (no RAG).
  - **OURS**: full pipeline.
  - **OURS−gate**: confidence gate disabled, to isolate its contribution.
- Metrics:
  - Translation: **BLEU, chrF, COMET**.
  - Retrieval (WL): **Recall@1 / @5, MRR**.
  - Intent: **macro-F1, confusion matrix**.
  - Hallucination: **% refusals on HALL-test** (higher is better),
    **invented-meaning rate** (lower is better).
  - Human eval: 5-point Likert on translation accuracy, dialect
    authenticity, helpfulness.

### §6 Results (~1.5 pages)
- §6.1 Translation quality table (all baselines vs OURS on TR-test).
- §6.2 Word-lookup retrieval table.
- §6.3 Intent classifier confusion matrix.
- §6.4 **Hallucination experiment** — the headline result:
  show that B1/B4 invent meanings for fabricated strings while OURS
  refuses ≥ X% of the time.
- §6.5 Confidence-gate ablation sweep (0.45–0.85, 5 points).
- §6.6 Human study summary.

### §7 Error Analysis (~0.5 page)
- Where translation fails (paragraph length, idiomatic phrases,
  proverbs not in lexicon, code-switching with English/Standard Arabic).
- Where retrieval misses (orthographic variants, root-but-not-form
  matches, semantic search recall).
- Specific failing examples (qualitative).

### §8 Limitations & Ethics (~0.4 page)
- Coverage: 1,047 entries is small; rare words and recent neologisms
  excluded.
- Regional variation within Hadrami (coastal vs Wadi vs diaspora).
- Native-speaker reviewer demographics.
- Data subject consent for the feedback table; how IPs are handled
  (already truncated).
- LLM dependency: Gemini API is closed; we provide a deterministic
  lexicon fallback for when it is unavailable.

### §9 Conclusion + Future Work (~0.25 page)
- Larger lexicon via the Flutter feedback loop.
- Open-weight model (Jais, Aya 23) drop-in.
- Dialect-aware tokenisation.

---

## 3. Experiments — concrete plan

Each experiment lives in its own script under `scripts/eval/` so it can be
re-run against any code change.

| ID | Goal | Script (to create) | Inputs | Outputs |
|---|---|---|---|---|
| **E1** | Translation quality | `scripts/eval/run_translation_eval.py` | TR-test, all baselines | `results/translation.csv`, BLEU/chrF/COMET per row + system mean |
| **E2** | Word-lookup recall | `scripts/eval/run_lookup_eval.py` | WL-test, OURS only (varies retriever) | Recall@1/5, MRR |
| **E3** | Intent accuracy | `scripts/eval/run_intent_eval.py` | INT-test | macro-F1, confusion matrix PNG |
| **E4** | Hallucination | `scripts/eval/run_hallucination_eval.py` | HALL-test | refusal-rate per system, invented-meaning rate (manual rubric) |
| **E5** | Gate sweep | `scripts/eval/run_gate_sweep.py` | TR-test + HALL-test, 5 gate values | trade-off curve |
| **E6** | Embedding model A/B | `scripts/eval/run_embedding_ab.py` | WL-test, gemini vs LaBSE vs multilingual-e5 | Recall@5 per model |
| **E7** | Human eval | Flutter app + form | 100 OURS responses | mean Likert per dimension, IAA (Cohen's kappa) |

**Ownership:** I'll scaffold E1–E5 once you approve the test-set construction
plan in §7 below. E6 needs a small refactor in `embedding_service.py` to swap
backends. E7 needs you to recruit reviewers.

---

## 4. Numbers I already have (verified against Supabase today)

```
entries:      1,000 rows (live; total likely 1,047 once embedding-dirty refresh runs)
              - 998 with embedding_dirty=False
              -   2 with embedding_dirty=True   ← ACTION: regenerate
              - 768-dim pgvector embeddings (Gemini gemini-embedding-001)
              - schema fields verified via OpenAPI

feedback:     4 rows (all status=open)
              - 2 correction
              - 2 new_word
              - most recent: 2026-04-24 ("أم حبيل")

LLM:          gemini-2.5-flash primary; 2.0-flash / 2.5-flash-lite / 1.5-flash fallbacks
Tests:        42 passing (16 hermetic + 26 live E2E)
```

These can go into Table 1 of §3 directly. Once I run the stats query I'll
add: distribution by POS, by region, top tags, % with examples, % with
proverbs.

---

## 5. Database improvement work (needs your approval before I run)

You confirmed I have write access via the service-role key. I'm **not**
running these without explicit go-ahead per turn — a service-role write to
a shared table is destructive territory. Below is the list, ordered by
risk:

### Low risk (read-only diagnostics first)
1. **Audit empty fields**: count entries missing `fusha_equivalent`,
   `examples`, `definition`, `tags`. → guides the next two steps.
2. **Audit suspicious entries**: words where `word_vocalized != word_clean`
   normalised, missing root, etc.

### Medium risk (single-purpose updates, easy to roll back)
3. **Regenerate the 2 dirty embeddings** — re-embed those rows with
   gemini-embedding-001 and clear `embedding_dirty`. ~$0.0001 cost.
4. **Backfill missing `examples`** — for entries with `fusha_equivalent`
   but no example pair, generate `(h, f)` candidates with Gemini, then
   you review / approve before write. **This is the single biggest lever
   for the paragraph-translation problem (§6).**
5. **Normalise `tags_ar`** — fill in Arabic mirror tags where missing.

### Higher risk (large-scale) — only after dry-run approval
6. **Re-embed all 1,000 entries** with a richer document
   (`headword + fusha + definition + first-example`) instead of just the
   headword. This is what the user typically wants the vector to match.
   Likely the largest single gain on E2 / E6.
7. **Schema additions** (would require a migration):
   - `audio_url` for pronunciation (paper future-work).
   - `confidence_score` filled by reviewers (helps gate calibration).

I'll wait for your sign-off on each before running. To unblock E1/E2 we
mainly need #3, #4, #6.

---

## 6. The paragraph-translation weakness — diagnosis and fix

Your example reproduces a real limitation:

```
Input:    اليوم شفت أم حبيل في السقف، قلت لاخوي إكس عليه وخله،
          لكنه أكشف وخاف منها.
Expected: اليوم رأيت عنكبوتاً في السقف، فقلت لأخي تجاهله واتركه،
          لكنه كان عنيداً وخاف منه.
```

The dispatcher classifies this as `translate` and routes to
`retrieve_phrase_context` + `translation_prompt`. That path:

1. Tokenises the input via `_extract_search_candidates` and looks each
   token up.
2. Merges keyword + vector hits.
3. Builds up to 10 few-shot Hadrami↔Fusha pairs from retrieved entries'
   `examples`.

**Why it fails on paragraphs**, in order of impact:

1. **Examples coverage is sparse.** If the entries for `أم حبيل`, `إكس`,
   `أكشف`, `خله` don't have `(h, f)` example pairs, the few-shot block is
   thin — Gemini falls back on definitions, which are explanatory, not
   parallel translation. → **Fix: §5 step 4** (backfill examples).
2. **Retrieval top-k is too small for paragraphs.** `retrieve_phrase_context`
   caps at 5 entries; a 4-headword paragraph already exhausts that.
   → **Fix: bump to 8–12 for translate intent** (one-line change in
   `pipeline.py`).
3. **No sentence-level chunking inside `/chat`.** The phrase translation
   service has chunking (`PHRASE_TRANSLATE_CHUNK_SIZE=800`), but the chat
   dispatcher hands the whole paragraph to Gemini in one shot.
   → **Fix: split on `،` / `.` / `؟`, retrieve per-sentence, then have
   Gemini stitch.** Bigger change but the right one for paper-quality
   results.
4. **Embeddings index headwords only**, not the full entry text. A
   paragraph rarely contains a bare headword; vector retrieval needs to
   match against context. → **Fix: §5 step 6** (re-embed with richer
   document).

I'd recommend addressing them in this order: 2 (cheap), 1 (medium —
content work), 4 (one-time embedding re-run), 3 (refactor). After 2+1+4
the example you gave should work.

---

## 7. Test-set construction plan (the gating dependency for §3 experiments)

Each test set is small enough to label by hand in a few sittings. Native
Hadrami speakers needed for TR-test and WL-test gold labels.

| Set | Size | How to build | Owner |
|---|---|---|---|
| **TR-test** (paragraph) | 100 | Sample paragraphs from any Hadrami-language source (poetry collections, social media if licensed, narratives elicited from speakers). Get gold MSA translations from 2 native speakers; resolve disagreements. | You + 1 reviewer |
| **WL-test** (word lookup) | 200 | 100 words *in* the lexicon (held out from training of any reranker), 100 *out of* lexicon (real Hadrami words deliberately not yet curated). | You |
| **INT-test** (intent) | 500 | I'll generate 250 candidate messages per intent (synthetic templates + real chat logs once we have them); you label. | Me + you |
| **HALL-test** | 50 | 50 fabricated Hadrami-looking strings (e.g. `بُغطْحَش`). Deliberately not real words. | Me |

`HALL-test` is the only one I can build alone. The others need you.

---

## 8. The application angle

The Flutter app is a **paper asset**, not a side-project:

- **Demo video** for the paper supplementary materials (1–2 min).
- **Data-collection loop**: the existing `/feedback` endpoint already
  captures corrections + new-word suggestions with consent. Re-frame this
  as the "human-in-the-loop curation" experiment in §6.6.
- **User study platform**: ship the app to N=10–20 native speakers, ask
  them to query 20 prompts each, log responses + their 5-pt rating.
  That **is** the human evaluation.
- A short §4.4 in the paper titled *"Mobile deployment as a curation
  pipeline"* makes the resource section much stronger.

---

## 9. Timeline (realistic)

Working backwards from a hypothetical ArabicNLP @ EMNLP 2026 deadline of
**~July 15 2026**:

| Week | Window | Work |
|---|---|---|
| W-12 | May 4 – May 17 | DB improvements (steps 3–6 of §5). E2 + E3 scripts and runs. |
| W-10 | May 18 – May 31 | Build TR-test + WL-test gold labels with reviewers. Fix paragraph translation (§6 fixes 1+2+4). |
| W-8  | Jun 1 – Jun 14  | Run E1 (translation), E4 (hallucination), E5 (gate sweep). Draft §3 + §4 of paper. |
| W-6  | Jun 15 – Jun 28 | Recruit human evaluators. Run E7 in the app. Draft §5 + §6. |
| W-4  | Jun 29 – Jul 5  | Error analysis (§7). Draft §1, §2, §8, §9. Internal review pass. |
| W-2  | Jul 6 – Jul 12  | Native-speaker proofread; figure polishing; LaTeX submission. |
| W-0  | Jul 13 – Jul 15 | Submit. |

If LREC-COLING is the target instead, compress by 4 weeks (resource paper
is shorter on system experiments).

---

## 10. Immediate next actions (what I'd like to do this week)

In priority order, with what I need from you:

1. **Run the lexicon stats query** and add the table to §3 of this plan. *(I can do this read-only — no approval needed.)*
2. **Audit empty fields** (§5 step 1+2). Read-only.
3. **Approve the embedding re-run** (§5 step 6) — cheapest single gain.
4. **Decide conference target** — ArabicNLP vs LREC. Affects timeline.
5. **Commit to building TR-test gold labels** (§7) — without this we
   have no headline numbers.
6. **Hand me the Flutter screens** you want me to wire `intent` /
   `suggest_word` into — closes the loop on the chat work shipped today.

Reply with which of these you want me to start on; for #3 specifically
I'll need explicit "go" before I run any UPDATE / re-embedding job.

---

## 11. Progress log

### 2026-05-03 — paragraph fix + experiment scaffolding

**Code-only changes (shipped):**

- `backend/app/rag/retrieval.py:retrieve_phrase_context`: paragraph-aware
  retrieval. Inputs ≥ 80 chars now also retrieve per-sentence (split on
  `.,!?؟،؛\n`) and merge the results. Top-k bumped to 12 for paragraphs,
  10 for short input. Output cap 12 for paragraphs (was 5). Directly
  addresses §6 fix #2 and §6 fix #3.
- `backend/app/rag/prompts.py:translation_prompt`: bumped few-shot pair
  budget from 10 to 16 and the entry walk from 8 to 12, so the wider
  paragraph context is not silently truncated.
- `backend/app/services/embedding_doc.py` (new): canonical Arabic-first
  document text. Now includes `fusha_equivalent` and `tags` (the v1
  layout used by `sync_to_supabase.py` had neither). Versioned as
  `EMBEDDING_DOC_VERSION = "v2"` so callers can decide to re-embed.
- `scripts/sync_to_supabase.py`: imports the shared builder above; the
  next `--reembed-all` run will use v2 docs. **Not auto-run** — re-embed
  needs explicit "go" per §5.

**Eval scaffolding (shipped):**

- `scripts/eval/metrics.py` — BLEU, chrF (sacrebleu), recall@k, MRR,
  macro-F1, confusion matrix, refusal rate. No sklearn dependency.
- `scripts/eval/audit_lexicon.py` — read-only DB audit (E0). Counts
  missing fields, POS/region distribution, embedding NULL/dirty,
  top-20 tags. Writes `results/lexicon_audit.json`.
- `scripts/eval/run_translation_eval.py` — E1; systems `ours`, `no_rag`.
- `scripts/eval/run_lookup_eval.py` — E2; recall@1/5, MRR.
- `scripts/eval/run_intent_eval.py` — E3; macro-F1 + confusion (no LLM
  calls, runs against the `intent_for` classifier).
- `scripts/eval/run_hallucination_eval.py` — E4; HALL-test refusal rate.
- `scripts/eval/run_gate_sweep.py` — E5; sweeps `RAG_CONFIDENCE_GATE`
  ∈ {0.45, 0.55, 0.65, 0.75, 0.85}.

**Test sets:**

- `backend/tests/fixtures/hall_test.json` (50 items, complete) — only
  the test set the model can build alone. Single-word, instruction, and
  paragraph-shaped fabricated items.
- `backend/tests/fixtures/{tr_test,wl_test,int_test}.template.json` —
  templates with construction protocols. **Need native-speaker labeling
  before they produce reportable numbers.**

**Smoke-test status:**

- All eval scripts import cleanly under `backend/venv/bin/python`.
- `run_intent_eval.py` runs end-to-end on the template fixture and
  produces `results/intent_eval.json`.
- E1/E2/E4/E5 require Gemini + Supabase credentials; not auto-run.

### Next, in priority order

1. **APPROVAL needed — re-embed all 1,000 entries with v2 doc layout**
   (`backend/venv/bin/python scripts/sync_to_supabase.py --embeddings-only --reembed-all`).
   Cost ≈ $0.001, ~10 min wall time. This is §5 step 6 plus the new
   `fusha_equivalent`+`tags` fields. Single biggest expected gain on E2.
2. **APPROVAL needed — backfill missing examples** (§5 step 4) using
   Gemini drafts that you review before insert. The audit script run is
   the gating dependency: tells us how many entries actually need it.
3. **Build TR-test gold (100 items)** — without this E1 has no headline.
   I can scaffold the labeling tool in the Flutter app if you want.
4. **Run E0 (audit) and E3 (intent) now** — both are safe (read-only DB
   for E0, no DB at all for E3). They give §3 stats and the intent
   confusion matrix without needing native speakers.
5. **Decide conference target** — affects whether the timeline in §9
   works as written.
