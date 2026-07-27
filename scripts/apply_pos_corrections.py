#!/usr/bin/env python3
"""Apply LLM-recommended POS corrections from ``results/pos_validation_all.json``.

Decision policy:
  * **Compound-POS rows** (Noun/Verb, Adjective/Verb, Adjective/Noun) — the user
    wants these collapsed. We accept the LLM's single-POS recommendation
    automatically when its confidence is ``high`` or ``medium``. Low-confidence
    or unparseable rows are left as-is and surfaced for review.
  * **Other disagreements** — written to ``results/pos_review_queue.json``
    with ``accept=false`` for the user to inspect. Pass ``--apply-all`` to
    accept every disagreement instead (only do this after eyeballing the queue).

Workflow::

    # 1. Dry-run: show what would change.
    backend/venv/bin/python scripts/apply_pos_corrections.py

    # 2. Commit only the auto-collapse decisions.
    backend/venv/bin/python scripts/apply_pos_corrections.py --apply

    # 3. Inspect results/pos_review_queue.json, flip accept=true on the
    #    rows you agree with, then:
    backend/venv/bin/python scripts/apply_pos_corrections.py --apply-queue
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import sync_to_supabase as sync  # noqa: E402

RESULTS_DIR = REPO_ROOT / "results"
ALL_PATH = RESULTS_DIR / "pos_validation_all.json"
QUEUE_PATH = RESULTS_DIR / "pos_review_queue.json"

COMPOUND_POS = {"Noun/Verb", "Adjective/Verb", "Adjective/Noun"}
HIGH_CONF = {"high", "medium"}

# Expression is a known overflow bucket for Adverb / Particle / Pronoun /
# Interrogative. When the LLM moves *out* of Expression with high confidence
# we treat the move as routine cleanup, not a flag-for-review.
EXPRESSION_DRAINS = {"Adverb", "Particle", "Pronoun", "Interrogative"}


def _load_validation() -> list[dict[str, Any]]:
    if not ALL_PATH.exists():
        sys.exit(
            f"Missing {ALL_PATH}. Run scripts/validate_pos.py first."
        )
    return json.loads(ALL_PATH.read_text(encoding="utf-8"))


def _split(entries: list[dict[str, Any]]) -> tuple[list[dict], list[dict], list[dict]]:
    """Return (auto_collapse, review_queue, agree)."""
    auto: list[dict] = []
    review: list[dict] = []
    agree: list[dict] = []
    for e in entries:
        llm = e.get("llm")
        stored = e.get("stored_pos") or ""
        if not llm:
            review.append({**e, "reason": "unparseable LLM response"})
            continue
        new = llm.get("pos") or ""
        if new == stored:
            agree.append(e)
            continue
        is_compound = stored in COMPOUND_POS
        is_expression_drain = stored == "Expression" and new in EXPRESSION_DRAINS
        if (is_compound or is_expression_drain) and llm.get("confidence", "low") in HIGH_CONF:
            auto.append(e)
        else:
            review.append({**e, "accept": False})
    return auto, review, agree


def _commit(client: Any, items: list[dict[str, Any]]) -> int:
    n = 0
    for it in items:
        new_pos = it["llm"]["pos"]
        client.table("entries").update({"pos": new_pos}).eq("id", it["id"]).execute()
        print(f"  id={it['id']}: {it['stored_pos']} -> {new_pos} ({it['llm'].get('confidence')})")
        n += 1
    return n


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply", action="store_true", help="Commit auto-collapse decisions.")
    p.add_argument(
        "--apply-all",
        action="store_true",
        help="Commit ALL LLM disagreements (not just compound-POS rows).",
    )
    p.add_argument(
        "--apply-queue",
        action="store_true",
        help="Commit rows in pos_review_queue.json marked accept=true.",
    )
    args = p.parse_args()

    if args.apply_queue:
        if not QUEUE_PATH.exists():
            sys.exit(f"Missing {QUEUE_PATH}; run without flags first.")
        items = json.loads(QUEUE_PATH.read_text(encoding="utf-8"))
        accepted = [it for it in items if it.get("accept")]
        if not accepted:
            sys.exit("No items marked accept=true in pos_review_queue.json.")
        sync._require_service_role()
        client = sync._make_supabase_client()
        n = _commit(client, accepted)
        print(f"\nApplied {n} corrections from review queue.")
        return

    data = _load_validation()
    auto, review, agree = _split(data)

    print(f"Total classified:   {len(data)}")
    print(f"Agree with stored:  {len(agree)}")
    print(f"Auto-collapse:      {len(auto)}  (compound-POS, high/med conf)")
    print(f"Review queue:       {len(review)}")

    print()
    print("--- Auto-collapse plan (first 30) ---")
    for e in auto[:30]:
        llm = e["llm"]
        print(
            f"  id={e['id']:>4}  {e['stored_pos']:<14} -> {llm['pos']:<10} "
            f"({llm.get('confidence', '?')})  word={e.get('word')}"
        )
    if len(auto) > 30:
        print(f"  … {len(auto) - 30} more")

    QUEUE_PATH.write_text(json.dumps(review, ensure_ascii=False, indent=2), encoding="utf-8")
    print()
    print(f"Review queue (mark accept=true to commit): {QUEUE_PATH}")

    if args.apply or args.apply_all:
        sync._require_service_role()
        client = sync._make_supabase_client()
        target = data if args.apply_all else None
        if args.apply_all:
            commit_list = [
                e
                for e in data
                if e.get("llm")
                and e["llm"]["pos"] != e.get("stored_pos")
                and e["llm"].get("confidence", "low") in HIGH_CONF
            ]
            print(f"\nApplying ALL high/med-confidence corrections ({len(commit_list)} rows)…")
        else:
            commit_list = auto
            print(f"\nApplying compound-POS auto-collapse ({len(commit_list)} rows)…")
        n = _commit(client, commit_list)
        print(f"Applied {n} POS corrections.")
    else:
        print("\nDry-run only. Re-run with --apply to commit auto-collapses, "
              "or --apply-all to accept all high/med-confidence disagreements.")


if __name__ == "__main__":
    main()
