"""Public orchestration layer: compose retrieval → prompt → generation → serialize.

This module owns the three user-facing functions the HTTP handlers call:

* :func:`get_rag_answer`        — ``/ask``
* :func:`get_chat_answer`       — ``/chat``
* :func:`get_conversion_answer` — ``/ask`` when the question looks like a
                                  dialect-conversion request (shared behavior
                                  with ``/convert-phrase`` but without chunking)

The phrase-conversion service
(:mod:`app.services.phrase_conversion_service`) imports a few helpers from
:mod:`.generation` and :mod:`.retrieval` directly — it is *not* a
private-import coupling; it is a deliberately-thin wrapper around the same
retrieval + generation primitives.
"""

from __future__ import annotations

from typing import Any

from .config import (
    MODE,
    RAG_CONFIDENCE_GATE,
    gemini_api_key,
    rag_response_mode_tag,
)
from .generation import chat_generation_config, gemini_generate, is_gemini_unavailable
from .logging_utils import preview, rag_log
from .prompts import (
    chat_prompt,
    conversion_prompt,
    looks_like_conversion_request,
    prompt_for_gemini,
)
from .retrieval import (
    expanded_keyword_context,
    phrase_top_score,
    retrieve_phrase_context,
    retrieve_rag_context,
)
from .serialization import finalize_ask_payload
from .system_prompt import HADRAMI_SYSTEM_PROMPT, Intent, intent_for
from .text_utils import first_example


__all__ = [
    "MODE",
    "get_chat_answer",
    "get_conversion_answer",
    "get_rag_answer",
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


def _suggest_word_block(question: str) -> str:
    """The exact unknown-word block the spec requires.

    The leading marker is the canonical refusal text the system prompt also
    instructs the model to emit; we inline it here for fallback paths and as
    the deterministic answer when retrieval is empty / weak.
    """
    word = (question or "").strip() or "—"
    return (
        "هذه الكلمة غير موجودة في القاموس الحالي. يمكنك اقتراح إضافتها.\n\n"
        "---\n"
        "⚠️ كلمات غير موجودة في القاموس:\n"
        f"- \"{word}\" — لم يتم العثور عليها في القاموس الحالي.\n"
        "هل تريد اقتراح إضافتها؟ سيتم مراجعتها من قِبل المختصين قبل إضافتها رسمياً.\n"
        "---"
    )


def _top_similarity(entries: list[dict]) -> float:
    """Return the highest ``similarity`` score among vector hits, or 0.0."""
    best = 0.0
    for e in entries:
        sim = e.get("similarity")
        if isinstance(sim, (int, float)) and sim > best:
            best = float(sim)
    return best


def _is_confidently_grounded(entries: list[dict], top_keyword_score: int) -> bool:
    """Decide whether retrieval is strong enough to ground a real answer.

    Confident if either:
      * keyword scoring produced a strong hit (>= _MIN_FALLBACK_SCORE), OR
      * the best vector similarity meets the confidence gate.
    """
    if not entries:
        return False
    if top_keyword_score >= _MIN_FALLBACK_SCORE:
        return True
    return _top_similarity(entries) >= RAG_CONFIDENCE_GATE


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
    """Grounded fallback for ``/chat`` when Gemini fails.

    Mirrors :func:`_lexicon_fallback_answer` (single best-match entry) rather
    than dumping the top-3 hits — a multi-entry dump reads as broken/unrelated
    answers glued together when the user only asked about one word.
    """
    if not entries or top_score < _MIN_FALLBACK_SCORE:
        return (
            "تعذّر الاتصال بنموذج الإجابة، ولم يُسترجَع من القاموس ما يكفي للإجابة بدقة. "
            "جرّب إعادة صياغة السؤال أو البحث عن الكلمة مباشرةً في صفحة القاموس."
        )
    return _lexicon_fallback_answer(entries, top_score)


# ---------------------------------------------------------------------------
# Public entrypoints
# ---------------------------------------------------------------------------

def get_conversion_answer(question: str) -> dict[str, Any]:
    """Answer a Hadrami→MSA conversion question with phrase-lexicon retrieval."""
    merged, ctx_for_api = retrieve_phrase_context(question)
    top_score = phrase_top_score(question)
    prompt = conversion_prompt(question, merged)
    answer = gemini_generate(prompt, gemini_api_key())

    if is_gemini_unavailable(answer):
        print(
            f"🤖❌ RAG/convert: Gemini not used. Reason: {preview(answer, 240)} | "
            f"top_score={top_score} | lexicon_hits={len(merged)}",
            flush=True,
        )
        fb = _lexicon_fallback_answer(merged, top_score)
        tag = rag_response_mode_tag()
        rag_log(f"conversion Gemini failed -> grounded fallback mode={tag} preview={preview(fb)}")
        return finalize_ask_payload(fb, tag, ctx_for_api, answer_source="lexicon")

    tag = rag_response_mode_tag()
    rag_log(
        f"🤖✅ RAG/convert: reply from Gemini | mode={tag!r} | chars={len(answer)} | "
        f"preview: {preview(answer)}"
    )
    rag_log(f"get_conversion_answer END mode={tag} preview={preview(answer)}")
    return finalize_ask_payload(answer, tag, ctx_for_api, answer_source="model")


def get_rag_answer(question: str) -> dict[str, Any]:
    """Answer an informational question about a Hadrami word/phrase."""
    q = (question or "").strip()

    if looks_like_conversion_request(q):
        return get_conversion_answer(q)

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


def _chat_payload(
    reply: str,
    ctx_for_api: list[dict],
    *,
    intent: Intent,
    suggest_word: bool,
    answer_source: str,
) -> dict[str, Any]:
    from .serialization import entries_to_response
    from .text_utils import collect_highlight_surfaces, find_hadrami_spans

    highlight_surfaces = collect_highlight_surfaces(ctx_for_api)
    return {
        "reply": reply,
        "intent": intent,
        "context": entries_to_response(ctx_for_api),
        "hadrami_spans": find_hadrami_spans(reply, highlight_surfaces),
        "highlight_surfaces": highlight_surfaces,
        "suggest_word": suggest_word,
        "answer_source": answer_source,
    }


def get_chat_answer(message: str, history: list[dict[str, str]]) -> dict[str, Any]:
    """Unified Hadrami chat dispatcher.

    Auto-classifies the user message and routes through the right
    retrieval + prompt builder. ``/ask`` (Q&A) and ``/convert-phrase``
    behaviour are merged into this entrypoint behind a single Gemini call
    that always carries the canonical Hadrami system prompt.

    Intents:
      * ``convert`` — phrase-lexicon retrieval + conversion prompt
      * ``word`` / ``define`` / ``semantic`` / ``qa`` — RAG retrieval +
        chat prompt body
    """
    q = (message or "").strip()
    intent: Intent = intent_for(q)

    if intent == "convert":
        merged, ctx_for_api = retrieve_phrase_context(q)
        top_score = phrase_top_score(q)
        body = conversion_prompt(q, merged)
    else:
        merged, ctx_for_api = retrieve_rag_context(q)
        kw_payload = expanded_keyword_context(q, top_k=8)
        top_score = int(kw_payload.get("top_score") or 0)
        body = chat_prompt(q, history, merged)

    confident = _is_confidently_grounded(merged, top_score)

    # Short-circuit when the user is clearly asking about a specific word that
    # is not in the lexicon — emit the spec's suggest-word block deterministically
    # rather than spend a Gemini call to refuse.
    if not confident and intent in ("word", "define", "convert"):
        rag_log(
            f"chat suggest-word short-circuit intent={intent} top_score={top_score} "
            f"hits={len(merged)}"
        )
        reply = _suggest_word_block(q)
        return _chat_payload(
            reply,
            ctx_for_api,
            intent=intent,
            suggest_word=True,
            answer_source="lexicon",
        )

    answer = gemini_generate(
        body,
        gemini_api_key(),
        chat_generation_config(),
        system_instruction=HADRAMI_SYSTEM_PROMPT,
    )

    if is_gemini_unavailable(answer):
        rag_log(
            f"Chat Gemini failed -> grounded fallback intent={intent} top_score={top_score}"
        )
        answer = _chat_fallback_reply(merged, top_score=top_score)
        return _chat_payload(
            answer,
            ctx_for_api,
            intent=intent,
            suggest_word=not confident,
            answer_source="lexicon",
        )

    rag_log(
        f"🤖✅ /chat: reply from Gemini | intent={intent} | chars={len(answer)} | "
        f"preview: {preview(answer)}"
    )
    return _chat_payload(
        answer,
        ctx_for_api,
        intent=intent,
        suggest_word=False,
        answer_source="model",
    )
