"""Environment-driven knobs for the RAG pipeline.

Kept in a dedicated module so callers and tests can monkey-patch these values
without importing the whole pipeline.
"""

from __future__ import annotations

import os


MODE = os.getenv("RAG_MODE", "local").strip().lower() or "local"

GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")


def _parse_fallback_models() -> list[str]:
    """``GEMINI_FALLBACK_MODELS`` env var (comma-separated) overrides the default."""
    raw = (os.getenv("GEMINI_FALLBACK_MODELS") or "").strip()
    if raw:
        return [m.strip() for m in raw.split(",") if m.strip()]
    # Default: sensible chain after GEMINI_MODEL; all must support
    # ``generateContent`` on the current API.
    return [
        "gemini-2.0-flash",
        "gemini-2.5-flash-lite",
    ]


GEMINI_FALLBACK_MODELS: list[str] = _parse_fallback_models()

QUERY_CACHE_TTL_SECONDS = max(0, int((os.getenv("RAG_CACHE_TTL_SECONDS") or "90").strip()))


def _parse_confidence_gate() -> float:
    raw = (os.getenv("RAG_CONFIDENCE_GATE") or "0.65").strip()
    try:
        v = float(raw)
    except ValueError:
        v = 0.65
    return max(0.0, min(1.0, v))


# Soft "is the user's word actually in our lexicon?" gate. When neither the
# keyword search produces a strong hit (>= 70) nor the vector search produces
# a similarity >= this gate, we emit the unknown-word block + suggest_word=True
# instead of a confident answer. NOT a retrieval cutoff — retrieval still uses
# the existing 0.25 vector floor in retrieval.py.
RAG_CONFIDENCE_GATE: float = _parse_confidence_gate()


def gemini_api_key() -> str:
    """Read ``GEMINI_API_KEY`` lazily so .env reloads are picked up."""
    return (os.getenv("GEMINI_API_KEY") or "").strip()


def rag_debug_enabled() -> bool:
    return os.getenv("RAG_DEBUG", "1").lower() not in ("0", "false", "no", "off")


def rag_response_mode_tag() -> str:
    return "local_gemini" if MODE == "local" else "gemini"
