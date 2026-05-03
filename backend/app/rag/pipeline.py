"""Public orchestration layer: compose retrieval → prompt → generation → serialize.

This module owns the three user-facing functions the HTTP handlers call:

* :func:`get_rag_answer`         — ``/ask``
* :func:`get_chat_answer`        — ``/chat``
* :func:`get_translation_answer` — ``/ask`` when the question looks like a
                                   translation request (shared behavior with
                                   ``/translate-phrase`` but without chunking)

The phrase-translation service
(:mod:`app.services.phrase_translation_service`) imports a few helpers from
:mod:`.generation` and :mod:`.retrieval` directly — it is *not* a
private-import coupling; it is a deliberately-thin wrapper around the same
retrieval + generation primitives.
"""

from __future__ import annotations

from typing import Any

from .config import MODE, gemini_api_key, rag_response_mode_tag
from .generation import chat_generation_config, gemini_generate, is_gemini_unavailable
from .logging_utils import preview, rag_log
from .prompts import (
    chat_prompt,
    looks_like_translation_request,
    prompt_for_gemini,
    translation_prompt,
)
from .retrieval import (
    expanded_keyword_context,
    phrase_top_score,
    retrieve_phrase_context,
    retrieve_rag_context,
)
from .serialization import finalize_ask_payload
from .text_utils import first_example


__all__ = [
    "MODE",
    "get_chat_answer",
    "get_rag_answer",
    "get_translation_answer",
    "retrieve_phrase_context",
    "retrieve_rag_context",
]


_INSUFFICIENT_CONTEXT_MSG = (
    "لم يُسترجَع من القاموس ما يكفي للإجابة عن هذا السؤال بدقة. "
    "حاول إعادة الصياغة أو البحث عن الكلمة مباشرةً في صفحة القاموس."
)

# Below this top_score the deterministic fallback refuses to emit a
# speculative MSA gloss — returning one would be a silent hallucination.
# 100 = exact word-level hit; 70 ≈ strong partial match.
_MIN_FALLBACK_SCORE = 70


def _lexicon_fallback_answer(entries: list[dict], top_score: int) -> str:
    """Deterministic offline answer used when Gemini is unavailable."""
    if not entries or top_score < _MIN_FALLBACK_SCORE:
        return _INSUFFICIENT_CONTEXT_MSG

    entry = entries[0]
    head = str(entry.get("word_vocalized") or "").strip() or "—"
    fusha = str(entry.get("fusha_equivalent") or "").strip() or "—"
    definition = str(entry.get("definition") or "").strip()
    ex_h, ex_f = first_example(entry)
    block = f"**{head}**\n\nالمعنى بالفصحى: {fusha}"
    if definition:
        block += f"\n\nالشرح (من القاموس): {definition[:500]}"
    if ex_h and ex_f:
        block += f"\n\nمثال: {ex_h} — {ex_f}"
    block += "\n\n_(إجابة من القاموس المحلي؛ نموذج التوليد غير متاح مؤقتاً.)_"
    return block


def _chat_fallback_reply(entries: list[dict], top_score: int = 0) -> str:
    """Grounded fallback for ``/chat`` when Gemini fails."""
    if not entries or top_score < _MIN_FALLBACK_SCORE:
        return (
            "تعذّر الاتصال بنموذج الإجابة، ولم يُسترجَع من القاموس ما يكفي للإجابة بدقة. "
            "جرّب إعادة صياغة السؤال أو البحث عن الكلمة مباشرةً في صفحة القاموس."
        )
    parts: list[str] = []
    for entry in entries[:3]:
        head = str(entry.get("word_vocalized") or "").strip() or "—"
        fusha = str(entry.get("fusha_equivalent") or "").strip() or "—"
        definition = str(entry.get("definition") or "").strip()
        ex_h, ex_f = first_example(entry)
        block = f"**{head}**\n\nالمعنى بالفصحى: {fusha}"
        if definition:
            block += f"\n\nالشرح (من القاموس): {definition[:500]}"
        if ex_h and ex_f:
            block += f"\n\nمثال: {ex_h} — {ex_f}"
        parts.append(block)
    tail = "\n\n_(إجابة مبسّطة من القاموس فقط؛ لتفسير أغنى فعّل نموذج Gemini.)_"
    return "\n\n---\n\n".join(parts) + tail


# ---------------------------------------------------------------------------
# Public entrypoints
# ---------------------------------------------------------------------------

def get_translation_answer(question: str) -> dict[str, Any]:
    """Answer a Hadrami→MSA translation question with phrase-lexicon retrieval."""
    merged, ctx_for_api = retrieve_phrase_context(question)
    top_score = phrase_top_score(question)
    prompt = translation_prompt(question, merged)
    answer = gemini_generate(prompt, gemini_api_key())

    if is_gemini_unavailable(answer):
        print(
            f"🤖❌ RAG/translate: Gemini not used. Reason: {preview(answer, 240)} | "
            f"top_score={top_score} | lexicon_hits={len(merged)}",
            flush=True,
        )
        fb = _lexicon_fallback_answer(merged, top_score)
        tag = rag_response_mode_tag()
        rag_log(f"translation Gemini failed -> grounded fallback mode={tag} preview={preview(fb)}")
        return finalize_ask_payload(fb, tag, ctx_for_api, answer_source="lexicon")

    tag = rag_response_mode_tag()
    rag_log(
        f"🤖✅ RAG/translate: reply from Gemini | mode={tag!r} | chars={len(answer)} | "
        f"preview: {preview(answer)}"
    )
    rag_log(f"get_translation_answer END mode={tag} preview={preview(answer)}")
    return finalize_ask_payload(answer, tag, ctx_for_api, answer_source="model")


def get_rag_answer(question: str) -> dict[str, Any]:
    """Answer an informational question about a Hadrami word/phrase."""
    q = (question or "").strip()

    if looks_like_translation_request(q):
        return get_translation_answer(q)

    merged, ctx_for_api = retrieve_rag_context(q)
    kw_payload = expanded_keyword_context(q, top_k=8)
    top_score = int(kw_payload.get("top_score") or 0)
    prompt = prompt_for_gemini(q, merged)
    answer = gemini_generate(prompt, gemini_api_key())

    if is_gemini_unavailable(answer):
        print(
            f"🤖❌ /ask: Gemini not used — the answer is the offline lexicon path. "
            f"Reason: {preview(answer, 240)} | top_score={top_score} | "
            f"retrieved_entries={len(merged)} (need score≥{_MIN_FALLBACK_SCORE} to fill from dict)",
            flush=True,
        )
        fb = _lexicon_fallback_answer(merged, top_score)
        if fb == _INSUFFICIENT_CONTEXT_MSG:
            print(
                f"📚ℹ️  /ask: lexicon fallback = generic 'not enough retrieved' message | "
                f"usually top_score<{_MIN_FALLBACK_SCORE} or no hits (now top_score={top_score})",
                flush=True,
            )
        tag = rag_response_mode_tag()
        rag_log(
            f"Gemini failed -> grounded fallback mode={tag} top_score={top_score} preview={preview(fb)}"
        )
        return finalize_ask_payload(fb, tag, ctx_for_api, answer_source="lexicon")

    tag = rag_response_mode_tag()
    rag_log(
        f"🤖✅ /ask: reply from Gemini | mode={tag!r} | chars={len(answer)} | "
        f"answer_source=model | preview: {preview(answer)}"
    )
    rag_log(f"get_rag_answer END mode={tag} preview={preview(answer)}")
    return finalize_ask_payload(answer, tag, ctx_for_api, answer_source="model")


def get_chat_answer(message: str, history: list[dict[str, str]]) -> dict[str, Any]:
    """Multi-turn chat with retrieval-grounded replies."""
    q = (message or "").strip()
    merged, ctx_for_api = retrieve_rag_context(q)
    kw_payload = expanded_keyword_context(q, top_k=8)
    top_score = int(kw_payload.get("top_score") or 0)
    prompt = chat_prompt(q, history, merged)

    answer = gemini_generate(prompt, gemini_api_key(), chat_generation_config())

    if is_gemini_unavailable(answer):
        rag_log(f"Chat Gemini failed -> grounded fallback top_score={top_score}")
        answer = _chat_fallback_reply(merged, top_score=top_score)

    from .text_utils import collect_highlight_surfaces, find_hadrami_spans

    highlight_surfaces = collect_highlight_surfaces(merged)
    from .serialization import entries_to_response

    return {
        "reply": answer,
        "context": entries_to_response(ctx_for_api),
        "hadrami_spans": find_hadrami_spans(answer, highlight_surfaces),
        "highlight_surfaces": highlight_surfaces,
    }
