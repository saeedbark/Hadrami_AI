"""Metrics used across the eval harness.

Pure functions, deliberately small dependencies (sacrebleu only) so the
scripts can run in CI / on a fresh checkout without scikit-learn.

Implemented:
    * BLEU and chrF — sacrebleu corpus-level wrappers.
    * recall_at_k, mrr — retrieval ranking.
    * macro_f1, confusion_matrix — intent classification (no sklearn).
"""

from __future__ import annotations

from collections import Counter
from typing import Iterable


# ---------------------------------------------------------------------------
# Conversion quality
# ---------------------------------------------------------------------------

def corpus_bleu_chrf(
    hypotheses: list[str], references: list[str]
) -> dict[str, float]:
    """Return ``{"bleu": ..., "chrf": ...}`` for parallel hyp/ref lists."""
    import sacrebleu

    if len(hypotheses) != len(references):
        raise ValueError(
            f"len(hyp)={len(hypotheses)} != len(ref)={len(references)}"
        )
    bleu = sacrebleu.corpus_bleu(hypotheses, [references])
    chrf = sacrebleu.corpus_chrf(hypotheses, [references])
    return {"bleu": float(bleu.score), "chrf": float(chrf.score)}


# ---------------------------------------------------------------------------
# Retrieval
# ---------------------------------------------------------------------------

def recall_at_k(retrieved_ids: list[list[int]], gold_ids: list[int], k: int) -> float:
    """Fraction of queries where the gold id appears in the top-k retrieved."""
    if len(retrieved_ids) != len(gold_ids):
        raise ValueError("retrieved_ids and gold_ids must align")
    if not retrieved_ids:
        return 0.0
    hits = sum(1 for r, g in zip(retrieved_ids, gold_ids) if g in (r or [])[:k])
    return hits / len(retrieved_ids)


def mrr(retrieved_ids: list[list[int]], gold_ids: list[int]) -> float:
    """Mean reciprocal rank — 0 if the gold id is not retrieved."""
    if not retrieved_ids:
        return 0.0
    total = 0.0
    for r, g in zip(retrieved_ids, gold_ids):
        try:
            rank = (r or []).index(g) + 1
            total += 1.0 / rank
        except ValueError:
            continue
    return total / len(retrieved_ids)


# ---------------------------------------------------------------------------
# Classification
# ---------------------------------------------------------------------------

def confusion_matrix(
    y_true: list[str], y_pred: list[str], labels: Iterable[str] | None = None
) -> tuple[list[str], list[list[int]]]:
    """Return ``(labels, matrix)``. ``matrix[i][j]`` = count(y_true=i, y_pred=j)."""
    if len(y_true) != len(y_pred):
        raise ValueError("y_true and y_pred lengths differ")
    if labels is None:
        labels = sorted(set(y_true) | set(y_pred))
    labels = list(labels)
    idx = {lbl: i for i, lbl in enumerate(labels)}
    n = len(labels)
    m = [[0] * n for _ in range(n)]
    for t, p in zip(y_true, y_pred):
        if t in idx and p in idx:
            m[idx[t]][idx[p]] += 1
    return labels, m


def macro_f1(y_true: list[str], y_pred: list[str]) -> dict[str, float]:
    """Macro-F1 over the union of observed labels (no sklearn dependency)."""
    if len(y_true) != len(y_pred):
        raise ValueError("y_true and y_pred lengths differ")
    labels = sorted(set(y_true) | set(y_pred))
    f1s: list[float] = []
    per_label: dict[str, dict[str, float]] = {}
    for lbl in labels:
        tp = sum(1 for t, p in zip(y_true, y_pred) if t == lbl and p == lbl)
        fp = sum(1 for t, p in zip(y_true, y_pred) if t != lbl and p == lbl)
        fn = sum(1 for t, p in zip(y_true, y_pred) if t == lbl and p != lbl)
        prec = tp / (tp + fp) if (tp + fp) else 0.0
        rec = tp / (tp + fn) if (tp + fn) else 0.0
        f1 = 2 * prec * rec / (prec + rec) if (prec + rec) else 0.0
        f1s.append(f1)
        per_label[lbl] = {"precision": prec, "recall": rec, "f1": f1, "support": tp + fn}
    macro = sum(f1s) / len(f1s) if f1s else 0.0
    accuracy = sum(1 for t, p in zip(y_true, y_pred) if t == p) / len(y_true) if y_true else 0.0
    return {"macro_f1": macro, "accuracy": accuracy, "per_label": per_label}


# ---------------------------------------------------------------------------
# Hallucination
# ---------------------------------------------------------------------------

def refusal_rate(replies: list[str], markers: tuple[str, ...] | None = None) -> float:
    """Fraction of replies that contain the system's canonical refusal marker.

    ``markers`` defaults to the two phrases the prompts.py / system_prompt.py
    contract uses for "I don't know this word".
    """
    if not replies:
        return 0.0
    markers = markers or (
        "غير موجودة في القاموس",
        "لم يُسترجَع قاموسياً",
        "لم يُسترجَع من القاموس",
        "هل تريد اقتراح إضافتها",
    )
    hits = sum(1 for r in replies if any(m in (r or "") for m in markers))
    return hits / len(replies)


# ---------------------------------------------------------------------------
# Pretty-printing helpers (used by all eval scripts)
# ---------------------------------------------------------------------------

def render_confusion(labels: list[str], matrix: list[list[int]]) -> str:
    """Plain-text confusion matrix. Rows = true, cols = predicted."""
    pad = max(len(lbl) for lbl in labels) if labels else 4
    head = " " * (pad + 2) + " ".join(f"{lbl:>{pad}}" for lbl in labels)
    lines = [head]
    for i, row in enumerate(matrix):
        cells = " ".join(f"{cell:>{pad}}" for cell in row)
        lines.append(f"{labels[i]:<{pad}}  {cells}")
    return "\n".join(lines)


def freq_table(items: Iterable[str]) -> list[tuple[str, int]]:
    return Counter(items).most_common()
