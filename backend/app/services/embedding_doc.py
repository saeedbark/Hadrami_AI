"""Canonical Arabic-first document text used to embed a lexicon entry.

The same builder is used at:
  * sync time (``scripts/sync_to_supabase.py`` backfill), and
  * query-side document construction (eval scripts, future re-embedding jobs).

Keeping it in one place is what makes ``RETRIEVAL_DOCUMENT`` ↔
``RETRIEVAL_QUERY`` parity possible: if the doc text drifts between the
sync script and any other consumer the cosine similarity collapses.

Versioned via ``EMBEDDING_DOC_VERSION``; bump it whenever the layout
changes so callers can decide to re-embed.
"""

from __future__ import annotations

from typing import Any


EMBEDDING_DOC_VERSION = "v2"


def _as_list(v: Any) -> list:
    return v if isinstance(v, list) else []


def embedding_text_for_entry(entry: dict[str, Any]) -> str:
    """Single Arabic-first document string for vector embedding.

    Layout (one field per line, Arabic labels):

        الكلمة: <word_vocalized> (<word_clean>)
        الجذر: <root>
        الفصحى: <fusha_equivalent>
        المعنى: <definition>
        المرادفات: a، b، c
        مثال: <h>
        الوسوم: t1، t2
        ملاحظة: <note>

    ``fusha_equivalent`` and ``tags`` are the two fields the previous
    version (``v1``) omitted; both are primary retrieval signals when
    a user query contains MSA paraphrases or topical hints.
    """
    parts: list[str] = []
    wv = (entry.get("word_vocalized") or "").strip()
    wc = (entry.get("word_clean") or "").strip()
    if wv:
        parts.append(f"الكلمة: {wv} ({wc})" if wc and wc != wv else f"الكلمة: {wv}")

    root = (entry.get("root") or "").strip()
    if root:
        parts.append(f"الجذر: {root}")

    fusha = (entry.get("fusha_equivalent") or "").strip()
    if fusha:
        parts.append(f"الفصحى: {fusha}")

    definition = (entry.get("definition") or "").strip()
    if definition:
        parts.append(f"المعنى: {definition}")

    syns = [str(s).strip() for s in _as_list(entry.get("synonyms")) if s]
    if syns:
        parts.append("المرادفات: " + "، ".join(syns))

    for ex in _as_list(entry.get("examples"))[:1]:
        if isinstance(ex, dict):
            h = (ex.get("h") or "").strip()
            if h:
                parts.append(f"مثال: {h}")
                break

    tags = [str(t).strip() for t in _as_list(entry.get("tags")) if t]
    if tags:
        parts.append("الوسوم: " + "، ".join(tags))

    note = (entry.get("note") or "").strip()
    if note:
        parts.append(f"ملاحظة: {note}")

    return "\n".join(parts) if parts else wv
