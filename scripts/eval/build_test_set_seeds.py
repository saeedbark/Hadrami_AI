#!/usr/bin/env python3
"""Generate *candidate* test-set items for the user to review.

Outputs three files under ``backend/tests/fixtures/``:

* ``wl_test.candidate.json``  — 100 in-lexicon headword queries, sampled
  stratified by POS.
* ``tr_test.candidate.json``  — up to 100 paragraph-style items synthesised
  from entries whose ``examples`` field has a Hadrami↔MSA pair. We do
  NOT invent translations; each candidate carries the existing
  example pair verbatim, so a reviewer only has to accept/reject and
  optionally edit, never write from scratch.
* ``int_test.candidate.json`` — 250 intent-labeled candidates (50 per
  intent) generated from the spec's regex/heuristic patterns and
  populated with real headwords from the lexicon.

Each file is a *candidate* — reviewers MUST audit before merging into
the canonical ``*_test.json`` used by the eval scripts. The files are
deliberately suffixed ``.candidate.json`` so they cannot be
accidentally consumed by the runners (which look for unsuffixed
fixtures).
"""

from __future__ import annotations

import json
import os
import random
from collections import defaultdict
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from supabase import create_client

ROOT = Path(__file__).resolve().parents[2]
FIXTURES_DIR = ROOT / "backend" / "tests" / "fixtures"

random.seed(20260503)


def _supabase_client():
    load_dotenv(ROOT / "backend" / ".env")
    return create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_KEY"])


def _fetch_entries() -> list[dict[str, Any]]:
    s = _supabase_client()
    return (
        s.table("entries")
        .select(
            "id,word_vocalized,word_clean,pos,region,fusha_equivalent,definition,examples"
        )
        .limit(2000)
        .execute()
        .data
    )


def build_wl_seeds(rows: list[dict[str, Any]], n_target: int = 100) -> dict[str, Any]:
    by_pos: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        if not (r.get("word_clean") or r.get("word_vocalized")):
            continue
        by_pos[(r.get("pos") or "unspecified")].append(r)

    quota = {pos: max(1, round(n_target * len(items) / sum(len(v) for v in by_pos.values())))
             for pos, items in by_pos.items()}
    sampled: list[dict] = []
    for pos, items in by_pos.items():
        k = min(quota[pos], len(items))
        sampled.extend(random.sample(items, k))
    sampled = sampled[:n_target]

    items = []
    for i, r in enumerate(sampled, 1):
        items.append({
            "id": f"wl_seed_{i:03d}",
            "query": r.get("word_clean") or r.get("word_vocalized"),
            "gold_entry_id": r["id"],
            "in_lexicon": True,
            "pos": r.get("pos"),
            "_review_note": "verify the surface form is what a user would type",
        })
    return {
        "name": "WL-test (candidate)",
        "description": (
            "Auto-sampled in-lexicon headwords stratified by POS. Reviewer must: "
            "(1) confirm the query is the form a user would actually type "
            "(strip diacritics if needed), (2) decide whether to keep or replace "
            "with a more idiomatic surface form. After review, drop the "
            "_review_note field, renumber, and merge into wl_test.json. "
            "100 OUT-of-lexicon items (real Hadrami words deliberately NOT in "
            "the corpus) still need to come from native speakers — see _todo."
        ),
        "version": "0.2-candidate",
        "stratified_by": "pos",
        "items": items,
        "_todo": [
            "Add 100 out-of-lexicon items (real Hadrami words not yet curated).",
            "Have a second native speaker spot-check 10%.",
        ],
    }


def build_tr_seeds(rows: list[dict[str, Any]], n_target: int = 100) -> dict[str, Any]:
    candidates = []
    for r in rows:
        ex = r.get("examples") or []
        if not isinstance(ex, list):
            continue
        for e in ex:
            if not isinstance(e, dict):
                continue
            h = (e.get("h") or e.get("hadrami") or e.get("ar") or "").strip()
            f = (e.get("f") or e.get("fusha") or e.get("msa") or "").strip()
            if h and f and h != f and len(h) >= 8 and len(h) <= 220:
                candidates.append((r, h, f))

    random.shuffle(candidates)
    candidates = candidates[:n_target]

    items = []
    for i, (r, h, f) in enumerate(candidates, 1):
        items.append({
            "id": f"tr_seed_{i:03d}",
            "hadrami": h,
            "msa_gold": f,
            "source_entry_id": r["id"],
            "source_headword": r.get("word_clean") or r.get("word_vocalized"),
            "annotators": ["lexicon_example"],
            "agreement": "single-source — needs second-annotator review",
            "_review_note": (
                "this gold MSA came verbatim from the lexicon's examples field. "
                "Reviewer must: (1) confirm the MSA is faithful and idiomatic, "
                "(2) edit if too literal, (3) flag if the Hadrami sentence is too "
                "short to be a real paragraph (target ≥1 clause with ≥2 dialect words)."
            ),
        })
    return {
        "name": "TR-test (candidate)",
        "description": (
            "Hadrami↔MSA pairs lifted verbatim from the lexicon's examples field. "
            "These are SENTENCE-level, not paragraph-level — for paragraph items "
            "you'll need to commission additional translations. Reviewers MUST "
            "verify before BLEU/chrF is computed against these references."
        ),
        "version": "0.2-candidate",
        "items": items,
        "_todo": [
            "Have 2 native speakers re-translate each Hadrami sentence independently; "
            "compare to the lexicon-provided MSA; resolve disagreements.",
            "Add ~30 longer paragraph items (mixed dialect + MSA + code-switching) "
            "for paragraph-level evaluation.",
        ],
    }


# ----- INT-test seeds: spec-derived patterns × real headwords -----

INTENT_PATTERNS: dict[str, list[str]] = {
    "word": [
        "{w}",
        "{w}؟",
        "كلمة {w}",
    ],
    "convert": [
        "ترجم: {w}",
        "ترجم هذه الجملة: قال لي {w}",
        "translate to fusha: {w}",
        "ايش الفصحى لـ {w}",
    ],
    "define": [
        "ما معنى {w}؟",
        "اشرح كلمة {w}",
        "وش يعني {w}",
        "what does {w} mean",
    ],
    "semantic": [
        "كلمة تعني {gloss}",
        "أداة لـ {gloss}",
        "ما اسم {gloss} عند الحضارم",
    ],
    "qa": [
        "هل كلمة {w} تستخدم اليوم؟",
        "كيف أقول {gloss} بالحضرمية؟",
        "من أين أصل كلمة {w}؟",
        "هل {w} كلمة قديمة؟",
    ],
}


def build_int_seeds(rows: list[dict[str, Any]], per_intent: int = 20) -> dict[str, Any]:
    pool = [r for r in rows if (r.get("word_clean") or r.get("word_vocalized")) and r.get("fusha_equivalent")]
    random.shuffle(pool)
    items = []
    idx = 1
    for intent, patterns in INTENT_PATTERNS.items():
        seen_texts: set[str] = set()
        for r in pool:
            if len([x for x in items if x["intent"] == intent]) >= per_intent:
                break
            w = r.get("word_clean") or r.get("word_vocalized")
            gloss = (r.get("fusha_equivalent") or "").split("/")[0].split("،")[0].strip()
            for pat in patterns:
                text = pat.format(w=w, gloss=gloss).strip()
                if text in seen_texts:
                    continue
                seen_texts.add(text)
                items.append({
                    "id": f"int_seed_{idx:03d}",
                    "text": text,
                    "intent": intent,
                    "_template": pat,
                    "_source_entry_id": r["id"],
                    "_review_note": "confirm intent label is unambiguous; remove if borderline",
                })
                idx += 1
                if len([x for x in items if x["intent"] == intent]) >= per_intent:
                    break
    random.shuffle(items)
    return {
        "name": "INT-test (candidate)",
        "description": (
            "Intent-labeled candidates generated from spec patterns × real "
            "headwords. Each pattern–intent mapping reflects the project's "
            "intent_for() heuristics. Reviewers MUST sanity-check labels and "
            "drop ambiguous items before computing macro-F1."
        ),
        "version": "0.2-candidate",
        "intents": list(INTENT_PATTERNS.keys()),
        "items": items,
        "_todo": [
            "Hand-review every label; drop ambiguous items.",
            "Add ~50 *real* chat messages per intent harvested from the Flutter app "
            "(once a logging-with-consent pipeline exists).",
            "Cross-check 10% with a second annotator; report Cohen's kappa.",
        ],
    }


def main() -> None:
    rows = _fetch_entries()
    print(f"loaded {len(rows)} entries from supabase")

    out = {
        FIXTURES_DIR / "wl_test.candidate.json": build_wl_seeds(rows),
        FIXTURES_DIR / "tr_test.candidate.json": build_tr_seeds(rows),
        FIXTURES_DIR / "int_test.candidate.json": build_int_seeds(rows),
    }
    for p, doc in out.items():
        p.write_text(json.dumps(doc, ensure_ascii=False, indent=2))
        n = len(doc["items"])
        print(f"  wrote {p.relative_to(ROOT)}  (items={n})")


if __name__ == "__main__":
    main()
