#!/usr/bin/env python3
"""E3 — Intent classifier accuracy on INT-test (macro-F1, confusion matrix)."""

from __future__ import annotations

import argparse
import json

from _common import load_fixture, setup_backend_path, write_results, is_template
from metrics import confusion_matrix, macro_f1, render_confusion

setup_backend_path()


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="E3 — Intent classifier eval.")
    p.add_argument("--max-items", type=int, default=0)
    return p.parse_args()


def main() -> None:
    args = _parse_args()
    from app.rag.system_prompt import intent_for

    fixture = load_fixture("int_test")
    if is_template(fixture):
        print("WARN: INT-test is still the template (5 items) — F1 here is illustrative only.")

    items = fixture.get("items") or []
    if args.max_items:
        items = items[: args.max_items]

    labels_known: list[str] = list(fixture.get("intents") or [
        "word",
        "translate",
        "define",
        "semantic",
        "qa",
    ])

    y_true: list[str] = []
    y_pred: list[str] = []
    misclassified: list[dict[str, str]] = []
    for it in items:
        text = (it.get("text") or "").strip()
        gold = (it.get("intent") or "").strip()
        if not text or gold not in labels_known:
            continue
        pred = intent_for(text)
        y_true.append(gold)
        y_pred.append(pred)
        if pred != gold:
            misclassified.append({"id": it.get("id", ""), "text": text, "gold": gold, "pred": pred})

    metrics = macro_f1(y_true, y_pred)
    cm_labels, cm = confusion_matrix(y_true, y_pred, labels=labels_known)

    summary = {
        "items": len(y_true),
        "macro_f1": metrics["macro_f1"],
        "accuracy": metrics["accuracy"],
        "per_label": metrics["per_label"],
        "confusion_labels": cm_labels,
        "confusion_matrix": cm,
        "misclassified": misclassified[:50],
    }
    out_path = write_results("intent_eval", summary)
    print(json.dumps({k: v for k, v in summary.items() if k != "confusion_matrix"}, ensure_ascii=False, indent=2))
    print("\nConfusion matrix (rows=gold, cols=pred):")
    print(render_confusion(cm_labels, cm))
    print(f"\nSummary JSON: {out_path}")


if __name__ == "__main__":
    main()
