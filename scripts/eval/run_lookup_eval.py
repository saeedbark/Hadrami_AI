#!/usr/bin/env python3
"""E2 — Word-lookup retrieval (Recall@1, Recall@5, MRR) on WL-test.

For each ``query`` in WL-test, run the production hybrid retriever and
record the ranked list of returned entry ids. Compute Recall@k and MRR
against ``gold_entry_id``. Only items with ``in_lexicon=true`` contribute
to recall; out-of-lexicon items are reported separately as a refusal-rate
sanity check.
"""

from __future__ import annotations

import argparse
import json

from _common import RESULTS_DIR, load_fixture, setup_backend_path, write_results, is_template
from metrics import mrr, recall_at_k

setup_backend_path()


def _retrieved_ids(query: str, k: int) -> list[int]:
    from app.rag.retrieval import retrieve_rag_context

    merged, _ = retrieve_rag_context(query)
    return [int(e["id"]) for e in merged[:k] if e.get("id") is not None]


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="E2 — Word-lookup eval.")
    p.add_argument("--top-k", type=int, default=10)
    p.add_argument("--max-items", type=int, default=0)
    return p.parse_args()


def main() -> None:
    args = _parse_args()
    fixture = load_fixture("wl_test")
    if is_template(fixture):
        print("WARN: WL-test is still the template — recall numbers will be meaningless.")

    items = fixture.get("items") or []
    if args.max_items:
        items = items[: args.max_items]

    in_lex = [it for it in items if it.get("in_lexicon")]
    out_lex = [it for it in items if not it.get("in_lexicon")]

    retrieved: list[list[int]] = []
    gold: list[int] = []
    for it in in_lex:
        q = (it.get("query") or "").strip()
        if not q or it.get("gold_entry_id") is None:
            continue
        retrieved.append(_retrieved_ids(q, args.top_k))
        gold.append(int(it["gold_entry_id"]))

    out_lex_retrieved_count = 0
    for it in out_lex:
        q = (it.get("query") or "").strip()
        if not q:
            continue
        if _retrieved_ids(q, args.top_k):
            out_lex_retrieved_count += 1

    summary = {
        "in_lexicon_items": len(retrieved),
        "out_of_lexicon_items": len(out_lex),
        "recall_at_1": recall_at_k(retrieved, gold, 1),
        "recall_at_5": recall_at_k(retrieved, gold, 5),
        "mrr": mrr(retrieved, gold),
        "out_of_lexicon_retriever_hit_rate": (
            out_lex_retrieved_count / len(out_lex) if out_lex else None
        ),
    }
    out_path = write_results("lookup_eval", summary)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"Summary JSON: {out_path}")


if __name__ == "__main__":
    main()
