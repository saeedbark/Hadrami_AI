"""RAG-grounded phrase translation (MSA <-> Hadrami) via Gemini.

Retrieval, prompting, and Gemini access all live in :mod:`app.rag.*` now;
this module owns only the pieces that are specific to the phrase-translate
endpoint:

* chunked long-text handling with bounded parallelism,
* strict JSON parsing of the model output,
* span normalization + lexicon-grounded span filtering.
"""

from __future__ import annotations

import json
import re
from concurrent.futures import Future, ThreadPoolExecutor, as_completed
from typing import Any

from ..core.config import PHRASE_TRANSLATE_CHUNK_SIZE, PHRASE_TRANSLATE_MAX_WORKERS
from ..rag.config import MODE, gemini_api_key, rag_response_mode_tag
from ..rag.generation import (
    GEMINI_UNAVAILABLE_PREFIX,
    gemini_generate,
    is_gemini_unavailable,
)
from ..rag.logging_utils import preview, rag_log
from ..rag.prompts import phrase_prompt
from ..rag.retrieval import retrieve_phrase_context
from ..rag.serialization import entries_to_response


# ---------------------------------------------------------------------------
# Span cleanup & lexicon filtering
# ---------------------------------------------------------------------------

def _normalize_span_token(s: str) -> str:
    t = (s or "").strip()
    while t and t[-1] in "؟!.,،؛:!?)】」":
        t = t[:-1].rstrip()
    while t and t[0] in "(【「":
        t = t[1:].lstrip()
    return t.strip()


def _allowed_surfaces_from_entries(merged: list[dict], direction: str) -> set[str]:
    """Surfaces the model is *allowed* to highlight, by direction.

    For ``ar_to_hadrami`` we only trust the Hadrami headword; for
    ``hadrami_to_ar`` we only trust the MSA gloss. Synonyms and examples
    are intentionally excluded from the *highlight* filter (they're already
    used for prompt grounding) to keep spans crisp.
    """
    raw: set[str] = set()
    for e in merged:
        if direction == "ar_to_hadrami":
            w = (e.get("word_vocalized") or "").strip()
        else:
            w = (e.get("fusha_equivalent") or "").strip()
        if w:
            raw.add(w)
    return {_normalize_span_token(x) for x in raw if _normalize_span_token(x)}


def _filter_spans_to_lexicon(
    translated_text: str,
    spans: list[dict[str, Any]],
    merged: list[dict],
    direction: str,
    max_spans: int = 12,
) -> list[dict[str, Any]]:
    allowed = _allowed_surfaces_from_entries(merged, direction)
    if not allowed:
        return []
    kept: list[dict[str, Any]] = []
    for sp in spans:
        surf = str(sp.get("surface", "")).strip()
        if not surf:
            try:
                s, e = int(sp["start"]), int(sp["end"])
                if 0 <= s <= e <= len(translated_text):
                    surf = translated_text[s:e].strip()
            except (KeyError, TypeError, ValueError):
                surf = ""
        if not surf:
            continue
        if _normalize_span_token(surf) in allowed:
            kept.append(sp)
        if len(kept) >= max_spans:
            break
    return kept


# ---------------------------------------------------------------------------
# JSON + span parsing
# ---------------------------------------------------------------------------

def _parse_json_payload(raw: str) -> dict[str, Any]:
    t = (raw or "").strip()
    m = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", t, re.IGNORECASE)
    if m:
        t = m.group(1).strip()
    try:
        return json.loads(t)
    except json.JSONDecodeError:
        return {}


def _normalize_spans(translated_text: str, spans: Any) -> list[dict[str, Any]]:
    if not isinstance(spans, list):
        return []
    n = len(translated_text)
    out: list[dict[str, Any]] = []
    for s in spans:
        if not isinstance(s, dict):
            continue
        try:
            start = int(s["start"])
            end = int(s["end"])
        except (KeyError, TypeError, ValueError):
            surf = str(s.get("surface") or "").strip()
            if not surf:
                continue
            idx = translated_text.find(surf)
            if idx < 0:
                continue
            start, end = idx, idx + len(surf)
        if start < 0 or end > n or start > end:
            surf = str(s.get("surface") or "").strip()
            if surf:
                idx = translated_text.find(surf)
                if idx >= 0:
                    start, end = idx, idx + len(surf)
                else:
                    continue
            else:
                continue
        surface = translated_text[start:end]
        if not surface and str(s.get("surface") or "").strip():
            surface = str(s.get("surface")).strip()
        out.append({"start": start, "end": end, "surface": surface})
    out.sort(key=lambda x: x["start"])
    return out


# ---------------------------------------------------------------------------
# Chunking for long inputs
# ---------------------------------------------------------------------------

def _split_into_chunks(text: str, max_chunk: int) -> list[str]:
    """Paragraph-then-sentence split that respects ``max_chunk``.

    We split on blank-line paragraphs first, then on sentence terminators
    (``.``, ``!``, ``?``, ``،``, ``؟``) only if a single paragraph still
    overflows. The goal is to keep each chunk under the model's comfortable
    context size while never breaking a sentence mid-word.
    """
    if len(text) <= max_chunk:
        return [text]

    chunks: list[str] = []
    paragraphs = re.split(r"(\n\s*\n)", text)
    current = ""
    for para in paragraphs:
        if len(current) + len(para) <= max_chunk:
            current += para
        else:
            if current.strip():
                chunks.append(current.strip())
            if len(para) > max_chunk:
                sentences = re.split(r"(?<=[.!?،؟])\s+", para)
                for s in sentences:
                    if len(current) + len(s) + 1 <= max_chunk:
                        current = (current + " " + s).strip()
                    else:
                        if current.strip():
                            chunks.append(current.strip())
                        current = s
            else:
                current = para
    if current.strip():
        chunks.append(current.strip())
    return chunks if chunks else [text]


# ---------------------------------------------------------------------------
# Per-chunk translation
# ---------------------------------------------------------------------------

def _translate_single_chunk(
    text: str, direction: str, merged: list[dict], api_key: str
) -> tuple[str, list[dict[str, Any]]]:
    prompt = phrase_prompt(text, direction, merged)
    raw = gemini_generate(prompt, api_key)
    if is_gemini_unavailable(raw):
        return raw, []
    data = _parse_json_payload(raw)
    translated = (data.get("translated_text") if isinstance(data, dict) else None) or raw.strip()
    spans = _normalize_spans(
        translated,
        data.get("hadrami_spans") if isinstance(data, dict) else None,
    )
    spans = _filter_spans_to_lexicon(translated, spans, merged, direction)
    return translated, spans


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

def translate_phrase(text: str, direction: str) -> dict[str, Any]:
    stripped = (text or "").strip()
    merged, ctx_for_api = retrieve_phrase_context(stripped)
    context_models = entries_to_response(ctx_for_api)
    api_key = gemini_api_key()

    chunks = _split_into_chunks(stripped, PHRASE_TRANSLATE_CHUNK_SIZE)

    if len(chunks) == 1:
        translated, spans = _translate_single_chunk(stripped, direction, merged, api_key)
        if is_gemini_unavailable(translated):
            rag_log(f"translate-phrase Gemini fail -> {preview(translated)}")
            return {
                "input_text": stripped,
                "direction": direction,
                "translated_text": translated,
                "hadrami_spans": [],
                "mode": "error",
                "rag_mode": MODE,
                "context": context_models,
            }
    else:
        workers = min(PHRASE_TRANSLATE_MAX_WORKERS, len(chunks))
        rag_log(
            f"translate-phrase chunked: {len(chunks)} chunks for {len(stripped)} chars "
            f"(workers={workers})"
        )
        ordered = _translate_chunks_parallel(chunks, direction, merged, api_key, workers)

        translated, spans = _merge_chunk_results(ordered)
        if is_gemini_unavailable(translated):
            return {
                "input_text": stripped,
                "direction": direction,
                "translated_text": translated,
                "hadrami_spans": [],
                "mode": "error",
                "rag_mode": MODE,
                "context": context_models,
            }

    mode_tag = rag_response_mode_tag()
    rag_log(
        f"translate-phrase dir={direction!r} mode={mode_tag} "
        f"chars={len(translated)} spans={len(spans)} preview={preview(translated)}"
    )

    return {
        "input_text": stripped,
        "direction": direction,
        "translated_text": translated,
        "hadrami_spans": spans,
        "mode": mode_tag,
        "rag_mode": MODE,
        "context": context_models,
    }


# ---------------------------------------------------------------------------
# Parallel chunk translation helpers
# ---------------------------------------------------------------------------

def _translate_chunks_parallel(
    chunks: list[str],
    direction: str,
    merged: list[dict],
    api_key: str,
    workers: int,
) -> list[tuple[str, list[dict[str, Any]]]]:
    if workers <= 1:
        return [_translate_single_chunk(c, direction, merged, api_key) for c in chunks]

    future_to_idx: dict[Future, int] = {}
    with ThreadPoolExecutor(max_workers=workers) as ex:
        for i, chunk in enumerate(chunks):
            fut = ex.submit(_translate_single_chunk, chunk, direction, merged, api_key)
            future_to_idx[fut] = i
        indexed: list[tuple[int, str, list[dict[str, Any]]]] = []
        for fut in as_completed(future_to_idx):
            idx = future_to_idx[fut]
            t, s = fut.result()
            indexed.append((idx, t, s))
    indexed.sort(key=lambda x: x[0])
    return [(t, s) for _, t, s in indexed]


def _merge_chunk_results(
    ordered: list[tuple[str, list[dict[str, Any]]]],
) -> tuple[str, list[dict[str, Any]]]:
    all_translated: list[str] = []
    all_spans: list[dict[str, Any]] = []
    offset = 0
    for t, s in ordered:
        if t.startswith(GEMINI_UNAVAILABLE_PREFIX):
            return t, []
        for sp in s:
            sp["start"] += offset
            sp["end"] += offset
        all_translated.append(t)
        all_spans.extend(s)
        offset += len(t) + 1
    return "\n".join(all_translated), all_spans
