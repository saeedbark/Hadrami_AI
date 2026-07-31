"""Retrieval-Augmented Generation pipeline.

Layered architecture:

    retrieval   -> ``retrieval.py``      — keyword / vector / phrase lookups
    generation  -> ``generation.py``     — Gemini client wrapper
    prompts     -> ``prompts.py``        — RAG, chat, conversion, phrase prompts
    serialization-> ``serialization.py`` — DB dict -> Pydantic / response payload
    text_utils  -> ``text_utils.py``     — span detection + normalization
    pipeline    -> ``pipeline.py``       — public orchestration (get_rag_answer…)

External callers should import from :mod:`app.rag.pipeline` directly — the
legacy ``app.rag_engine`` backward-compat shim has been removed (it had zero
remaining importers).
"""

from .pipeline import (
    MODE,
    get_chat_answer,
    get_conversion_answer,
    get_rag_answer,
    retrieve_phrase_context,
    retrieve_rag_context,
)

__all__ = [
    "MODE",
    "get_chat_answer",
    "get_conversion_answer",
    "get_rag_answer",
    "retrieve_phrase_context",
    "retrieve_rag_context",
]
