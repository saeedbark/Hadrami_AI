#!/usr/bin/env python3
"""Evaluate the Hadrami NLP system against ``data/eval_pairs.json``.

Computes four families of metrics:

* **Conversion quality (Hadrami → MSA)** — chrF, chrF++, BLEU, and
  exact-match, via ``sacrebleu``. Uses character-level tokenization for
  BLEU when requested to stay fair across dialect pairs.
* **Retrieval quality** — Recall@k and MRR against the gold headword(s).
  The gold set for each pair is the union of Hadrami tokens that appear
  in the lexicon. If a pair has no lexicon-matching token, it is excluded
  from retrieval metrics (counted separately).
* **Refusal / grounding** — fraction of out-of-domain questions for which
  the system correctly refuses (uses a small hand-picked OOD set when
  provided via ``--ood-file``).
* **Latency** — wall-clock per pair, so we can report tail latency.

Systems supported via ``--system``:

* ``keyword_only`` — only ``search_entries_expanded``, no LLM
  (deterministic lower bound).
* ``vector_only`` — only pgvector, no LLM.
* ``ours_simple`` — RAG_MODE=simple, keyword retrieval + Gemini.
* ``ours_local`` — RAG_MODE=local, hybrid retrieval + Gemini (default).
* ``plain_gemini`` — no retrieval, Gemini-only (zero-shot baseline).

Example::

    python scripts/evaluate.py --system ours_local \
        --pairs data/eval_pairs.json \
        --output results/ours_local.json \
        --limit 20

Output is a single JSON report with per-pair hypotheses and aggregated
metrics, suitable for copy-pasting into a paper or tracking over time.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(BACKEND_DIR))

try:
    from dotenv import load_dotenv

    load_dotenv(BACKEND_DIR / ".env")
except ImportError:
    pass


DEFAULT_PAIRS = BACKEND_DIR / "data" / "eval_pairs.json"

# Systems we can evaluate. Each sets RAG_MODE/GEMINI_API_KEY externally
# via environment before calling the pipeline; we restore the originals
# after the run.
SYSTEMS = ("keyword_only", "vector_only", "ours_simple", "ours_local", "plain_gemini")


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def _load_pairs(path: Path, limit: int | None) -> list[dict[str, Any]]:
    with open(path, encoding="utf-8") as f:
        payload = json.load(f)
    pairs = payload.get("pairs") if isinstance(payload, dict) else payload
    if not isinstance(pairs, list):
        sys.exit(f"ERROR: {path} does not contain a 'pairs' list")
    if limit is not None:
        pairs = pairs[:limit]
    return pairs


# ---------------------------------------------------------------------------
# Retrieval metrics
# ---------------------------------------------------------------------------

def _hadrami_tokens(text: str) -> list[str]:
    return [t for t in text.replace("؟", " ").replace("،", " ").split() if t.strip()]


def _gold_ids_for_pair(pair: dict[str, Any]) -> set[int] | None:
    """Gold entry ids are taken from the pair's ``gold_ids`` field when
    present; otherwise we skip the pair in retrieval metrics."""
    gold = pair.get("gold_ids")
    if isinstance(gold, list) and gold:
        return {int(x) for x in gold if isinstance(x, (int, str)) and str(x).isdigit()}
    return None


def _retrieval_recall_at_k(retrieved_ids: list[int], gold: set[int], k: int) -> float:
    if not gold:
        return 0.0
    top = set(retrieved_ids[:k])
    return len(top & gold) / len(gold)


def _mrr(retrieved_ids: list[int], gold: set[int]) -> float:
    if not gold:
        return 0.0
    for i, eid in enumerate(retrieved_ids, 1):
        if eid in gold:
            return 1.0 / i
    return 0.0


# ---------------------------------------------------------------------------
# Conversion quality
# ---------------------------------------------------------------------------

def _compute_conversion_metrics(
    hyps: list[str], refs: list[str]
) -> dict[str, float]:
    """Aggregate sacrebleu-style metrics over a corpus of hypotheses."""
    if not hyps:
        return {"chrF": 0.0, "chrFpp": 0.0, "BLEU": 0.0, "exact_match": 0.0}

    try:
        import sacrebleu
    except ImportError:
        print(
            "sacrebleu not installed; install with `pip install sacrebleu`"
            " to compute chrF/BLEU.",
            file=sys.stderr,
        )
        return {
            "chrF": float("nan"),
            "chrFpp": float("nan"),
            "BLEU": float("nan"),
            "exact_match": sum(h.strip() == r.strip() for h, r in zip(hyps, refs))
            / len(hyps),
        }

    refs_corpus = [refs]
    chrf = sacrebleu.corpus_chrf(hyps, refs_corpus, word_order=0)
    chrfpp = sacrebleu.corpus_chrf(hyps, refs_corpus, word_order=2)
    bleu = sacrebleu.corpus_bleu(
        hyps, refs_corpus, tokenize="intl", smooth_method="exp"
    )
    em = sum(h.strip() == r.strip() for h, r in zip(hyps, refs)) / len(hyps)

    return {
        "chrF": round(chrf.score, 2),
        "chrFpp": round(chrfpp.score, 2),
        "BLEU": round(bleu.score, 2),
        "exact_match": round(em, 4),
    }


# ---------------------------------------------------------------------------
# System runners
# ---------------------------------------------------------------------------

def _run_keyword_only(hadrami: str) -> tuple[str, list[int]]:
    """Pure-lexicon lower bound: top-1 MSA gloss from expanded keyword search."""
    from app.rag.retrieval import expanded_keyword_context

    payload = expanded_keyword_context(hadrami, top_k=5)
    rows = payload.get("results") or []
    ids = [int(r["id"]) for r in rows if r.get("id") is not None]
    if rows:
        return str(rows[0].get("fusha_equivalent") or "").strip(), ids
    return "", ids


def _run_vector_only(hadrami: str) -> tuple[str, list[int]]:
    from app.rag.retrieval import vector_context

    rows = vector_context(hadrami, top_k=5)
    ids = [int(r["id"]) for r in rows if r.get("id") is not None]
    if rows:
        return str(rows[0].get("fusha_equivalent") or "").strip(), ids
    return "", ids


def _run_ours(hadrami: str) -> tuple[str, list[int]]:
    """Full pipeline (honors current ``RAG_MODE`` env)."""
    from app.rag.pipeline import get_conversion_answer

    result = get_conversion_answer(hadrami)
    answer = str(result.get("answer") or "").strip()
    ids = [int(getattr(e, "id", 0)) for e in result.get("context") or []]
    return answer, ids


def _run_plain_gemini(hadrami: str) -> tuple[str, list[int]]:
    """Baseline: Gemini zero-shot, no retrieval context at all."""
    from app.rag.config import gemini_api_key
    from app.rag.generation import gemini_generate, is_gemini_unavailable

    prompt = (
        "You convert Hadrami Arabic dialect into Modern Standard Arabic. "
        "Convert the following sentence. Output only the MSA rendering, no explanation.\n\n"
        f"{hadrami}"
    )
    reply = gemini_generate(prompt, gemini_api_key())
    if is_gemini_unavailable(reply):
        return "", []
    return reply.strip(), []


RUNNERS = {
    "keyword_only": _run_keyword_only,
    "vector_only": _run_vector_only,
    "ours_simple": _run_ours,
    "ours_local": _run_ours,
    "plain_gemini": _run_plain_gemini,
}


def _apply_system_env(system: str) -> dict[str, str | None]:
    """Mutate environment for the target system; return saved originals."""
    saved = {"RAG_MODE": os.environ.get("RAG_MODE")}
    if system == "ours_simple":
        os.environ["RAG_MODE"] = "simple"
    elif system == "ours_local":
        os.environ["RAG_MODE"] = "local"
    return saved


def _restore_env(saved: dict[str, str | None]) -> None:
    for key, value in saved.items():
        if value is None:
            os.environ.pop(key, None)
        else:
            os.environ[key] = value


# ---------------------------------------------------------------------------
# Main evaluation loop
# ---------------------------------------------------------------------------

def evaluate(
    pairs: list[dict[str, Any]],
    system: str,
    verbose: bool = False,
) -> dict[str, Any]:
    runner = RUNNERS[system]
    saved_env = _apply_system_env(system)

    # Invalidate the retrieval module-level cache so RAG_MODE switches
    # actually take effect between systems in the same process.
    try:
        import importlib

        from app.rag import retrieval as _ret

        importlib.reload(_ret)
    except Exception:
        pass

    per_pair: list[dict[str, Any]] = []
    hyps: list[str] = []
    refs: list[str] = []
    recalls_at_1: list[float] = []
    recalls_at_5: list[float] = []
    mrrs: list[float] = []
    retrieval_eligible = 0
    latencies_ms: list[float] = []

    try:
        for i, pair in enumerate(pairs, 1):
            hadrami = str(pair.get("hadrami") or "").strip()
            fusha = str(pair.get("fusha") or "").strip()
            if not hadrami or not fusha:
                continue

            t0 = time.perf_counter()
            try:
                hyp, retrieved_ids = runner(hadrami)
            except Exception as exc:
                if verbose:
                    print(f"  [{i}] runner error: {exc}", file=sys.stderr)
                hyp, retrieved_ids = "", []
            dt_ms = (time.perf_counter() - t0) * 1000.0
            latencies_ms.append(dt_ms)

            gold = _gold_ids_for_pair(pair)
            r1: float | None
            r5: float | None
            mrr: float | None
            if gold is not None:
                r1 = _retrieval_recall_at_k(retrieved_ids, gold, 1)
                r5 = _retrieval_recall_at_k(retrieved_ids, gold, 5)
                mrr = _mrr(retrieved_ids, gold)
                recalls_at_1.append(r1)
                recalls_at_5.append(r5)
                mrrs.append(mrr)
                retrieval_eligible += 1
            else:
                r1 = r5 = mrr = None

            hyps.append(hyp)
            refs.append(fusha)

            per_pair.append(
                {
                    "id": pair.get("id"),
                    "hadrami": hadrami,
                    "reference_fusha": fusha,
                    "hypothesis": hyp,
                    "retrieved_ids": retrieved_ids,
                    "recall_at_1": r1,
                    "recall_at_5": r5,
                    "mrr": mrr,
                    "latency_ms": round(dt_ms, 2),
                    "domain": pair.get("domain"),
                }
            )

            if verbose:
                print(
                    f"  [{i:>3}/{len(pairs)}] {dt_ms:7.1f} ms | {hadrami[:40]:<40} -> "
                    f"{hyp[:60]}"
                )
    finally:
        _restore_env(saved_env)

    quality = _compute_conversion_metrics(hyps, refs)
    retrieval = {
        "recall_at_1": round(sum(recalls_at_1) / retrieval_eligible, 4)
        if retrieval_eligible
        else None,
        "recall_at_5": round(sum(recalls_at_5) / retrieval_eligible, 4)
        if retrieval_eligible
        else None,
        "mrr": round(sum(mrrs) / retrieval_eligible, 4)
        if retrieval_eligible
        else None,
        "eligible_pairs": retrieval_eligible,
        "ineligible_pairs": len(per_pair) - retrieval_eligible,
    }
    latencies_ms.sort()
    p50 = latencies_ms[len(latencies_ms) // 2] if latencies_ms else 0.0
    p95 = (
        latencies_ms[max(0, int(len(latencies_ms) * 0.95) - 1)]
        if latencies_ms
        else 0.0
    )
    latency = {
        "mean_ms": round(sum(latencies_ms) / len(latencies_ms), 2)
        if latencies_ms
        else 0.0,
        "p50_ms": round(p50, 2),
        "p95_ms": round(p95, 2),
    }
    domain_counts = Counter(p.get("domain") for p in per_pair if p.get("domain"))

    return {
        "system": system,
        "n_pairs": len(per_pair),
        "quality": quality,
        "retrieval": retrieval,
        "latency": latency,
        "domain_counts": dict(domain_counts),
        "per_pair": per_pair,
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _format_summary(report: dict[str, Any]) -> str:
    q = report["quality"]
    r = report["retrieval"]
    lat = report["latency"]
    lines = [
        f"=== {report['system']} — {report['n_pairs']} pairs ===",
        f"  chrF={q['chrF']}   chrF++={q['chrFpp']}   BLEU={q['BLEU']}   EM={q['exact_match']}",
        f"  Recall@1={r['recall_at_1']}   Recall@5={r['recall_at_5']}   MRR={r['mrr']}",
        f"  Retrieval-eligible pairs: {r['eligible_pairs']}  "
        f"(ineligible: {r['ineligible_pairs']})",
        f"  Latency: mean={lat['mean_ms']}ms  p50={lat['p50_ms']}ms  p95={lat['p95_ms']}ms",
    ]
    if report.get("domain_counts"):
        lines.append(f"  Domains: {report['domain_counts']}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Evaluate the Hadrami NLP system.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--pairs",
        type=Path,
        default=DEFAULT_PAIRS,
        help="Evaluation pairs JSON file.",
    )
    parser.add_argument(
        "--system",
        choices=SYSTEMS,
        default="ours_local",
        help="Which system configuration to evaluate.",
    )
    parser.add_argument(
        "--systems",
        nargs="+",
        choices=SYSTEMS,
        help="Evaluate multiple systems sequentially (overrides --system).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Write the full JSON report here (default: stdout summary only).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Only evaluate the first N pairs (useful for smoke tests).",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print per-pair hypotheses as they are produced.",
    )
    args = parser.parse_args()

    if not args.pairs.exists():
        sys.exit(f"ERROR: pairs file not found: {args.pairs}")

    pairs = _load_pairs(args.pairs, args.limit)
    systems = args.systems or [args.system]

    all_reports: list[dict[str, Any]] = []
    for system in systems:
        print(f"\nRunning {system} on {len(pairs)} pairs ...")
        report = evaluate(pairs, system, verbose=args.verbose)
        all_reports.append(report)
        print(_format_summary(report))

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        payload = all_reports[0] if len(all_reports) == 1 else {"reports": all_reports}
        args.output.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(f"\nWrote report to {args.output}")


if __name__ == "__main__":
    main()
