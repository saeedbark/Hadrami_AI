"""Small logging helpers shared across the RAG pipeline."""

from __future__ import annotations

from .config import rag_debug_enabled


def rag_log(msg: str) -> None:
    """Print ``msg`` to stdout when ``RAG_DEBUG`` is enabled."""
    if rag_debug_enabled():
        print(msg, flush=True)


def preview(text: str, max_len: int = 160) -> str:
    t = (text or "").replace("\n", " ")
    return t if len(t) <= max_len else t[: max_len - 3] + "..."
