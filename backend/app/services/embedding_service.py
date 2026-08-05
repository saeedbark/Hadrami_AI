"""Thin wrapper around Google Generative AI embedding model.

Used by the semantic-search endpoint and the sync script to produce
768-dim vectors compatible with the ``entries.embedding`` column.
"""

from __future__ import annotations

import os
from typing import Optional

# Use a model that supports ``embedContent`` (see ``genai.list_models()``). 768-d output matches
# ``public.entries.embedding vector(768)``; ``output_dimensionality`` is required for ``gemini-embedding-001``.
_EMBED_MODEL = "models/gemini-embedding-001"
OUTPUT_DIM = 768
_EMBED_TASK = "RETRIEVAL_QUERY"
_EMBED_TASK_DOC = "RETRIEVAL_DOCUMENT"


def _api_key() -> str:
    return (os.getenv("GEMINI_API_KEY") or "").strip()


def embed_text(text: str, *, task_type: str = _EMBED_TASK) -> Optional[list[float]]:
    """Return a 768-dim embedding or ``None`` if the service is unavailable."""
    key = _api_key()
    if not key:
        return None
    try:
        import google.generativeai as genai

        genai.configure(api_key=key)
        result = genai.embed_content(
            model=_EMBED_MODEL,
            content=text,
            task_type=task_type,
            output_dimensionality=OUTPUT_DIM,
        )
    
        return result["embedding"]
    except Exception as e:
        try:
            from ..rag.logging_utils import rag_log

            rag_log(f"embed_text: failed ({_EMBED_MODEL!r}): {e!r}")
        except Exception:
            pass
        return None


def embed_texts(
    texts: list[str], *, task_type: str = _EMBED_TASK_DOC
) -> list[Optional[list[float]]]:
    """Batch-embed a list of texts. Returns one embedding (or None) per input."""
    key = _api_key()
    if not key:
        return [None] * len(texts)
    try:
        import google.generativeai as genai

        genai.configure(api_key=key)
        out: list[Optional[list[float]]] = []
        for text in texts:
            try:
                result = genai.embed_content(
                    model=_EMBED_MODEL,
                    content=text,
                    task_type=task_type,
                    output_dimensionality=OUTPUT_DIM,
                )
                out.append(result["embedding"])
            except Exception:
                out.append(None)
        return out
    except ImportError:
        return [None] * len(texts)
