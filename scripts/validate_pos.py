#!/usr/bin/env python3
"""LLM-based POS validation for the live ``entries`` table.

For each entry, ask Gemini to classify the POS based on
``(word_vocalized, fusha_equivalent, definition)``. Compare the LLM's
answer with the stored ``pos`` and surface every mismatch as a
reviewable correction list. **Read-only** by default; pass ``--apply``
after reviewing the list to commit the LLM's choice.

Usage::

    # Dry-run: classify all rows, write the disagreement list to disk.
    backend/venv/bin/python scripts/validate_pos.py

    # Sample first to gauge accuracy / cost (10 rows ≈ free).
    backend/venv/bin/python scripts/validate_pos.py --max 10

    # After reviewing results/pos_disagreements.json, commit the LLM's
    # answer for the disagreements you accept (edit ``accept`` field
    # in the JSON before running with --apply).
    backend/venv/bin/python scripts/validate_pos.py --apply

Cost estimate: ~$0.0001 / row with gemini-2.5-flash → ~$0.10 for 1,000 rows.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402

from gemini_rotator import KeyRotator  # noqa: E402

_rotator = KeyRotator()

RESULTS_DIR = REPO_ROOT / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)
DISAGREEMENT_PATH = RESULTS_DIR / "pos_disagreements.json"
ALL_PATH = RESULTS_DIR / "pos_validation_all.json"


# Keep the label set tight so the LLM doesn't invent new categories.
# v2 taxonomy: dropped compound POS (single primary class per entry); added
# Pronoun + Interrogative (was previously shoehorned into Expression).
ALLOWED_POS = {
    "Noun",
    "Verb",
    "Adjective",
    "Adverb",
    "Preposition",
    "Particle",
    "Pronoun",
    "Interrogative",
    "Expression",
    "Verb Phrase",
}


PROMPT_TEMPLATE = """You are an Arabic linguist. Classify the part of speech of a Hadrami Arabic dialect word given its Modern Standard Arabic equivalent and Arabic definition.

Allowed labels (choose EXACTLY ONE, exactly as written):
{labels}

Decision rules:
- "Verb" — any conjugated verb form (past, present, imperative). Use this even if a related noun exists.
- "Noun" — nouns, including verbal nouns (مصدر) and gerunds. Definite-article + nominal morphology (الخَلْع, الرَّزْم) is Noun.
- "Adjective" — adjectives and active/passive participles (اسم فاعل، اسم مفعول) like مهلِّل، مكسور.
- "Adverb" — words that function as ظرف زمان أو مكان (تَوْك، أَبَداً، ذَحِين، لَمَّانْ).
- "Pronoun" — personal/demonstrative/relative pronouns (نحنا، حَد، لِي، ذَا).
- "Interrogative" — question words (إِيش، لِيْشْ، وِيْش، وَيْن، مِنْ وَيْن).
- "Particle" — short interjections, vocative/imperative particles (صَه، أَحّ، اش، قَاق).
- "Preposition" — prepositions (عَا، قَفَا).
- "Verb Phrase" — verb + complement functioning as a verb (حَطَّت الدَّار).
- "Expression" — fixed multi-word phrases that aren't a Verb Phrase, when no other category fits.

If the headword has BOTH a noun and verb sense (different vocalizations), return the POS of the *citation form* shown — usually the noun if it has ال or taa marbuta, otherwise the verb.

Word (Hadrami, vocalized): {word}
Modern Standard Arabic equivalent: {fusha}
Definition (Arabic): {definition}

Return ONLY a JSON object on a single line:
{{"pos": "<one of the allowed labels>", "confidence": "high|medium|low", "reason": "<one short Arabic phrase>"}}"""


_JSON_RE = re.compile(r"\{[^{}]*\}", re.DOTALL)


def _parse_response(raw: str) -> dict[str, Any] | None:
    if not raw:
        return None
    # The model sometimes wraps the JSON in code fences or trailing prose.
    m = _JSON_RE.search(raw)
    if not m:
        return None
    try:
        obj = json.loads(m.group(0))
    except json.JSONDecodeError:
        return None
    pos = (obj.get("pos") or "").strip()
    if pos not in ALLOWED_POS:
        return None
    return {
        "pos": pos,
        "confidence": (obj.get("confidence") or "low").strip().lower(),
        "reason": (obj.get("reason") or "").strip(),
    }


def classify_entry(entry: dict[str, Any]) -> dict[str, Any] | None:
    prompt = PROMPT_TEMPLATE.format(
        labels="\n".join(f"- {p}" for p in sorted(ALLOWED_POS)),
        word=entry.get("word_vocalized") or "",
        fusha=entry.get("fusha_equivalent") or "",
        definition=(entry.get("definition") or "")[:500],
    )
    raw = _rotator.call(prompt)
    return _parse_response(raw)


def fetch_all() -> list[dict[str, Any]]:
    sync._require_service_role()
    client = sync._make_supabase_client()
    out: list[dict[str, Any]] = []
    page = 500
    off = 0
    while True:
        r = (
            client.table("entries")
            .select("id, word_vocalized, fusha_equivalent, definition, pos")
            .order("id")
            .range(off, off + page - 1)
            .execute()
        )
        rows = r.data or []
        out.extend(rows)
        if len(rows) < page:
            break
        off += page
    return out


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--max", type=int, default=0, help="Limit rows (smoke test).")
    p.add_argument(
        "--sleep",
        type=float,
        default=0.05,
        help="Seconds between requests (free tier needs ~15s for 4 req/min).",
    )
    p.add_argument(
        "--start-id",
        type=int,
        default=0,
        help="Resume from this id (skips classified rows already in the cache file).",
    )
    p.add_argument(
        "--apply",
        action="store_true",
        help="Commit LLM POS for entries marked accept=true in the disagreement file.",
    )
    p.add_argument(
        "--from-cache",
        action="store_true",
        help="Re-derive disagreement list from results/pos_validation_all.json (no API calls).",
    )
    args = p.parse_args()

    if args.apply:
        return _apply_accepted_changes()

    rows = fetch_all()
    if args.max:
        rows = rows[: args.max]
    print(f"Validating POS on {len(rows)} rows…", flush=True)

    # Resume support: load any prior checkpoint and skip ids already classified.
    prior: dict[int, dict[str, Any]] = {}
    if ALL_PATH.exists():
        try:
            for r in json.loads(ALL_PATH.read_text(encoding="utf-8")):
                prior[int(r["id"])] = r
        except Exception:
            prior = {}

    if args.from_cache and prior:
        print(f"  loaded {len(prior)} cached classifications", flush=True)
        all_results = list(prior.values())
    else:
        all_results = list(prior.values())
        ids_done = set(prior.keys())
        to_run = [r for r in rows if r["id"] not in ids_done and r["id"] >= args.start_id]
        if not to_run:
            print("  nothing new to classify (cache is complete)", flush=True)
        else:
            print(f"  classifying {len(to_run)} rows ({len(prior)} already in cache)", flush=True)
            for i, row in enumerate(to_run, 1):
                llm = classify_entry(row)
                all_results.append(
                    {
                        "id": row["id"],
                        "word": row.get("word_vocalized"),
                        "fusha": row.get("fusha_equivalent"),
                        "stored_pos": (row.get("pos") or "").strip(),
                        "llm": llm,
                    }
                )
                if i % 20 == 0 or i == len(to_run):
                    print(f"  {i}/{len(to_run)}", flush=True)
                    ALL_PATH.write_text(
                        json.dumps(all_results, ensure_ascii=False, indent=2),
                        encoding="utf-8",
                    )
                time.sleep(args.sleep)

            ALL_PATH.write_text(
                json.dumps(all_results, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )

    # Split into agree / disagree / unparseable.
    agree = [r for r in all_results if r["llm"] and r["llm"]["pos"] == r["stored_pos"]]
    disagree = [
        {
            **r,
            "accept": False,  # human flips this to True for changes they want applied
        }
        for r in all_results
        if r["llm"] and r["llm"]["pos"] != r["stored_pos"]
    ]
    unparseable = [r for r in all_results if not r["llm"]]

    DISAGREEMENT_PATH.write_text(
        json.dumps(disagree, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print()
    print(f"agree:        {len(agree)}")
    print(f"disagree:     {len(disagree)}")
    print(f"unparseable:  {len(unparseable)}")
    print()
    print(f"Full classifications: {ALL_PATH}")
    print(f"Disagreements (review then mark accept=true): {DISAGREEMENT_PATH}")

    # Show the first 25 disagreements as a quick eyeball.
    print()
    print("--- First 25 disagreements ---")
    for d in disagree[:25]:
        llm = d["llm"]
        print(
            f"  id={d['id']:>4} stored={d['stored_pos']:<14} "
            f"llm={llm['pos']:<14} ({llm['confidence']:<6}) "
            f"word={d['word']:<18} fusha={d['fusha'][:30]}  reason={llm['reason'][:60]}"
        )


def _apply_accepted_changes() -> None:
    if not DISAGREEMENT_PATH.exists():
        sys.exit(f"Missing {DISAGREEMENT_PATH}; run without --apply first.")
    items = json.loads(DISAGREEMENT_PATH.read_text(encoding="utf-8"))
    accepted = [it for it in items if it.get("accept")]
    if not accepted:
        sys.exit("No items marked accept=true in pos_disagreements.json. Edit and re-run.")

    sync._require_service_role()
    client = sync._make_supabase_client()
    print(f"Applying {len(accepted)} POS corrections…")
    for it in accepted:
        client.table("entries").update({"pos": it["llm"]["pos"]}).eq("id", it["id"]).execute()
        print(f"  id={it['id']}: {it['stored_pos']} -> {it['llm']['pos']}")
    print("Done.")


if __name__ == "__main__":
    main()
