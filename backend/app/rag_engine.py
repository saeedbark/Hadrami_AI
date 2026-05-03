"""Backward-compatibility shim for the old monolithic ``rag_engine`` module.

The real implementation now lives in :mod:`app.rag` (split into
``retrieval``, ``generation``, ``prompts``, ``serialization``,
``text_utils``, and ``pipeline``). Existing imports of
``from app.rag_engine import ...`` continue to work unchanged.

New callers should import from :mod:`app.rag` directly; this shim will be
removed once every internal call site (tests, scripts) migrates.
"""

from __future__ import annotations

from .rag.config import MODE, gemini_api_key as _gemini_api_key
from .rag.generation import (
    GEMINI_UNAVAILABLE_PREFIX,
    gemini_generate as _gemini_generate,
    is_gemini_unavailable,
)
from .rag.logging_utils import preview as _preview, rag_log as _rag_log
from .rag.pipeline import (
    get_chat_answer,
    get_rag_answer,
    get_translation_answer,
)
from .rag.retrieval import (
    retrieve_phrase_context,
    retrieve_rag_context,
)


__all__ = [
    "MODE",
    "GEMINI_UNAVAILABLE_PREFIX",
    "get_chat_answer",
    "get_rag_answer",
    "get_translation_answer",
    "is_gemini_unavailable",
    "retrieve_phrase_context",
    "retrieve_rag_context",
    # legacy private aliases kept for backward-compat with older call sites:
    "_gemini_api_key",
    "_gemini_generate",
    "_preview",
    "_rag_log",
]


if __name__ == "__main__":
    import sys

    query = sys.argv[1] if len(sys.argv) > 1 else "ما معنى كلمة ويش؟"
    print(f"Query: {query}")
    print(f"Mode: {MODE}")
    result = get_rag_answer(query)
    print(f"Answer: {result['answer']}")
    print(f"Context ({len(result['context'])} entries):")
    for e in result["context"]:
        print(f"  - {e.word_vocalized} -> {e.fusha_equivalent}")
