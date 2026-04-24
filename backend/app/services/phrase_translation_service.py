"""RAG-grounded phrase translation (MSA <-> Hadrami) via Gemini."""

from __future__ import annotations

import json
import re
from concurrent.futures import Future, ThreadPoolExecutor, as_completed
from typing import Any

from ..core.config import (
    PHRASE_TRANSLATE_CHUNK_SIZE,
    PHRASE_TRANSLATE_LONG_HINT_CHARS,
    PHRASE_TRANSLATE_MAX_WORKERS,
)
from ..rag_engine import (
    MODE,
    _gemini_api_key,
    _gemini_generate,
    _preview,
    _rag_log,
    retrieve_phrase_context,
)
from ..schemas import Entry


def _context_block(entries: list[dict], *, definition_cap: int) -> str:
    lines = []
    for e in entries:
        lines.append(
            f"- حضرمي: {e.get('word_vocalized', '')} | فصحى: {e.get('fusha_equivalent', '')} | "
            f"شرح: {(e.get('definition') or '')[:definition_cap]}"
        )
    return (
        "\n".join(lines)
        if lines
        else "(لا توجد مطابقات قاموسية واضحة — ترجم النص بأسلوب حضرمي طبيعي كما في المحادثة الحرة.)"
    )


def _normalize_span_token(s: str) -> str:
    t = (s or "").strip()
    while t and t[-1] in "؟!.,،؛:!?)】」":
        t = t[:-1].rstrip()
    while t and t[0] in "(【「":
        t = t[1:].lstrip()
    return t.strip()


def _allowed_surfaces_from_entries(merged: list[dict], direction: str) -> set[str]:
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


def _phrase_prompt(text: str, direction: str, entries: list[dict]) -> str:
    n = len(text)
    def_cap = 70 if n > PHRASE_TRANSLATE_LONG_HINT_CHARS else 120
    ctx = _context_block(entries, definition_cap=def_cap)
    long_note = ""
    if n > PHRASE_TRANSLATE_LONG_HINT_CHARS:
        long_note = (
            "\n\nالنص طويل: أنجز ترجمة كاملة بنفس ترتيب الجمل والفقرات دون تلخيص أو حذف أجزاء. "
            "لا تختصر الفقرة إلى جملة واحدة. في hadrami_spans أدرج على الأكثر 12 إدخالاً، "
            "وأدرج فقط أشكالاً تطابق كلمات حضرمية (أو معادلاتها الفصحى حسب الاتجاه) من قائمة القاموس أعلاه — "
            "لا تُبرز حروف جر أو كلمات عامة (مثل: على، في، من، إلى، مع، القهوة، الناس) إن لم تكن وردت كمدخل قاموس صريح."
        )
    if direction == "ar_to_hadrami":
        task = (
            "ترجم النص من العربية الفصحى إلى اللهجة الحضرمية اليمنية بأسلوب طبيعي. "
            "استخدم مداخل القاموس أعلاه عندما تنطبق؛ لا تخترع كلمات حضرمية بعيدة عن المعنى."
        )
        span_hint = (
            "في hadrami_spans ضع فقط مقاطع من translated_text تساوي بالضبط كلمات حضرمية وردت في قائمة القاموس أعلاه "
            "(بعد إزالة علامات الترقيم الطرفية فقط إن لزم)."
        )
    else:
        task = (
            "ترجم النص من اللهجة الحضرمية إلى العربية الفصحى بأسلوب طبيعي. "
            "استخدم مداخل القاموس أعلاه عندما تنطبق."
        )
        span_hint = (
            "في hadrami_spans ضع فقط مقاطع من translated_text تساوي بالضبط معادلات فصحى وردت في قائمة القاموس أعلاه "
            "(عمود الفصحى)، وليست كلمات عامة لم تُذكر في القاموس."
        )

    return f"""أنت مترجم متخصص في اللهجة الحضرمية اليمنية.

مراجع من القاموس (استخدمها فقط عندما تكون **منطقية ومرتبطة بالنص**):
{ctx}

إذا بدت المداخل غير ذات صلة أو عشوائية، **تجاهلها تماماً** وترجم بأسلوب حضرمي سليم كما تفعل مع نص حر، دون فرض كلمات من القاموس في غير موضعها.

المهمة: {task}
{span_hint}
{long_note}

النص الأصلي:
{text}

أعد الإجابة كـ JSON صالح فقط بدون شرح أو markdown، بالشكل التالي:
{{"translated_text":"...","hadrami_spans":[{{"start":0,"end":3,"surface":"..."}}]}}

قواعد:
- start و end: موضعا الأحرف في translated_text (عدّ الأحرف كوحدات يونيكود كما في لغة بايثون len والقطع).
- surface يجب أن يساوي translated_text[start:end].
- إن لم يكن هناك شيء للتمييز، استخدم مصفوفة فارغة لـ hadrami_spans."""


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


def _entries_to_response(entries: list[dict]) -> list[Entry]:
    from ..schemas import ExamplePair

    out: list[Entry] = []
    for e in entries:
        examples = None
        raw_ex = e.get("examples")
        if isinstance(raw_ex, list):
            examples = [
                ExamplePair(
                    h=str(x.get("h", "")),
                    f=str(x.get("f", "")),
                )
                for x in raw_ex
                if isinstance(x, dict)
            ]
        out.append(
            Entry(
                id=int(e.get("id", 0)),
                word_vocalized=str(e.get("word_vocalized", "")),
                word_clean=e.get("word_clean"),
                root=e.get("root"),
                pos=e.get("pos"),
                fusha_equivalent=str(e.get("fusha_equivalent", "")),
                definition=str(e.get("definition", "")),
                region=e.get("region", "General"),
                synonyms=e.get("synonyms"),
                examples=examples,
            )
        )
    return out


def _split_into_chunks(text: str, max_chunk: int) -> list[str]:
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


def _translate_single_chunk(
    text: str, direction: str, merged: list[dict], api_key: str
) -> tuple[str, list[dict[str, Any]]]:
    prompt = _phrase_prompt(text, direction, merged)
    raw = _gemini_generate(prompt, api_key)
    if raw.startswith("Gemini not available:"):
        return raw, []
    data = _parse_json_payload(raw)
    translated = (data.get("translated_text") if isinstance(data, dict) else None) or raw.strip()
    spans = _normalize_spans(translated, data.get("hadrami_spans") if isinstance(data, dict) else None)
    spans = _filter_spans_to_lexicon(translated, spans, merged, direction)
    return translated, spans


def translate_phrase(text: str, direction: str) -> dict[str, Any]:
    stripped = (text or "").strip()
    merged, ctx_for_api = retrieve_phrase_context(stripped)
    context_models = _entries_to_response(ctx_for_api)
    api_key = _gemini_api_key()

    chunks = _split_into_chunks(stripped, PHRASE_TRANSLATE_CHUNK_SIZE)

    if len(chunks) == 1:
        translated, spans = _translate_single_chunk(stripped, direction, merged, api_key)
        if translated.startswith("Gemini not available:"):
            _rag_log(f"translate-phrase Gemini fail -> {_preview(translated)}")
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
        _rag_log(
            f"translate-phrase chunked: {len(chunks)} chunks for {len(stripped)} chars "
            f"(workers={workers})"
        )

        def _merge_ordered(
            ordered: list[tuple[str, list[dict[str, Any]]]],
        ) -> tuple[str, list[dict[str, Any]]]:
            all_translated: list[str] = []
            all_spans: list[dict[str, Any]] = []
            offset = 0
            for t, s in ordered:
                if t.startswith("Gemini not available:"):
                    return t, []
                for sp in s:
                    sp["start"] += offset
                    sp["end"] += offset
                all_translated.append(t)
                all_spans.extend(s)
                offset += len(t) + 1
            return "\n".join(all_translated), all_spans

        if workers <= 1:
            ordered = [_translate_single_chunk(c, direction, merged, api_key) for c in chunks]
        else:
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
                ordered = [(t, s) for _, t, s in indexed]

        translated, spans = _merge_ordered(ordered)
        if translated.startswith("Gemini not available:"):
            return {
                "input_text": stripped,
                "direction": direction,
                "translated_text": translated,
                "hadrami_spans": [],
                "mode": "error",
                "rag_mode": MODE,
                "context": context_models,
            }

    mode_tag = "local_gemini" if MODE == "local" else "gemini"
    _rag_log(
        f"translate-phrase dir={direction!r} mode={mode_tag} "
        f"chars={len(translated)} spans={len(spans)} preview={_preview(translated)}"
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
