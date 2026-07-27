#!/usr/bin/env python3
"""Generate ``semantic_intent`` and ``transliteration`` for every entry.

Both fields are produced by Gemini in a single call per row to amortize
the rate-limit cost. Uses the multi-key rotator.

Pre-requisite: run
``backend/migrations/20260503_add_semantic_intent_and_transliteration.sql``
in Supabase SQL Editor first (adds the two new columns).

Workflow::

    # Dry-run: classify all rows, write to results/enrichment.json. No DB writes.
    backend/venv/bin/python scripts/generate_enrichment.py

    # Commit: also UPDATE the rows.
    backend/venv/bin/python scripts/generate_enrichment.py --apply
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

RESULTS_DIR = REPO_ROOT / "results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)
CACHE_PATH = RESULTS_DIR / "enrichment.json"


SEMANTIC_INTENTS = (
    "action",
    "object",
    "person",
    "emotion",
    "place",
    "time",
    "descriptor",
    "expression",
    "function",
)


PROMPT_TEMPLATE = """You are an Arabic linguist. Given this Hadrami dialect entry, do TWO things:

1) Classify its semantic intent — what kind of thing the word refers to. Choose EXACTLY ONE label from:
{intents}

   Rules:
   - "action"     — verbs, actions, processes (يفعل، يخرج، يبني)
   - "object"     — concrete physical things (إناء، خشب، حيوان)
   - "person"     — people, roles (طفل، أم، تاجر)
   - "emotion"    — feelings or mental states (خوف، فرح، حسد)
   - "place"      — locations (السوق، المنزل، الساحل)
   - "time"       — temporal references (الفجر، الآن، أبداً)
   - "descriptor" — adjectives, qualities (جميل، طويل، أحمر)
   - "expression" — fixed phrases / interjections (مرحباً، إن شاء الله)
   - "function"   — pronouns, particles, prepositions, interrogatives (نحن، في، ماذا)

2) Provide a Latin-script transliteration of the Hadrami headword.
   Use the simple lay-reader scheme below (NOT IPA, NOT Buckwalter):
   - ا/أ/إ/آ → a   ب → b   ت → t   ث → th  ج → j   ح → H   خ → kh
   - د → d   ذ → dh  ر → r   ز → z   س → s   ش → sh  ص → S
   - ض → D   ط → T   ظ → Z   ع → 3   غ → gh  ف → f   ق → q
   - ك → k   ل → l   م → m   ن → n   ه → h   و → w / u   ي → y / i
   - shadda → double the consonant
   - Drop tashkeel from the headword first, then transliterate.

Word (Hadrami, vocalized): {word}
Modern Standard Arabic equivalent: {fusha}
Definition (Arabic): {definition}
Part of speech: {pos}

Return ONLY a single-line JSON object:
{{"semantic_intent": "<one of the labels>", "transliteration": "<latin form>"}}"""


_JSON_RE = re.compile(r"\{[^{}]*\}", re.DOTALL)


def _parse(raw: str) -> dict[str, Any] | None:
    if not raw:
        return None
    m = _JSON_RE.search(raw)
    if not m:
        return None
    try:
        obj = json.loads(m.group(0))
    except json.JSONDecodeError:
        return None
    intent = (obj.get("semantic_intent") or "").strip().lower()
    translit = (obj.get("transliteration") or "").strip()
    if intent not in SEMANTIC_INTENTS:
        return None
    if not translit or len(translit) > 80:
        return None
    return {"semantic_intent": intent, "transliteration": translit}


def fetch_rows(client: Any) -> list[dict[str, Any]]:
    cols = "id, word_vocalized, fusha_equivalent, definition, pos"
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
    p.add_argument("--apply", action="store_true", help="Commit the UPDATEs.")
    p.add_argument("--max", type=int, default=0, help="Cap rows for smoke testing.")
    p.add_argument("--sleep", type=float, default=2.5, help="Inter-request delay.")
    args = p.parse_args()

    sync._require_service_role()
    client = sync._make_supabase_client()
    rows = fetch_rows(client)
    if args.max:
        rows = rows[: args.max]

    cached: dict[int, dict[str, Any]] = {}
    if CACHE_PATH.exists():
        try:
            cached = {int(r["id"]): r for r in json.loads(CACHE_PATH.read_text("utf-8"))}
        except Exception:
            cached = {}

    rotator = KeyRotator()
    print(
        f"rows={len(rows)}  rotator_keys={rotator.n}  "
        f"sleep={args.sleep}s  cached={len(cached)}",
        flush=True,
    )

    todo = [r for r in rows if r["id"] not in cached]
    results: list[dict[str, Any]] = list(cached.values())
    for i, row in enumerate(todo, 1):
        prompt = PROMPT_TEMPLATE.format(
            intents="\n".join(f"   - {i}" for i in SEMANTIC_INTENTS),
            word=row.get("word_vocalized") or "",
            fusha=row.get("fusha_equivalent") or "",
            definition=(row.get("definition") or "")[:500],
            pos=row.get("pos") or "",
        )
        raw = rotator.call(prompt)
        out = _parse(raw)
        results.append(
            {
                "id": row["id"],
                "word": row.get("word_vocalized"),
                "stored_pos": row.get("pos"),
                "llm": out,
            }
        )
        # Write to DB immediately so partial progress is preserved if killed.
        if args.apply and out:
            try:
                client.table("entries").update(
                    {
                        "semantic_intent": out["semantic_intent"],
                        "transliteration": out["transliteration"],
                    }
                ).eq("id", row["id"]).execute()
            except Exception as exc:  # noqa: BLE001
                print(f"  WARN: UPDATE failed for id={row['id']}: {exc!r}", flush=True)
        if i % 20 == 0 or i == len(todo):
            CACHE_PATH.write_text(
                json.dumps(results, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            done_ok = sum(1 for r in results if r["llm"])
            print(f"  {i}/{len(todo)}  parseable={done_ok}", flush=True)
        time.sleep(args.sleep)

    CACHE_PATH.write_text(
        json.dumps(results, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    parseable = [r for r in results if r["llm"]]
    print()
    print(f"parseable: {len(parseable)} / {len(results)}")

    from collections import Counter
    intents = Counter(r["llm"]["semantic_intent"] for r in parseable)
    print("\nsemantic_intent distribution:")
    for k, n in intents.most_common():
        print(f"  {n:>4}  {k}")

    if args.apply:
        # Catch-up pass: re-apply for any cached rows that aren't yet in the DB
        # (handles cache loaded from a previous --dry-run).
        print(f"\nVerifying {len(parseable)} DB writes…", flush=True)
        n = 0
        for r in parseable:
            client.table("entries").update(
                {
                    "semantic_intent": r["llm"]["semantic_intent"],
                    "transliteration": r["llm"]["transliteration"],
                }
            ).eq("id", r["id"]).execute()
            n += 1
            if n % 200 == 0:
                print(f"  {n}/{len(parseable)}", flush=True)
        print(f"Confirmed {n} UPDATEs.")
    else:
        print("\nDry-run only. Re-run with --apply after migration SQL is in place.")
    print(f"\nCache: {CACHE_PATH}")


if __name__ == "__main__":
    main()
