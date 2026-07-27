"""Thin wrapper around the Gemini text-generation API.

Keeps the rest of the pipeline free of vendor-specific imports and gives us
exactly one place to migrate to ``google.genai`` when we finally drop the
deprecated ``google-generativeai`` SDK.
"""

from __future__ import annotations

from typing import Any

from .config import GEMINI_FALLBACK_MODELS, GEMINI_MODEL
from .logging_utils import preview, rag_log


GEMINI_UNAVAILABLE_PREFIX = "Gemini not available:"


def is_gemini_unavailable(reply: str) -> bool:
    return reply.startswith(GEMINI_UNAVAILABLE_PREFIX)


def _format_gemini_failure_chain(failures: list[tuple[str, Exception]]) -> str:
    """Prefer quota/rate-limit (the usual user-facing issue) over a trailing 404 on a bad model id."""
    s_all = " | ".join(f"{n}: {e!r}" for n, e in failures)
    for mname, err in failures:
        name = type(err).__name__
        s = str(err)
        if name == "ResourceExhausted" or "quota" in s.lower() or "exceeded" in s.lower():
            return f"quota or rate limit on {mname!r} ({name}): {s[:400]}"
    return s_all[:800]


def gemini_generate(
    prompt: str,
    api_key: str,
    generation_config: Any | None = None,
    system_instruction: str | None = None,
) -> str:
    """Generate text with the primary model, falling back through a model list.

    Returns either the generated text, or ``"Gemini not available: <reason>"``
    which callers detect via :func:`is_gemini_unavailable` to switch to the
    deterministic lexicon-grounded fallback.

    ``system_instruction`` is passed to ``GenerativeModel`` as Gemini's native
    system prompt; ``None`` preserves the legacy "everything in one user
    string" call shape.
    """
    if not api_key:
        rag_log("Gemini: no API key (GEMINI_API_KEY empty)")
        return f"{GEMINI_UNAVAILABLE_PREFIX} set GEMINI_API_KEY"

    rag_log(f"Gemini model={GEMINI_MODEL!r} chars={len(prompt)} | prompt: {preview(prompt, 200)}")
    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)

        order: list[str] = []
        for m in [GEMINI_MODEL, *GEMINI_FALLBACK_MODELS]:
            if m and m not in order:
                order.append(m)

        gen_kwargs: dict[str, Any] = {}
        if generation_config is not None:
            gen_kwargs["generation_config"] = generation_config

        model_kwargs: dict[str, Any] = {}
        if system_instruction:
            model_kwargs["system_instruction"] = system_instruction

        failures: list[tuple[str, Exception]] = []
        for mname in order:
            try:
                model = genai.GenerativeModel(mname, **model_kwargs)
                response = model.generate_content(prompt, **gen_kwargs)
                text = (response.text or "").strip()
                if mname != GEMINI_MODEL:
                    rag_log(f"Gemini used fallback model={mname!r}")
                rag_log(f"Gemini answer_chars={len(text)} preview: {preview(text)}")
                return text
            except Exception as e:
                failures.append((mname, e))
                rag_log(f"Gemini model {mname!r} failed: {e!r}")

        if failures:
            summary = _format_gemini_failure_chain(failures)
            return f"{GEMINI_UNAVAILABLE_PREFIX} {summary}"
        return f"{GEMINI_UNAVAILABLE_PREFIX} unknown error"
    except ImportError:
        rag_log("Gemini: google-generativeai not installed")
        return f"{GEMINI_UNAVAILABLE_PREFIX} google-generativeai not installed"


def chat_generation_config() -> Any | None:
    """Return a GenerationConfig that favors stable multi-sentence chat output."""
    try:
        import google.generativeai as genai

        return genai.types.GenerationConfig(
            max_output_tokens=1536,
            temperature=0.35,
        )
    except ImportError:
        return None
