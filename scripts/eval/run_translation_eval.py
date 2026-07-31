#!/usr/bin/env python3
"""E1 — Translation quality on TR-test.

For each Hadrami paragraph in TR-test, get the system's MSA translation and
compare with the gold reference using BLEU + chrF (sacrebleu).

Usage::

    backend/venv/bin/python scripts/eval/run_translation_eval.py \\
        --systems ours,no_rag

Systems implemented:
    * ``ours``    — full pipeline (``get_conversion_answer``).
    * ``no_rag``  — Gemini with no retrieval and no system prompt (B1 in §5).

External-baselines (Google Translate, GPT-4o) are intentionally NOT
shipped: each needs its own credentials. Stubs are left in
``_call_external_baseline`` so the user can plug them in.
"""

from __future__ import annotations

import argparse
import csv
import json
from typing import Any

from _common import (
    RESULTS_DIR,
    load_fixture,
    setup_backend_path,
    write_results,
    is_template,
)
from metrics import corpus_bleu_chrf

setup_backend_path()


def _system_ours(text: str) -> str:
    from app.rag.pipeline import get_conversion_answer

    payload = get_conversion_answer(text)
    return (payload.get("answer") or "").strip()


def _system_no_rag(text: str) -> str:
    """B1: bare Gemini, no retrieval, no system prompt."""
    from app.rag.config import gemini_api_key
    from app.rag.generation import gemini_generate

    prompt = (
        "Translate the following Hadrami Arabic text to Modern Standard Arabic. "
        "Output only the MSA translation, nothing else.\n\n"
        f"{text}"
    )
    out = gemini_generate(prompt, gemini_api_key())
    return (out or "").strip()


def _call_external_baseline(name: str, text: str) -> str:
    """Stub for B3 (Google Translate) and B4 (GPT-4o). Wire credentials before use."""
    raise NotImplementedError(
        f"External baseline '{name}' is not wired. Add credentials and an "
        f"implementation in run_translation_eval.py."
    )


SYSTEMS = {
    "ours": _system_ours,
    "no_rag": _system_no_rag,
}


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="E1 — Translation eval (BLEU/chrF).")
    p.add_argument(
        "--systems",
        default="ours",
        help="Comma-separated systems from: " + ", ".join(SYSTEMS),
    )
    p.add_argument(
        "--max-items",
        type=int,
        default=0,
        help="Cap on items (0 = all). Useful for smoke tests.",
    )
    p.add_argument(
        "--csv-out",
        default=str(RESULTS_DIR / "translation_eval.csv"),
        help="Per-row CSV output",
    )
    return p.parse_args()


def main() -> None:
    args = _parse_args()
    fixture = load_fixture("tr_test")
    if is_template(fixture):
        print(
            "WARN: TR-test is still the template (1 placeholder item). "
            "Build the gold set per research_paper_plan.md §7 before reporting numbers."
        )

    items = fixture.get("items") or []
    if args.max_items:
        items = items[: args.max_items]

    requested = [s.strip() for s in args.systems.split(",") if s.strip()]
    unknown = [s for s in requested if s not in SYSTEMS]
    if unknown:
        raise SystemExit(f"Unknown systems: {unknown}. Choose from {list(SYSTEMS)}.")

    rows: list[dict[str, Any]] = []
    by_system_hyp: dict[str, list[str]] = {s: [] for s in requested}
    refs: list[str] = []

    for item in items:
        h = (item.get("hadrami") or "").strip()
        ref = (item.get("msa_gold") or "").strip()
        if not h or not ref:
            continue
        refs.append(ref)
        for sys_name in requested:
            try:
                hyp = SYSTEMS[sys_name](h)
            except Exception as exc:  # noqa: BLE001 — log and continue
                hyp = f"<<error:{exc!r}>>"
            by_system_hyp[sys_name].append(hyp)
            rows.append(
                {
                    "id": item.get("id"),
                    "system": sys_name,
                    "hadrami": h,
                    "ref": ref,
                    "hyp": hyp,
                }
            )

    summary = {"items": len(refs), "systems": {}}
    for sys_name, hyps in by_system_hyp.items():
        if not hyps:
            continue
        scores = corpus_bleu_chrf(hyps, refs)
        summary["systems"][sys_name] = scores

    # Per-row CSV.
    with open(args.csv_out, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["id", "system", "hadrami", "ref", "hyp"])
        w.writeheader()
        for r in rows:
            w.writerow(r)

    out_path = write_results("translation_eval", summary)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"\nPer-row CSV: {args.csv_out}")
    print(f"Summary JSON: {out_path}")


if __name__ == "__main__":
    main()
