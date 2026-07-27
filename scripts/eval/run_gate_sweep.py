#!/usr/bin/env python3
"""E5 — RAG_CONFIDENCE_GATE ablation sweep (5 points: 0.45 → 0.85).

For each gate value, run a slimmed-down translation + hallucination eval
and record (BLEU, chrF, refusal_rate, invented_count). Plotted in §6.5
as the precision/refusal trade-off curve.
"""

from __future__ import annotations

import argparse
import importlib
import json
import os

from _common import load_fixture, setup_backend_path, write_results, is_template
from metrics import corpus_bleu_chrf, refusal_rate

setup_backend_path()


GATE_VALUES = (0.45, 0.55, 0.65, 0.75, 0.85)


def _reload_pipeline() -> None:
    """Re-import the RAG pipeline so the freshly-set env var takes effect."""
    import app.rag.config as rag_cfg
    import app.rag.pipeline as rag_pipe
    import app.rag.retrieval as rag_ret

    importlib.reload(rag_cfg)
    importlib.reload(rag_ret)
    importlib.reload(rag_pipe)


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="E5 — Gate sweep.")
    p.add_argument(
        "--values",
        default=",".join(str(v) for v in GATE_VALUES),
        help="Comma-separated RAG_CONFIDENCE_GATE values to test.",
    )
    p.add_argument("--max-tr-items", type=int, default=20)
    p.add_argument("--max-hall-items", type=int, default=20)
    return p.parse_args()


def main() -> None:
    args = _parse_args()
    values = [float(v.strip()) for v in args.values.split(",") if v.strip()]
    tr_fixture = load_fixture("tr_test")
    hall_fixture = load_fixture("hall_test")
    if is_template(tr_fixture):
        print("WARN: TR-test is still the template; sweep BLEU/chrF will be meaningless.")

    tr_items = (tr_fixture.get("items") or [])[: args.max_tr_items or None]
    hall_items = (hall_fixture.get("items") or [])[: args.max_hall_items or None]

    rows: list[dict] = []
    for gate in values:
        os.environ["RAG_CONFIDENCE_GATE"] = str(gate)
        _reload_pipeline()
        from app.rag.pipeline import get_chat_answer, get_translation_answer

        # Translation slice.
        hyps: list[str] = []
        refs: list[str] = []
        for it in tr_items:
            h = (it.get("hadrami") or "").strip()
            ref = (it.get("msa_gold") or "").strip()
            if not h or not ref:
                continue
            try:
                payload = get_translation_answer(h)
                hyps.append((payload.get("answer") or "").strip())
            except Exception as exc:  # noqa: BLE001
                hyps.append(f"<<error:{exc!r}>>")
            refs.append(ref)
        bleu_chrf = corpus_bleu_chrf(hyps, refs) if hyps else {"bleu": 0.0, "chrf": 0.0}

        # Hallucination slice.
        replies: list[str] = []
        for it in hall_items:
            try:
                payload = get_chat_answer((it.get("text") or "").strip(), history=[])
                replies.append((payload.get("reply") or "").strip())
            except Exception as exc:  # noqa: BLE001
                replies.append(f"<<error:{exc!r}>>")
        rr = refusal_rate(replies) if replies else 0.0

        rows.append({"gate": gate, **bleu_chrf, "refusal_rate": rr})
        print(f"  gate={gate:0.2f} -> {rows[-1]}")

    summary = {"sweep": rows}
    out_path = write_results("gate_sweep", summary)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"Summary JSON: {out_path}")


if __name__ == "__main__":
    main()
