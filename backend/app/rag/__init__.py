"""Retrieval-Augmented Generation pipeline.

Layered architecture:

    retrieval   -> ``retrieval.py``      — keyword / vector / phrase lookups
    generation  -> ``generation.py``     — Gemini client wrapper
    prompts     -> ``prompts.py``        — RAG, chat, translation, phrase prompts
    serialization-> ``serialization.py`` — DB dict -> Pydantic / response payload
    text_utils  -> ``text_utils.py``     — span detection + normalization
    pipeline    -> ``pipeline.py``       — public orchestration (get_rag_answer…)

External callers should import from :mod:`app.rag.pipeline` (or the legacy
``app.rag_engine`` shim, which re-exports these public symbols).
"""

from .pipeline import (
    MODE,
    get_chat_answer,
    get_rag_answer,
    get_translation_answer,
    retrieve_phrase_context,
    retrieve_rag_context,
)

__all__ = [
    "MODE",
    "get_chat_answer",
    "get_rag_answer",
    "get_translation_answer",
    "retrieve_phrase_context",
    "retrieve_rag_context",
]
