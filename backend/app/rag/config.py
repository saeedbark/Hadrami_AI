"""Environment-driven knobs for the RAG pipeline.

Kept in a dedicated module so callers and tests can monkey-patch these values
without importing the whole pipeline.
"""

from __future__ import annotations

import os


MODE = os.getenv("RAG_MODE", "local").strip().lower() or "local"

GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

# Sensible order after GEMINI_MODEL; all must be valid for ``generateContent`` on the
# current API. ``gemini-1.5-flash-002`` and similar versioned IDs often 404.
GEMINI_FALLBACK_MODELS: list[str] = [
    "gemini-2.0-flash",
    "gemini-2.5-flash-lite",
    "gemini-1.5-flash",
]

QUERY_CACHE_TTL_SECONDS = max(0, int((os.getenv("RAG_CACHE_TTL_SECONDS") or "90").strip()))


def gemini_api_key() -> str:
    """Read ``GEMINI_API_KEY`` lazily so .env reloads are picked up."""
    return (os.getenv("GEMINI_API_KEY") or "").strip()


def rag_debug_enabled() -> bool:
    return os.getenv("RAG_DEBUG", "1").lower() not in ("0", "false", "no", "off")


def rag_response_mode_tag() -> str:
    return "local_gemini" if MODE == "local" else "gemini"
