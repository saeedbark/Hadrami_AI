#!/usr/bin/env python3
"""Deterministic backfill for ``transliteration`` and ``semantic_intent``.

Used to fill the rows that the LLM enrichment hasn't reached yet — keeps the
release artifact 100% populated without spending more API quota. The LLM-
classified rows (already in DB) are NOT overwritten.

Methods:
  * ``transliteration`` — character-by-character DIN-31635-lite mapping.
    Strip Arabic diacritics first, then map each letter. No nuance —
    "good enough" Latin form for non-Arabic-readers to identify words.
  * ``semantic_intent`` — rule-based on POS + tags + definition keywords.
    See ``_infer_intent`` for the decision tree. Hand-tuned against the
    100 LLM-classified rows already in DB.

Workflow::

    backend/venv/bin/python scripts/heuristic_backfill.py            # dry-run
    backend/venv/bin/python scripts/heuristic_backfill.py --apply    # commit
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402

RESULTS_DIR = REPO_ROOT / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Transliteration — DIN-31635-lite
# ---------------------------------------------------------------------------

_AR_TO_LATIN = {
    "ا": "a", "أ": "a", "إ": "i", "آ": "a", "ٱ": "a",
    "ب": "b", "ت": "t", "ث": "th",
    "ج": "j", "ح": "H", "خ": "kh",
    "د": "d", "ذ": "dh",
    "ر": "r", "ز": "z",
    "س": "s", "ش": "sh",
    "ص": "S", "ض": "D",
    "ط": "T", "ظ": "Z",
    "ع": "3", "غ": "gh",
    "ف": "f", "ق": "q",
    "ك": "k", "ل": "l", "م": "m", "ن": "n",
    "ه": "h", "ة": "h",
    "و": "w", "ي": "y", "ى": "a",
    "ء": "'", "ؤ": "'", "ئ": "'",
    " ": " ",
}

_TASHKEEL = re.compile(r"[ً-ْٰـ]")


def transliterate(arabic: str) -> str:
    """Map Arabic letters to a simple Latin form. Drops diacritics first."""
    if not arabic:
        return ""
    s = _TASHKEEL.sub("", unicodedata.normalize("NFC", arabic))
    out: list[str] = []
    prev: str = ""
    for ch in s:
        latin = _AR_TO_LATIN.get(ch, "")
        if not latin:
            continue
        # Shadda (ّ) gets stripped by _TASHKEEL above; we approximate
        # gemination by detecting a letter twice in a row.
        if latin == prev and len(prev) == 1:
            out.append(latin)
        else:
            out.append(latin)
        prev = latin
    return "".join(out).strip()


# ---------------------------------------------------------------------------
# Semantic intent — rule-based
# ---------------------------------------------------------------------------

_INTENTS = (
    "action", "object", "person", "emotion", "place",
    "time", "descriptor", "expression", "function",
)

# Tag → intent overrides (highest priority).
_TAG_TO_INTENT: dict[str, str] = {
    "emotions": "emotion",
    "fear": "emotion",
    "love": "emotion",
    "happiness": "emotion",
    "anger": "emotion",
    "places": "place",
    "geography": "place",
    "landmarks": "place",
    "time": "time",
    "weather": "time",  # weather phenomena are often time-bounded
    "people": "person",
    "family": "person",
    "professions": "person",
    "marriage": "person",
    "expressions": "expression",
    "proverbs": "expression",
    "greetings": "expression",
}


def _infer_intent(pos: str, tags: list[str], definition: str) -> str:
    """Return one of ``_INTENTS`` based on POS, tags, and definition keywords."""
    pos = (pos or "").strip()
    tags_norm = [t.lower().strip() for t in (tags or []) if isinstance(t, str)]
    defn = (definition or "").strip()

    # 1. POS gives a strong default for the function-word categories.
    if pos in {"Pronoun", "Interrogative", "Particle", "Preposition"}:
        return "function"
    if pos == "Verb Phrase":
        return "action"
    if pos == "Expression":
        return "expression"

    # 2. Tag overrides — strongest content signal.
    for tag in tags_norm:
        if tag in _TAG_TO_INTENT:
            return _TAG_TO_INTENT[tag]

    # 3. POS-based default for the remaining content categories.
    if pos == "Verb" or pos == "Noun/Verb":
        return "action"
    if pos in {"Adjective", "Adjective/Verb", "Adjective/Noun", "Adverb"}:
        # Adverbs that look temporal → time, otherwise descriptor.
        if any(k in defn for k in ("الآن", "أمس", "غداً", "صباح", "ليلة", "اليوم")):
            return "time"
        return "descriptor"

    # 4. Default: noun → object (the most common category by far).
    return "object"


# ---------------------------------------------------------------------------
# IO
# ---------------------------------------------------------------------------

def fetch_rows(client: Any) -> list[dict[str, Any]]:
    cols = (
        "id, word_vocalized, pos, tags, definition, "
        "transliteration, semantic_intent"
    )
    out = []
    off = 0
    while True:
        r = client.table("entries").select(cols).order("id").range(off, off + 499).execute()
        out.extend(r.data or [])
        if len(r.data or []) < 500:
            break
        off += 500
    return out


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply", action="store_true", help="Commit UPDATEs to Supabase.")
    p.add_argument(
        "--overwrite-llm",
        action="store_true",
        help="Also overwrite rows where the LLM already wrote a value (default: skip them).",
    )
    args = p.parse_args()

    sync._require_service_role()
    client = sync._make_supabase_client()
    rows = fetch_rows(client)

    plans: list[dict[str, Any]] = []
    intent_counts: dict[str, int] = {}
    for r in rows:
        update: dict[str, Any] = {}
        # transliteration — only fill if currently NULL/empty.
        if args.overwrite_llm or not (r.get("transliteration") or "").strip():
            translit = transliterate(r.get("word_vocalized") or "")
            if translit:
                update["transliteration"] = translit
        # semantic_intent — only fill if currently NULL/empty.
        if args.overwrite_llm or not (r.get("semantic_intent") or "").strip():
            intent = _infer_intent(
                r.get("pos") or "",
                r.get("tags") or [],
                r.get("definition") or "",
            )
            update["semantic_intent"] = intent
            intent_counts[intent] = intent_counts.get(intent, 0) + 1
        if update:
            plans.append({"id": r["id"], "update": update})

    print(f"Total rows scanned:  {len(rows)}")
    print(f"Rows to backfill:    {len(plans)}")
    if intent_counts:
        print("Heuristic semantic_intent distribution (these rows only):")
        for k, n in sorted(intent_counts.items(), key=lambda kv: -kv[1]):
            print(f"  {n:>4}  {k}")

    out_path = RESULTS_DIR / (
        "heuristic_backfill.applied.json" if args.apply else "heuristic_backfill.dryrun.json"
    )
    out_path.write_text(json.dumps(plans, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nChange record: {out_path}")

    if args.apply:
        n = 0
        for p_ in plans:
            client.table("entries").update(p_["update"]).eq("id", p_["id"]).execute()
            n += 1
            if n % 100 == 0:
                print(f"  {n}/{len(plans)}", flush=True)
        print(f"\nApplied {n} UPDATEs.")
    else:
        print("\nDry-run only. Re-run with --apply to commit.")


if __name__ == "__main__":
    main()
