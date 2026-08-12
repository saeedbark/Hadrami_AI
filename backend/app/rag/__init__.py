"""Retrieval-Augmented Generation pipeline.

Layered architecture:

    retrieval   -> ``retrieval.py``      — keyword / vector / phrase lookups
    generation  -> ``generation.py``     — Gemini client wrapper
    prompts     -> ``prompts.py``        — RAG, chat, conversion, phrase prompts
    serialization-> ``serialization.py`` — DB dict -> Pydantic / response payload
    text_utils  -> ``text_utils.py``     — span detection + normalization
    pipeline    -> ``pipeline.py``       — public orchestration (get_rag_answer…)

External callers import the submodules directly, e.g.
``from app.rag.pipeline import get_chat_answer``.
"""
