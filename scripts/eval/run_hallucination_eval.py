#!/usr/bin/env python3
"""E4 — Hallucination resistance on HALL-test.

Run the system on 50 fabricated Hadrami-shaped strings and measure how
often it correctly refuses / emits the suggest-word block instead of
inventing a meaning. The headline result for §6.4 of the paper.

A reply is counted as a *correct refusal* if it contains any of the
canonical refusal markers from ``metrics.refusal_rate``. Replies that
do not contain a refusal marker are written to
``results/hallucination_inventions.jsonl`` for manual rubric scoring of
the "invented-meaning rate".
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from _common import RESULTS_DIR, load_fixture, setup_backend_path, write_results
from metrics import refusal_rate

setup_backend_path()


def _system_ours(text: str) -> str:
    from app.rag.pipeline import get_chat_answer

    payload = get_chat_answer(text, history=[])
    return (payload.get("reply") or "").strip()


def _system_no_rag(text: str) -> str:
    from app.rag.config import gemini_api_key
    from app.rag.generation import gemini_generate

    prompt = (
        "You are an expert on the Hadrami Arabic dialect. The user asks:\n"
        f"{text}\n\nAnswer in Arabic."
    )
    return (gemini_generate(prompt, gemini_api_key()) or "").strip()


SYSTEMS = {"ours": _system_ours, "no_rag": _system_no_rag}


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="E4 — Hallucination eval.")
    p.add_argument("--systems", default="ours")
    p.add_argument("--max-items", type=int, default=0)
    return p.parse_args()


def main() -> None:
    args = _parse_args()
    fixture = load_fixture("hall_test")
    items = fixture.get("items") or []
    if args.max_items:
        items = items[: args.max_items]

    requested = [s.strip() for s in args.systems.split(",") if s.strip()]
    summary: dict = {"items": len(items), "systems": {}}
    inventions_path = RESULTS_DIR / "hallucination_inventions.jsonl"
    inventions: list[dict] = []

    for sys_name in requested:
        if sys_name not in SYSTEMS:
            raise SystemExit(f"Unknown system '{sys_name}'. Available: {list(SYSTEMS)}")
        replies: list[str] = []
        for it in items:
            text = (it.get("text") or "").strip()
            try:
                reply = SYSTEMS[sys_name](text)
            except Exception as exc:  # noqa: BLE001
                reply = f"<<error:{exc!r}>>"
            replies.append(reply)

        rate = refusal_rate(replies)
        summary["systems"][sys_name] = {"refusal_rate": rate}
        for it, reply in zip(items, replies):
            if not any(
                m in reply
                for m in (
                    "غير موجودة في القاموس",
                    "لم يُسترجَع قاموسياً",
                    "هل تريد اقتراح إضافتها",
                )
            ):
                inventions.append(
                    {"system": sys_name, "id": it.get("id"), "text": it.get("text"), "reply": reply}
                )

    Path(inventions_path).write_text(
        "\n".join(json.dumps(r, ensure_ascii=False) for r in inventions),
        encoding="utf-8",
    )
    out_path = write_results("hallucination_eval", summary)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"Inventions for manual review: {inventions_path}")
    print(f"Summary JSON: {out_path}")


if __name__ == "__main__":
    main()
